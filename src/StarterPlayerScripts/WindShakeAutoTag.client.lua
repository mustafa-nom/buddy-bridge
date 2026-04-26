--!strict
-- WindShake auto-tagger. The boatbomber module only animates parts that
-- carry the CollectionService tag "WindShake", and tagging by hand in
-- Studio is easy to forget. This script walks the workspace at startup
-- and tags any BasePart whose name (or ancestor folder name) matches a
-- foliage keyword. Also lets the user opt a whole subtree in by tagging
-- a parent Model/Folder with "WindZone".
--
-- Runs after ClientBootstrap requires WindShake, so the module's
-- DescendantAdded listener picks up the tags immediately.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WindShake = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WindShake"))

local TAG = "WindShake"
local ZONE_TAG = "WindZone"

-- Bump the global defaults so the effect is actually visible. The module
-- reads these attributes off its own ModuleScript every Heartbeat, so
-- setting them at runtime applies live. Per-part attributes override.
local windScript = ReplicatedStorage.Modules:WaitForChild("WindShake")
windScript:SetAttribute("WindPower", 1.4)
windScript:SetAttribute("WindSpeed", 22)
windScript:SetAttribute("WindDirection", Vector3.new(0.6, 0, 0.4).Unit)
local _ = WindShake -- ensure the module is required (kicks off Init via ClientBootstrap)

-- Lowercased substrings that hint a part is foliage-like.
local FOLIAGE_KEYWORDS = {
	"palm", "frond", "leaf", "leaves", "reed", "grass", "bush", "fern",
	"vine", "branch", "tree", "shrub", "kelp", "lily", "weed",
	"banner", "flag", "pennant", "cloth", "sail",
}

local function nameMatches(name: string): boolean
	local lower = string.lower(name)
	for _, kw in ipairs(FOLIAGE_KEYWORDS) do
		if string.find(lower, kw, 1, true) then
			return true
		end
	end
	return false
end

local tagged = 0

local function tryTag(inst: Instance)
	if not inst:IsA("BasePart") then return end
	if CollectionService:HasTag(inst, TAG) then return end
	if not nameMatches(inst.Name) then
		-- Check ancestor names too — a part inside a Model called "Palm"
		-- counts even if the leaf-part itself is just "Mesh".
		local p = inst.Parent
		local match = false
		while p and p ~= workspace do
			if nameMatches(p.Name) then match = true; break end
			p = p.Parent
		end
		if not match then return end
	end
	CollectionService:AddTag(inst, TAG)
	tagged += 1
end

local function tagDescendants(root: Instance)
	for _, d in ipairs(root:GetDescendants()) do
		tryTag(d)
	end
end

-- 1. Anything inside a Model/Folder tagged WindZone gets shaken (escape
--    hatch for things that don't match the keyword list).
for _, zone in ipairs(CollectionService:GetTagged(ZONE_TAG)) do
	tagDescendants(zone)
end
CollectionService:GetInstanceAddedSignal(ZONE_TAG):Connect(tagDescendants)

-- 2. Auto-tag anything in workspace by name match.
tagDescendants(workspace)

-- 3. Keep auto-tagging anything streamed in later.
workspace.DescendantAdded:Connect(tryTag)

print(string.format("[PHISH] WindShake auto-tagged %d parts.", tagged))
