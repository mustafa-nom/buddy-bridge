--!strict
-- Lightweight hovercraft-style boat. Server holds the authoritative position
-- of each tagged PhishRowboat; passengers get network ownership of the model
-- so the driver's input feels responsive. Server validates input window
-- rate-limit and clamps speed/turn from per-boat attributes.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))

local RowboatService = {}

type BoatState = {
	model: Model,
	rootPart: BasePart,
	driver: Player?,
	throttle: number,
	steer: number,
	speed: number,
	yaw: number,
	maxSpeed: number,
	turnRate: number,
	accel: number,
	decel: number,
}

local boats: { [string]: BoatState } = {}
local boatByPlayer: { [Player]: string } = {}

local function boatId(model: Model): string
	local id = model:GetAttribute(Constants.ATTRS.BoatId)
	if typeof(id) == "string" and id ~= "" then return id end
	return model:GetFullName()
end

local function ensureRootPart(model: Model): BasePart?
	if model.PrimaryPart then return model.PrimaryPart end
	for _, c in ipairs(model:GetDescendants()) do
		if c:IsA("BasePart") then
			model.PrimaryPart = c
			return c
		end
	end
	return nil
end

local function registerBoat(model: Model)
	local root = ensureRootPart(model)
	if not root then return end
	local id = boatId(model)
	if boats[id] then return end
	boats[id] = {
		model = model,
		rootPart = root,
		driver = nil,
		throttle = 0,
		steer = 0,
		speed = 0,
		yaw = 0,
		maxSpeed = (model:GetAttribute(Constants.ATTRS.BoatSpeed) :: number?) or 28,
		turnRate = (model:GetAttribute(Constants.ATTRS.BoatTurnRate) :: number?) or 1.5,
		accel = 12,
		decel = 6,
	}
end


local function step(dt: number)
	for _, b in pairs(boats) do
		local target = b.throttle * b.maxSpeed
		local diff = target - b.speed
		local stepRate = (diff > 0) and b.accel or b.decel
		b.speed += math.clamp(diff, -stepRate * dt, stepRate * dt)
		b.yaw += b.steer * b.turnRate * dt
		local cf = b.rootPart.CFrame
		local pos = cf.Position
		local newCFrame = CFrame.new(pos) * CFrame.Angles(0, b.yaw - cf:ToOrientation() , 0)
		-- Simpler: rotate by steer*turnRate*dt and translate forward.
		local rot = CFrame.Angles(0, b.steer * b.turnRate * dt, 0)
		newCFrame = (cf * rot)
		local forward = newCFrame.LookVector
		local newPos = newCFrame.Position + forward * b.speed * dt
		newCFrame = CFrame.new(newPos) * (newCFrame - newCFrame.Position)
		b.rootPart.CFrame = newCFrame
		if b.driver then
			RemoteService.FireClient(b.driver, "BoatStateUpdated", {
				BoatId = boatId(b.model),
				CFrame = { newCFrame:GetComponents() },
				Speed = b.speed,
			})
		end
	end
end

local function handleEnter(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.boatId) ~= "string" then return end
	if not RemoteValidation.RequirePlayer(player) then return end
	local b = boats[payload.boatId]
	if not b then return end
	-- Proximity check: 12 studs from boat root.
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return end
	if (root.Position - b.rootPart.Position).Magnitude > 14 then return end
	if b.driver and b.driver ~= player then
		RemoteService.FireClient(player, "Notify", { Kind = "Info", Text = "Someone else is driving." })
		return
	end
	b.driver = player
	boatByPlayer[player] = payload.boatId
	b.rootPart:SetNetworkOwner(player)
	RemoteService.FireClient(player, "BoatStateUpdated", {
		BoatId = payload.boatId,
		Driving = true,
	})
end

local function handleExit(player: Player, _payload: any)
	local id = boatByPlayer[player]
	if not id then return end
	local b = boats[id]
	if b and b.driver == player then
		b.driver = nil
		b.throttle = 0
		b.steer = 0
		pcall(function() b.rootPart:SetNetworkOwner(nil) end)
	end
	boatByPlayer[player] = nil
	RemoteService.FireClient(player, "BoatStateUpdated", { BoatId = id, Driving = false })
end

local function handleInput(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	if not RemoteValidation.RequirePlayer(player) then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestBoatInput", Constants.RATE_LIMIT_BOAT_INPUT) then return end
	local id = boatByPlayer[player]
	if not id then return end
	local b = boats[id]
	if not b or b.driver ~= player then return end
	local throttle = typeof(payload.throttle) == "number" and math.clamp(payload.throttle, -1, 1) or 0
	local steer = typeof(payload.steer) == "number" and math.clamp(payload.steer, -1, 1) or 0
	b.throttle = throttle
	b.steer = steer
end

function RowboatService.Init()
	for _, m in ipairs(CollectionService:GetTagged(Constants.TAGS.Rowboat)) do
		if m:IsA("Model") then registerBoat(m) end
	end
	CollectionService:GetInstanceAddedSignal(Constants.TAGS.Rowboat):Connect(function(m)
		if m:IsA("Model") then registerBoat(m) end
	end)
	RemoteService.OnServerEvent("RequestEnterBoat", handleEnter)
	RemoteService.OnServerEvent("RequestExitBoat", handleExit)
	RemoteService.OnServerEvent("RequestBoatInput", handleInput)
	Players.PlayerRemoving:Connect(function(player)
		handleExit(player, nil)
	end)
	RunService.Heartbeat:Connect(function(dt)
		step(math.min(dt, 0.1))
	end)
end

function RowboatService.Diagnostics(): { [string]: number }
	local n = 0
	for _ in pairs(boats) do n += 1 end
	return { Boats = n }
end

return RowboatService
