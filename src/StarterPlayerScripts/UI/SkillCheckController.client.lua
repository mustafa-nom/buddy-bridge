--!strict
-- Balance-the-line skill check. After the reel taps complete, the server
-- fires BeginSkillCheck and the player has a fixed window (default ~6.5s)
-- to keep their cursor inside a moving green zone.
--
-- Mechanic (Fisch-style):
--   - Hold mouse button = cursor accelerates RIGHT
--   - Release mouse button = cursor drifts LEFT
--   - Green zone moves left/right with random direction flips and speed
--     changes. Width and target shifts vary so it can't be memorized.
--   - When the timer ends, fire SkillCheckComplete with the accuracy
--     (fraction of frames the cursor was inside the zone). The server
--     advances to the inspection card whether you "won" or not — accuracy
--     is just a reward modifier hook.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local UIStyle = require(Modules:WaitForChild("UIStyle"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local player = Players.LocalPlayer

-- Tuning. All cursor / zone values are in normalized [0..1] space so the
-- math doesn't depend on the bar's pixel width.
local BAR_WIDTH = 540
local BAR_HEIGHT = 36
local CURSOR_WIDTH = 8
local CURSOR_OVERHANG = 14            -- cursor extends this many px above/below bar

local CURSOR_ACCEL = 4.0               -- /s² when held
local CURSOR_DECEL = 3.4               -- /s² when not held (toward left)
local CURSOR_DRAG = 0.94               -- per-frame velocity damping
local CURSOR_MAX_VEL = 1.6             -- cap velocity so it doesn't snap

local ZONE_WIDTH_MIN = 0.18
local ZONE_WIDTH_MAX = 0.30
local ZONE_SPEED_MIN = 0.08
local ZONE_SPEED_MAX = 0.22
local ZONE_FLIP_MIN_SEC = 1.1
local ZONE_FLIP_MAX_SEC = 2.6

-- ---------------------------------------------------------------------------

local active = false
local activeGui: ScreenGui? = nil
local heartbeatConn: RBXScriptConnection? = nil
local inputBeganConn: RBXScriptConnection? = nil
local inputEndedConn: RBXScriptConnection? = nil

local function clear()
	active = false
	if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
	if inputBeganConn then inputBeganConn:Disconnect(); inputBeganConn = nil end
	if inputEndedConn then inputEndedConn:Disconnect(); inputEndedConn = nil end
	if activeGui then activeGui:Destroy(); activeGui = nil end
end

local function start(payload: any)
	if active then clear() end
	active = true
	local duration = (type(payload) == "table" and tonumber(payload.duration)) or 6.5
	if payload and type(payload.seed) == "number" then
		math.randomseed(payload.seed)
	end

	local screen = UIBuilder.GetScreenGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PhishSkillCheckGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 35
	gui.Parent = screen.Parent
	activeGui = gui

	-- Outer panel: title + tooltip + bar + countdown. Panel grew taller to
	-- fit the how-to-play strip between the title and the bar.
	local panel = UIStyle.MakePanel({
		Name = "SkillCheckPanel",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -120),
		Size = UDim2.fromOffset(BAR_WIDTH + 64, BAR_HEIGHT + 130),
		BackgroundColor3 = UIStyle.Palette.Panel,
		Parent = gui,
	})
	UIStyle.ApplyScale(panel, 0.85)

	UIStyle.MakeLabel({
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(BAR_WIDTH, 28),
		Text = "BALANCE THE LINE",
		Font = UIStyle.FontDisplay,
		TextSize = UIStyle.TextSize.Heading,
		TextColor3 = UIStyle.Palette.TitleGold,
		Parent = panel,
	})

	-- Inline how-to-play tooltip. Sits between the title and the bar so
	-- a first-time player learns the controls without a modal.
	local tip = Instance.new("Frame")
	tip.Name = "Tip"
	tip.AnchorPoint = Vector2.new(0.5, 0)
	tip.Position = UDim2.new(0.5, 0, 0, 40)
	tip.Size = UDim2.fromOffset(BAR_WIDTH, 28)
	tip.BackgroundColor3 = UIStyle.Palette.CardSlot
	tip.BackgroundTransparency = 0.2
	tip.BorderSizePixel = 0
	tip.Parent = panel
	UIStyle.ApplyCorner(tip, UDim.new(0, 6))
	UIStyle.ApplyStroke(tip, UIStyle.Palette.SlotStroke, 1)
	UIStyle.MakeLabel({
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		Text = "<b>Hold click</b> to move right · <b>release</b> to drift left · stay in the <b>green</b>",
		Font = UIStyle.FontBold,
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = UIStyle.Palette.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Center,
		RichText = true,
		Parent = tip,
	})

	local timerLabel = UIStyle.MakeLabel({
		Name = "Timer",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(BAR_WIDTH, 22),
		Text = "",
		Font = UIStyle.FontBold,
		TextSize = UIStyle.TextSize.Body,
		TextColor3 = UIStyle.Palette.TextMuted,
		Parent = panel,
	})

	-- The bar itself. Pulled down a bit so the tooltip has space above it.
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.new(0.5, 0, 0.5, 18)
	bar.Size = UDim2.fromOffset(BAR_WIDTH, BAR_HEIGHT)
	bar.BackgroundColor3 = UIStyle.Palette.CardSlot
	bar.BorderSizePixel = 0
	bar.Parent = panel
	UIStyle.ApplyCorner(bar, UDim.new(0, 8))
	UIStyle.ApplyStroke(bar, UIStyle.Palette.SlotStroke, 2)
	UIStyle.ApplyGradient(bar, {
		top = Color3.fromRGB(14, 10, 18),
		bottom = Color3.fromRGB(28, 22, 32),
		rotation = 90,
	})

	-- Green safe zone.
	local zone = Instance.new("Frame")
	zone.Name = "Zone"
	zone.AnchorPoint = Vector2.new(0, 0.5)
	zone.Size = UDim2.fromScale(0.25, 1)
	zone.Position = UDim2.fromScale(0.4, 0.5)
	zone.BackgroundColor3 = Color3.fromRGB(120, 230, 130)
	zone.BorderSizePixel = 0
	zone.Parent = bar
	UIStyle.ApplyCorner(zone, UDim.new(0, 6))
	UIStyle.ApplyStroke(zone, Color3.fromRGB(40, 110, 50), 1)
	UIStyle.ApplyGradient(zone, {
		top = Color3.fromRGB(160, 240, 150),
		bottom = Color3.fromRGB(80, 200, 100),
		rotation = 90,
	})

	-- Cursor: thin black bar overhanging the bar above and below.
	local cursor = Instance.new("Frame")
	cursor.Name = "Cursor"
	cursor.AnchorPoint = Vector2.new(0.5, 0.5)
	cursor.Size = UDim2.fromOffset(CURSOR_WIDTH, BAR_HEIGHT + CURSOR_OVERHANG * 2)
	cursor.Position = UDim2.fromScale(0.1, 0.5)
	cursor.BackgroundColor3 = Color3.fromRGB(20, 14, 22)
	cursor.BorderSizePixel = 0
	cursor.Parent = bar
	UIStyle.ApplyCorner(cursor, UDim.new(0, 3))
	UIStyle.ApplyStroke(cursor, Color3.fromRGB(255, 245, 220), 1)

	-- ---------------------------- state ------------------------------
	local cursorX = 0.1                     -- normalized [0, 1]
	local cursorVel = 0.0
	local zoneCenter = 0.5
	local zoneWidth = math.random() * (ZONE_WIDTH_MAX - ZONE_WIDTH_MIN) + ZONE_WIDTH_MIN
	local zoneVel = (math.random() < 0.5 and -1 or 1) *
		(ZONE_SPEED_MIN + math.random() * (ZONE_SPEED_MAX - ZONE_SPEED_MIN))
	local nextZoneFlip = ZONE_FLIP_MIN_SEC + math.random() * (ZONE_FLIP_MAX_SEC - ZONE_FLIP_MIN_SEC)
	local elapsed = 0
	local timeInZone = 0
	local frameCount = 0
	local framesInZone = 0
	local mouseHeld = false

	-- Input: mouse + touch + space (so it works on any device).
	local function inputDown(input: InputObject, processed: boolean)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.Space
		then
			mouseHeld = true
		end
	end
	local function inputUp(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.Space
		then
			mouseHeld = false
		end
	end
	inputBeganConn = UserInputService.InputBegan:Connect(inputDown)
	inputEndedConn = UserInputService.InputEnded:Connect(inputUp)

	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		frameCount += 1

		-- Cursor physics.
		local accel = mouseHeld and CURSOR_ACCEL or -CURSOR_DECEL
		cursorVel += accel * dt
		cursorVel *= CURSOR_DRAG
		cursorVel = math.clamp(cursorVel, -CURSOR_MAX_VEL, CURSOR_MAX_VEL)
		cursorX += cursorVel * dt
		if cursorX <= 0 then cursorX = 0; cursorVel = 0 end
		if cursorX >= 1 then cursorX = 1; cursorVel = 0 end

		-- Zone movement.
		nextZoneFlip -= dt
		if nextZoneFlip <= 0 then
			zoneVel = -zoneVel * (0.6 + math.random())
			zoneVel = math.clamp(zoneVel, -ZONE_SPEED_MAX, ZONE_SPEED_MAX)
			-- Occasionally resize too, so nothing is memorizable.
			zoneWidth = math.random() * (ZONE_WIDTH_MAX - ZONE_WIDTH_MIN) + ZONE_WIDTH_MIN
			nextZoneFlip = ZONE_FLIP_MIN_SEC + math.random() * (ZONE_FLIP_MAX_SEC - ZONE_FLIP_MIN_SEC)
		end
		zoneCenter += zoneVel * dt
		local halfWidth = zoneWidth * 0.5
		if zoneCenter - halfWidth <= 0 then zoneCenter = halfWidth; zoneVel = math.abs(zoneVel) end
		if zoneCenter + halfWidth >= 1 then zoneCenter = 1 - halfWidth; zoneVel = -math.abs(zoneVel) end

		-- Render.
		zone.Size = UDim2.fromScale(zoneWidth, 1)
		zone.Position = UDim2.fromScale(zoneCenter - halfWidth, 0.5)
		cursor.Position = UDim2.fromScale(cursorX, 0.5)

		local inZone = (cursorX >= zoneCenter - halfWidth) and (cursorX <= zoneCenter + halfWidth)
		if inZone then
			framesInZone += 1
			timeInZone += dt
			cursor.BackgroundColor3 = Color3.fromRGB(40, 100, 50)
		else
			cursor.BackgroundColor3 = Color3.fromRGB(20, 14, 22)
		end

		timerLabel.Text = string.format("%.1fs left  ·  %d%% in zone",
			math.max(0, duration - elapsed),
			frameCount > 0 and math.floor((framesInZone / frameCount) * 100) or 0)

		if elapsed >= duration then
			local accuracy = frameCount > 0 and (framesInZone / frameCount) or 0
			RemoteService.FireServer("SkillCheckComplete", { accuracy = accuracy })
			clear()
		end
	end)
end

RemoteService.OnClientEvent("BeginSkillCheck", start)

-- Defensive: if the inspection card shows for any reason (server timeout,
-- external advance), kill the skill-check UI so they don't overlap.
RemoteService.OnClientEvent("ShowInspectionCard", function()
	if active then clear() end
end)

player.AncestryChanged:Connect(function(_, parent)
	if not parent then clear() end
end)
