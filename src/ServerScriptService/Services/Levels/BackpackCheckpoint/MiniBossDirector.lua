--!strict
-- Backpack Checkpoint Mini-Boss "VIP bag".
--
-- After Wave 3's normal items drain, an oversized backpack arrives with
-- three nested items the duo must sort sequentially while the belt halts.
-- Per BACKPACK_CHECKPOINT_PRD_V1_POLISHED.md and the edge-case addendum:
--   * Bag is a vessel — only inner items are sorted (#23).
--   * Inner items resolve serially; only one is "active" at a time (#24).
--   * Wrong inner sort with combo >= MiniBossFailStreakThreshold ends the
--     round with EndRound("MiniBossFail") (#21). Below threshold is a
--     normal mistake and the bag continues (#22).
--   * Successful all-three completion grants MiniBossSuccessBonus.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local ItemRegistry = require(Modules:WaitForChild("ItemRegistry"))
local ScoringConfig = require(Modules:WaitForChild("ScoringConfig"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent.Parent.Parent
local ScoringService = require(Services:WaitForChild("ScoringService"))

local BeltController = require(script.Parent:WaitForChild("BeltController"))

local MiniBossDirector = {}

local function getState(round)
	round.LevelState[LevelTypes.BackpackCheckpoint] = round.LevelState[LevelTypes.BackpackCheckpoint] or {}
	return round.LevelState[LevelTypes.BackpackCheckpoint]
end

-- Pick 3 inner items biased toward Mixed / Phishing tiers so the boss
-- actually feels like a final test. Avoid keys already used this round if
-- possible; if the registry is exhausted, fall back to any.
local function pickInnerItems(usedKeys: { [string]: boolean }): { string }
	local pool: { string } = {}
	for key in pairs(ItemRegistry.Items) do
		if not usedKeys[key] then
			-- Bias: tier 2/3 + Mixed/Phishing categories preferred, but include
			-- tier 1 too if needed.
			table.insert(pool, key)
		end
	end
	if #pool < Constants.BACKPACK_MINI_BOSS_INNER_COUNT then
		-- Exhausted — open the floodgates including used keys.
		pool = {}
		for key in pairs(ItemRegistry.Items) do
			table.insert(pool, key)
		end
	end
	-- Shuffle and take 3.
	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local picked = {}
	for i = 1, math.min(Constants.BACKPACK_MINI_BOSS_INNER_COUNT, #pool) do
		table.insert(picked, pool[i])
	end
	return picked
end

local function makeInnerItem(key: string, idx: number)
	local info = ItemRegistry.GetItem(key)
	return {
		Id = string.format("miniboss_inner_%d", idx),
		ItemKey = key,
		DisplayLabel = info.DisplayLabel,
		CorrectLane = info.CorrectLane,
		Category = info.Category,
		DifficultyTier = info.DifficultyTier,
		ScanTags = info.ScanTags,
	}
end

local function activateInner(round, mbState, idx: number)
	local inner = mbState.InnerItems[idx]
	if not inner then return end
	mbState.CurrentInnerIndex = idx
	-- Reuse BeltController.SpawnItem so Highlight/Lane-Lock/Scan all work
	-- per-active-item via the existing ScannerService remotes.
	local function onResolved(_reason: string)
		MiniBossDirector.OnInnerResolved(round)
	end
	BeltController.SpawnItem(round, round.ActiveScenario, inner, 4, idx, #mbState.InnerItems, onResolved)
	-- The belt is halted, but BeltController.SpawnItem armed a fall-off
	-- timer. Halting again here is safe and idempotent: it cancels the new
	-- timer. (BeltController.HaltBelt no-ops if already halted.)
	BeltController.HaltBelt(round)
	RemoteService.FirePair(round, "MiniBossInnerActivated", {
		RoundId = round.RoundId,
		InnerIndex = idx,
		ItemId = inner.Id,
		ItemKey = inner.ItemKey,
		DisplayLabel = inner.DisplayLabel,
	})
end

function MiniBossDirector.Begin(round, scenario, onLevelComplete: () -> (), onMiniBossFail: () -> ())
	local state = getState(round)
	state.MiniBossActive = true
	state.MiniBossOnComplete = onLevelComplete
	state.MiniBossOnFail = onMiniBossFail

	-- Build the 3 inner items, biased away from items the duo already saw.
	local usedKeys: { [string]: boolean } = {}
	for _, wave in ipairs(scenario.Waves) do
		for _, item in ipairs(wave.Items) do
			usedKeys[item.ItemKey] = true
		end
	end
	local keys = pickInnerItems(usedKeys)
	local innerItems = {}
	for i, key in ipairs(keys) do
		table.insert(innerItems, makeInnerItem(key, i))
	end
	local mbState = {
		InnerItems = innerItems,
		CurrentInnerIndex = 0,
	}
	state.MiniBoss = mbState

	-- Pre-reveal payload for the Guide HUD: labels + tags for all 3 at once.
	-- Per addendum #20 a single bag-scan reveals all 3 — for P1 we just hand
	-- it over with the start event so the Guide doesn't have to scan a
	-- separate bag instance.
	local pre = {}
	for _, item in ipairs(innerItems) do
		table.insert(pre, {
			ItemId = item.Id,
			DisplayLabel = item.DisplayLabel,
			ScanTags = item.ScanTags,
		})
	end
	RemoteService.FirePair(round, "MiniBossStarted", {
		RoundId = round.RoundId,
		InnerCount = #innerItems,
		InnerItems = pre,
	})

	-- Activate the first inner item.
	activateInner(round, mbState, 1)
end

-- Called when an inner item leaves the active slot (correct sort, wrong
-- sort below threshold, fall-off — though fall-off shouldn't happen since
-- we keep the belt halted).
function MiniBossDirector.OnInnerResolved(round)
	if not round.IsActive then return end
	local state = round.LevelState[LevelTypes.BackpackCheckpoint]
	local mbState = state and state.MiniBoss
	if not mbState then return end
	local nextIndex = mbState.CurrentInnerIndex + 1
	if nextIndex > #mbState.InnerItems then
		MiniBossDirector.Finish(round, true)
		return
	end
	activateInner(round, mbState, nextIndex)
end

-- Mini-Boss success path. Grants the success bonus and ends the level.
function MiniBossDirector.Finish(round, success: boolean)
	local state = round.LevelState[LevelTypes.BackpackCheckpoint]
	if not state or not state.MiniBossActive then return end
	state.MiniBossActive = false
	local onComplete = state.MiniBossOnComplete
	state.MiniBossOnComplete = nil
	state.MiniBossOnFail = nil
	state.MiniBoss = nil

	RemoteService.FirePair(round, "MiniBossEnded", {
		RoundId = round.RoundId,
		Success = success,
	})

	if success then
		ScoringService.AddTrustPoints(round, ScoringConfig.MiniBossSuccessBonus, "MiniBossSuccess", 1.0)
	else
		-- Kid-friendly recap. ScoreScreen still renders whatever was earned.
		RemoteService.FirePair(round, "Notify", {
			Kind = "Info",
			Text = "Whoa — that one got us. Wanna try again?",
		})
	end

	-- Belt isn't resumed — level is finishing anyway. Cleanup runs on level
	-- complete and clears all the per-item state.
	if onComplete then
		onComplete()
	end
end

-- Sort handler called by ExplorerInteractionService while Mini-Boss is
-- active. Returns (accepted, correct, reason). When wrong below threshold,
-- the bag continues — we advance to the next inner item ourselves and
-- return (true, false, "WrongInner") so ExplorerInteractionService knows
-- not to apply its own AddMistake (we already did).
function MiniBossDirector.HandleInnerSort(round, itemId: string, laneId: string): (boolean, boolean, string?)
	local scenario = round.ActiveScenario
	if not scenario or scenario.Type ~= LevelTypes.BackpackCheckpoint then
		return false, false, nil
	end
	local state = round.LevelState[LevelTypes.BackpackCheckpoint]
	if not state or not state.MiniBossActive then
		return false, false, nil
	end
	if itemId ~= round.ActiveItemId then
		return false, false, nil
	end
	local inner = BeltController.GetActiveItemInfo(round)
	if not inner then return false, false, nil end

	-- Lane lock check (same as normal flow).
	local locks = BeltController.GetLaneLocks(round)
	if locks[laneId] then
		RemoteService.FireClient(round.Explorer, "Notify", {
			Kind = "Info",
			Text = "Buddy hasn't unlocked that lane yet.",
		})
		return false, false, "Locked"
	end

	local correct = inner.CorrectLane == laneId
	RemoteService.FirePair(round, "ItemSortResult", {
		RoundId = round.RoundId,
		ItemId = itemId,
		LaneId = laneId,
		Correct = correct,
		MiniBoss = true,
	})

	if correct then
		-- Score it as a normal sort with combo multiplier.
		round.ItemsSorted += 1
		local nextStreak = (round.Streak or 0) + 1
		local multiplier = ScoringConfig.GetComboMultiplier(nextStreak)
		ScoringService.AddTrustPoints(round, Constants.TRUST_POINTS_PER_CORRECT_SORT, "MiniBossInner", multiplier)
		-- Advance via the BeltController OnResolved path (which calls
		-- MiniBossDirector.OnInnerResolved → activates next inner).
		local resolved = state.OnResolved
		-- Replicate the BeltController.HandleSort correct-path tail without
		-- a re-import: clear active + fire onResolved.
		state.OnResolved = nil
		if state.ActiveItemModel and state.ActiveItemModel.Parent then
			state.ActiveItemModel:Destroy()
		end
		state.ActiveItemModel = nil
		state.HeldByPlayer = nil
		round.ActiveItemId = nil
		if resolved then
			resolved("Sorted")
		end
		return true, true, nil
	end

	-- Wrong sort. Threshold check decides round-fail vs. continue.
	if (round.Streak or 0) >= ScoringConfig.MiniBossFailStreakThreshold then
		ScoringService.AddMistake(round, "MiniBossFail")
		local onFail = state.MiniBossOnFail
		-- Tear down active model so cleanup is consistent.
		if state.ActiveItemModel and state.ActiveItemModel.Parent then
			state.ActiveItemModel:Destroy()
		end
		state.ActiveItemModel = nil
		round.ActiveItemId = nil
		MiniBossDirector.Finish(round, false)
		if onFail then
			onFail()
		end
		return true, false, "MiniBossFail"
	end

	-- Below threshold: normal mistake, bag continues.
	ScoringService.AddMistake(round, "MiniBossWrong")
	local resolved = state.OnResolved
	state.OnResolved = nil
	if state.ActiveItemModel and state.ActiveItemModel.Parent then
		state.ActiveItemModel:Destroy()
	end
	state.ActiveItemModel = nil
	round.ActiveItemId = nil
	if resolved then
		resolved("WrongInner")
	end
	return true, false, "WrongInner"
end

function MiniBossDirector.IsActive(round): boolean
	local state = round.LevelState[LevelTypes.BackpackCheckpoint]
	return state ~= nil and state.MiniBossActive == true
end

return MiniBossDirector
