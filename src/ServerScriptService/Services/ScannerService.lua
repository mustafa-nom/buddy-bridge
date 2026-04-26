--!strict
-- Backpack Checkpoint Active Scanner Guide tools.
--
-- Implements the PRD's four-tool workstation: Scan / Highlight / Lane Lock /
-- (Veto in P1).
--
--   * RequestScanItem(itemId)   — reveal hidden ScanTags; cooldown + per-wave
--                                  cap; cached so repeat scans on the same
--                                  itemId are free (edge case 17).
--   * RequestHighlightItem(itemId, color) — colored ring visible to both
--                                  players; last-write-wins (edge case 18).
--   * RequestUnlockLane(lane)   — toggle a lane's lock for the *current*
--                                  active item only; per-item re-lock on
--                                  bounce/spawn (edge case 11).
--
-- All state lives on `round.LevelState[BackpackCheckpoint]`. Module-level
-- state would cross-talk between concurrent duos (edge case 32).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local ItemRegistry = require(Modules:WaitForChild("ItemRegistry"))
local ScoringConfig = require(Modules:WaitForChild("ScoringConfig"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))
local ScoringService = require(Services:WaitForChild("ScoringService"))
local Levels = Services:WaitForChild("Levels")
local BackpackCheckpointLevel = require(Levels:WaitForChild("BackpackCheckpointLevel"))

local ScannerService = {}

local VALID_HIGHLIGHT_COLORS = {
	Green = true,
	Yellow = true,
	Red = true,
}

local function getState(round)
	round.LevelState[LevelTypes.BackpackCheckpoint] = round.LevelState[LevelTypes.BackpackCheckpoint] or {}
	return round.LevelState[LevelTypes.BackpackCheckpoint]
end

local function getCurrentWaveScanCap(scenario): number
	if not scenario or not scenario.Waves then return 0 end
	local wave = scenario.Waves[scenario.CurrentWaveIndex]
	if not wave then return 0 end
	return wave.ScansAllowed or 0
end

local function handleScanItem(player: Player, itemId: string)
	if typeof(itemId) ~= "string" then return end
	local okPlayer = RemoteValidation.RequirePlayer(player)
	if not okPlayer then return end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return end
	local okRole = RemoteValidation.RequireGuide(player)
	if not okRole then return end
	local okLevel = RemoteValidation.RequireLevelType(round, LevelTypes.BackpackCheckpoint)
	if not okLevel then return end
	local okRate = RemoteValidation.RequireRateLimit(player, "RequestScanItem", Constants.RATE_LIMIT_SCAN)
	if not okRate then return end

	local state = getState(round)
	if itemId ~= round.ActiveItemId then
		-- Edge case 19: ghost-ring race. Drop silently.
		return
	end
	local activeItem = BackpackCheckpointLevel.GetActiveItemInfo(round)
	if not activeItem then return end

	state.ScannedTags = state.ScannedTags or {}
	-- Edge case 17: cached re-scan. If we've already scanned this itemKey
	-- this round, return the cached result without consuming the cap.
	local cached = state.ScannedTags[activeItem.ItemKey]
	if cached then
		RemoteService.FireClient(round.Guide, "ScannerOverlayUpdated", {
			RoundId = round.RoundId,
			ItemId = itemId,
			ItemKey = activeItem.ItemKey,
			Tags = cached,
			Cached = true,
			ScansUsedThisWave = state.ScansUsedThisWave or 0,
			ScansAllowedThisWave = getCurrentWaveScanCap(round.ActiveScenario),
		})
		return
	end

	local cap = getCurrentWaveScanCap(round.ActiveScenario)
	state.ScansUsedThisWave = (state.ScansUsedThisWave or 0) + 1
	if state.ScansUsedThisWave > cap then
		state.ScansUsedThisWave = cap
		RemoteService.FireClient(round.Guide, "Notify", {
			Kind = "Info",
			Text = "Out of scans this wave.",
		})
		return
	end

	local tags = activeItem.ScanTags or {}
	state.ScannedTags[activeItem.ItemKey] = tags
	RemoteService.FireClient(round.Guide, "ScannerOverlayUpdated", {
		RoundId = round.RoundId,
		ItemId = itemId,
		ItemKey = activeItem.ItemKey,
		Tags = tags,
		Cached = false,
		ScansUsedThisWave = state.ScansUsedThisWave,
		ScansAllowedThisWave = cap,
	})
end

local function handleHighlightItem(player: Player, itemId: string, color: string)
	if typeof(itemId) ~= "string" or typeof(color) ~= "string" then return end
	if not VALID_HIGHLIGHT_COLORS[color] then return end
	local okPlayer = RemoteValidation.RequirePlayer(player)
	if not okPlayer then return end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return end
	local okRole = RemoteValidation.RequireGuide(player)
	if not okRole then return end
	local okLevel = RemoteValidation.RequireLevelType(round, LevelTypes.BackpackCheckpoint)
	if not okLevel then return end
	local okRate = RemoteValidation.RequireRateLimit(player, "RequestHighlightItem", Constants.RATE_LIMIT_HIGHLIGHT)
	if not okRate then return end

	-- Edge case 19: drop silently if itemId is no longer active.
	if itemId ~= round.ActiveItemId then return end

	BackpackCheckpointLevel.SetHighlight(round, itemId, color)
end

local function handleUnlockLane(player: Player, lane: string)
	if typeof(lane) ~= "string" then return end
	if not ItemRegistry.IsValidLane(lane) then return end
	local okPlayer = RemoteValidation.RequirePlayer(player)
	if not okPlayer then return end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return end
	local okRole = RemoteValidation.RequireGuide(player)
	if not okRole then return end
	local okLevel = RemoteValidation.RequireLevelType(round, LevelTypes.BackpackCheckpoint)
	if not okLevel then return end
	local okRate = RemoteValidation.RequireRateLimit(player, "RequestUnlockLane:" .. lane, Constants.RATE_LIMIT_UNLOCK_LANE)
	if not okRate then return end

	-- Toggle the chosen lane open. Other lanes stay locked — the Guide picks
	-- exactly one. (We don't re-lock automatically on second click; clicking
	-- an unlocked lane locks it again so the Guide can reconsider.)
	local locks = BackpackCheckpointLevel.GetLaneLocks(round)
	if not locks then return end
	local nowLocked = not locks[lane]
	-- If they're unlocking THIS lane, lock the other two.
	if not nowLocked then
		for otherLane in pairs(ItemRegistry.Lanes) do
			BackpackCheckpointLevel.SetLaneLock(round, otherLane, otherLane ~= lane)
		end
	else
		BackpackCheckpointLevel.SetLaneLock(round, lane, true)
	end
end

local function handleVeto(player: Player)
	local okPlayer = RemoteValidation.RequirePlayer(player)
	if not okPlayer then return end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return end
	local okRole = RemoteValidation.RequireGuide(player)
	if not okRole then return end
	local okLevel = RemoteValidation.RequireLevelType(round, LevelTypes.BackpackCheckpoint)
	if not okLevel then return end
	local okRate = RemoteValidation.RequireRateLimit(player, "RequestVeto", Constants.RATE_LIMIT_VETO)
	if not okRate then return end

	local state = getState(round)
	-- Edge case 12: no active item → disallow.
	if not round.ActiveItemId or not state.ActiveItemModel then
		RemoteService.FireClient(round.Guide, "Notify", {
			Kind = "Info",
			Text = "Nothing on the belt to veto.",
		})
		return
	end
	if state.VetoUsed then
		RemoteService.FireClient(round.Guide, "Notify", {
			Kind = "Info",
			Text = "Veto already used this round.",
		})
		return
	end
	state.VetoUsed = true

	-- Edge case 15: cost combo by halving (not zeroing) — encourages "use it
	-- when it matters" without nuking the run.
	ScoringService.ReduceStreak(round, ScoringConfig.VetoComboDivisor)

	-- Edge case 13: during Mini-Boss the belt is already halted, but Veto
	-- still costs the charge and re-locks lanes so the Guide must reconfirm.
	-- BeltController.HaltBelt is idempotent so it's safe to call regardless.
	BackpackCheckpointLevel.HaltBelt(round)
	-- Re-lock all lanes (edge case 14: if Explorer is mid-carry, they can
	-- still walk back; placement just blocks until lanes re-arm).
	for laneName in pairs(ItemRegistry.Lanes) do
		BackpackCheckpointLevel.SetLaneLock(round, laneName, true)
	end

	RemoteService.FirePair(round, "VetoActivated", {
		RoundId = round.RoundId,
		DurationSeconds = Constants.BACKPACK_VETO_FREEZE_SECONDS,
	})

	task.delay(Constants.BACKPACK_VETO_FREEZE_SECONDS, function()
		if not round.IsActive then return end
		local s = round.LevelState[LevelTypes.BackpackCheckpoint]
		-- Don't auto-resume if Mini-Boss took over the halt.
		if s and not s.MiniBossActive then
			BackpackCheckpointLevel.ResumeBelt(round)
		end
		RemoteService.FirePair(round, "VetoEnded", {
			RoundId = round.RoundId,
		})
	end)
end

local function handleDismissIntro(player: Player)
	local okPlayer = RemoteValidation.RequirePlayer(player)
	if not okPlayer then return end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return end
	local okRate = RemoteValidation.RequireRateLimit(player, "RequestDismissIntro", Constants.RATE_LIMIT_DISMISS_INTRO)
	if not okRate then return end

	local state = getState(round)
	state.IntroDismissedBy = state.IntroDismissedBy or {}
	state.IntroDismissedBy[player] = true

	-- P2 gating: fire the gate as soon as BOTH players have dismissed.
	-- The gate also self-fires on timeout (set in BackpackCheckpointLevel).
	if state.IntroGate
		and state.IntroDismissedBy[round.Explorer]
		and state.IntroDismissedBy[round.Guide]
	then
		local gate = state.IntroGate
		state.IntroGate = nil
		gate()
	end
end

function ScannerService.Init()
	RemoteService.OnServerEvent("RequestScanItem", handleScanItem)
	RemoteService.OnServerEvent("RequestHighlightItem", handleHighlightItem)
	RemoteService.OnServerEvent("RequestUnlockLane", handleUnlockLane)
	RemoteService.OnServerEvent("RequestVeto", handleVeto)
	RemoteService.OnServerEvent("RequestDismissIntro", handleDismissIntro)
end

return ScannerService
