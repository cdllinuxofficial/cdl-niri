pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Niri equivalent of HyprlandKeybinds.qml.
 * Parses comments in config.kdl using get_keybinds.py (niri KDL parser)
 * and exposes the same JSON structure to the cheatsheet UI.
 *
 * No config-reload event available on niri via IPC, so we parse once
 * at startup. Re-parse can be triggered by restarting quickshell.
 */
Singleton {
    id: root
    property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/niri/get_keybinds.py`)
    property string defaultKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/niri/config.kdl`)
    property var defaultKeybinds: {"children": []}
    property var keybinds: ({
        children: [
            ...(defaultKeybinds.children ?? []),
        ]
    })

    Process {
        id: getDefaultKeybinds
        running: true
        command: [root.keybindParserPath, "--path", root.defaultKeybindConfigPath]

        stdout: SplitParser {
            onRead: data => {
                try {
                    root.defaultKeybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[NiriKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }
}
