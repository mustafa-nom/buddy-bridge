--!strict
-- Stranger Danger Park setup: NPC badges plus Guide booth controls.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local PlayAreaConfig = require(Modules:WaitForChild("PlayAreaConfig"))
local TagQueries = require(Modules:WaitForChild("TagQueries"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local BadgeConfig = require(Modules:WaitForChild("BadgeConfig"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local StrangerDangerLevel = {}

local function getLevelModel(slot: Model): Model?
	local playArea = slot:FindFirstChild(Constants.SLOT_PLAY_AREA_FOLDER)
	if not playArea then return nil end
	for _, child in ipairs(playArea:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute(PlayAreaConfig.Attributes.LevelType) == LevelTypes.StrangerDangerPark then
			return child
		end
	end
	return nil
end

local function pickTemplateForArchetype(archetype: string?): Model?
	local templates = ServerStorage:FindFirstChild("NpcTemplates")
	if not templates then return nil end
	local match = archetype and templates:FindFirstChild(archetype)
	if match and match:IsA("Model") then return match end
	for _, child in ipairs(templates:GetChildren()) do
		if child:IsA("Model") then return child end
	end
	return nil
end

local function attachKnifeAccessory(npcModel: Model)
	local templates = ServerStorage:FindFirstChild("NpcTemplates")
	local knifeTemplate = templates and templates:FindFirstChild("KnifeAccessory")
	local knife: Instance
	if knifeTemplate then
		knife = knifeTemplate:Clone()
	else
		local part = Instance.new("Part")
		part.Name = "KnifePlaceholder"
		part.Size = Vector3.new(0.4, 0.4, 1.2)
		part.Color = Color3.fromRGB(180, 180, 200)
		part.Material = Enum.Material.SmoothPlastic
		part.CanCollide = false
		knife = part
	end
	local hand = npcModel:FindFirstChild("RightHand") or npcModel:FindFirstChild("Right Arm") or npcModel.PrimaryPart
	if hand and knife:IsA("BasePart") and hand:IsA("BasePart") then
		knife.Parent = npcModel
		knife.CFrame = hand.CFrame * CFrame.new(0, -0.5, -0.5)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = knife
		weld.Parent = knife
	else
		knife.Parent = npcModel
	end
end

local function findTorso(npcModel: Model): BasePart?
	local torso = npcModel:FindFirstChild("UpperTorso")
		or npcModel:FindFirstChild("Torso")
		or npcModel:FindFirstChild("HumanoidRootPart")
		or npcModel.PrimaryPart
	return torso and torso:IsA("BasePart") and torso or nil
end

local function makeSurfaceGui(parent: BasePart, name: string, face: Enum.NormalId): SurfaceGui
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local surface = Instance.new("SurfaceGui")
	surface.Name = name
	surface.Face = face
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 50
	surface.LightInfluence = 0
	surface.Parent = parent
	return surface
end

local function drawBadge(parent: Instance, colorName: string?, shapeName: string?, status: string?)
	for _, child in ipairs(parent:GetChildren()) do
		child:Destroy()
	end
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = colorName and BadgeConfig.Colors[colorName] or Color3.fromRGB(255, 235, 200)
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 8
	stroke.Color = status == "Correct" and Color3.fromRGB(70, 220, 90)
		or status == "Wrong" and Color3.fromRGB(230, 60, 60)
		or Color3.fromRGB(60, 40, 20)
	stroke.Parent = frame
	local shape = Instance.new("TextLabel")
	shape.BackgroundTransparency = 1
	shape.Size = UDim2.fromScale(1, 0.7)
	shape.Position = UDim2.fromScale(0, 0.08)
	shape.Font = Enum.Font.Cartoon
	shape.TextScaled = true
	shape.TextColor3 = Color3.fromRGB(40, 28, 16)
	shape.Text = shapeName or status or "Empty"
	shape.Parent = frame
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 0.22)
	label.Position = UDim2.fromScale(0, 0.74)
	label.Font = Enum.Font.Cartoon
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(40, 28, 16)
	label.Text = colorName and (colorName .. " " .. (shapeName or "")) or (status or "Empty")
	label.Parent = frame
end

local function applyNpcBadge(npcModel: Model, badge)
	local torso = findTorso(npcModel)
	if torso then
		drawBadge(makeSurfaceGui(torso, "BB_BadgeGui", Enum.NormalId.Front), badge.Color, badge.Shape, nil)
	end
end

local function buildPromptOnNpc(npcModel: Model, npcId: string)
	local root = npcModel.PrimaryPart or npcModel:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk"
	prompt.ObjectText = npcModel.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Constants.INSPECT_RADIUS_STUDS
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("BB_NpcId", npcId)
	prompt.Parent = root
end

local function stabilizeNpc(npcModel: Model)
	for _, descendant in ipairs(npcModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
end

local function setNpcAttributes(npcModel: Model, npcInfo)
	npcModel:SetAttribute("BB_NpcId", npcInfo.Id)
	npcModel:SetAttribute("BB_Role", npcInfo.Role)
	npcModel:SetAttribute("BB_SpawnPointId", npcInfo.SpawnPointId)
	npcModel:SetAttribute("BB_BadgeColor", npcInfo.Badge.Color)
	npcModel:SetAttribute("BB_BadgeShape", npcInfo.Badge.Shape)
	for _, trait in ipairs(npcInfo.Traits or {}) do
		if trait == "HoldingKnife" then
			attachKnifeAccessory(npcModel)
		end
	end
end

local function resetBoothState(round)
	round.AttemptsLeft = Constants.STRANGER_DANGER_ATTEMPTS
	round.BoothState = {
		Slots = {
			{ Color = nil, Shape = nil, Locked = false, Status = "Empty" },
			{ Color = nil, Shape = nil, Locked = false, Status = "Empty" },
			{ Color = nil, Shape = nil, Locked = false, Status = "Empty" },
		},
		History = {},
	}
end

function StrangerDangerLevel.RefreshBoothDisplays(round)
	local state = round.BoothState
	local levelState = round.LevelState[LevelTypes.StrangerDangerPark]
	if not state or not levelState then return end
	for slotIndex, part in pairs(levelState.BoothSlots or {}) do
		local slot = state.Slots[slotIndex]
		if part and part.Parent and slot then
			drawBadge(makeSurfaceGui(part, "BB_SlotGui", Enum.NormalId.Top), slot.Color, slot.Shape, slot.Status)
		end
	end
	if levelState.SubmitPad then
		drawBadge(makeSurfaceGui(levelState.SubmitPad, "BB_AttemptsGui", Enum.NormalId.Top), nil, nil, ("Attempts: %d"):format(round.AttemptsLeft))
	end
	RemoteService.FirePair(round, "BoothStateUpdated", {
		RoundId = round.RoundId,
		AttemptsLeft = round.AttemptsLeft,
		BoothState = state,
	})
end

local function wireBooth(round, slotModel: Model)
	local boothFolder = slotModel:FindFirstChild(Constants.SLOT_BOOTH_FOLDER)
	if not boothFolder then return end
	local levelState = round.LevelState[LevelTypes.StrangerDangerPark]
	levelState.BoothSlots = {}
	for _, part in ipairs(TagQueries.GetTaggedInside(boothFolder, PlayAreaConfig.Tags.BoothSlot)) do
		if part:IsA("BasePart") then
			local slotIndex = part:GetAttribute(PlayAreaConfig.Attributes.BoothSlotIndex)
			if typeof(slotIndex) == "number" and slotIndex >= 1 and slotIndex <= 3 then
				levelState.BoothSlots[slotIndex] = part
				local click = part:FindFirstChildOfClass("ClickDetector") or Instance.new("ClickDetector")
				click.MaxActivationDistance = 18
				click.Parent = part
				table.insert(round.Connections, click.MouseClick:Connect(function(player)
					local slot = round.BoothState.Slots[slotIndex]
					if player == round.Guide and slot and not slot.Locked then
						RemoteService.FireClient(player, "OpenSlotPicker", {
							RoundId = round.RoundId,
							SlotIndex = slotIndex,
							Current = slot,
						})
					end
				end))
			end
		end
	end
	for _, part in ipairs(TagQueries.GetTaggedInside(boothFolder, PlayAreaConfig.Tags.BoothSubmit)) do
		if part:IsA("BasePart") then
			levelState.SubmitPad = part
			levelState.SubmitTouching = {}
			table.insert(round.Connections, part.Touched:Connect(function(other)
				local character = other:FindFirstAncestorOfClass("Model")
				local player = character and Players:GetPlayerFromCharacter(character)
				if player == round.Guide and not levelState.SubmitTouching[player] then
					levelState.SubmitTouching[player] = true
					require(script.Parent.Parent:WaitForChild("GuideControlService")).SubmitForPlayer(player)
				end
			end))
			table.insert(round.Connections, part.TouchEnded:Connect(function(other)
				local character = other:FindFirstAncestorOfClass("Model")
				local player = character and Players:GetPlayerFromCharacter(character)
				if player == round.Guide then
					task.delay(0.2, function()
						for _, touchingPart in ipairs(part:GetTouchingParts()) do
							local touchingCharacter = touchingPart:FindFirstAncestorOfClass("Model")
							if touchingCharacter and Players:GetPlayerFromCharacter(touchingCharacter) == player then
								return
							end
						end
						levelState.SubmitTouching[player] = nil
					end)
				end
			end))
			break
		end
	end
	StrangerDangerLevel.RefreshBoothDisplays(round)
end

function StrangerDangerLevel.Begin(round, scenario)
	local slotModel
	for _, candidate in ipairs(TagQueries.GetSortedSlots()) do
		if candidate:GetAttribute(PlayAreaConfig.Attributes.SlotIndex) == round.SlotIndex then
			slotModel = candidate
			break
		end
	end
	if not slotModel then return false end
	local levelModel = getLevelModel(slotModel)
	if not levelModel then return false end

	resetBoothState(round)
	round.LevelState[LevelTypes.StrangerDangerPark] = round.LevelState[LevelTypes.StrangerDangerPark] or {}
	local levelState = round.LevelState[LevelTypes.StrangerDangerPark]
	levelState.LevelModel = levelModel
	levelState.NpcModels = {}

	for _, npcInfo in ipairs(scenario.Npcs) do
		local spawnPart = TagQueries.GetNpcSpawnById(levelModel, npcInfo.SpawnPointId)
		local template = pickTemplateForArchetype(npcInfo.Archetype)
		if not spawnPart or not template then continue end
		local clone = template:Clone()
		clone.Name = npcInfo.Id
		clone.Parent = levelModel
		if clone.PrimaryPart then
			clone:PivotTo(spawnPart.CFrame + Vector3.new(0, 3, 0))
		end
		setNpcAttributes(clone, npcInfo)
		applyNpcBadge(clone, npcInfo.Badge)
		stabilizeNpc(clone)
		buildPromptOnNpc(clone, npcInfo.Id)
		levelState.NpcModels[npcInfo.Id] = clone
	end

	wireBooth(round, slotModel)
	RemoteService.FireClient(round.Guide, "GuideManualUpdated", {
		RoundId = round.RoundId,
		LevelType = LevelTypes.StrangerDangerPark,
		Manual = scenario.GuideManual,
	})
	return true
end

function StrangerDangerLevel.Cleanup(round)
	local levelState = round.LevelState[LevelTypes.StrangerDangerPark]
	if not levelState then return end
	for _, model in pairs(levelState.NpcModels or {}) do
		if model and model.Parent then
			model:Destroy()
		end
	end
	levelState.NpcModels = nil
	levelState.BoothSlots = nil
	levelState.SubmitPad = nil
end

return StrangerDangerLevel
