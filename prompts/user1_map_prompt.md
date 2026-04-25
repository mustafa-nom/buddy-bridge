# User 1 — Map Builder Prompt (Roblox MCP / Studio)

> Paste this prompt into your Claude Code session. You are the **Map User**. You have the Roblox MCP attached and you build everything in Roblox Studio. You do **not** write Lua scripts — that is User 2's job.

---

## Prompt

You are working on **Buddy Bridge: A Two Player Trust Game**, a 2-player asymmetric co-op safety game for the LAHacks Roblox Civility Challenge. The team is targeting Roblox's **"Learn and Explore"** sort.

Before doing anything, read these files in this order and treat them as authoritative:

1. `CLAUDE.md`
2. `docs/PRD.md`
3. `docs/GAME_DESIGN.md`
4. `docs/TECHNICAL_DESIGN.md`
5. `docs/MVP_SCOPE.md`
6. `docs/JUDGING_STRATEGY.md`
7. `tasks/todo.md`
8. `tasks/lessons.md`
9. `human_todo.md`

Then read this prompt to understand your scope.

### Your Role

You are the **Map User**. Your scope:

- Build the **lobby**, **play arena slots**, **level templates**, **NPC templates**, **item templates**, and **booth template** in Roblox Studio using the Roblox MCP.
- Place all CollectionService tags and Instance attributes the scripting user needs.
- Set up `Workspace`, `ServerStorage`, and any geometry-only parts of `ReplicatedStorage` (no scripts).
- Apply visual polish — colors, materials, signage, themed decoration, SFX placeholders.

You do **NOT**:
- Write Lua scripts (that is User 2's responsibility, working from `src/` via Rojo).
- Modify files in `src/` on disk.
- Create RemoteEvents / RemoteFunctions / BindableEvents — those are managed by `RemoteService.lua`.

### Visual Style Bible (read this first, applies to everything you build)

Judge Andrew specifically flagged **consistent styling** as a make-or-break. Judge Jenine's reference comp is *Ecos La Brea* — educational MMO that doesn't break its own world. Buddy Bridge needs to read as **one cohesive game**, not a mash-up of three different art directions.

Lock these defaults before you build anything:

- **Palette:** warm cartoon — saturated but not neon. Soft greens, friendly oranges, cozy browns. Avoid grays / steel / military / corporate looks anywhere.
- **Material vocabulary:** SmoothPlastic and Plastic mostly. Avoid Metal, Glass, ForceField, Neon (except for sparkle accents), DiamondPlate, Slate.
- **Proportions:** chunky / cartoon. Rounded edges. Use parts with `CornerRadius`-like bevels via beveled meshes where you can.
- **Font on signage / billboards:** `Cartoon` (Roblox built-in) or `Fredoka`-equivalent. Same font everywhere.
- **Lighting:** warm `Atmosphere` with daylight feel; soft shadows. No horror lighting, no nightclub lighting.
- **NPC art style:** all NPCs share the same proportions and outline weight. Whether the NPC is the hot dog vendor or the white-van guy, they should look like they came from the same animated short.
- **Item art style:** all 13 Backpack Checkpoint items share the same chunky cartoon-prop language. A glowing house and a paint palette should look like siblings.
- **UI:** rounded corner radius, drop shadows, cartoon font. The booth's manual UI, the lobby HUD, and the score screen should all share a single style kit.

Anything that breaks this bible should be revised before you ship.

### Game Design Recap

This game has **2 polished levels**:

1. **Stranger Danger Park** — a friendly park / plaza with NPCs. The Explorer walks up to NPCs to gather clues; some NPCs are risky strangers. The Guide reads a manual of warning signs.
2. **Backpack Checkpoint** — a TSA-style sorting station with a conveyor belt and three bins (Pack It / Ask First / Leave It). The Guide reads the chart, the Explorer sorts items.

Players: **8 max per server**, in **duos of 2**, up to 4 simultaneous duos. The lobby is shared. Each duo plays in its own instanced **play arena slot**.

### Build Plan

Build in this order. Save and verify in Studio after each section.

#### 1. Place Settings

- Set **Max Players** = 8 in Game Settings.
- `Workspace.FilteringEnabled = true`.

#### 2. Lobby

A single shared hub area where all 8 players spawn.

- `Lobby` Model in `Workspace`.
- Bright cartoon styling. Big welcome sign: "Buddy Bridge — Find a buddy and start a run".
- `SpawnLocation` so all players spawn here.
- A **Treehouse / Garden** decorative area visible from spawn — User 2's progression visuals will eventually grow here.

##### Capsule Pads

Place **4 capsule pad pairs** around the lobby (8 pads total):

- Each pad: small bright cylinder (~6 studs wide, ~1 stud tall).
- Tag: `LobbyCapsule`.
- Attributes:
    - `CapsuleId` — unique, e.g. `"capsule_1a"`, `"capsule_1b"`, `"capsule_2a"`, `"capsule_2b"`, etc.
    - `CapsulePairId` — shared between pads of a pair, e.g. `"pair_1"`, `"pair_2"`, etc.
- Pads in a pair sit visibly next to each other (~6 studs apart) with a small archway/sign labeled "Buddy Pair 1", "Buddy Pair 2", etc.
- `BillboardGui` over each pad: "Step here to find a buddy".

No scripts on capsules — User 2's `LobbyService` handles all logic via tags.

#### 3. Play Arena Slots

Build **4 play arena slots** in a hidden region (e.g. y = -500 below the lobby).

For each slot:
- `Model` named `Slot1`, `Slot2`, `Slot3`, `Slot4` under a `Workspace/PlayArenaSlots` folder.
- Tag the root: `PlayArenaSlot`.
- Attribute `SlotIndex` = 1, 2, 3, 4.
- Slots spaced far apart (~500 studs between each) so cloned levels don't overlap.

Inside each slot:
- `ExplorerSpawn` part (small invisible part). Tag: `ExplorerSpawn`.
- `BoothAnchor` part — reference part where the booth template's `PrimaryPart` will align. Place ~30 studs to the side, with sightline to where the levels will load. Tag: `BoothAnchor`.
- Empty `Folder` named `PlayArea` — level templates clone in here.
- Empty `Folder` named `Booth` — booth template clones in here.
- A simple ground plane is fine for visual reference.

Each slot must have enough room for **two level templates** to clone side-by-side (Stranger Danger Park ~80×80 studs, Backpack Checkpoint ~40×40 studs). Plan for ~150 studs of level area per slot.

#### 4. Level Templates

Create the level templates as Models under `ServerStorage/Levels`. Each Model needs `PrimaryPart` set.

##### Level A: StrangerDangerPark

A friendly cartoon park / plaza.

- Root Model name: `StrangerDangerPark`.
- Attribute `LevelType` = `"StrangerDangerPark"` on the root.
- Geometry to include — these are the "different backgrounds and scenes" the judges (Andrew specifically) want to see, each anchoring a recognizable stranger-danger archetype:
    - A small park with grass, trees, a fountain centerpiece.
    - A **hot dog stand or shop counter** (safe-NPC archetype — uniformed worker doing their job).
    - A **playground** with kid-sized play structures (safe-NPC archetype — parent with kids).
    - A **parked white van** off to one side (the canonical risky archetype — make it visibly a white van, not just a generic car). Include an open side door for the "calling you over" pose.
    - A **back alley** / narrow passage behind a shop wall (risky archetype — lurking adult, possibly with a knife).
    - A **police officer / park ranger booth** (safe-NPC archetype — uniformed authority).
    - A **public bench / fountain** area (neutral or safe archetype — person reading or relaxing).
- `LevelEntry` part where the Explorer spawns at level start. Tag: `LevelEntry`.
- 6 `BuddyNpcSpawn` parts placed at the locations above (hot dog stand, playground, white van, alley, ranger booth, bench). Each has:
    - Tag: `BuddyNpcSpawn`
    - Attribute `NpcSpawnId` — unique, e.g. `"npc_spawn_hotdog"`, `"npc_spawn_playground"`, `"npc_spawn_whitevan"`, `"npc_spawn_alley"`, `"npc_spawn_ranger"`, `"npc_spawn_bench"`.
    - Attribute `Anchor` — descriptive string about the spot, e.g. `"HotdogStand"`, `"WhiteVan"`, `"AlleyBehindShop"`. User 2's scenario logic uses this to bias which NPC role types are plausible at which spawns (e.g. the white van and alley spawns will skew risky; the hot dog stand and ranger booth will skew safe).
- 4 candidate `PuppySpawn` parts scattered around (under a bench, near the fountain, behind the playground slide, etc.). Tag: `PuppySpawn`. The server picks one per round.
- `LevelExit` part / trigger near the puppy spawns. Tag: `LevelExit`. (User 2's code activates the correct one once the puppy is found.)
- `BuddyPortal` part on one edge — this is the door/portal to Backpack Checkpoint. Tag: `BuddyPortal`. Initially disabled visually; User 2 enables it when StrangerDangerPark completes.

Aesthetic: bright, friendly, cartoon. Trees with rounded foliage. No horror vibes.

##### Level B: BackpackCheckpoint

A bright airport-style sorting checkpoint.

- Root Model name: `BackpackCheckpoint`.
- Attribute `LevelType` = `"BackpackCheckpoint"` on the root.
- Geometry:
    - A floor pad where the Explorer stands.
    - A conveyor belt visual (a long flat segment with cartoon arrows).
    - A `BeltStart` part at one end (where items spawn). Tag: `BeltStart`.
    - A `BeltEnd` part at the other end. Tag: `BeltEnd`.
    - 3 bins on the wall behind the belt:
        - Green "Pack It" bin. Tag: `BuddyBin`. Attribute `LaneId` = `"PackIt"`.
        - Yellow "Ask First" bin. Tag: `BuddyBin`. Attribute `LaneId` = `"AskFirst"`.
        - Red "Leave It" bin. Tag: `BuddyBin`. Attribute `LaneId` = `"LeaveIt"`.
    - Each bin has a `ProximityPrompt` so the Explorer can drop items by standing near and triggering.
- `LevelEntry` part — spawn for the Explorer when this level starts.
- `LevelExit` part / trigger that fires when the conveyor finishes its item count. Tag: `LevelExit`. (Server-controlled.)
- `RoundFinishZone` part beyond the level exit. Tag: `RoundFinishZone`. (Triggers the score screen.)

Aesthetic: cartoon TSA / airport. Big readable bin labels. No "no-fly list" jargon.

#### 5. NPC Templates

Build **at least 6 visually distinct NPC rigs** in `ServerStorage/NpcTemplates`. These get cloned into NPC spawn points at round start.

Each NPC:
- Anchored `Model` with a humanoid rig (R6 or R15, your call — keep it consistent).
- `PrimaryPart` set to `HumanoidRootPart`.
- A head-mounted `BillboardGui` named `TraitCard` (initially empty — User 2 fills text per round).
- Distinct outfit / accessories so the Explorer can describe them visually.

Suggested set (covers both safe and risky archetypes the judges asked for):
- Hot dog vendor with apron and hat
- Police officer / park ranger in uniform
- Parent with stroller / kid accessory
- Casual park-goer with sunglasses
- Suspicious-looking adult in trench coat / hoodie (used for risky roles)
- Person leaning out of a vehicle with sunglasses
- An NPC variant **holding a cartoon knife** (kid-friendly: blocky, clearly a prop, not gory) — this is the "guy with a knife" archetype judge Andrew explicitly called out. The knife should be a held accessory the server toggles per-round, not baked into the rig, so this NPC can also appear unarmed in other roles.

Do NOT lock specific NPCs to specific roles — User 2's scenario logic randomizes role assignments each round. The knife is an *accessory* the server attaches when the assigned role is risky-knife-archetype.

#### 6. Item Templates

Build cartoon item models in `ServerStorage/ItemTemplates`. Each is an anchored Model with `PrimaryPart`. These get cloned onto the conveyor belt.

Required items (matches `docs/GAME_DESIGN.md` "Backpack Checkpoint"):

- `FavoriteGame` — a game controller
- `FavoriteColor` — a paint palette
- `FunnyMeme` — a meme card / image
- `PetDrawing` — a kid's drawing of a pet
- `RealName` — a name tag with handwritten name
- `PersonalPhoto` — a polaroid photo
- `Birthday` — a balloon with floating date
- `BigAchievement` — a trophy
- `HomeAddress` — a glowing tiny house
- `SchoolName` — a school crest banner
- `Password` — a padlock card
- `PhoneNumber` — a phone with floating number
- `PrivateSecret` — a locked diary

Each item Model is named exactly the `ItemKey` above (e.g. `HomeAddress`).

Make them readable from a few studs away — they need to be identifiable on the conveyor belt.

#### 7. Booth Template

`ServerStorage/GuideBooths/DefaultBooth`:

- Small enclosed Model (~12×12 studs).
- `PrimaryPart` set on a reference part at the booth origin.
- `GuideSpawn` part inside. Tag: `GuideSpawn`.
- `ControlPanel` part on the front wall — a desk-height block (~6×3 studs) facing the window. Add a `SurfaceGui` on its top face — User 2 populates the manual UI here.
- `Window` part — transparent (Transparency 0.5), CanCollide false, on one wall, sized so the Guide can see the play area.
- Walls thick enough to prevent leaving by walking. No door.

Theme: cozy "lookout post" or "lighthouse cabin" — not a corporate ops center.

#### 8. Polish Pass

- Warm, inviting Lighting / skybox.
- Background music placeholder (`SoundService` child, looped, disabled — User 2 may wire it up).
- SFX placeholders in `SoundService`: `ConfirmPair`, `RoundStart`, `LevelComplete`, `WrongSort`, `CorrectSort`, `ClueCollected`, `RiskyTalk`, `RoundComplete`.
- Avoid clutter that obscures interactables.
- Cartoon font on any standalone signage.

### Coordination With User 2

- User 2 reads the same docs and assumes you produced these exact tags / attributes / model names. **Do not rename them** without updating `docs/TECHNICAL_DESIGN.md` first.
- If you discover something User 2 needs that isn't in the docs, update `docs/TECHNICAL_DESIGN.md` "Map Object Conventions" yourself, log it in `tasks/lessons.md`, and tell User 2.
- Keep `human_todo.md` checklist up to date as you finish items.

### When You Are Done

1. Verify every checkbox in the "Studio Map" section of `human_todo.md` is checked.
2. Save the Studio place.
3. Commit any doc changes.
4. Tell the team User 2 can begin scripting (or continue if they're already going).
