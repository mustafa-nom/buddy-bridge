"""buddy-map-generator MCP server.

exposes high-level tools that emit Lua and forward it through a roblox-studio
backend (boshyxd robloxstudio-mcp by default; rbx-studio-mcp via
BUDDY_STUDIO_BACKEND=rbx-studio). the studio plugin must be running for
tools that touch Studio. set BUDDY_MAP_DRY_RUN=1 to return the emitted Lua
instead of contacting Studio. set BUDDY_MAP_DRY_RUN=1 + dump_preliminary_map
to write a single combined Lua program to disk for command-bar paste.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from typing import Any

from mcp.server.fastmcp import FastMCP

from .studio_client import StudioClient
from .tools.backpack_checkpoint import emit_backpack_checkpoint_lua
from .tools.booth_template import emit_booth_template_lua
from .tools.item_templates import emit_item_templates_lua
from .tools.lobby import emit_lobby_lua
from .tools.npc_templates import emit_npc_templates_lua
from .tools.play_arena_slots import emit_play_arena_slots_lua
from .tools.polish_pass import emit_polish_pass_lua
from .tools.stranger_danger_park import emit_stranger_danger_park_lua
from .tools.verify import emit_verify_style_lua


# environment switches:
# - BUDDY_MAP_DRY_RUN=1 → tools return Lua instead of contacting Studio.
# - RBX_STUDIO_MCP_BIN=/path → override binary location.
def _dry_run() -> bool:
    return os.environ.get("BUDDY_MAP_DRY_RUN", "").lower() in {"1", "true", "yes"}


@dataclass
class ServerState:
    client: StudioClient = field(default_factory=StudioClient)


_state = ServerState()


def _run_or_return(lua: str, *, label: str) -> dict[str, Any]:
    """either ship lua to studio and surface results, or echo it for dry runs."""
    if _dry_run():
        return {
            "mode": "dry_run",
            "label": label,
            "lua_chars": len(lua),
            "lua": lua,
        }
    output = _state.client.run_code(lua)
    parsed: Any
    try:
        parsed = json.loads(output)
    except (json.JSONDecodeError, ValueError):
        parsed = {"raw": output}
    return {
        "mode": "studio",
        "label": label,
        "result": parsed,
    }


mcp = FastMCP(
    "buddy-map-generator",
    instructions=(
        "build a preliminary buddy bridge studio map. invoke build_preliminary_map "
        "to scaffold everything in order, or call individual builders. set "
        "BUDDY_MAP_DRY_RUN=1 to inspect the emitted lua without touching studio."
    ),
)


@mcp.tool()
def build_lobby(pair_count: int = 4) -> dict[str, Any]:
    """build the shared lobby hub: spawn, welcome sign, treehouse, capsule pads.

    pair_count must be 1..8. default 4 matches the spec.
    """
    lua = emit_lobby_lua(pair_count=pair_count)
    return _run_or_return(lua, label="build_lobby")


@mcp.tool()
def build_play_arena_slots(slot_count: int = 4) -> dict[str, Any]:
    """build N play arena slots in a hidden region of Workspace.

    slot_count must be 1..8. default 4.
    """
    lua = emit_play_arena_slots_lua(slot_count=slot_count)
    return _run_or_return(lua, label="build_play_arena_slots")


@mcp.tool()
def build_stranger_danger_park() -> dict[str, Any]:
    """build the StrangerDangerPark level template under ServerStorage/Levels."""
    lua = emit_stranger_danger_park_lua()
    return _run_or_return(lua, label="build_stranger_danger_park")


@mcp.tool()
def build_backpack_checkpoint() -> dict[str, Any]:
    """build the BackpackCheckpoint level template under ServerStorage/Levels."""
    lua = emit_backpack_checkpoint_lua()
    return _run_or_return(lua, label="build_backpack_checkpoint")


@mcp.tool()
def build_npc_templates() -> dict[str, Any]:
    """build the 7 NPC rig templates under ServerStorage/NpcTemplates."""
    lua = emit_npc_templates_lua()
    return _run_or_return(lua, label="build_npc_templates")


@mcp.tool()
def build_item_templates() -> dict[str, Any]:
    """build the 13 item templates under ServerStorage/ItemTemplates."""
    lua = emit_item_templates_lua()
    return _run_or_return(lua, label="build_item_templates")


@mcp.tool()
def build_booth_template() -> dict[str, Any]:
    """build the DefaultBooth template under ServerStorage/GuideBooths."""
    lua = emit_booth_template_lua()
    return _run_or_return(lua, label="build_booth_template")


@mcp.tool()
def build_polish_pass() -> dict[str, Any]:
    """apply lighting/atmosphere defaults and create SFX placeholders."""
    lua = emit_polish_pass_lua()
    return _run_or_return(lua, label="build_polish_pass")


@mcp.tool()
def verify_style() -> dict[str, Any]:
    """walk the map and report material / font / required-tag violations."""
    lua = emit_verify_style_lua()
    return _run_or_return(lua, label="verify_style")


# preview tools — clone server-storage templates into workspace temporarily
# so user 1 can visually verify a build step without leaving studio. each
# preview replaces any prior _Preview folder, so calling preview_park then
# preview_checkpoint won't pile up.

_PREVIEW_HEADER = (
    "local Workspace = game:GetService(\"Workspace\")\n"
    "local ServerStorage = game:GetService(\"ServerStorage\")\n"
    "local preview = Workspace:FindFirstChild(\"_Preview\")\n"
    "if preview then preview:Destroy() end\n"
    "preview = Instance.new(\"Folder\")\n"
    "preview.Name = \"_Preview\"\n"
    "preview.Parent = Workspace\n"
)


def _preview_lua(body: str) -> str:
    return _PREVIEW_HEADER + body


@mcp.tool()
def preview_booth() -> dict[str, Any]:
    """clone the booth template into workspace at (0, 0, 100) and aim camera."""
    lua = _preview_lua(
        "local b = ServerStorage.GuideBooths.DefaultBooth:Clone()\n"
        "b:PivotTo(CFrame.new(0, 0, 100))\n"
        "b.Parent = preview\n"
        "Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable\n"
        "Workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(20, 12, 90), Vector3.new(0, 4, 100))\n"
        "return \"booth previewed\"\n"
    )
    return _run_or_return(lua, label="preview_booth")


@mcp.tool()
def preview_park() -> dict[str, Any]:
    """clone the StrangerDangerPark level into workspace at (0, 0, 200)."""
    lua = _preview_lua(
        "local lvl = ServerStorage.Levels.StrangerDangerPark:Clone()\n"
        "lvl:PivotTo(CFrame.new(0, 0, 200))\n"
        "lvl.Parent = preview\n"
        "Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable\n"
        "Workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(80, 60, 130), Vector3.new(0, 4, 200))\n"
        "return \"park previewed\"\n"
    )
    return _run_or_return(lua, label="preview_park")


@mcp.tool()
def preview_checkpoint() -> dict[str, Any]:
    """clone the BackpackCheckpoint level into workspace at (0, 0, 300)."""
    lua = _preview_lua(
        "local lvl = ServerStorage.Levels.BackpackCheckpoint:Clone()\n"
        "lvl:PivotTo(CFrame.new(0, 0, 300))\n"
        "lvl.Parent = preview\n"
        "Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable\n"
        "Workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 16, 280), Vector3.new(0, 4, 305))\n"
        "return \"checkpoint previewed\"\n"
    )
    return _run_or_return(lua, label="preview_checkpoint")


@mcp.tool()
def preview_npc_lineup() -> dict[str, Any]:
    """clone every NpcTemplate side-by-side on a grass strip near (0, 0, 400)."""
    lua = _preview_lua(
        "local floor = Instance.new(\"Part\")\n"
        "floor.Size = Vector3.new(80, 1, 16)\n"
        "floor.CFrame = CFrame.new(0, -0.5, 400)\n"
        "floor.Anchored = true\n"
        "floor.Color = Color3.fromRGB(133, 196, 92)\n"
        "floor.Material = Enum.Material.Grass\n"
        "floor.Parent = preview\n"
        "local i = 0\n"
        "for _, tpl in ipairs(ServerStorage.NpcTemplates:GetChildren()) do\n"
        "  local clone = tpl:Clone()\n"
        "  clone:PivotTo(CFrame.new(-30 + i * 10, 1.5, 400) * CFrame.Angles(0, math.rad(180), 0))\n"
        "  clone.Parent = preview\n"
        "  i = i + 1\n"
        "end\n"
        "Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable\n"
        "Workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 8, 380), Vector3.new(0, 3, 400))\n"
        "return (\"placed \" .. i .. \" npcs\")\n"
    )
    return _run_or_return(lua, label="preview_npc_lineup")


@mcp.tool()
def preview_item_lineup() -> dict[str, Any]:
    """clone every ItemTemplate side-by-side on a concrete pad at (0, 0, 500)."""
    lua = _preview_lua(
        "local floor = Instance.new(\"Part\")\n"
        "floor.Size = Vector3.new(72, 1, 12)\n"
        "floor.CFrame = CFrame.new(0, -0.5, 500)\n"
        "floor.Anchored = true\n"
        "floor.Color = Color3.fromRGB(212, 200, 178)\n"
        "floor.Material = Enum.Material.Concrete\n"
        "floor.Parent = preview\n"
        "local i = 0\n"
        "for _, tpl in ipairs(ServerStorage.ItemTemplates:GetChildren()) do\n"
        "  local clone = tpl:Clone()\n"
        "  clone:PivotTo(CFrame.new(-30 + i * 5, 1, 500))\n"
        "  clone.Parent = preview\n"
        "  i = i + 1\n"
        "end\n"
        "Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable\n"
        "Workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 18, 484), Vector3.new(0, 1.5, 500))\n"
        "return (\"placed \" .. i .. \" items\")\n"
    )
    return _run_or_return(lua, label="preview_item_lineup")


@mcp.tool()
def clear_preview() -> dict[str, Any]:
    """remove the temporary _Preview folder from workspace."""
    lua = (
        "local preview = workspace:FindFirstChild(\"_Preview\")\n"
        "if preview then preview:Destroy() end\n"
        "return \"preview cleaned\"\n"
    )
    return _run_or_return(lua, label="clear_preview")


@mcp.tool()
def screenshot() -> dict[str, Any]:
    """capture a screenshot of the studio window. dry_run echoes a stub."""
    if _dry_run():
        return {"mode": "dry_run", "label": "screenshot", "note": "would call capture_screenshot"}
    return {"mode": "studio", "label": "screenshot", "result": _state.client.capture_screenshot()}


def _compose_preliminary_steps(
    *, pair_count: int = 4, slot_count: int = 4
) -> list[tuple[str, str]]:
    """return [(label, lua), ...] for the full preliminary build, in order.

    pure: doesn't touch Studio, doesn't depend on mcp. usable by tests and
    by the dump_preliminary_map tool.
    """
    return [
        ("build_lobby", emit_lobby_lua(pair_count=pair_count)),
        ("build_play_arena_slots", emit_play_arena_slots_lua(slot_count=slot_count)),
        ("build_booth_template", emit_booth_template_lua()),
        ("build_stranger_danger_park", emit_stranger_danger_park_lua()),
        ("build_backpack_checkpoint", emit_backpack_checkpoint_lua()),
        ("build_npc_templates", emit_npc_templates_lua()),
        ("build_item_templates", emit_item_templates_lua()),
        ("build_polish_pass", emit_polish_pass_lua()),
        ("verify_style", emit_verify_style_lua()),
    ]


def _default_dump_path() -> str:
    """resolve the dump path relative to the map-generator package root.

    package layout: <repo>/tools/map-generator/src/buddy_map_generator/...
    we want: <repo>/tools/map-generator/out/preliminary_map.lua
    """
    here = os.path.dirname(os.path.abspath(__file__))  # .../buddy_map_generator
    pkg_root = os.path.normpath(os.path.join(here, "..", ".."))  # .../map-generator
    return os.path.join(pkg_root, "out", "preliminary_map.lua")


@mcp.tool()
def dump_preliminary_map(
    pair_count: int = 4,
    slot_count: int = 4,
    output_path: str = "",
) -> dict[str, Any]:
    """write a single concatenated lua program for command-bar paste.

    each section gets a `-- ===== <step> =====` header so you can see where
    one ends and the next begins. paste the whole file into studio's command
    bar (or `loadstring(file)()` from a plugin) and the entire map
    materializes.

    if output_path is empty, defaults to map-generator/out/preliminary_map.lua
    relative to the package root (cwd-independent).
    """
    steps = _compose_preliminary_steps(pair_count=pair_count, slot_count=slot_count)
    parts: list[str] = []
    for label, lua in steps:
        parts.append(f"-- ===== {label} =====\n{lua}\n")
    program = "\n".join(parts)

    abs_path = os.path.abspath(output_path) if output_path else _default_dump_path()
    os.makedirs(os.path.dirname(abs_path), exist_ok=True)
    with open(abs_path, "w") as f:
        f.write(program)

    return {
        "mode": "dump",
        "path": abs_path,
        "step_count": len(steps),
        "char_count": len(program),
    }


@mcp.tool()
def build_preliminary_map(
    pair_count: int = 4,
    slot_count: int = 4,
    capture_screenshots: bool = True,
) -> dict[str, Any]:
    """run every build_* step in order. screenshots after each one if enabled.

    intended as a one-shot kickoff: opens with lobby, then arenas, then the
    two level templates, npcs, items, booth, polish, and finally style verify.
    """
    steps: list[tuple[str, Any]] = []

    def _step(label: str, runner) -> None:
        result = runner()
        steps.append((label, result))
        if capture_screenshots and not _dry_run():
            try:
                shot = _state.client.capture_screenshot()
                steps.append((f"{label}.screenshot", shot))
            except Exception as exc:
                steps.append((f"{label}.screenshot.error", {"error": str(exc)}))

    _step("build_lobby", lambda: build_lobby(pair_count=pair_count))
    _step("build_play_arena_slots", lambda: build_play_arena_slots(slot_count=slot_count))
    _step("build_booth_template", build_booth_template)
    _step("build_stranger_danger_park", build_stranger_danger_park)
    _step("build_backpack_checkpoint", build_backpack_checkpoint)
    _step("build_npc_templates", build_npc_templates)
    _step("build_item_templates", build_item_templates)
    _step("build_polish_pass", build_polish_pass)
    _step("verify_style", verify_style)

    return {"steps": steps, "mode": "dry_run" if _dry_run() else "studio"}


def main() -> None:
    """entrypoint used by the project script."""
    mcp.run()


if __name__ == "__main__":
    main()
