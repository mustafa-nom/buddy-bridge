--!strict
-- Locks the Guide's camera to a "looking down at a book" pose while a level
-- is active. The book itself is a full-screen ScreenGui (BookView) so this
-- camera mostly affects the soft warm context behind it — a slight downward
-- tilt sells the "I'm reading at a desk" feel.
--
-- Restores the default Custom camera when the level ends or the player
-- swaps out of the Guide role.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local RoleTypes = require(Modules:WaitForChild("RoleTypes"))

local LocalPlayer = Players.LocalPlayer

local state = {
	Role = RoleTypes.None,
	RoundId = nil :: string?,
	SlotIndex = nil :: number?,
	BoothName = nil :: string?,
	LevelType = nil :: string?,
	Active = false,
	CameraFrame = nil :: CFrame?,
	RenderConnection = nil :: RBXScriptConnection?,
	PreviousCameraMode = nil :: Enum.CameraMode?,
	PreviousMinZoom = nil :: number?,
	PreviousMaxZoom = nil :: number?,
	PreviousFieldOfView = nil :: number?,
}

local function findBoothModel(): Model?
	if not state.SlotIndex then return nil end
	local slotsRoot = Workspace:FindFirstChild("PlayArenaSlots")
	if not slotsRoot then return nil end
	for _, slot in ipairs(slotsRoot:GetChildren()) do
		if slot:GetAttribute("SlotIndex") == state.SlotIndex then
			local boothFolder = slot:FindFirstChild("Booth")
			if not boothFolder then return nil end
			local boothModel = state.BoothName and boothFolder:FindFirstChild(state.BoothName)
				or boothFolder:FindFirstChildOfClass("Model")
			if boothModel then
				return boothModel :: Model
			end
		end
	end
	return nil
end

local function boothCameraFrame(boothModel: Model): CFrame?
	local cameraAnchor = boothModel:FindFirstChild("GuideCameraAnchor", true)
	if cameraAnchor and cameraAnchor:IsA("BasePart") then
		return cameraAnchor.CFrame
	end
	local guideSpawn = boothModel:FindFirstChild("GuideSpawn", true)
	if not guideSpawn or not guideSpawn:IsA("BasePart") then return nil end
	local pos = (guideSpawn.CFrame * CFrame.new(0, 4.2, 6)).Position
	local target = (guideSpawn.CFrame * CFrame.new(0, 1.8, -7)).Position
	return CFrame.lookAt(pos, target)
end

local function holdCamera(camera: Camera)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = nil
	camera.FieldOfView = 62
	if state.CameraFrame then
		camera.CFrame = state.CameraFrame
	end
end

local function startRenderLock(camera: Camera)
	if state.RenderConnection then
		state.RenderConnection:Disconnect()
	end
	state.RenderConnection = RunService.RenderStepped:Connect(function()
		if state.Active then
			holdCamera(camera)
		end
	end)
end

local function tryActivate()
	if state.Role ~= RoleTypes.Guide or not state.LevelType then return end
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local boothModel = findBoothModel()
	if not boothModel then
		-- if the booth hasn't replicated yet, retry on the next frame
		task.defer(tryActivate)
		return
	end
	local frame = boothCameraFrame(boothModel)
	if not frame then
		task.defer(tryActivate)
		return
	end
	if not state.Active then
		state.PreviousCameraMode = LocalPlayer.CameraMode
		state.PreviousMinZoom = LocalPlayer.CameraMinZoomDistance
		state.PreviousMaxZoom = LocalPlayer.CameraMaxZoomDistance
		state.PreviousFieldOfView = camera.FieldOfView
	end
	state.CameraFrame = frame
	LocalPlayer.CameraMode = Enum.CameraMode.Classic
	LocalPlayer.CameraMinZoomDistance = 8
	LocalPlayer.CameraMaxZoomDistance = 18
	holdCamera(camera)
	state.Active = true
	startRenderLock(camera)
end

local function release()
	if not state.Active then return end
	if state.RenderConnection then
		state.RenderConnection:Disconnect()
		state.RenderConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		if state.PreviousFieldOfView then
			camera.FieldOfView = state.PreviousFieldOfView
		end
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			camera.CameraSubject = hum
		end
	end
	if state.PreviousCameraMode then
		LocalPlayer.CameraMode = state.PreviousCameraMode
	end
	if state.PreviousMinZoom then
		LocalPlayer.CameraMinZoomDistance = state.PreviousMinZoom
	end
	if state.PreviousMaxZoom then
		LocalPlayer.CameraMaxZoomDistance = state.PreviousMaxZoom
	end
	state.CameraFrame = nil
	state.Active = false
end

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	state.Role = payload.Role or RoleTypes.None
	if state.Role ~= RoleTypes.Guide then
		release()
	else
		tryActivate()
	end
end)

RemoteService.OnClientEvent("RoundStarted", function(payload)
	state.RoundId = payload.RoundId
	state.SlotIndex = payload.SlotIndex
	state.BoothName = payload.BoothName
end)

RemoteService.OnClientEvent("LevelStarted", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	state.LevelType = payload.LevelType
	tryActivate()
end)

RemoteService.OnClientEvent("LevelEnded", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	state.LevelType = nil
	release()
end)

RemoteService.OnClientEvent("RoundEnded", function(_payload)
	state.RoundId = nil
	state.LevelType = nil
	release()
end)
