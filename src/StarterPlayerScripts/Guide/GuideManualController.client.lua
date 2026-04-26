--!strict
-- Renders the active manual on the booth's ControlPanel SurfaceGui.
-- Resolves the SurfaceGui via the slot index in RoundStarted payload.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local RoleTypes = require(Modules:WaitForChild("RoleTypes"))
local UIStyle = require(Modules:WaitForChild("UIStyle"))

local Manuals = script.Parent:WaitForChild("Manuals")
local StrangerDangerManual = require(Manuals:WaitForChild("StrangerDangerManual"))
local BackpackCheckpointManual = require(Manuals:WaitForChild("BackpackCheckpointManual"))
local StrangerDangerBookContent = require(Manuals:WaitForChild("StrangerDangerBookContent"))
local BookView = require(script.Parent:WaitForChild("BookView"))

local state = {
	Role = RoleTypes.None,
	RoundId = nil :: string?,
	SlotIndex = nil :: number?,
	BoothName = nil :: string?,
	LevelType = nil :: string?,
	ActiveManual = nil :: any?,
	ManualPayload = nil :: any?,
	-- Fallback: a screen-space backup if we can't find the SurfaceGui.
	FallbackContainer = nil :: ScreenGui?,
	-- Polished book overlay shown for the Guide on top of the SurfaceGui
	-- manual.
	Book = nil :: any?,
	ManualOpen = false,
	ToggleGui = nil :: ScreenGui?,
	ToggleButton = nil :: TextButton?,
}

local renderManual: () -> ()

local function destroyBook()
	if state.Book then
		state.Book:Destroy()
		state.Book = nil
	end
end

local function destroyActiveManual()
	if state.ActiveManual then
		state.ActiveManual:Destroy()
		state.ActiveManual = nil
	end
	destroyBook()
end

local function ensureBook()
	if state.Role ~= RoleTypes.Guide then return end
	if state.LevelType ~= LevelTypes.StrangerDangerPark then
		destroyBook()
		return
	end
	if state.Book then return end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	state.Book = BookView.new(playerGui, StrangerDangerBookContent)
end

local function updateToggle()
	if not state.ToggleButton then return end
	state.ToggleButton.Visible = state.Role == RoleTypes.Guide and state.LevelType ~= nil and state.ManualPayload ~= nil
	state.ToggleButton.Text = state.ManualOpen and "Close Manual" or "Open Manual"
end

local function ensureToggle()
	if state.ToggleGui and state.ToggleButton then
		updateToggle()
		return
	end
	local screen = Instance.new("ScreenGui")
	screen.Name = "BB_GuideManualToggle"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local button = UIStyle.MakeButton({
		Name = "Toggle",
		Size = UDim2.fromOffset(180, 46),
		Position = UDim2.fromOffset(24, 112),
		Text = "Open Manual",
		TextSize = UIStyle.TextSize.Body,
		Parent = screen,
	})
	button.Activated:Connect(function()
		state.ManualOpen = not state.ManualOpen
		if state.ManualOpen then
			renderManual()
		else
			destroyActiveManual()
			updateToggle()
		end
	end)
	state.ToggleGui = screen
	state.ToggleButton = button
	updateToggle()
end

local function findControlPanelSurfaceGui(): SurfaceGui?
	if not state.SlotIndex then return nil end
	local slotsRoot = Workspace:FindFirstChild("PlayArenaSlots")
	if not slotsRoot then return nil end
	for _, slot in ipairs(slotsRoot:GetChildren()) do
		if slot:GetAttribute("SlotIndex") == state.SlotIndex then
			local boothFolder = slot:FindFirstChild("Booth")
			if not boothFolder then return nil end
			local boothModel = state.BoothName and boothFolder:FindFirstChild(state.BoothName) or boothFolder:FindFirstChildOfClass("Model")
			if not boothModel then return nil end
			local controlPanel = boothModel:FindFirstChild("ControlPanel")
			if not controlPanel then return nil end
			local surfaceGui = controlPanel:FindFirstChildOfClass("SurfaceGui")
			if surfaceGui then return surfaceGui end
		end
	end
	return nil
end

local function getRenderTarget(): Instance
	-- Try the booth's SurfaceGui; fall back to a corner ScreenGui so the
	-- demo still works when the map ships without a SurfaceGui mounted.
	local surfaceGui = findControlPanelSurfaceGui()
	if surfaceGui then
		if state.FallbackContainer then
			state.FallbackContainer:Destroy()
			state.FallbackContainer = nil
		end
		return surfaceGui
	end
	if not state.FallbackContainer then
		local screen = Instance.new("ScreenGui")
		screen.Name = "BB_GuideManualFallback"
		screen.ResetOnSpawn = false
		screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(0.3, 0.62)
		frame.AnchorPoint = Vector2.new(0, 0.5)
		frame.Position = UDim2.fromScale(0.02, 0.55)
		frame.BackgroundColor3 = UIStyle.Palette.Panel
		frame.BorderSizePixel = 0
		frame.Name = "ManualPanel"
		frame.Parent = screen
		UIStyle.ApplyCorner(frame)
		UIStyle.ApplyStroke(frame)
		state.FallbackContainer = screen
	end
	local frame = state.FallbackContainer:FindFirstChild("ManualPanel")
	return frame or state.FallbackContainer
end

renderManual = function()
	if state.Role ~= RoleTypes.Guide then return end
	if not state.LevelType then return end
	if not state.ManualPayload then return end
	if not state.ManualOpen then
		destroyActiveManual()
		updateToggle()
		return
	end
	local target = getRenderTarget()
	if state.ActiveManual then
		state.ActiveManual:Destroy()
		state.ActiveManual = nil
	end
	if state.LevelType == LevelTypes.StrangerDangerPark then
		state.ActiveManual = StrangerDangerManual.Build(target, state.ManualPayload)
	elseif state.LevelType == LevelTypes.BackpackCheckpoint then
		state.ActiveManual = BackpackCheckpointManual.Build(target, state.ManualPayload)
	end
	if state.LevelType == LevelTypes.StrangerDangerPark then
		ensureBook()
	end
	updateToggle()
end

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	state.Role = payload.Role or RoleTypes.None
	ensureToggle()
	if state.Role ~= RoleTypes.Guide then
		state.ManualOpen = false
		destroyActiveManual()
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
	state.ManualOpen = false
	state.ManualPayload = nil
	destroyActiveManual()
	updateToggle()
	-- Manual will arrive separately via GuideManualUpdated for the Guide.
	-- For the Explorer, we just clear local state.
	if state.Role ~= RoleTypes.Guide then
		state.ManualPayload = nil
		if state.ActiveManual then
			state.ActiveManual:Destroy()
			state.ActiveManual = nil
		end
		return
	end
end)

RemoteService.OnClientEvent("GuideManualUpdated", function(payload)
	if state.Role ~= RoleTypes.Guide then return end
	if payload.RoundId ~= state.RoundId then return end
	state.ManualPayload = payload.Manual
	state.LevelType = payload.LevelType
	state.ManualOpen = false
	destroyActiveManual()
	ensureToggle()
end)

RemoteService.OnClientEvent("NpcDialogNoteAdded", function(payload)
	if state.Role ~= RoleTypes.Guide then return end
	if payload.RoundId ~= state.RoundId then return end
	if state.LevelType ~= LevelTypes.StrangerDangerPark then return end
	if state.ActiveManual then
		local note = payload.Note or {}
		state.ActiveManual:Highlight(note.CueTags or {})
	end
	if state.Book and payload.Note and payload.Note.Archetype then
		local idx = StrangerDangerBookContent.ArchetypeIndex(payload.Note.Archetype)
		if idx then
			state.Book:GoToIndex(idx)
		end
	end
end)

RemoteService.OnClientEvent("ConveyorItemSpawned", function(payload)
	if state.Role ~= RoleTypes.Guide then return end
	if payload.RoundId ~= state.RoundId then return end
	if not state.ActiveManual then return end
	if state.LevelType ~= LevelTypes.BackpackCheckpoint then return end
	state.ActiveManual:Highlight(payload.ItemKey)
	-- Flag this key as seen the moment we render it. Even if FieldManualUpdated
	-- arrives later, a no-op MarkSeen on a known key is safe.
	if state.ActiveManual.MarkSeen then
		state.ActiveManual:MarkSeen(payload.ItemKey)
	end
end)

RemoteService.OnClientEvent("FieldManualUpdated", function(payload)
	if state.Role ~= RoleTypes.Guide then return end
	if payload.RoundId ~= state.RoundId then return end
	if not state.ActiveManual then return end
	if state.LevelType ~= LevelTypes.BackpackCheckpoint then return end
	if payload.Encountered and state.ActiveManual.MarkAllSeen then
		state.ActiveManual:MarkAllSeen(payload.Encountered)
	end
	if payload.NewKey and state.ActiveManual.MarkSeen then
		state.ActiveManual:MarkSeen(payload.NewKey)
	end
end)

RemoteService.OnClientEvent("LevelEnded", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	state.ManualOpen = false
	destroyActiveManual()
	updateToggle()
end)

RemoteService.OnClientEvent("RoundEnded", function(_payload)
	state.RoundId = nil
	state.LevelType = nil
	state.ManualPayload = nil
	state.ManualOpen = false
	destroyActiveManual()
	if state.FallbackContainer then
		state.FallbackContainer:Destroy()
		state.FallbackContainer = nil
	end
	if state.ToggleGui then
		state.ToggleGui:Destroy()
		state.ToggleGui = nil
		state.ToggleButton = nil
	end
end)
