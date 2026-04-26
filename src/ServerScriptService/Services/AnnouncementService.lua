--!strict
-- Server-wide hype channel. Broadcasts rare-catch and streak-milestone events
-- to every connected player so the lodge feels alive.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local AnnouncementService = {}

local function broadcast(payload: any)
	RemoteService.FireAllClients("RareCatchAnnouncement", payload)
end

function AnnouncementService.RareCatch(player: Player, fishDisplayName: string, rarity: string)
	if rarity == "Epic" or rarity == "Legendary" then
		broadcast({
			Kind = "RareCatch",
			PlayerName = player.DisplayName or player.Name,
			FishName = fishDisplayName,
			Rarity = rarity,
		})
	end
end

function AnnouncementService.StreakMilestone(player: Player, streak: number)
	broadcast({
		Kind = "StreakMilestone",
		PlayerName = player.DisplayName or player.Name,
		Streak = streak,
	})
end

function AnnouncementService.Init() end

return AnnouncementService
