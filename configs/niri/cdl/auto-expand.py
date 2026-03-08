#!/usr/bin/env python3
"""
Auto-expand tiled windows to full width when they're the only window
on their workspace. Runs as a daemon alongside niri.
"""
import json
import subprocess

def main():
    proc = subprocess.Popen(
        ["niri", "msg", "-j", "event-stream"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )

    prev_ids = None  # None = haven't seen initial state yet

    for line in proc.stdout:
        line = line.strip()
        if not line:
            continue

        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue

        if "WindowsChanged" not in event:
            continue

        windows = event["WindowsChanged"]["windows"]
        current_ids = {w["id"] for w in windows}

        if prev_ids is None:
            # First event: record existing windows without acting
            prev_ids = current_ids
            continue

        new_ids = current_ids - prev_ids
        prev_ids = current_ids

        if not new_ids:
            continue

        for new_id in new_ids:
            window = next((w for w in windows if w["id"] == new_id), None)
            if window is None or window["is_floating"] or window["workspace_id"] is None:
                continue

            workspace_id = window["workspace_id"]
            tiled_on_workspace = [
                w for w in windows
                if w["workspace_id"] == workspace_id and not w["is_floating"]
            ]

            if len(tiled_on_workspace) == 1:
                subprocess.run(
                    ["niri", "msg", "action", "expand-column-to-available-width"],
                    capture_output=True,
                )

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
