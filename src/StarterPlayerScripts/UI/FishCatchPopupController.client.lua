--!strict
-- Top-right "NEW!" / "MASTERED!" popup, modeled on the reference Roblox
-- fishing-game catch banner. Listens for the server's SpeciesFound and
-- SpeciesUnlocked events, queues them so multiple unlocks don't overlap,
-- and renders one card at a time with the fish art from FishArt.lua.
--
-- Falls back to a small text-only badge when no asset id is wired up yet,
-- so the popup never visually breaks before the upload step is done.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local UIStyle = require(Modules:WaitForChild("UIStyle"))
local FishArt = require(Modules:WaitForChild("FishArt"))
local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local screen = UIBuilder.GetScreenGui()

-- Flip to false to silence the dev-time receipt logs once we've confirmed
-- the SpeciesFound / SpeciesUnlocked pipeline is healthy.
local DEBUG = true

local CARD_WIDTH = 240
local CARD_HEIGHT = 220
local TOP_OFFSET = 16
local RIGHT_PADDING = 16
local SLIDE_IN_TIME = 0.32
local SLIDE_OUT_TIME = 0.28
local HOLD_TIME = 3.2

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

type Variant = "Found" | "Mastered"

type PopupPayload = {
	id: string,
	displayName: string,
	rarity: string?,
	variant: Variant,
}

local queue: { PopupPayload } = {}
local active = false

local function clearAny()
	local old = screen:FindFirstChild("FishCatchPopup")
	if old then old:Destroy() end
end

local function buildBanner(parent: Instance, variant: Variant): Frame
	local isMastered = variant == "Mastered"
	local label = isMastered and "MASTERED!" or "NEW!"
	local bgColor = isMastered and UIStyle.Palette.TitleGoldHero or UIStyle.Palette.AskFirst
	local strokeColor = isMastered and UIStyle.Palette.BannerStroke or Color3.fromRGB(140, 90, 20)

	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.AnchorPoint = Vector2.new(0, 0)
	banner.Position = UDim2.new(0, -10, 0, -14)
	banner.Size = UDim2.fromOffset(isMastered and 130 or 86, 32)
	banner.BackgroundColor3 = bgColor
	banner.BorderSizePixel = 0
	banner.ZIndex = 6
	banner.Parent = parent
	UIStyle.ApplyCorner(banner, UDim.new(0, 8))
	UIStyle.ApplyStroke(banner, strokeColor, 2)

	local txt = UIStyle.MakeLabel({
		Size = UDim2.fromScale(1, 1),
		Text = label,
		Font = UIStyle.FontDisplay,
		TextSize = isMastered and 20 or 22,
		TextColor3 = Color3.fromRGB(60, 36, 8),
		ZIndex = 7,
		Parent = banner,
	})
	local txtStroke = Instance.new("UIStroke")
	txtStroke.Color = Color3.fromRGB(255, 250, 220)
	txtStroke.Thickness = 1.2
	txtStroke.Transparency = 0.4
	txtStroke.Parent = txt

	return banner
end

local function buildArt(parent: Instance, speciesId: string, found: boolean)
	local art = FishArt.Get(speciesId)
	if art then
		local img = Instance.new("ImageLabel")
		img.Name = "FishArt"
		img.AnchorPoint = Vector2.new(0.5, 0)
		img.Position = UDim2.new(0.5, 0, 0, 22)
		img.Size = UDim2.fromOffset(CARD_WIDTH - 24, 110)
		img.BackgroundTransparency = 1
		img.Image = art
		img.ScaleType = Enum.ScaleType.Fit
		img.ZIndex = 4
		img.Parent = parent

		if not found then
			img.ImageColor3 = Color3.fromRGB(40, 40, 50)
			img.ImageTransparency = 0.2
		end
		return
	end

	-- No asset uploaded yet: render a quiet placeholder so the popup is
	-- still useful (you'll still see the species name + NEW! tag).
	local placeholder = Instance.new("Frame")
	placeholder.Name = "ArtPlaceholder"
	placeholder.AnchorPoint = Vector2.new(0.5, 0)
	placeholder.Position = UDim2.new(0.5, 0, 0, 22)
	placeholder.Size = UDim2.fromOffset(CARD_WIDTH - 24, 110)
	placeholder.BackgroundColor3 = UIStyle.Palette.CardSlot
	placeholder.BackgroundTransparency = 0.2
	placeholder.BorderSizePixel = 0
	placeholder.ZIndex = 4
	placeholder.Parent = parent
	UIStyle.ApplyCorner(placeholder, UDim.new(0, 8))
	UIStyle.ApplyStroke(placeholder, UIStyle.Palette.SlotStroke, 2)
	UIStyle.MakeLabel({
		Size = UDim2.fromScale(1, 1),
		Text = "FISH",
		Font = UIStyle.FontDisplay,
		TextSize = 28,
		TextColor3 = UIStyle.Palette.TextMuted,
		ZIndex = 5,
		Parent = placeholder,
	})
end

local function buildCard(payload: PopupPayload): Frame
	local card = UIStyle.MakePanel({
		Name = "FishCatchPopup",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT),
		BackgroundColor3 = UIStyle.Palette.Panel,
		BackgroundTransparency = 0.05,
	})
	card.ZIndex = 50
	card.Parent = screen

	local rar = rarityColor(payload.rarity)

	-- Top rarity stripe.
	local stripe = Instance.new("Frame")
	stripe.Name = "RarityStripe"
	stripe.Size = UDim2.new(1, -16, 0, 5)
	stripe.Position = UDim2.fromOffset(8, 8)
	stripe.BackgroundColor3 = rar
	stripe.BorderSizePixel = 0
	stripe.ZIndex = 5
	stripe.Parent = card
	UIStyle.ApplyCorner(stripe, UDim.new(0, 2))

	buildBanner(card, payload.variant)
	buildArt(card, payload.id, true)

	UIStyle.MakeLabel({
		Name = "Name",
		Size = UDim2.new(1, -16, 0, 24),
		Position = UDim2.fromOffset(8, CARD_HEIGHT - 60),
		Text = payload.displayName or payload.id,
		Font = UIStyle.FontBold,
		TextSize = UIStyle.TextSize.Heading,
		TextColor3 = UIStyle.Palette.TextPrimary,
		ZIndex = 5,
		Parent = card,
	})

	UIStyle.MakeLabel({
		Name = "Rarity",
		Size = UDim2.new(1, -16, 0, 18),
		Position = UDim2.fromOffset(8, CARD_HEIGHT - 32),
		Text = string.upper(payload.rarity or "Common"),
		Font = UIStyle.FontBold,
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = rar,
		ZIndex = 5,
		Parent = card,
	})

	return card
end

local function show(payload: PopupPayload)
	clearAny()

	local card = buildCard(payload)
	-- Start off-screen to the right, slide in.
	card.Position = UDim2.new(1, CARD_WIDTH + 40, 0, TOP_OFFSET)
	local visible = UDim2.new(1, -RIGHT_PADDING, 0, TOP_OFFSET)

	local slideIn = TweenService:Create(card,
		TweenInfo.new(SLIDE_IN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = visible })
	slideIn:Play()
	slideIn.Completed:Wait()

	task.wait(HOLD_TIME)

	if not card.Parent then return end
	local slideOut = TweenService:Create(card,
		TweenInfo.new(SLIDE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(1, CARD_WIDTH + 40, 0, TOP_OFFSET) })
	slideOut:Play()
	slideOut.Completed:Wait()
	if card.Parent then card:Destroy() end
end

local function pumpQueue()
	if active then return end
	active = true
	task.spawn(function()
		while #queue > 0 do
			local payload = table.remove(queue, 1)
			if payload then
				-- Surface errors instead of silently swallowing them. Without
				-- this, any failure in buildCard / buildArt / TweenService
				-- silently disappears and the user sees nothing.
				local ok, err = pcall(show, payload)
				if not ok then
					warn(string.format(
						"[FishCatchPopup] show() errored for %s (%s): %s",
						tostring(payload.id), tostring(payload.variant), tostring(err)
					))
					clearAny()
				end
				-- Tiny gap so back-to-back popups don't visually collide.
				task.wait(0.15)
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
	})
	pumpQueue()
end

RemoteService.OnClientEvent("SpeciesFound", function(payload)
	enqueue("Found", payload)
end)

RemoteService.OnClientEvent("SpeciesUnlocked", function(payload)
	enqueue("Mastered", payload)
end)
