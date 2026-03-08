pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * Keyboard layout service for niri.
 * Replaces HyprlandXkb.qml — reads layout data from NiriData instead of Hyprland events.
 *
 * niri exposes layout names directly (e.g. "English (US)"), so we look up the short
 * code (e.g. "us") from /usr/share/X11/xkb/rules/base.lst, same as HyprlandXkb did.
 */
Singleton {
    id: root

    // ---- Public ----
    property list<string> layoutCodes: []
    property var cachedLayoutCodes: ({})
    property string currentLayoutName: NiriData.activeKeyboardLayoutName
    property string currentLayoutCode: ""

    property var baseLayoutFilePath: "/usr/share/X11/xkb/rules/base.lst"

    // Resolve code whenever the name changes
    onCurrentLayoutNameChanged: updateLayoutCode()

    function updateLayoutCode() {
        if (!currentLayoutName) return
        if (cachedLayoutCodes.hasOwnProperty(currentLayoutName)) {
            root.currentLayoutCode = cachedLayoutCodes[currentLayoutName]
        } else {
            getLayoutProc.running = true
        }
    }

    // Build layoutCodes list when the available layouts change
    onLayoutCodesChanged: updateLayoutCode()
    Binding {
        target: root
        property: "layoutCodes"
        value: NiriData.keyboardLayouts
    }

    // Also update OSK layout name when layout switches
    Connections {
        target: NiriData
        function onActiveKeyboardLayoutIdxChanged() {
            Config.options.osk.layout = root.currentLayoutName.split(" (")[0]
        }
    }

    // ---- Internal: look up short code from base.lst ----

    Process {
        id: getLayoutProc
        command: ["cat", root.baseLayoutFilePath]
        stdout: StdioCollector {
            id: layoutCollector
            onStreamFinished: {
                const lines = layoutCollector.text.split("\n")
                const target = root.currentLayoutName
                lines.find(line => {
                    if (!line.trim() || line.trim().startsWith("!")) return false

                    // Base layout: "  code   Description"
                    const mLayout = line.match(/^\s*(\S+)\s+(.+)$/)
                    if (mLayout && mLayout[2] === target) {
                        root.cachedLayoutCodes[mLayout[2]] = mLayout[1]
                        root.currentLayoutCode = mLayout[1]
                        return true
                    }

                    // Variant: "  variant   key   Description"
                    const mVariant = line.match(/^\s*(\S+)\s+(\S+)\s+(.+)$/)
                    if (mVariant && mVariant[3] === target) {
                        const code = mVariant[2] + mVariant[1]
                        root.cachedLayoutCodes[mVariant[3]] = code
                        root.currentLayoutCode = code
                        return true
                    }
                    return false
                })
            }
        }
    }
}
