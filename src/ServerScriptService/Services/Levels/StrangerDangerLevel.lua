--!strict
-- Stranger Danger Park: applies the scenario to the cloned level instance.
-- Spawns NPCs at BuddyNpcSpawn parts, attaches accessories per trait,
-- adds ProximityPrompts, activates puppy on completion.

local ServerStorage = game:GetService("ServerStorage")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local PlayAreaConfig = require(Modules:WaitForChild("PlayAreaConfig"))
local TagQueries = require(Modules:WaitForChild("TagQueries"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local StrangerDangerLevel = {}
local HOTDOG_MESH_ID = "rbxassetid://29896287"
local HOTDOG_TEXTURE_ID = "rbxassetid://29896653"

local function findDescendantOfClass(model: Model, className: string, names: { string }): Instance?
	for _, name in ipairs(names) do
		local found = model:FindFirstChild(name, true)
		if found and found.ClassName == className then
			return found
		end
	end
	return nil
end

local function findBodyPart(model: Model, names: { string }): BasePart?
	return findDescendantOfClass(model, "Part", names)
		or findDescendantOfClass(model, "MeshPart", names)
end

local function findJoint(model: Model, names: { string }): Motor6D?
	local found = findDescendantOfClass(model, "Motor6D", names)
	if found and found:IsA("Motor6D") then
		return found
	end
	return nil
end

local function resetPose(model: Model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			descendant.Transform = CFrame.identity
		end
	end
end

local function setJointTransform(model: Model, names: { string }, transform: CFrame)
	local joint = findJoint(model, names)
	if joint then
		joint.Transform = transform
	end
end

local function attachPropToLimb(
	npcModel: Model,
	propName: string,
	limbNames: { string },
	size: Vector3,
	offset: CFrame,
	configure: (BasePart) -> ()
): BasePart?
	local existing = npcModel:FindFirstChild(propName)
	if existing and existing:IsA("BasePart") then
		return existing
	end
	local limb = findBodyPart(npcModel, limbNames)
	if not limb then
		return nil
	end

	local prop = Instance.new("Part")
	prop.Name = propName
	prop.Size = size
	prop.Anchored = false
	prop.CanCollide = false
	prop.CanQuery = false
	prop.CanTouch = false
	prop.Massless = true
	configure(prop)
	prop.Parent = npcModel

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = limb
	weld.Part1 = prop
	weld.Parent = prop
	prop.CFrame = limb.CFrame * offset
	return prop
end

local function attachHotDogProp(npcModel: Model)
	attachPropToLimb(
		npcModel,
		"HotDogProp",
		{ "RightHand", "Right Arm" },
		Vector3.new(1, 1.2, 1),
		CFrame.new(0, -0.65, -0.2) * CFrame.Angles(math.rad(12), math.rad(90), math.rad(78)),
		function(prop)
			prop.Color = Color3.fromRGB(235, 178, 86)
			prop.Material = Enum.Material.SmoothPlastic
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = HOTDOG_MESH_ID
			mesh.TextureId = HOTDOG_TEXTURE_ID
			mesh.Scale = Vector3.new(1.05, 1.05, 1.05)
			mesh.Parent = prop
		end
	)
end

local function getLevelModel(slot: Model): Model?
	local playArea = slot:FindFirstChild(Constants.SLOT_PLAY_AREA_FOLDER)
	if not playArea then
		return nil
	end
	for _, child in ipairs(playArea:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute(PlayAreaConfig.Attributes.LevelType) == LevelTypes.StrangerDangerPark then
			return child
		end
	end
	return nil
end

local function pickRandomTemplate(): Model?
	local templates = ServerStorage:FindFirstChild("NpcTemplates")
	if not templates then
		return nil
	end
	local options: { Model } = {}
	for _, child in ipairs(templates:GetChildren()) do
		if child:IsA("Model") then
			table.insert(options, child)
		end
	end
	if #options == 0 then
		return nil
	end
	return options[math.random(#options)]
end

-- prefer the archetype the scenario picked; fall back to random so demos
-- still work if a template happens to be missing
local function pickTemplateForArchetype(archetype: string?): Model?
	local templates = ServerStorage:FindFirstChild("NpcTemplates")
	if templates and archetype then
		local match = templates:FindFirstChild(archetype)
		if match and match:IsA("Model") then
			return match :: Model
		end
	end
	return pickRandomTemplate()
end

local function attachKnifeAccessory(npcModel: Model)
	attachPropToLimb(
		npcModel,
		"KnifePlaceholder",
		{ "RightHand", "Right Arm" },
		Vector3.new(0.4, 0.4, 1.2),
		CFrame.new(0, -0.55, -0.45) * CFrame.Angles(0, math.rad(90), math.rad(78)),
		function(prop)
			prop.Color = Color3.fromRGB(180, 180, 200)
			prop.Material = Enum.Material.SmoothPlastic
		end
	)
end

local function applyNpcPose(npcModel: Model, archetype: string?)
	resetPose(npcModel)

	if archetype == "HotDogVendor" then
		setJointTransform(npcModel, { "Right Shoulder", "RightShoulder" }, CFrame.Angles(math.rad(-15), math.rad(80), math.rad(88)))
		setJointTransform(npcModel, { "Left Shoulder", "LeftShoulder" }, CFrame.Angles(math.rad(18), math.rad(-12), math.rad(-28)))
		setJointTransform(npcModel, { "Right Hip", "RightHip" }, CFrame.Angles(math.rad(6), 0, math.rad(4)))
		setJointTransform(npcModel, { "Left Hip", "LeftHip" }, CFrame.Angles(math.rad(-4), 0, math.rad(-4)))
		setJointTransform(npcModel, { "Neck" }, CFrame.Angles(math.rad(-6), math.rad(10), 0))
		attachHotDogProp(npcModel)
	elseif archetype == "Ranger" then
		setJointTransform(npcModel, { "Right Shoulder", "RightShoulder" }, CFrame.Angles(math.rad(10), math.rad(18), math.rad(18)))
		setJointTransform(npcModel, { "Left Shoulder", "LeftShoulder" }, CFrame.Angles(math.rad(-42), math.rad(-8), math.rad(-40)))
		setJointTransform(npcModel, { "Right Hip", "RightHip" }, CFrame.Angles(math.rad(4), 0, math.rad(5)))
		setJointTransform(npcModel, { "Left Hip", "LeftHip" }, CFrame.Angles(math.rad(-3), 0, math.rad(-5)))
	elseif archetype == "ParentWithKid" then
		setJointTransform(npcModel, { "Right Shoulder", "RightShoulder" }, CFrame.Angles(math.rad(8), math.rad(10), math.rad(14)))
		setJointTransform(npcModel, { "Left Shoulder", "LeftShoulder" }, CFrame.Angles(math.rad(-6), math.rad(-12), math.rad(-22)))
		setJointTransform(npcModel, { "Right Hip", "RightHip" }, CFrame.Angles(math.rad(10), 0, math.rad(6)))
		setJointTransform(npcModel, { "Left Hip", "LeftHip" }, CFrame.Angles(math.rad(-12), 0, math.rad(-6)))
	elseif archetype == "CasualParkGoer" then
		setJointTransform(npcModel, { "RootJoint" }, CFrame.Angles(math.rad(10), 0, 0))
		setJointTransform(npcModel, { "Right Shoulder", "RightShoulder" }, CFrame.Angles(math.rad(38), math.rad(6), math.rad(24)))
		setJointTransform(npcModel, { "Left Shoulder", "LeftShoulder" }, CFrame.Angles(math.rad(32), math.rad(-6), math.rad(-24)))
		setJointTransform(npcModel, { "Neck" }, CFrame.Angles(math.rad(10), 0, 0))
	elseif archetype == "VehicleLeaner" then
		setJointTransform(npcModel, { "RootJoint" }, CFrame.Angles(0, math.rad(18), math.rad(10)))
		setJointTransform(npcModel, { "Right Shoulder", "RightShoulder" }, CFrame.Angles(math.rad(22), math.rad(35), math.rad(46)))
		setJointTransform(npcModel, { "Left Shoulder", "LeftShoulder" }, CFrame.Angles(math.rad(-8), math.rad(-15), math.rad(-10)))
		setJointTransform(npcModel, { "Right Hip", "RightHip" }, CFrame.Angles(math.rad(8), 0, math.rad(10)))
	elseif archetype == "KnifeArchetype" then
		setJointTransform(npcModel, { "RootJoint" }, CFrame.Angles(0, math.rad(-12), 0))
		setJointTransform(npcModel, { "Right Shoulder", "RightShoulder" }, CFrame.Angles(math.rad(-8), math.rad(44), math.rad(82)))
		setJointTransform(npcModel, { "Left Shoulder", "LeftShoulder" }, CFrame.Angles(math.rad(14), math.rad(-10), math.rad(-26)))
		setJointTransform(npcModel, { "Right Hip", "RightHip" }, CFrame.Angles(math.rad(16), 0, math.rad(10)))
		setJointTransform(npcModel, { "Left Hip", "LeftHip" }, CFrame.Angles(math.rad(-12), 0, math.rad(-8)))
		setJointTransform(npcModel, { "Neck" }, CFrame.Angles(math.rad(8), math.rad(-10), 0))
	elseif archetype == "HoodedAdult" then
		setJointTransform(npcModel, { "RootJoint" }, CFrame.Angles(math.rad(6), math.rad(-8), 0))
		setJointTransform(npcModel, { "Right Shoulder", "RightShoulder" }, CFrame.Angles(math.rad(22), 0, math.rad(10)))
		setJointTransform(npcModel, { "Left Shoulder", "LeftShoulder" }, CFrame.Angles(math.rad(18), 0, math.rad(-10)))
		setJointTransform(npcModel, { "Neck" }, CFrame.Angles(math.rad(10), 0, 0))
	end
end

local function buildPromptOnNpc(npcModel: Model, npcId: string)
	local root = npcModel.PrimaryPart or npcModel:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Take a closer look"
	prompt.ObjectText = npcModel.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Constants.INSPECT_RADIUS_STUDS
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt:SetAttribute("BB_NpcId", npcId)
	prompt.Parent = root
end

local function setNpcAttributes(npcModel: Model, npcInfo)
	npcModel:SetAttribute("BB_NpcId", npcInfo.Id)
	npcModel:SetAttribute("BB_Role", npcInfo.Role)
	npcModel:SetAttribute("BB_SpawnPointId", npcInfo.SpawnPointId)
	-- Note: traits are not exposed as attributes — only revealed via
	-- NpcDescriptionShown remote when the Explorer inspects.
	for _, trait in ipairs(npcInfo.Traits) do
		if trait == "HoldingKnife" then
			attachKnifeAccessory(npcModel)
		end
	end
	applyNpcPose(npcModel, npcInfo.Archetype)
end

local function activatePuppyMarker(levelModel: Model, scenario)
	if not scenario.PuppySpawnId or scenario.PuppySpawnId == "" then
		return
	end
	-- Find the chosen puppy spawn and put a placeholder marker on it.
	-- The actual puppy reveal happens after 3 clues are collected.
	for _, part in ipairs(TagQueries.GetTaggedInside(levelModel, PlayAreaConfig.Tags.PuppySpawn)) do
		if part:GetFullName() == scenario.PuppySpawnId then
			part:SetAttribute("BB_IsChosen", true)
		else
			part:SetAttribute("BB_IsChosen", false)
		end
	end
end

local function activateLevelExitForPuppy(levelModel: Model)
	-- The level template ships with one or more LevelExit triggers; for MVP
	-- we just activate them all once the puppy is found.
	for _, part in ipairs(TagQueries.GetTaggedInside(levelModel, PlayAreaConfig.Tags.LevelExit)) do
		if part:IsA("BasePart") then
			part:SetAttribute("BB_Active", true)
		end
	end
end

local function wireLevelExits(round, levelModel: Model, onComplete: () -> ())
	for _, part in ipairs(TagQueries.GetTaggedInside(levelModel, PlayAreaConfig.Tags.LevelExit)) do
		if part:IsA("BasePart") then
			local conn
			conn = part.Touched:Connect(function(other)
				if not round.IsActive then return end
				if not part:GetAttribute("BB_Active") then return end
				local character = other:FindFirstAncestorOfClass("Model")
				if not character then return end
				local Players = game:GetService("Players")
				local player = Players:GetPlayerFromCharacter(character)
				if not player or player ~= round.Explorer then return end
				if conn then conn:Disconnect() end
				onComplete()
			end)
			table.insert(round.Connections, conn)
		end
	end
end

function StrangerDangerLevel.Begin(round, scenario)
	local slot = round and round.SlotIndex
	if not slot then
		return false
	end
	-- Find slot model
	local slotModel
	for _, candidate in ipairs(TagQueries.GetSortedSlots()) do
		if candidate:GetAttribute(PlayAreaConfig.Attributes.SlotIndex) == round.SlotIndex then
			slotModel = candidate
			break
		end
	end
	if not slotModel then
		warn("StrangerDangerLevel: slot not found")
		return false
	end
	local levelModel = getLevelModel(slotModel)
	if not levelModel then
		warn("StrangerDangerLevel: level model not in slot")
		return false
	end

	round.LevelState[LevelTypes.StrangerDangerPark] = round.LevelState[LevelTypes.StrangerDangerPark] or {}
	local levelState = round.LevelState[LevelTypes.StrangerDangerPark]
	levelState.LevelModel = levelModel
	levelState.NpcModels = {}

	-- Spawn each NPC
	for _, npcInfo in ipairs(scenario.Npcs) do
		local spawnPart = TagQueries.GetNpcSpawnById(levelModel, npcInfo.SpawnPointId)
		if not spawnPart then
			warn(("StrangerDangerLevel: spawn part not found for id %s"):format(npcInfo.SpawnPointId))
			continue
		end
		local template = pickTemplateForArchetype(npcInfo.Archetype)
		if not template then
			warn("StrangerDangerLevel: no NPC templates available in ServerStorage/NpcTemplates")
			break
		end
		local clone = template:Clone()
		clone.Name = npcInfo.Id
		clone.Parent = levelModel
		if clone.PrimaryPart then
			clone:PivotTo(spawnPart.CFrame + Vector3.new(0, 3, 0))
		end
		setNpcAttributes(clone, npcInfo)
		if npcInfo.Bark then
			clone:SetAttribute("BB_Bark", npcInfo.Bark)
		end
		if npcInfo.Archetype then
			clone:SetAttribute("BB_Archetype", npcInfo.Archetype)
		end
		buildPromptOnNpc(clone, npcInfo.Id)
		levelState.NpcModels[npcInfo.Id] = clone
	end

	activatePuppyMarker(levelModel, scenario)

	-- Wire LevelExit touch → level complete. Use a lazy require to avoid
	-- a circular import at module-load time (LevelService requires this
	-- module, so we can't require it back at the top).
	wireLevelExits(round, levelModel, function()
		task.spawn(function()
			local Services = script.Parent.Parent
			local LevelService = require(Services:WaitForChild("LevelService"))
			LevelService.CompleteLevel(round, LevelTypes.StrangerDangerPark)
		end)
	end)

	-- Push manual to Guide
	RemoteService.FireClient(round.Guide, "GuideManualUpdated", {
		RoundId = round.RoundId,
		LevelType = LevelTypes.StrangerDangerPark,
		Manual = scenario.GuideManual,
	})

	return true
end

function StrangerDangerLevel.OnClueCollected(round, scenario)
	if round.CluesCollected >= Constants.CLUES_TO_FIND then
		local slotModel
		for _, candidate in ipairs(TagQueries.GetSortedSlots()) do
			if candidate:GetAttribute(PlayAreaConfig.Attributes.SlotIndex) == round.SlotIndex then
				slotModel = candidate
				break
			end
		end
		if not slotModel then
			return
		end
		local levelModel = getLevelModel(slotModel)
		if not levelModel then
			return
		end
		activateLevelExitForPuppy(levelModel)
		RemoteService.FirePair(round, "PuppyRevealed", {
			RoundId = round.RoundId,
			PuppySpawnId = scenario.PuppySpawnId,
		})
	end
end

function StrangerDangerLevel.Cleanup(round)
	local levelState = round.LevelState[LevelTypes.StrangerDangerPark]
	if levelState then
		if levelState.NpcModels then
			for _, model in pairs(levelState.NpcModels) do
				if model and model.Parent then
					model:Destroy()
				end
			end
		end
		levelState.NpcModels = nil
	end
end

return StrangerDangerLevel
