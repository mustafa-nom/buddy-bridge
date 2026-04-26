--!strict
-- The Phisherman boss event. MVP stub: every PHISHERMAN_INTERVAL_SECONDS,
-- broadcast PhishermanArrived to every client. Full multi-step "build a case"
-- flow is post-MVP. For the demo this surfaces a server-wide event the
-- client can react to (warning toast, bobber visual change, etc.).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhishConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PhishConstants"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local BossService = {}

function BossService.Init()
	task.spawn(function()
		while true do
			task.wait(PhishConstants.PHISHERMAN_INTERVAL_SECONDS)
			if #Players:GetPlayers() == 0 then continue end
			local spawn = CollectionService:GetTagged(PhishConstants.Tags.PhishermanSpawn)[1]
			local pos = spawn and spawn:IsA("BasePart") and spawn.Position or Vector3.new(60, 3, -40)
			RemoteService.FireAllClients("PhishermanArrived", { position = pos })
			-- Auto-resolve after 90s as a placeholder until full flow lands.
			task.delay(90, function()
				RemoteService.FireAllClients("PhishermanDefeated", {})
			end)
		end
	end)
end

return BossService
