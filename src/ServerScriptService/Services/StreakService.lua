--!strict
-- Per-player correct-catch streak. Multiplies pearls/XP and pushes
-- StreakUpdated to the client. Reset on wrong action / escape.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

local StreakService = {}

local function multiplierFor(streak: number): number
	local table_ = Constants.STREAK.Multiplier
	if streak <= 0 then return 1 end
	if streak > #table_ then return table_[#table_] end
	return table_[streak]
end

local function push(player: Player, delta: number?)
	local d = DataService.GetData(player)
	RemoteService.FireClient(player, "StreakUpdated", {
		Streak = d.Streak,
		BestStreak = d.BestStreak,
		Multiplier = multiplierFor(d.Streak),
		Delta = delta,
	})
end

function StreakService.MultiplierFor(streak: number): number
	return multiplierFor(streak)
end

function StreakService.GetCurrent(player: Player): number
	local d = DataService.GetData(player)
	return d.Streak
end

function StreakService.RegisterCorrect(player: Player): number
	local d = DataService.GetData(player)
	d.Streak += 1
	if d.Streak > d.BestStreak then d.BestStreak = d.Streak end
	d.TotalCorrectCatches += 1
	push(player, 1)
	return d.Streak
end

function StreakService.RegisterWrong(player: Player)
	local d = DataService.GetData(player)
	if d.Streak <= 0 then return end
	d.Streak = 0
	push(player, -1)
end

function StreakService.Reset(player: Player)
	local d = DataService.GetData(player)
	d.Streak = 0
	push(player, nil)
end

function StreakService.Init()
	Players.PlayerAdded:Connect(function(player)
		task.wait(2)
		if player.Parent then push(player, nil) end
	end)
end

return StreakService
