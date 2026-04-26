--!strict
-- Top-center "NEW!" / "CAUGHT" / "MASTERED!" call card, modeled on the
-- Fish It! catch popup. Yellow ribbon banner with the variant text, the
-- fish art floating below it, then a wood-plank with the species name +
-- catch count. Slides down from above, bobs gently while held, slides
-- back up. Listens for SpeciesFound / SpeciesCaught / SpeciesUnlocked.
--
-- Falls back to a quiet placeholder when no asset id is wired up yet, so
-- the popup never visually breaks before art uploads are done.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local UIStyle = require(Modules:WaitForChild("UIStyle"))
local FishArt = require(Modules:WaitForChild("FishArt"))
local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local screen = UIBuilder.GetScreenGui()

local DEBUG = true

local CARD_WIDTH = 320
local CARD_HEIGHT = 230
local TOP_OFFSET = 16
local SLIDE_TIME = 0.32
local SLIDE_OUT_TIME = 0.26
local HOLD_TIME = 3.0
local CAUGHT_HOLD_TIME = 1.8

local rarityColors: { [string]: Color3 } = {
	Common = UIStyle.Palette.Common,
	Uncommon = UIStyle.Palette.Uncommon,
	Rare = UIStyle.Palette.Rare,
	Epic = UIStyle.Palette.Epic,
	Legendary = UIStyle.Palette.Legendary,
}

local function rarityColor(rarity: string?): Color3
	return (rarity and rarityColors[rarity]) or UIStyle.Palette.Common
end

type Variant = "Found" | "Caught" | "Mastered"

type PopupPayload = {
	id: string,
	displayName: string,
	rarity: string?,
	variant: Variant,
	count: number?,
	catchesToUnlock: number?,
}

local queue: { PopupPayload } = {}
local active = false

local function clearAny()
	local old = screen:FindFirstChild("FishCatchPopup")
	if old then old:Destroy() end
end

-- Yellow ribbon banner with the variant text. Cream→yellow→orange
-- gradient, dark brown stroke, 3-stop gradient, faux ribbon shadow tab.
local function buildBanner(parent: Instance, variant: Variant): Frame
	local label, bannerColorTop, bannerColorBottom, strokeColor, textColor
	local width, textSize

	if variant == "Mastered" then
		label = "MASTERED!"
		bannerColorTop = Color3.fromRGB(255, 232, 130)
		bannerColorBottom = Color3.fromRGB(232, 150, 36)
		strokeColor = Color3.fromRGB(96, 50, 12)
		textColor = Color3.fromRGB(72, 36, 8)
		width, textSize = 220, 30
	elseif variant == "Found" then
		label = "NEW!"
		bannerColorTop = Color3.fromRGB(255, 232, 110)
		bannerColorBottom = Color3.fromRGB(248, 178, 50)
		strokeColor = Color3.fromRGB(96, 50, 12)
		textColor = Color3.fromRGB(72, 36, 8)
		width, textSize = 140, 34
	else  -- Caught
		label = "CAUGHT!"
		bannerColorTop = Color3.fromRGB(248, 220, 152)
		bannerColorBottom = Color3.fromRGB(200, 152, 70)
		strokeColor = Color3.fromRGB(80, 44, 14)
		textColor = Color3.fromRGB(60, 32, 8)
		width, textSize = 170, 26
	end

	-- Faux ribbon shadow / drop tab behind the banner — slightly larger,
	-- offset down/right, very transparent. Gives the banner depth.
	local shadow = Instance.new("Frame")
	shadow.Name = "BannerShadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0)
	shadow.Position = UDim2.new(0.5, 4, 0, 6)
	shadow.Size = UDim2.fromOffset(width + 6, 48)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.55
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 4
	shadow.Parent = parent
	UIStyle.ApplyCorner(shadow, UDim.new(0, 10))

	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 2)
	banner.Size = UDim2.fromOffset(width, 46)
	banner.BackgroundColor3 = bannerColorTop
	banner.BorderSizePixel = 0
	banner.ZIndex = 6
	banner.Parent = parent
	UIStyle.ApplyCorner(banner, UDim.new(0, 10))
	UIStyle.ApplyStroke(banner, strokeColor, 3)
	UIStyle.ApplyGradient(banner, {
		top = Color3.new(
			math.min(1, bannerColorTop.R * 1.05),
			math.min(1, bannerColorTop.G * 1.05),
			math.min(1, bannerColorTop.B * 1.05)
		),
		mid = bannerColorTop,
		bottom = bannerColorBottom,
		rotation = 90,
	})

	-- Inner sheen strip across the top.
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.AnchorPoint = Vector2.new(0.5, 0)
	shine.Position = UDim2.new(0.5, 0, 0, 4)
	shine.Size = UDim2.new(1, -18, 0, 4)
	shine.BackgroundColor3 = Color3.fromRGB(255, 255, 240)
	shine.BackgroundTransparency = 0.3
	shine.BorderSizePixel = 0
	shine.ZIndex = 7
	shine.Parent = banner
	UIStyle.ApplyCorner(shine, UDim.new(0, 2))

	-- Text — bold display font with strong dark stroke for that
	-- "stickered cartoon" feel.
	local txt = UIStyle.MakeLabel({
		Size = UDim2.fromScale(1, 1),
		Text = label,
		Font = UIStyle.FontDisplay,
		TextSize = textSize,
		TextColor3 = textColor,
		ZIndex = 8,
		Parent = banner,
	})
	local txtStroke = Instance.new("UIStroke")
	txtStroke.Color = Color3.fromRGB(255, 250, 220)
	txtStroke.Thickness = 1.4
	txtStroke.Transparency = 0.35
	txtStroke.Parent = txt

	return banner
end

-- Brown wood-plank style label — used for the species name + weight row.
-- Looks like the wooden sign in the Fish It! reference: warm wood gradient,
-- darker stroke, cream text with a subtle drop.
local function buildWoodPlank(props: { [string]: any }): Frame
	local plank = Instance.new("Frame")
	plank.Name = props.Name or "WoodPlank"
	plank.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0)
	plank.Position = props.Position or UDim2.new(0.5, 0, 0, 0)
	plank.Size = props.Size or UDim2.fromOffset(280, 38)
	plank.BackgroundColor3 = Color3.fromRGB(116, 78, 44)
	plank.BorderSizePixel = 0
	plank.ZIndex = props.ZIndex or 5
	if props.Parent then plank.Parent = props.Parent end
	UIStyle.ApplyCorner(plank, UDim.new(0, 8))
	UIStyle.ApplyStroke(plank, Color3.fromRGB(58, 36, 18), 3)
	UIStyle.ApplyGradient(plank, {
		top = Color3.fromRGB(160, 110, 64),
		mid = Color3.fromRGB(126, 86, 48),
		bottom = Color3.fromRGB(86, 54, 26),
		rotation = 90,
	})
	-- A faint inner top highlight, like the catch sign in the reference.
	local sheen = Instance.new("Frame")
	sheen.AnchorPoint = Vector2.new(0.5, 0)
	sheen.Position = UDim2.new(0.5, 0, 0, 3)
	sheen.Size = UDim2.new(1, -16, 0, 2)
	sheen.BackgroundColor3 = Color3.fromRGB(220, 180, 130)
	sheen.BackgroundTransparency = 0.55
	sheen.BorderSizePixel = 0
	sheen.ZIndex = (props.ZIndex or 5) + 1
	sheen.Parent = plank
	UIStyle.ApplyCorner(sheen, UDim.new(0, 1))
	return plank
end

local function buildArt(parent: Instance, speciesId: string)
	local art = FishArt.Get(speciesId)
	if art then
		local img = Instance.new("ImageLabel")
		img.Name = "FishArt"
		img.AnchorPoint = Vector2.new(0.5, 0)
		img.Position = UDim2.new(0.5, 0, 0, 78)
		img.Size = UDim2.fromOffset(CARD_WIDTH - 40, 100)
		img.BackgroundTransparency = 1
		img.Image = art
		img.ScaleType = Enum.ScaleType.Fit
		img.ZIndex = 5
		img.Parent = parent
		return
	end
	-- Placeholder so the popup is still useful pre-uploads.
	local placeholder = Instance.new("Frame")
	placeholder.Name = "ArtPlaceholder"
	placeholder.AnchorPoint = Vector2.new(0.5, 0)
	placeholder.Position = UDim2.new(0.5, 0, 0, 78)
	placeholder.Size = UDim2.fromOffset(180, 100)
	placeholder.BackgroundTransparency = 1
	placeholder.BorderSizePixel = 0
	placeholder.Parent = parent
	UIStyle.MakeLabel({
		Size = UDim2.fromScale(1, 1),
		Text = "?",
		Font = UIStyle.FontDisplay,
		TextSize = 64,
		TextColor3 = UIStyle.Palette.TextMuted,
		ZIndex = 5,
		Parent = placeholder,
	})
end

local function buildCard(payload: PopupPayload): Frame
	-- Transparent root — no panel chrome. Stacks: banner ribbon, art,
	-- catch-count line, wood plank with name.
	local root = Instance.new("Frame")
	root.Name = "FishCatchPopup"
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
	root.BackgroundTransparency = 1
	root.ZIndex = 50
	root.Parent = screen
	-- Render at 60% so the call card doesn't dominate the screen.
	UIStyle.ApplyScale(root, 0.6)

	buildBanner(root, payload.variant)
	buildArt(root, payload.id)

	-- Catch progress line (e.g. "3 / 50") — shown for Caught, also for
	-- Found and Mastered when the data is present.
	if payload.count and payload.catchesToUnlock then
		local progressTxt = UIStyle.MakeLabel({
			Name = "Progress",
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromOffset(CARD_WIDTH, 22),
			Position = UDim2.new(0.5, 0, 0, 54),
			Text = string.format("%d / %d", payload.count, payload.catchesToUnlock),
			Font = UIStyle.FontDisplay,
			TextSize = 22,
			TextColor3 = Color3.fromRGB(220, 56, 48),
			ZIndex = 6,
			Parent = root,
		})
		local pStroke = Instance.new("UIStroke")
		pStroke.Color = Color3.fromRGB(255, 250, 235)
		pStroke.Thickness = 1.5
		pStroke.Transparency = 0.15
		pStroke.Parent = progressTxt
	end

	-- Bottom wood plank: species name + rarity tag.
	local plank = buildWoodPlank({
		Position = UDim2.new(0.5, 0, 0, CARD_HEIGHT - 50),
		Size = UDim2.fromOffset(CARD_WIDTH - 20, 38),
		Parent = root,
	})

	UIStyle.MakeLabel({
		Name = "Name",
		Size = UDim2.fromScale(1, 1),
		Text = payload.displayName or payload.id,
		Font = UIStyle.FontDisplay,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(252, 240, 215),
		ZIndex = 7,
		Parent = plank,
	})
	-- Tiny rarity pill below the plank as a finishing accent.
	local rar = rarityColor(payload.rarity)
	local rarPill = Instance.new("Frame")
	rarPill.Name = "RarityPill"
	rarPill.AnchorPoint = Vector2.new(0.5, 0)
	rarPill.Position = UDim2.new(0.5, 0, 0, CARD_HEIGHT - 10)
	rarPill.Size = UDim2.fromOffset(110, 18)
	rarPill.BackgroundColor3 = rar
	rarPill.BackgroundTransparency = 0.1
	rarPill.BorderSizePixel = 0
	rarPill.ZIndex = 8
	rarPill.Parent = root
	UIStyle.ApplyCorner(rarPill, UDim.new(1, 0))
	UIStyle.ApplyStroke(rarPill, Color3.fromRGB(20, 14, 22), 2)
	UIStyle.MakeLabel({
		Size = UDim2.fromScale(1, 1),
		Text = string.upper(payload.rarity or "Common"),
		Font = UIStyle.FontDisplay,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(20, 14, 22),
		ZIndex = 9,
		Parent = rarPill,
	})

	return root
end

local function show(payload: PopupPayload)
	clearAny()

	local root = buildCard(payload)
	-- Slide DOWN from above the screen, then a gentle bob, then slide back up.
	local hidden = UDim2.new(0.5, 0, 0, -CARD_HEIGHT - 20)
	local visible = UDim2.new(0.5, 0, 0, TOP_OFFSET)
	root.Position = hidden

	local slideIn = TweenService:Create(root,
		TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = visible })
	slideIn:Play()
	slideIn.Completed:Wait()

	-- Subtle bob loop while the card is held. Cancelled on slide-out.
	local bobInfo = TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local bob = TweenService:Create(root, bobInfo,
		{ Position = UDim2.new(0.5, 0, 0, TOP_OFFSET + 6) })
	bob:Play()

	local hold = (payload.variant == "Caught") and CAUGHT_HOLD_TIME or HOLD_TIME
	task.wait(hold)

	if not root.Parent then return end
	bob:Cancel()
	root.Position = visible

	local slideOut = TweenService:Create(root,
		TweenInfo.new(SLIDE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = hidden })
	slideOut:Play()
	slideOut.Completed:Wait()
	if root.Parent then root:Destroy() end
end

local function pumpQueue()
	if active then return end
	active = true
	task.spawn(function()
		while #queue > 0 do
			local payload = table.remove(queue, 1)
			if payload then
				local ok, err = pcall(show, payload)
				if not ok then
					warn(string.format(
						"[FishCatchPopup] show() errored for %s (%s): %s",
						tostring(payload.id), tostring(payload.variant), tostring(err)
					))
					clearAny()
				end
				task.wait(0.12)
			end
		end
		active = false
	end)
end

local function enqueue(variant: Variant, payload: any)
	if DEBUG then
		print(string.format(
			"[FishCatchPopup] received %s for %s",
			variant, tostring(payload and (payload :: any).id)
		))
	end
	if type(payload) ~= "table" then return end
	if type(payload.id) ~= "string" or payload.id == "" then return end
	table.insert(queue, {
		id = payload.id,
		displayName = payload.displayName or payload.id,
		rarity = payload.rarity,
		variant = variant,
		count = payload.count,
		catchesToUnlock = payload.catchesToUnlock,
	})
	pumpQueue()
end

RemoteService.OnClientEvent("SpeciesFound", function(payload)
	enqueue("Found", payload)
end)

RemoteService.OnClientEvent("SpeciesCaught", function(payload)
	enqueue("Caught", payload)
end)

RemoteService.OnClientEvent("SpeciesUnlocked", function(payload)
	enqueue("Mastered", payload)
end)
