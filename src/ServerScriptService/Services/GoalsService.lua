--!strict
-- Per-player session goals. On join, picks 3 from GoalCatalog. Catch
-- resolution and aquarium services emit events here; we tally progress and
-- pay out pearls + a "GOAL!" toast on completion.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GoalCatalog = require(Modules:WaitForChild("GoalCatalog"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

local GoalsService = {}

type GoalState = {
	id: string,
	displayName: string,
	target: number,
	reward: number,
	kind: string,
	filter: { [string]: any }?,
	progress: number,
	completed: boolean,
}

local sessionGoals: { [Player]: { GoalState } } = {}

local rarityRank = { Common = 1, Rare = 2, Epic = 3, Legendary = 4 }

local function pushSnapshot(player: Player)
	local goals = sessionGoals[player]
	if not goals then return end
	RemoteService.FireClient(player, "GoalsUpdated", {
		Goals = goals,
	})
end

local function generateGoals(player: Player)
	local picked = GoalCatalog.Pick(3)
	local list: { GoalState } = {}
	for _, g in ipairs(picked) do
		table.insert(list, {
			id = g.id,
			displayName = g.displayName,
			target = g.target,
			reward = g.reward,
			kind = g.kind,
			filter = g.filter,
			progress = 0,
			completed = false,
		})
	end
	sessionGoals[player] = list
end

local function bump(player: Player, goalIndex: number, amount: number)
	local goals = sessionGoals[player]
	if not goals then return end
	local goal = goals[goalIndex]
	if not goal or goal.completed then return end
	goal.progress = math.min(goal.progress + amount, goal.target)
	if goal.progress >= goal.target then
		goal.completed = true
		DataService.GrantPearls(player, goal.reward)
		RemoteService.FireClient(player, "GoalCompleted", {
			GoalId = goal.id,
			DisplayName = goal.displayName,
			Reward = goal.reward,
		})
	end
	pushSnapshot(player)
end

local function setMin(player: Player, goalIndex: number, value: number)
	-- Used for Streak goals where progress is "highest streak observed".
	local goals = sessionGoals[player]
	if not goals then return end
	local goal = goals[goalIndex]
	if not goal or goal.completed then return end
	if value > goal.progress then
		goal.progress = math.min(value, goal.target)
		if goal.progress >= goal.target then
			goal.completed = true
			DataService.GrantPearls(player, goal.reward)
			RemoteService.FireClient(player, "GoalCompleted", {
				GoalId = goal.id,
				DisplayName = goal.displayName,
				Reward = goal.reward,
			})
		end
		pushSnapshot(player)
	end
end

-- Public: called by other services on event-of-interest.

local function catchGoalMatches(goal, fishCategory: string, fishRarity: string, action: string): boolean
	if goal.kind == "CategoryCorrect" then
		return goal.filter ~= nil and goal.filter.category == fishCategory
	end
	if goal.kind == "ActionCorrect" then
		return goal.filter ~= nil and goal.filter.action == action
	end
	if goal.kind == "RarityCatch" then
		if not goal.filter then return false end
		return (rarityRank[fishRarity] or 0) >= (rarityRank[goal.filter.minRarity] or 99)
	end
	return false
end

function GoalsService.RecordCorrectCatch(player: Player, fishCategory: string, fishRarity: string, action: string)
	local goals = sessionGoals[player]
	if not goals then return end
	for i, goal in ipairs(goals) do
		if goal.completed then continue end
		if catchGoalMatches(goal, fishCategory, fishRarity, action) then
			bump(player, i, 1)
		end
	end
end

function GoalsService.RecordVerifyUse(player: Player)
	local goals = sessionGoals[player]
	if not goals then return end
	for i, goal in ipairs(goals) do
		if goal.kind == "VerifyUse" and not goal.completed then
			bump(player, i, 1)
		end
	end
end

function GoalsService.RecordStreak(player: Player, streak: number)
	local goals = sessionGoals[player]
	if not goals then return end
	for i, goal in ipairs(goals) do
		if goal.kind == "Streak" and not goal.completed then
			setMin(player, i, streak)
		end
	end
end

function GoalsService.RecordPearlsEarned(player: Player, amount: number)
	if amount <= 0 then return end
	local goals = sessionGoals[player]
	if not goals then return end
	for i, goal in ipairs(goals) do
		if goal.kind == "EarnPearls" and not goal.completed then
			bump(player, i, amount)
		end
	end
end

function GoalsService.RecordAquariumPlace(player: Player)
	local goals = sessionGoals[player]
	if not goals then return end
	for i, goal in ipairs(goals) do
		if goal.kind == "AquariumPlace" and not goal.completed then
			bump(player, i, 1)
		end
	end
end

function GoalsService.GetGoalsFor(player: Player): { GoalState }
	return sessionGoals[player] or {}
end

function GoalsService.Init()
	Players.PlayerAdded:Connect(function(player)
		generateGoals(player)
		task.wait(2.5)
		if player.Parent then pushSnapshot(player) end
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessionGoals[player] = nil
	end)
	-- Pick goals for any player already in the game (e.g. after a script reload).
	for _, player in ipairs(Players:GetPlayers()) do
		if not sessionGoals[player] then
			generateGoals(player)
			task.delay(2, function()
				if player.Parent then pushSnapshot(player) end
			end)
		end
	end
end

return GoalsService
