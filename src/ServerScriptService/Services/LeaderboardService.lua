--!strict
-- Persistent Board of Fame backed by OrderedDataStore. Score = correct
-- catches. The board reads the top 10 globally and renders them onto
-- every BasePart tagged BoardOfFame (SurfaceGui body label) plus fires
-- LeaderboardUpdated to clients. Updates on a 30s loop.
--
-- DataService.OnSaved hooks fire after each profile save so the
-- player's score stays current without waiting for the periodic refresh.
--
-- Failure modes: if Studio API access is disabled or the store errors,
-- the previous text stays on the board and nothing crashes.

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhishConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PhishConstants"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

local LeaderboardService = {}

local LEADERBOARD_NAME = "PhishLeaderboardCorrectCatchesV1"
local TOP_N = 10
local REFRESH_INTERVAL = 30

local store: OrderedDataStore? = nil
do
	local ok, s = pcall(function()
		return DataStoreService:GetOrderedDataStore(LEADERBOARD_NAME)
	end)
	if ok then store = s else warn("[PHISH][Leaderboard] No OrderedDataStore: " .. tostring(s)) end
end

-- Avoid hammering Players:GetNameFromUserIdAsync — cache lookups.
local nameCache: { [number]: string } = {}
local function nameForUserId(userId: number): string
	local cached = nameCache[userId]
	if cached then return cached end
	-- If the player is currently online we already have the name.
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId == userId then
			nameCache[userId] = p.DisplayName
			return p.DisplayName
		end
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(name) == "string" then
		nameCache[userId] = name
		return name
	end
	return string.format("Player %d", userId)
end

local function writeScore(userId: number, score: number)
	if not store then return end
	local s = store
	pcall(function()
		s:UpdateAsync(tostring(userId), function(prev)
			-- Only overwrite if the new score is bigger so we never regress
			-- a player's leaderboard rank on a misread.
			if type(prev) == "number" and prev >= score then return nil end
			return score
		end)
	end)
end

local function readTop(): { { userId: number, score: number } }
	if not store then return {} end
	local s = store
	local ok, page = pcall(function()
		return s:GetSortedAsync(false, TOP_N):GetCurrentPage()
	end)
	if not ok or type(page) ~= "table" then return {} end
	local out = {}
	for _, entry in ipairs(page) do
		local uid = tonumber(entry.key)
		local score = tonumber(entry.value)
		if uid and score then
			table.insert(out, { userId = uid, score = score })
		end
	end
	return out
end

-- ---------------------------------------------------------------------------
-- SurfaceGui table renderer. Structured #|Name|Catches with a bold header,
-- alternating row backgrounds, and rebuilt fresh on each refresh.
-- ---------------------------------------------------------------------------

local TABLE_FRAME_NAME = "PhishLeaderTable"
local COL_RANK_SCALE = 0.14
local COL_NAME_SCALE = 0.58
local COL_SCORE_SCALE = 0.28

local TEXT_HEADER = Color3.fromRGB(255, 218, 130)
local TEXT_BODY = Color3.fromRGB(245, 240, 226)
local TEXT_MUTED = Color3.fromRGB(170, 162, 150)
local ROW_EVEN = Color3.fromRGB(34, 26, 36)
local ROW_ODD = Color3.fromRGB(28, 22, 30)

local function makeColLabel(parent: Instance, text: string, scale: number, x: number, opts: { bold: boolean?, color: Color3?, align: Enum.TextXAlignment? })
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(scale, -8, 1, 0)
	label.Position = UDim2.new(x, 4, 0, 0)
	label.Font = opts.bold and Enum.Font.FredokaOne or Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = opts.color or TEXT_BODY
	label.TextXAlignment = opts.align or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = text
	label.Parent = parent
	-- Cap font size so very wide rows don't blow up the text.
	local size = Instance.new("UITextSizeConstraint")
	size.MaxTextSize = opts.bold and 32 or 28
	size.MinTextSize = 8
	size.Parent = label
	return label
end

local function ensureTableFrame(sg: SurfaceGui): Frame
	local existing = sg:FindFirstChild(TABLE_FRAME_NAME)
	if existing and existing:IsA("Frame") then return existing end
	if existing then existing:Destroy() end
	local frame = Instance.new("Frame")
	frame.Name = TABLE_FRAME_NAME
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -16)
	frame.Size = UDim2.new(0.92, 0, 0.78, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = sg
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.Padding = UDim.new(0, 4)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = frame
	return frame
end

local function clearChildrenExceptLayout(frame: Frame)
	for _, c in ipairs(frame:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
end

local function buildHeaderRow(parent: Frame): Frame
	local row = Instance.new("Frame")
	row.Name = "Header"
	row.LayoutOrder = 0
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = Color3.fromRGB(20, 14, 22)
	row.BorderSizePixel = 0
	row.Parent = parent
	makeColLabel(row, "#", COL_RANK_SCALE, 0, { bold = true, color = TEXT_HEADER, align = Enum.TextXAlignment.Center })
	makeColLabel(row, "NAME", COL_NAME_SCALE, COL_RANK_SCALE, { bold = true, color = TEXT_HEADER, align = Enum.TextXAlignment.Left })
	makeColLabel(row, "CATCHES", COL_SCORE_SCALE, COL_RANK_SCALE + COL_NAME_SCALE, { bold = true, color = TEXT_HEADER, align = Enum.TextXAlignment.Right })
	return row
end

local function buildDataRow(parent: Frame, layoutOrder: number, rank: number, name: string, score: number): Frame
	local row = Instance.new("Frame")
	row.Name = string.format("Row%d", rank)
	row.LayoutOrder = layoutOrder
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundColor3 = (rank % 2 == 0) and ROW_EVEN or ROW_ODD
	row.BorderSizePixel = 0
	row.Parent = parent
	makeColLabel(row, string.format("%d.", rank), COL_RANK_SCALE, 0,
		{ color = TEXT_HEADER, align = Enum.TextXAlignment.Center })
	makeColLabel(row, name, COL_NAME_SCALE, COL_RANK_SCALE,
		{ color = TEXT_BODY, align = Enum.TextXAlignment.Left })
	makeColLabel(row, tostring(score), COL_SCORE_SCALE, COL_RANK_SCALE + COL_NAME_SCALE,
		{ color = TEXT_BODY, align = Enum.TextXAlignment.Right })
	return row
end

local function buildEmptyRow(parent: Frame)
	local row = Instance.new("Frame")
	row.Name = "Empty"
	row.LayoutOrder = 1
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundTransparency = 1
	row.Parent = parent
	makeColLabel(row, "(no one's caught a phish yet)", 1, 0,
		{ color = TEXT_MUTED, align = Enum.TextXAlignment.Center })
end

local lastTop: { { userId: number, score: number } } = {}

local function renderTable(sg: SurfaceGui, top: { { userId: number, score: number } })
	local frame = ensureTableFrame(sg)
	clearChildrenExceptLayout(frame)
	buildHeaderRow(frame)
	if #top == 0 then
		buildEmptyRow(frame)
		return
	end
	for i, entry in ipairs(top) do
		buildDataRow(frame, i, i, nameForUserId(entry.userId), entry.score)
	end
end

local function pushBoard()
	local top = readTop()
	-- Cache the last known good ranking so a transient store error doesn't
	-- blank the boards. Empty result keeps prior data.
	if #top > 0 then lastTop = top end

	for _, panel in ipairs(CollectionService:GetTagged(PhishConstants.Tags.BoardOfFame)) do
		local sg = panel:FindFirstChildWhichIsA("SurfaceGui")
		if sg then
			-- Hide the legacy "Body" TextLabel if the SurfaceGui still has
			-- one — the structured table replaces it.
			local body = sg:FindFirstChild("Body")
			if body and body:IsA("TextLabel") then body.Visible = false end
			renderTable(sg, lastTop)
		end
	end

	RemoteService.FireAllClients("LeaderboardUpdated", { top = lastTop })
end

-- Public hook: force a board refresh now (e.g. after a high-value catch).
-- Used by ScoringService.GrantCatchReward so the in-world SurfaceGui
-- updates immediately, not on the next 30s tick.
function LeaderboardService.Refresh()
	pushBoard()
end

function LeaderboardService.Init()
	-- Mirror every profile save into the ordered store so live ranks
	-- update without waiting for the 30s loop.
	DataService.OnSaved(function(player, profile)
		writeScore(player.UserId, profile.correctCatches or 0)
	end)

	-- Initial paint as soon as we boot — gives the SurfaceGui content even
	-- before the first periodic tick.
	task.spawn(function()
		task.wait(2)
		pushBoard()
	end)

	task.spawn(function()
		while true do
			task.wait(REFRESH_INTERVAL)
			pushBoard()
		end
	end)
end

return LeaderboardService
