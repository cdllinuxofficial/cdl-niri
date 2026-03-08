pragma Singleton

import QtQuick
import qs.modules.common
import Quickshell
import Quickshell.Io

/**
 * Hyprsunset service — niri edition.
 *
 * hyprsunset is a standalone binary; it works on any Wayland compositor.
 * The only Hyprland-specific parts were:
 *   - State query via `hyprctl hyprsunset temperature`  → replaced with `pidof`
 *   - Temperature change via `Hyprland.dispatch()`      → replaced with restart
 *
 * Everything else (automatic on/off by time, manual toggle) is unchanged.
 */
Singleton {
    id: root
    property string from: Config.options?.light?.night?.from ?? "19:00"
    property string to:   Config.options?.light?.night?.to   ?? "06:30"
    property bool automatic: Config.options?.light?.night?.automatic && (Config?.ready ?? true)
    property int  colorTemperature: Config.options?.light?.night?.colorTemperature ?? 5000
    property bool shouldBeOn
    property bool firstEvaluation: true
    property bool active: false

    property int fromHour:   Number(from.split(":")[0])
    property int fromMinute: Number(from.split(":")[1])
    property int toHour:     Number(to.split(":")[0])
    property int toMinute:   Number(to.split(":")[1])

    property int clockHour:   DateTime.clock.hours
    property int clockMinute: DateTime.clock.minutes

    property var manualActive
    property int manualActiveHour
    property int manualActiveMinute

    onClockMinuteChanged: reEvaluate()
    onAutomaticChanged: {
        root.manualActive = undefined
        root.firstEvaluation = true
        reEvaluate()
    }

    function inBetween(t, from, to) {
        return from < to ? (t >= from && t <= to) : (t >= from || t <= to)
    }

    function reEvaluate() {
        const t    = clockHour * 60 + clockMinute
        const from = fromHour  * 60 + fromMinute
        const to   = toHour    * 60 + toMinute
        const man  = manualActiveHour * 60 + manualActiveMinute

        if (root.manualActive !== undefined && (inBetween(from, man, t) || inBetween(to, man, t))) {
            root.manualActive = undefined
        }
        root.shouldBeOn = inBetween(t, from, to)
        if (firstEvaluation) {
            firstEvaluation = false
            root.ensureState()
        }
    }

    onShouldBeOnChanged: ensureState()
    function ensureState() {
        if (!root.automatic || root.manualActive !== undefined) return
        if (root.shouldBeOn) root.enable()
        else root.disable()
    }

    function load() {} // Force singleton init

    function fetchState() {
        fetchProc.running = true
    }

    function enable() {
        root.active = true
        Quickshell.execDetached(["bash", "-c",
            `pidof hyprsunset || hyprsunset --temperature ${root.colorTemperature}`])
    }

    function disable() {
        root.active = false
        Quickshell.execDetached(["bash", "-c", "pkill hyprsunset"])
    }

    // Determine initial state by checking if hyprsunset is running
    Process {
        id: fetchProc
        running: true
        command: ["bash", "-c", "pidof hyprsunset"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.active = text.trim().length > 0
            }
        }
    }

    // When temperature setting changes while active: restart with new temp
    Connections {
        target: Config.options.light.night
        function onColorTemperatureChanged() {
            if (!root.active) return
            Quickshell.execDetached(["bash", "-c",
                `pkill hyprsunset; sleep 0.2; hyprsunset --temperature ${Config.options.light.night.colorTemperature}`])
        }
    }

    function toggle(active = undefined) {
        if (root.manualActive === undefined) {
            root.manualActive = root.active
            root.manualActiveHour   = root.clockHour
            root.manualActiveMinute = root.clockMinute
        }
        root.manualActive = active !== undefined ? active : !root.manualActive
        if (root.manualActive) root.enable()
        else root.disable()
    }
}
