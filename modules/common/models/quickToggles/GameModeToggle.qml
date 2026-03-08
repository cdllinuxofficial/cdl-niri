import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    id: root
    name: Translation.tr("Game mode")
    toggled: toggled
    icon: "gamepad"

    // niri has no hyprctl batch for disabling animations/blur/shadows.
    // We toggle gamemode (the CPU/GPU performance daemon) instead.
    // Visual tweaks (compositor-side) are not available on niri via IPC.
    mainAction: () => {
        const enabling = !root.toggled
        root.toggled = enabling
        if (enabling) {
            Quickshell.execDetached(["gamemoded", "-r"])
            Quickshell.execDetached(["notify-send", "-a", "Game mode", "Game mode enabled",
                "gamemoded running. Note: compositor visual tweaks are not available on niri."])
        } else {
            Quickshell.execDetached(["gamemoded", "-E"])
            Quickshell.execDetached(["notify-send", "-a", "Game mode", "Game mode disabled", "gamemoded stopped."])
        }
    }
    Process {
        id: fetchActiveState
        running: true
        command: ["gamemoded", "-s"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.toggled = text.includes("active")
            }
        }
    }
    tooltipText: Translation.tr("Game mode")
}
