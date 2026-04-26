--!strict
-- Updates the Board of Fame SurfaceGui with the top players. MVP: top 5 by
-- correct catches; refreshes every 30 seconds.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhishConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PhishConstants"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

local LeaderboardService = {}

local function buildBoardText(): string
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local p = DataService.Get(player)
		local accuracy = p.totalCatches > 0 and (p.correctCatches / p.totalCatches) or 0
		table.insert(rows, { name = player.DisplayName, correct = p.correctCatches, accuracy = accuracy })
	end
	table.sort(rows, function(a, b) return a.correct > b.correct end)
	if #rows == 0 then return "(no one's caught a phish yet)" end
	local lines = {}
	for i = 1, math.min(5, #rows) do
		local r = rows[i]
		table.insert(lines, string.format("%d. %s — %d catches (%d%% acc)",
			i, r.name, r.correct, math.floor(r.accuracy * 100)))
	end
	return table.concat(lines, "\n")
end

local function pushBoard()
	local text = buildBoardText()
	-- Update the in-world SurfaceGui label directly. The Panel is the BasePart
	-- and the SurfaceGui is its child; the body label is the second TextLabel.
	for _, panel in ipairs(CollectionService:GetTagged(PhishConstants.Tags.BoardOfFame)) do
		local sg = panel:FindFirstChildWhichIsA("SurfaceGui")
		if sg then
			local labels = {}
			for _, c in ipairs(sg:GetChildren()) do
				if c:IsA("TextLabel") then table.insert(labels, c) end
			end
			-- title is first by Y position, body second
			table.sort(labels, function(a, b) return a.Position.Y.Scale < b.Position.Y.Scale end)
			if labels[2] then labels[2].Text = text end
		end
	end
	RemoteService.FireAllClients("LeaderboardUpdated", { text = text })
end

function LeaderboardService.Init()
	task.spawn(function()
		while true do
			task.wait(30)
			pushBoard()
		end
	end)
end

return LeaderboardService
