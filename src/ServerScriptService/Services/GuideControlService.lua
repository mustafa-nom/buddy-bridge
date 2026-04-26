--!strict
-- Guide-side Stranger Danger booth slot submission handlers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local BadgeConfig = require(Modules:WaitForChild("BadgeConfig"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))
local ScoringService = require(Services:WaitForChild("ScoringService"))

local GuideControlService = {}

local function validateGuide(player: Player)
	if not RemoteValidation.RequirePlayer(player) then return nil end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return nil end
	if not RemoteValidation.RequireGuide(player) then return nil end
	if not RemoteValidation.RequireLevelType(round, LevelTypes.StrangerDangerPark) then return nil end
	return round
end

local function pushBoothState(round)
	local StrangerDangerLevel = require(Services:WaitForChild("Levels"):WaitForChild("StrangerDangerLevel"))
	StrangerDangerLevel.RefreshBoothDisplays(round)
end

local function handleSetSlotBadge(player: Player, payload)
	if typeof(payload) ~= "table" then return end
	local slotIndex, color, shape = payload.SlotIndex, payload.Color, payload.Shape
	if typeof(slotIndex) ~= "number" or not BadgeConfig.IsValidColor(color) or not BadgeConfig.IsValidShape(shape) then
		return
	end
	local round = validateGuide(player)
	if not round then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestSetSlotBadge", Constants.RATE_LIMIT_BOOTH_SLOT) then return end
	local slot = round.BoothState and round.BoothState.Slots[slotIndex]
	if not slot or slot.Locked then return end
	slot.Color = color
	slot.Shape = shape
	slot.Status = "Pending"
	pushBoothState(round)
end

local function allSlotsFilled(round): boolean
	for i = 1, 3 do
		local slot = round.BoothState.Slots[i]
		if not slot or not BadgeConfig.IsValidColor(slot.Color) or not BadgeConfig.IsValidShape(slot.Shape) then
			return false
		end
	end
	return true
end

local function consume(answerCounts: { [string]: number }, color: string, shape: string): boolean
	local key = BadgeConfig.Key(color, shape)
	local remaining = answerCounts[key] or 0
	if remaining <= 0 then return false end
	answerCounts[key] = remaining - 1
	return true
end

local function validateSlots(round): boolean
	local answerCounts = {}
	for _, badge in ipairs(round.ActiveScenario.AnswerBadges or {}) do
		local key = BadgeConfig.BadgeKey(badge)
		answerCounts[key] = (answerCounts[key] or 0) + 1
	end
	for _, slot in ipairs(round.BoothState.Slots) do
		if slot.Locked and slot.Color and slot.Shape then
			consume(answerCounts, slot.Color, slot.Shape)
		end
	end
	local allCorrect = true
	for _, slot in ipairs(round.BoothState.Slots) do
		if not slot.Locked then
			local correct = slot.Color and slot.Shape and consume(answerCounts, slot.Color, slot.Shape)
			slot.Locked = correct == true
			slot.Status = correct and "Correct" or "Wrong"
			allCorrect = allCorrect and correct == true
		end
	end
	return allCorrect
end

function GuideControlService.SubmitForPlayer(player: Player)
	local round = validateGuide(player)
	if not round then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestSubmitAccusation", Constants.RATE_LIMIT_BOOTH_SUBMIT) then return end
	if not allSlotsFilled(round) then
		RemoteService.FireClient(player, "Notify", { Kind = "Error", Text = "Fill all 3 slots before submitting." })
		return
	end
	local allCorrect = validateSlots(round)
	if allCorrect then
		pushBoothState(round)
		task.spawn(function()
			require(Services:WaitForChild("LevelService")).CompleteLevel(round, LevelTypes.StrangerDangerPark)
		end)
		return
	end
	round.AttemptsLeft -= 1
	ScoringService.AddMistake(round, "WrongAccusation")
	pushBoothState(round)
	if round.AttemptsLeft <= 0 then
		RemoteService.FirePair(round, "Notify", {
			Kind = "Info",
			Text = "Looks like a few got past us, but everyone got home okay. Wanna try again?",
		})
		task.spawn(function()
			require(Services:WaitForChild("RoundService")).EndRound(round, "FailedStrangerDanger")
		end)
	end
end

function GuideControlService.Init()
	RemoteService.OnServerEvent("RequestSetSlotBadge", handleSetSlotBadge)
	RemoteService.OnServerEvent("RequestSubmitAccusation", GuideControlService.SubmitForPlayer)
end

return GuideControlService
