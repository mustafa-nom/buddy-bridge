--!strict
-- Validates a KEEP / CUT_BAIT decision against the active card. Grants
-- rewards, updates the dex, fires DecisionResult.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhishConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PhishConstants"))
local PhishDex = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PhishDex"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local CardService = require(Services:WaitForChild("CardService"))
local FishingService = require(Services:WaitForChild("FishingService"))
local ScoringService = require(Services:WaitForChild("ScoringService"))
local PhishDexService = require(Services:WaitForChild("PhishDexService"))
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))

local DecisionService = {}

local DECISIONS = { KEEP = true, CUT_BAIT = true }

local function speciesDisplayName(id: string): string
	local s = PhishDex.Get(id)
	return s and s.displayName or id
end

local function onSubmitDecision(player: Player, payload: any)
	local ok, _ = RemoteValidation.RunChain({
		function() return RemoteValidation.RequirePlayer(player) end,
		function() return RemoteValidation.RequireRateLimit(player, "Decision", PhishConstants.RATE_LIMIT_DECISION) end,
	})
	if not ok then return end
	if FishingService.GetState(player) ~= "Inspecting" then return end
	if type(payload) ~= "table" or not DECISIONS[payload.decision] then return end

	local card = CardService.GetActive(player)
	if not card then
		FishingService.SetIdle(player)
		return
	end

	local playerSaidLegit = (payload.decision == "KEEP")
	local actuallyLegit = card.isLegit == true
	local wasCorrect = (playerSaidLegit == actuallyLegit)

	local rewardDelta = ScoringService.GrantCatchReward(player, wasCorrect, card)
	if wasCorrect then
		PhishDexService.RecordCatch(player, card.species)
	end

	RemoteService.FireClient(player, "DecisionResult", {
		cardId = card.id,
		wasCorrect = wasCorrect,
		decision = payload.decision,
		isLegit = actuallyLegit,
		species = card.species,
		speciesDisplayName = speciesDisplayName(card.species),
		redFlags = card.redFlags or {},
		coinsDelta = rewardDelta.coinsDelta,
		xpDelta = rewardDelta.xpDelta,
	})

	CardService.Clear(player)
	FishingService.SetIdle(player)
end

function DecisionService.Init()
	RemoteService.OnServerEvent("SubmitDecision", onSubmitDecision)
end

return DecisionService
