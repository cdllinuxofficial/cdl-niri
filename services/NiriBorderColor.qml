pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common

/**
 * NiriBorderColor — applies theme colors to niri compositor window decorations.
 *
 * Covers: focus-ring, border, tab-indicator, insert-hint, recent-windows.
 * Writes ~/.local/state/cdl-niri/user/generated/niri-colors.kdl and calls
 * `niri msg action load-config-file` to apply immediately.
 *
 * niri config must include at the very end:
 *   include "/home/cdl/.local/state/cdl-niri/user/generated/niri-colors.kdl"
 */
Singleton {
    id: root

    // Direct bindings — no optional chaining so QML tracks changes correctly
    property bool   borderEnable:   Config.options.appearance.border.enable
    property bool   useThemeColor:  Config.options.appearance.border.useThemeColor
    property int    borderWidth:    Config.options.appearance.border.width
    property string customActive:   Config.options.appearance.border.activeColor
    property string customInactive: Config.options.appearance.border.inactiveColor
    property string themeActive:   Appearance.m3colors.m3primary.toString()
    property string themeInactive: Appearance.m3colors.m3outlineVariant.toString()
    property string themeDim:      Appearance.m3colors.m3primaryContainer.toString()

    property string activeColor:   useThemeColor ? themeActive   : (customActive   || themeActive)
    property string inactiveColor: useThemeColor ? themeInactive : (customInactive || themeInactive)

    onBorderEnableChanged:    Qt.callLater(apply)
    onBorderWidthChanged:     Qt.callLater(apply)
    onUseThemeColorChanged:   Qt.callLater(apply)
    onActiveColorChanged:     Qt.callLater(apply)
    onInactiveColorChanged:   Qt.callLater(apply)
    onThemeDimChanged:        Qt.callLater(apply)

    Component.onCompleted: {
        console.log("[NiriBorderColor] Initialized, active=" + activeColor + " inactive=" + inactiveColor)
        apply()
    }

    function load() {}

    function hexWithAlpha(hexColor, alpha) {
        const c = Qt.color(hexColor)
        const r = Math.round(c.r * 255).toString(16).padStart(2, "0")
        const g = Math.round(c.g * 255).toString(16).padStart(2, "0")
        const b = Math.round(c.b * 255).toString(16).padStart(2, "0")
        const a = Math.round(alpha * 255).toString(16).padStart(2, "0")
        return `#${r}${g}${b}${a}`
    }

    // Normalize any color string to a valid 6-char hex via Qt.color()
    function safeHex(colorStr) {
        try {
            const c = Qt.color(colorStr)
            if (!c.valid) return "#000000"
            const r = Math.round(c.r * 255).toString(16).padStart(2, "0")
            const g = Math.round(c.g * 255).toString(16).padStart(2, "0")
            const b = Math.round(c.b * 255).toString(16).padStart(2, "0")
            return `#${r}${g}${b}`
        } catch (e) {
            return "#000000"
        }
    }

    function apply() {
        console.log("[NiriBorderColor] apply: w=" + root.borderWidth + " enable=" + root.borderEnable + " active=" + root.activeColor)
        const a  = safeHex(root.activeColor)
        const i  = safeHex(root.inactiveColor)
        const ad = safeHex(root.themeDim)
        const w  = root.borderWidth
        const off = root.borderEnable ? "" : "\n        off"

        const content = [
            "layout {",
            "    focus-ring {" + off,
            `        width ${w}`,
            `        active-color   "${a}"`,
            `        inactive-color "${i}"`,
            "    }",
            "    border {" + off,
            `        width ${w}`,
            `        active-color   "${a}"`,
            `        inactive-color "${i}"`,
            "    }",
            "    tab-indicator {",
            `        active-color   "${a}"`,
            `        inactive-color "${ad}"`,
            "    }",
            "    insert-hint {",
            `        color "${hexWithAlpha(a, 0.5)}"`,
            "    }",
            "}",
            "",
            "recent-windows {",
            "    highlight {",
            `        active-color "${a}"`,
            "    }",
            "}"
        ].join("\n") + "\n"

        // Pass content as sys.argv[1] and path as sys.argv[2] — no shell, no escaping needed
        Quickshell.execDetached([
            "python3", "-c",
            "import sys,subprocess; open(sys.argv[2],'w').write(sys.argv[1]); subprocess.run(['niri','msg','action','load-config-file'])",
            content,
            Directories.generatedNiriColorsPath
        ])
    }
}
