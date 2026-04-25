"""verify_style: introspect the studio map and report style-bible violations.

emits a small lua program that walks Workspace + ServerStorage and checks:
- materials inside the allowed set
- font usage on textlabels
- presence of required tags + attributes

returns a structured report (json string) that the MCP tool surfaces.
"""

from __future__ import annotations

from ..lua_emit import LuaProgram, lua_string
from ..style import ALLOWED_MATERIALS, FONT, Tags


_REQUIRED_TAG_PRESENCE = [
    Tags.LOBBY_CAPSULE,
    Tags.PLAY_ARENA_SLOT,
    Tags.EXPLORER_SPAWN,
    Tags.BOOTH_ANCHOR,
    Tags.LEVEL_ENTRY,
    Tags.LEVEL_EXIT,
    Tags.BUDDY_NPC_SPAWN,
    Tags.PUPPY_SPAWN,
    Tags.BUDDY_PORTAL,
    Tags.BUDDY_BIN,
    Tags.BELT_START,
    Tags.BELT_END,
    Tags.GUIDE_SPAWN,
    Tags.ROUND_FINISH_ZONE,
]


def emit_verify_style_lua() -> str:
    p = LuaProgram()
    p.comment("buddy bridge style + tag verification")

    allowed_lua_list = "{ " + ", ".join(lua_string(m) for m in sorted(ALLOWED_MATERIALS)) + " }"

    p.line(f"local allowed_materials_list = {allowed_lua_list}")
    p.line(
        "local allowed_materials = {}\n"
        "for _, m in ipairs(allowed_materials_list) do allowed_materials[m] = true end"
    )
    p.line(f"local expected_font = {lua_string(FONT)}")

    p.line(
        "local violations = { material = {}, font = {} }"
    )

    p.line(
        "local function is_under_buddy_root(inst)\n"
        "  while inst do\n"
        "    if inst == Workspace.Lobby then return true end\n"
        "    if inst.Name == \"PlayArenaSlots\" and inst.Parent == Workspace then return true end\n"
        "    if inst == ServerStorage:FindFirstChild(\"Levels\") then return true end\n"
        "    if inst == ServerStorage:FindFirstChild(\"GuideBooths\") then return true end\n"
        "    if inst == ServerStorage:FindFirstChild(\"NpcTemplates\") then return true end\n"
        "    if inst == ServerStorage:FindFirstChild(\"ItemTemplates\") then return true end\n"
        "    inst = inst.Parent\n"
        "  end\n"
        "  return false\n"
        "end"
    )

    # walk workspace + serverstorage looking at parts and textlabels
    p.line(
        "local function visit(root)\n"
        "  for _, d in ipairs(root:GetDescendants()) do\n"
        "    if not is_under_buddy_root(d) then\n"
        "      -- skip stuff outside our scope\n"
        "    elseif d:IsA(\"BasePart\") then\n"
        "      local m = tostring(d.Material):gsub(\"Enum.Material.\", \"\")\n"
        "      if not allowed_materials[m] then\n"
        "        table.insert(violations.material, d:GetFullName() .. \" => \" .. m)\n"
        "      end\n"
        "    elseif d:IsA(\"TextLabel\") or d:IsA(\"TextButton\") or d:IsA(\"TextBox\") then\n"
        "      local f = tostring(d.Font):gsub(\"Enum.Font.\", \"\")\n"
        "      if f ~= expected_font then\n"
        "        table.insert(violations.font, d:GetFullName() .. \" => \" .. f)\n"
        "      end\n"
        "    end\n"
        "  end\n"
        "end\n"
        "visit(Workspace)\n"
        "visit(ServerStorage)"
    )

    # required-tag presence
    required_tag_list = "{ " + ", ".join(lua_string(t) for t in _REQUIRED_TAG_PRESENCE) + " }"
    p.line(f"local required_tags = {required_tag_list}")
    p.line(
        "violations.tags_missing = {}\n"
        "for _, t in ipairs(required_tags) do\n"
        "  if #CollectionService:GetTagged(t) == 0 then\n"
        "    table.insert(violations.tags_missing, t)\n"
        "  end\n"
        "end"
    )

    # structural checks — every level template needs a primarypart and the
    # right tagged children. every npc template needs a humanoid root and a
    # traitcard. catches mid-refactor breakage that the json-only checks miss.
    p.line(
        "violations.structure = {}\n"
        "local levels = ServerStorage:FindFirstChild(\"Levels\")\n"
        "if not levels then\n"
        "  table.insert(violations.structure, \"ServerStorage.Levels missing\")\n"
        "else\n"
        "  for _, lvl in ipairs(levels:GetChildren()) do\n"
        "    if not lvl.PrimaryPart then\n"
        "      table.insert(violations.structure, lvl.Name .. \".PrimaryPart unset\")\n"
        "    end\n"
        "    if not lvl:GetAttribute(\"LevelType\") then\n"
        "      table.insert(violations.structure, lvl.Name .. \".LevelType attribute missing\")\n"
        "    end\n"
        "    -- every level should expose a tagged level entry within its tree\n"
        "    local has_entry = false\n"
        "    for _, d in ipairs(lvl:GetDescendants()) do\n"
        "      if CollectionService:HasTag(d, \"LevelEntry\") then has_entry = true break end\n"
        "    end\n"
        "    if not has_entry then\n"
        "      table.insert(violations.structure, lvl.Name .. \" missing LevelEntry tag\")\n"
        "    end\n"
        "  end\n"
        "end"
    )

    p.line(
        "local npcs = ServerStorage:FindFirstChild(\"NpcTemplates\")\n"
        "if not npcs then\n"
        "  table.insert(violations.structure, \"ServerStorage.NpcTemplates missing\")\n"
        "else\n"
        "  for _, n in ipairs(npcs:GetChildren()) do\n"
        "    if not n:FindFirstChild(\"HumanoidRootPart\") then\n"
        "      table.insert(violations.structure, n.Name .. \" missing HumanoidRootPart\")\n"
        "    end\n"
        "    if not n:FindFirstChild(\"TraitCard\", true) then\n"
        "      table.insert(violations.structure, n.Name .. \" missing TraitCard billboard\")\n"
        "    end\n"
        "  end\n"
        "end"
    )

    p.line(
        "local items = ServerStorage:FindFirstChild(\"ItemTemplates\")\n"
        "if not items then\n"
        "  table.insert(violations.structure, \"ServerStorage.ItemTemplates missing\")\n"
        "else\n"
        "  for _, it in ipairs(items:GetChildren()) do\n"
        "    if not it.PrimaryPart then\n"
        "      table.insert(violations.structure, it.Name .. \".PrimaryPart unset\")\n"
        "    end\n"
        "  end\n"
        "end"
    )

    p.line(
        "local booths = ServerStorage:FindFirstChild(\"GuideBooths\")\n"
        "if not booths or not booths:FindFirstChild(\"DefaultBooth\") then\n"
        "  table.insert(violations.structure, \"ServerStorage.GuideBooths.DefaultBooth missing\")\n"
        "else\n"
        "  local b = booths.DefaultBooth\n"
        "  if not b.PrimaryPart then\n"
        "    table.insert(violations.structure, \"DefaultBooth.PrimaryPart unset\")\n"
        "  end\n"
        "  if not b:FindFirstChild(\"ControlPanel\", true) then\n"
        "    table.insert(violations.structure, \"DefaultBooth.ControlPanel missing\")\n"
        "  end\n"
        "  if not b:FindFirstChild(\"Window\", true) then\n"
        "    table.insert(violations.structure, \"DefaultBooth.Window missing\")\n"
        "  end\n"
        "end"
    )

    p.line(
        "table.insert(_result.notes, \"material_violations=\" .. tostring(#violations.material))\n"
        "table.insert(_result.notes, \"font_violations=\" .. tostring(#violations.font))\n"
        "table.insert(_result.notes, \"tags_missing=\" .. tostring(#violations.tags_missing))\n"
        "table.insert(_result.notes, \"structure_violations=\" .. tostring(#violations.structure))"
    )
    p.line("_result.violations = violations")
    return p.render()


__all__ = ["emit_verify_style_lua"]
