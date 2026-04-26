--!strict
-- Initializes boatbomber's WindLines (vendored from his WindShake demo).
-- Trail-based wind streaks that follow the camera. NO parts shake — this
-- is the wind visual effect without the foliage shake module.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WindLines = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WindLines"))

WindLines:Init({
	Direction = Vector3.new(1, 0, 0.3),
	Speed = 20,
	Lifetime = 1.5,
	SpawnRate = 11,
})
