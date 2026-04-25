"""smoke tests for every emitter.

these don't run lua, they just check that the emitted text contains the
canonical tag/attribute/key strings that docs/TECHNICAL_DESIGN.md and
prompts/user1_map_prompt.md treat as the contract with User 2.

run with: cd tools/map-generator && python3 -m unittest discover tests
"""

from __future__ import annotations

import os
import sys
import unittest

# make src importable when running from repo root
_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "..", "src"))

from buddy_map_generator.tools.backpack_checkpoint import emit_backpack_checkpoint_lua  # noqa: E402
from buddy_map_generator.tools.booth_template import emit_booth_template_lua  # noqa: E402
from buddy_map_generator.tools.item_templates import emit_item_templates_lua  # noqa: E402
from buddy_map_generator.tools.lobby import emit_lobby_lua  # noqa: E402
from buddy_map_generator.tools.npc_templates import emit_npc_templates_lua  # noqa: E402
from buddy_map_generator.tools.play_arena_slots import emit_play_arena_slots_lua  # noqa: E402
from buddy_map_generator.tools.polish_pass import emit_polish_pass_lua  # noqa: E402
from buddy_map_generator.tools.stranger_danger_park import emit_stranger_danger_park_lua  # noqa: E402
from buddy_map_generator.tools.verify import emit_verify_style_lua  # noqa: E402


# canonical strings the spec promises to user 2. these are intentionally
# duplicated here (not imported from style.Tags) so a refactor that drops
# a tag breaks the test before it breaks the user 2 integration.
ITEM_KEYS = {
    "FavoriteGame",
    "FavoriteColor",
    "FunnyMeme",
    "PetDrawing",
    "RealName",
    "PersonalPhoto",
    "Birthday",
    "BigAchievement",
    "HomeAddress",
    "SchoolName",
    "Password",
    "PhoneNumber",
    "PrivateSecret",
}

PARK_SCENE_ANCHORS = {
    "HotdogShop",
    "GeneralStore",
    "WhiteVan",
    "AlleyMouth",
    "NorthSidewalk",
    "SouthSidewalk",
    "EastSidewalk",
    "WestSidewalk",
}

LANE_IDS = {"PackIt", "AskFirst", "LeaveIt"}

SFX_PLACEHOLDERS = {
    "ConfirmPair",
    "RoundStart",
    "LevelComplete",
    "WrongSort",
    "CorrectSort",
    "ClueCollected",
    "RiskyTalk",
    "RoundComplete",
}


def _contains_all(haystack: str, needles: set[str]) -> set[str]:
    """return any needles missing from haystack."""
    return {n for n in needles if n not in haystack}


class EmitterSmokeTest(unittest.TestCase):
    """every emitter must produce non-empty lua."""

    def test_lobby_nonempty(self) -> None:
        self.assertGreater(len(emit_lobby_lua()), 1000)

    def test_play_arena_slots_nonempty(self) -> None:
        self.assertGreater(len(emit_play_arena_slots_lua()), 500)

    def test_stranger_danger_park_nonempty(self) -> None:
        self.assertGreater(len(emit_stranger_danger_park_lua()), 5000)

    def test_backpack_checkpoint_nonempty(self) -> None:
        self.assertGreater(len(emit_backpack_checkpoint_lua()), 2000)

    def test_npc_templates_nonempty(self) -> None:
        self.assertGreater(len(emit_npc_templates_lua()), 5000)

    def test_item_templates_nonempty(self) -> None:
        self.assertGreater(len(emit_item_templates_lua()), 5000)

    def test_booth_template_nonempty(self) -> None:
        self.assertGreater(len(emit_booth_template_lua()), 1000)

    def test_polish_pass_nonempty(self) -> None:
        self.assertGreater(len(emit_polish_pass_lua()), 500)

    def test_verify_style_nonempty(self) -> None:
        self.assertGreater(len(emit_verify_style_lua()), 500)


class LobbyContractTest(unittest.TestCase):
    """lobby must place the lobby capsule tag + attributes user 2 reads."""

    def setUp(self) -> None:
        self.lua = emit_lobby_lua(pair_count=4)

    def test_lobby_capsule_tag_present(self) -> None:
        self.assertIn("LobbyCapsule", self.lua)

    def test_capsule_id_attribute_present(self) -> None:
        self.assertIn("CapsuleId", self.lua)

    def test_capsule_pair_id_attribute_present(self) -> None:
        self.assertIn("CapsulePairId", self.lua)

    def test_eight_pads_for_four_pairs(self) -> None:
        # 4 pairs × 2 pads per pair = 8 pad creations
        self.assertEqual(self.lua.count("CapsulePad_"), 8 * 2)  # name + label var
        # but always at least 8 distinct pad-name string literals
        for pair in range(1, 5):
            for side in ("A", "B"):
                self.assertIn(f"CapsulePad_{pair}{side}", self.lua)

    def test_spawn_location_present(self) -> None:
        self.assertIn("SpawnLocation", self.lua)

    def test_treehouse_present(self) -> None:
        self.assertIn("Treehouse", self.lua)


class PlayArenaSlotsContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.lua = emit_play_arena_slots_lua(slot_count=4)

    def test_play_arena_slot_tag_present(self) -> None:
        self.assertIn("PlayArenaSlot", self.lua)

    def test_explorer_spawn_tag_present(self) -> None:
        self.assertIn("ExplorerSpawn", self.lua)

    def test_booth_anchor_tag_present(self) -> None:
        self.assertIn("BoothAnchor", self.lua)

    def test_slot_index_attribute_present(self) -> None:
        self.assertIn("SlotIndex", self.lua)

    def test_play_area_folder_present(self) -> None:
        self.assertIn("PlayArea", self.lua)

    def test_booth_folder_present(self) -> None:
        self.assertIn('"Booth"', self.lua)

    def test_four_slots_named(self) -> None:
        for n in (1, 2, 3, 4):
            self.assertIn(f"Slot{n}", self.lua)


class StrangerDangerParkContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.lua = emit_stranger_danger_park_lua()

    def test_level_type_attribute(self) -> None:
        self.assertIn("StrangerDangerPark", self.lua)
        self.assertIn("LevelType", self.lua)

    def test_buddy_npc_spawn_tag(self) -> None:
        self.assertIn("BuddyNpcSpawn", self.lua)

    def test_puppy_spawn_tag(self) -> None:
        self.assertIn("PuppySpawn", self.lua)

    def test_buddy_portal_tag(self) -> None:
        self.assertIn("BuddyPortal", self.lua)

    def test_level_entry_and_exit_tags(self) -> None:
        self.assertIn("LevelEntry", self.lua)
        self.assertIn("LevelExit", self.lua)

    def test_all_scene_anchors_present(self) -> None:
        missing = _contains_all(self.lua, PARK_SCENE_ANCHORS)
        self.assertSetEqual(missing, set(), f"missing anchors: {missing}")

    def test_npc_spawn_id_attribute(self) -> None:
        self.assertIn("NpcSpawnId", self.lua)

    def test_anchor_attribute(self) -> None:
        self.assertIn('"Anchor"', self.lua)

    def test_intersection_streets_present(self) -> None:
        # the new aesthetic builds an asphalt + crosswalk intersection
        self.assertIn("RoadNS", self.lua)
        self.assertIn("RoadEW", self.lua)
        self.assertIn("Crosswalk", self.lua)
        self.assertIn("Sidewalk", self.lua)

    def test_patrol_paths_folder(self) -> None:
        # walking npcs need a patrol path waypoint folder per spawn anchor
        self.assertIn("PatrolPaths", self.lua)
        self.assertIn("BuddyPatrolNode", self.lua)


class BackpackCheckpointContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.lua = emit_backpack_checkpoint_lua()

    def test_level_type_attribute(self) -> None:
        self.assertIn("BackpackCheckpoint", self.lua)
        self.assertIn("LevelType", self.lua)

    def test_belt_start_and_end_tags(self) -> None:
        self.assertIn("BeltStart", self.lua)
        self.assertIn("BeltEnd", self.lua)

    def test_buddy_bin_tag(self) -> None:
        self.assertIn("BuddyBin", self.lua)

    def test_buddy_conveyor_tag(self) -> None:
        self.assertIn("BuddyConveyor", self.lua)

    def test_lane_id_attribute(self) -> None:
        self.assertIn("LaneId", self.lua)

    def test_all_lane_ids_present(self) -> None:
        missing = _contains_all(self.lua, LANE_IDS)
        self.assertSetEqual(missing, set(), f"missing lanes: {missing}")

    def test_round_finish_zone_tag(self) -> None:
        self.assertIn("RoundFinishZone", self.lua)


class ItemTemplatesContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.lua = emit_item_templates_lua()

    def test_all_thirteen_item_keys_present(self) -> None:
        missing = _contains_all(self.lua, ITEM_KEYS)
        self.assertSetEqual(missing, set(), f"missing item keys: {missing}")

    def test_each_item_in_its_own_model(self) -> None:
        # every item should produce one Model creation step
        # (at least 13 — one per ItemKey)
        self.assertGreaterEqual(self.lua.count('Instance.new("Model")'), 13)


class NpcTemplatesContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.lua = emit_npc_templates_lua()

    def test_seven_npc_models_minimum(self) -> None:
        # spec says "at least 6"; we ship 7
        for name in (
            "HotDogVendor",
            "Ranger",
            "ParentWithKid",
            "CasualParkGoer",
            "HoodedAdult",
            "VehicleLeaner",
            "KnifeArchetype",
        ):
            self.assertIn(name, self.lua)

    def test_trait_card_billboard_per_npc(self) -> None:
        # the user 2 contract: every npc has a TraitCard billboard the server fills
        self.assertGreaterEqual(self.lua.count("TraitCard"), 7)

    def test_humanoid_root_part_per_npc(self) -> None:
        self.assertGreaterEqual(self.lua.count("HumanoidRootPart"), 7)

    def test_r6_rig_type(self) -> None:
        # the npc rigs must be R6 so default character anatomy + Motor6Ds work
        self.assertIn("Enum.HumanoidRigType.R6", self.lua)

    def test_face_decal_per_npc(self) -> None:
        # every npc has a face decal placeholder so user 2 can swap visually
        self.assertGreaterEqual(self.lua.count('Instance.new("Decal")'), 7)

    def test_shirt_and_pants_slots(self) -> None:
        self.assertIn("ShirtTemplate", self.lua)
        self.assertIn("PantsTemplate", self.lua)

    def test_patrol_script_embedded(self) -> None:
        # each rig embeds a PatrolScript that drives the rig via humanoid:MoveTo
        self.assertIn("PatrolScript", self.lua)
        self.assertIn("humanoid:MoveTo", self.lua)
        self.assertIn("MoveToFinished", self.lua)


class BoothTemplateContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.lua = emit_booth_template_lua()

    def test_default_booth_name(self) -> None:
        self.assertIn("DefaultBooth", self.lua)

    def test_guide_spawn_tag(self) -> None:
        self.assertIn("GuideSpawn", self.lua)

    def test_control_panel_present(self) -> None:
        self.assertIn("ControlPanel", self.lua)

    def test_window_present(self) -> None:
        self.assertIn('"Window"', self.lua)

    def test_surface_gui_for_manual_ui(self) -> None:
        self.assertIn("SurfaceGui", self.lua)


class PolishPassContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.lua = emit_polish_pass_lua()

    def test_lighting_configured(self) -> None:
        self.assertIn("Lighting.ClockTime", self.lua)
        self.assertIn("Lighting.Brightness", self.lua)

    def test_atmosphere_present(self) -> None:
        self.assertIn("Atmosphere", self.lua)

    def test_all_sfx_placeholders_present(self) -> None:
        missing = _contains_all(self.lua, SFX_PLACEHOLDERS)
        self.assertSetEqual(missing, set(), f"missing sfx: {missing}")


class StyleConsistencyTest(unittest.TestCase):
    """no emitter may use a forbidden material or non-cartoon font."""

    FORBIDDEN_MATERIALS = (
        "Enum.Material.Metal",
        "Enum.Material.Glass",
        "Enum.Material.ForceField",
        "Enum.Material.Neon",
        "Enum.Material.DiamondPlate",
        "Enum.Material.Slate",
    )

    EMITTERS = (
        ("lobby", emit_lobby_lua),
        ("play_arena_slots", emit_play_arena_slots_lua),
        ("stranger_danger_park", emit_stranger_danger_park_lua),
        ("backpack_checkpoint", emit_backpack_checkpoint_lua),
        ("npc_templates", emit_npc_templates_lua),
        ("item_templates", emit_item_templates_lua),
        ("booth_template", emit_booth_template_lua),
        ("polish_pass", emit_polish_pass_lua),
    )

    def test_no_forbidden_materials(self) -> None:
        for name, fn in self.EMITTERS:
            lua = fn()
            for forbidden in self.FORBIDDEN_MATERIALS:
                with self.subTest(emitter=name, material=forbidden):
                    self.assertNotIn(forbidden, lua)

    def test_no_non_cartoon_fonts(self) -> None:
        # if any TextLabel / TextButton / TextBox is built, its Font must be
        # Enum.Font.Cartoon. emit a cheap heuristic: every "Font = " assignment
        # must read "Enum.Font.Cartoon".
        for name, fn in self.EMITTERS:
            lua = fn()
            for line in lua.splitlines():
                if ".Font = " in line and "Enum.Font" in line:
                    with self.subTest(emitter=name, line=line.strip()):
                        self.assertIn("Enum.Font.Cartoon", line)


class OrchestratorTest(unittest.TestCase):
    """compose_preliminary_steps must yield exactly the 9 expected sections."""

    def test_nine_steps_in_order(self) -> None:
        # importing server.py requires the mcp package; skip if absent so the
        # contract tests still run on minimal environments (e.g. cloud routine).
        try:
            from buddy_map_generator.server import _compose_preliminary_steps
        except ImportError:
            self.skipTest("mcp package not installed; skipping orchestrator test")

        steps = _compose_preliminary_steps(pair_count=4, slot_count=4)
        labels = [label for label, _ in steps]
        self.assertEqual(
            labels,
            [
                "build_lobby",
                "build_play_arena_slots",
                "build_booth_template",
                "build_stranger_danger_park",
                "build_backpack_checkpoint",
                "build_npc_templates",
                "build_item_templates",
                "build_polish_pass",
                "verify_style",
            ],
        )
        for label, lua in steps:
            with self.subTest(step=label):
                self.assertGreater(len(lua), 100, f"{label} emitted nothing")


class DumpPreliminaryMapTest(unittest.TestCase):
    """dump_preliminary_map must write a labelled lua program with all 9 sections."""

    def test_dump_writes_expected_sections(self) -> None:
        try:
            from buddy_map_generator.server import dump_preliminary_map
        except ImportError:
            self.skipTest("mcp package not installed; skipping dump test")

        import tempfile

        with tempfile.NamedTemporaryFile(suffix=".lua", delete=False) as tf:
            path = tf.name

        try:
            result = dump_preliminary_map(output_path=path)
            self.assertEqual(result["mode"], "dump")
            self.assertEqual(result["step_count"], 9)
            with open(path) as f:
                content = f.read()
            for label in [
                "build_lobby",
                "build_play_arena_slots",
                "build_booth_template",
                "build_stranger_danger_park",
                "build_backpack_checkpoint",
                "build_npc_templates",
                "build_item_templates",
                "build_polish_pass",
                "verify_style",
            ]:
                self.assertIn(f"-- ===== {label} =====", content)
        finally:
            import os as _os

            if _os.path.exists(path):
                _os.unlink(path)


if __name__ == "__main__":
    unittest.main()
