#!/usr/bin/env python3
"""
Niri KDL keybind parser for the end4/ii cheatsheet.

Comment convention (same as the Hyprland parser, adapted for KDL):
  // !SectionName       →  section heading
  // Description        →  description for the next keybind
  // [hidden]           →  hide the next keybind from the cheatsheet
  // #/# Mod+A/B, desc  →  paired keys shown as one entry (same as hyprland #/# syntax)

Output JSON matches the structure expected by HyprlandKeybinds.qml /
NiriKeybinds.qml:
  {
    "name": "",
    "children": [ Section, ... ],
    "keybinds": [ KeyBinding, ... ]
  }
"""

import argparse
import json
import os
import re
from typing import Optional

# Keys that are treated as modifiers (not the "main" key)
MODIFIERS = {"Mod", "Super", "Win", "Ctrl", "Control", "Shift", "Alt", "AltGr", "ISO_Level3_Shift"}

TITLE_REGEX   = re.compile(r"^//\s*!(.*)")          # // !Section
HIDE_COMMENT  = "[hidden]"
PAIRED_PREFIX = "#/# "                               # // #/# Mod+A/B, desc


def parse_modifier_key(combo: str):
    """Split 'Mod+Ctrl+A' into (['Super', 'Ctrl'], 'A')."""
    parts = combo.split("+")
    mods, keys = [], []
    for p in parts:
        if p in MODIFIERS:
            mods.append("Super" if p in ("Mod", "Win") else p)
        else:
            keys.append(p)
    key = "+".join(keys) if keys else combo
    return mods, key


def parse_keybind_line(line: str, comment: str) -> Optional[dict]:
    """Parse one KDL keybind line and return a KeyBinding dict or None."""
    line = line.strip()
    # Match:  KeyCombo { action; }   or   KeyCombo { action }
    m = re.match(r'^(\S+)\s*\{(.+?)\}', line)
    if not m:
        return None
    combo  = m.group(1)
    action = m.group(2).strip().rstrip(";")

    mods, key = parse_modifier_key(combo)

    # Derive a readable dispatcher + params from the action
    if action.startswith("spawn"):
        dispatcher = "exec"
        params = action[5:].strip().strip('"').strip("'")
    else:
        dispatcher = action
        params = ""

    return {
        "mods":       mods,
        "key":        key,
        "dispatcher": dispatcher,
        "params":     params,
        "comment":    comment,
    }


def new_section(name: str) -> dict:
    return {"name": name, "children": [], "keybinds": []}


def parse_file(path: str) -> dict:
    if not os.access(os.path.expanduser(os.path.expandvars(path)), os.R_OK):
        return new_section("")

    with open(os.path.expanduser(os.path.expandvars(path))) as f:
        lines = f.readlines()

    root    = new_section("")
    # Stack of (section_dict, depth).  depth = number of '#' after '!'
    stack   = [(root, 0)]

    pending_comment = ""
    pending_hidden  = False

    def current() -> dict:
        return stack[-1][0]

    for raw in lines:
        line = raw.rstrip()
        stripped = line.lstrip()

        # ── Blank lines reset pending state ──────────────────────────────────
        if not stripped:
            pending_comment = ""
            pending_hidden  = False
            continue

        # ── Comment lines ─────────────────────────────────────────────────────
        if stripped.startswith("//"):
            text = stripped[2:].strip()

            # Section heading: // !Shell  or  // ##! Shell
            m_title = TITLE_REGEX.match(stripped)
            if m_title:
                heading_text = m_title.group(1).strip()
                # Count leading '#' to determine nesting depth (// !Shell = 1, // ##!Shell = 2)
                depth = len(heading_text) - len(heading_text.lstrip("#")) + 1
                section_name = heading_text.lstrip("#").strip()

                # Pop stack back to the right level
                while len(stack) > 1 and stack[-1][1] >= depth:
                    stack.pop()

                new_sec = new_section(section_name)
                current()["children"].append(new_sec)
                stack.append((new_sec, depth))

                pending_comment = ""
                pending_hidden  = False
                continue

            # [hidden] marker
            if text == HIDE_COMMENT:
                pending_hidden = True
                continue

            # Paired key shorthand: // #/# Super+A/B, Do the thing
            if text.startswith(PAIRED_PREFIX[3:]):  # strip leading "//"
                pending_comment = text[len(PAIRED_PREFIX) - 3:].strip()
                continue

            # Normal description
            if text and not text.startswith("["):
                pending_comment = text
            continue

        # ── Keybind line ──────────────────────────────────────────────────────
        # Must look like:   KeyCombo { ... }
        if "{" in line and "}" in line and not stripped.startswith("//"):
            if pending_hidden:
                pending_comment = ""
                pending_hidden  = False
                continue

            kb = parse_keybind_line(line, pending_comment)
            if kb:
                current()["keybinds"].append(kb)

            pending_comment = ""
            pending_hidden  = False
            continue

        # ── Anything else (binds { ... }, layout { ... }) resets pending state
        pending_comment = ""
        pending_hidden  = False

    return root


def main():
    parser = argparse.ArgumentParser(description="Niri KDL keybind reader")
    parser.add_argument("--path", default="$HOME/.config/niri/config.kdl",
                        help="Path to niri config file")
    args = parser.parse_args()

    result = parse_file(args.path)
    print(json.dumps(result))


if __name__ == "__main__":
    main()
