"""visual style bible for buddy bridge.

every generator imports from here so the lobby, both levels, npcs, items, booth,
and lobby treehouse share one cohesive cartoon look. judge andrew flagged
consistency as make-or-break — never inline a color or a font in a tool.
"""

from __future__ import annotations

from dataclasses import dataclass


# warm cartoon palette — saturated but not neon. roblox Color3.fromRGB values.
@dataclass(frozen=True)
class Palette:
    # primary world tones
    grass: tuple[int, int, int] = (133, 196, 92)
    grass_dark: tuple[int, int, int] = (98, 158, 70)
    path: tuple[int, int, int] = (208, 184, 142)
    sky_warm: tuple[int, int, int] = (250, 232, 196)

    # wood + cozy
    wood_warm: tuple[int, int, int] = (164, 116, 78)
    wood_dark: tuple[int, int, int] = (105, 72, 50)
    treehouse_leaf: tuple[int, int, int] = (110, 178, 90)

    # signage + ui
    sign_face: tuple[int, int, int] = (250, 240, 220)
    sign_ink: tuple[int, int, int] = (60, 44, 32)

    # accents
    capsule_a: tuple[int, int, int] = (255, 188, 92)
    capsule_b: tuple[int, int, int] = (132, 200, 255)
    capsule_c: tuple[int, int, int] = (220, 158, 255)
    capsule_d: tuple[int, int, int] = (180, 232, 140)

    # checkpoint bins (these are intentionally bin-ish — the visual style bible
    # tolerates these because they map to the gameplay categories)
    bin_pack_it: tuple[int, int, int] = (118, 196, 102)
    bin_ask_first: tuple[int, int, int] = (252, 208, 88)
    bin_leave_it: tuple[int, int, int] = (236, 110, 110)

    # park scene anchors
    hot_dog_red: tuple[int, int, int] = (220, 90, 78)
    fountain_stone: tuple[int, int, int] = (212, 200, 178)
    fountain_water: tuple[int, int, int] = (140, 200, 232)
    white_van_body: tuple[int, int, int] = (240, 240, 232)
    alley_brick: tuple[int, int, int] = (146, 100, 84)
    ranger_green: tuple[int, int, int] = (78, 132, 88)
    bench_wood: tuple[int, int, int] = (150, 100, 70)
    playground_blue: tuple[int, int, int] = (108, 168, 232)

    # booth
    booth_wall: tuple[int, int, int] = (236, 218, 180)
    booth_trim: tuple[int, int, int] = (180, 130, 90)
    booth_window: tuple[int, int, int] = (200, 230, 250)

    # explorer marker / sparkle accents (used sparingly)
    sparkle: tuple[int, int, int] = (255, 240, 168)

    # neutral utility tones — used sparingly across many emitters; centralized
    # here so a future repaint touches one file.
    skin_warm: tuple[int, int, int] = (255, 220, 184)
    skin_neutral: tuple[int, int, int] = (240, 210, 178)
    near_black: tuple[int, int, int] = (60, 60, 64)
    soft_steel: tuple[int, int, int] = (180, 180, 192)
    pale_steel: tuple[int, int, int] = (220, 220, 230)
    paper_white: tuple[int, int, int] = (252, 252, 248)
    ink_dot: tuple[int, int, int] = (40, 40, 48)
    blush: tuple[int, int, int] = (140, 70, 70)

    # food / prop colors used by the hot dog scene
    bun: tuple[int, int, int] = (232, 196, 132)
    sausage: tuple[int, int, int] = (196, 96, 70)

    # warm gold for trophies, padlocks, brass accents
    gold: tuple[int, int, int] = (252, 208, 88)

    # cartoon park aesthetic — matches the reference style guide:
    # warm sandy ground, layered stylized trees, cottage huts with red roofs,
    # polygonal stone path wedges. these tones replace the green grass field
    # for the lobby + park while staying inside the saturated cartoon range.
    sand_warm: tuple[int, int, int] = (218, 158, 86)
    sand_dark: tuple[int, int, int] = (188, 124, 64)
    cottage_wall: tuple[int, int, int] = (188, 132, 88)
    cottage_trim: tuple[int, int, int] = (132, 84, 56)
    cottage_door: tuple[int, int, int] = (96, 60, 44)
    cottage_window: tuple[int, int, int] = (220, 232, 248)
    roof_red: tuple[int, int, int] = (172, 64, 56)
    roof_red_dark: tuple[int, int, int] = (132, 44, 40)
    stone_path: tuple[int, int, int] = (208, 200, 184)
    stone_path_dark: tuple[int, int, int] = (172, 164, 148)
    tree_top_dark: tuple[int, int, int] = (52, 96, 60)
    tree_top_mid: tuple[int, int, int] = (78, 132, 78)
    tree_top_light: tuple[int, int, int] = (118, 168, 96)

    # street + intersection palette for the new stranger-danger level. roads
    # are dark concrete-grey with white crosswalk and yellow centerline paint;
    # sidewalks are pale concrete with darker curb edges.
    asphalt: tuple[int, int, int] = (62, 62, 66)
    asphalt_dark: tuple[int, int, int] = (44, 44, 48)
    crosswalk_paint: tuple[int, int, int] = (244, 244, 240)
    road_yellow: tuple[int, int, int] = (240, 196, 64)
    sidewalk: tuple[int, int, int] = (210, 206, 196)
    curb: tuple[int, int, int] = (152, 148, 140)


PALETTE = Palette()


# materials live in a tight allowed-set. anything else gets rejected by
# verify_style. use names exactly as they appear in roblox's enum.material.
ALLOWED_MATERIALS = frozenset(
    {
        "SmoothPlastic",
        "Plastic",
        "Wood",
        "WoodPlanks",
        "Grass",
        "Sand",
        "Concrete",
        "Cobblestone",
    }
)

DEFAULT_MATERIAL = "SmoothPlastic"
GRASS_MATERIAL = "Grass"
PATH_MATERIAL = "Sand"
WOOD_MATERIAL = "Wood"

# canonical "ground" material for the cartoon park aesthetic. lobbies and
# stranger-danger areas paint with this so the floor reads as warm sand.
GROUND_MATERIAL = "Sand"


# the shared font for every billboard, sign, surface gui
FONT = "Cartoon"


# proportions — chunky cartoon. surfaces tend to be in multiples of 2 studs.
@dataclass(frozen=True)
class Proportions:
    base_unit: int = 2  # round dimensions to multiples of 2 where possible
    sign_text_size: int = 36
    billboard_text_size: int = 28
    bin_label_text_size: int = 32
    surface_padding: int = 4
    capsule_pad_radius: int = 3  # 6-stud diameter
    capsule_pad_thickness: int = 1
    pad_pair_spacing: int = 6
    arena_slot_separation: int = 500
    arena_slot_floor_y: int = -500


PROPORTIONS = Proportions()


# canonical tags — single source of truth so a typo in one tool can't drift
# from the rest of the stack. names match docs/TECHNICAL_DESIGN.md
# "Map Object Conventions".
class Tags:
    LOBBY_CAPSULE = "LobbyCapsule"
    LOBBY_CAPSULE_PAIR = "LobbyCapsulePair"
    PLAY_ARENA_SLOT = "PlayArenaSlot"
    EXPLORER_SPAWN = "ExplorerSpawn"
    GUIDE_SPAWN = "GuideSpawn"
    BOOTH_ANCHOR = "BoothAnchor"
    LEVEL_ENTRY = "LevelEntry"
    LEVEL_EXIT = "LevelExit"
    BUDDY_NPC_SPAWN = "BuddyNpcSpawn"
    PUPPY_SPAWN = "PuppySpawn"
    BUDDY_PORTAL = "BuddyPortal"
    BELT_START = "BeltStart"
    BELT_END = "BeltEnd"
    BUDDY_BIN = "BuddyBin"
    BUDDY_CONVEYOR = "BuddyConveyor"
    ROUND_FINISH_ZONE = "RoundFinishZone"
    # tags walking NPCs that should patrol their assigned path
    NPC_PATROL = "BuddyNpcPatrol"
    NPC_PATROL_NODE = "BuddyPatrolNode"


# canonical attributes — same single-source-of-truth principle.
class Attributes:
    LEVEL_TYPE = "LevelType"
    CAPSULE_ID = "CapsuleId"
    CAPSULE_PAIR_ID = "CapsulePairId"
    SLOT_INDEX = "SlotIndex"
    NPC_SPAWN_ID = "NpcSpawnId"
    ANCHOR = "Anchor"
    LANE_ID = "LaneId"
    BELT_START = "BeltStart"
    BELT_END = "BeltEnd"
    # patrol waypoint folder containing PATROL_NODE parts in walking order
    PATROL_PATH = "PatrolPath"
    PATROL_HOME = "PatrolHome"


def color3(rgb: tuple[int, int, int]) -> str:
    """emit `Color3.fromRGB(r, g, b)` for inlining into lua."""
    r, g, b = rgb
    return f"Color3.fromRGB({r}, {g}, {b})"


def material(name: str) -> str:
    """validate + emit `Enum.Material.<name>` for inlining."""
    if name not in ALLOWED_MATERIALS:
        raise ValueError(
            f"material {name!r} not in style bible; allowed: {sorted(ALLOWED_MATERIALS)}"
        )
    return f"Enum.Material.{name}"


def font() -> str:
    return f"Enum.Font.{FONT}"
