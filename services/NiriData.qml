pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Niri compositor IPC service.
 * Replaces HyprlandData.qml for niri.
 *
 * Workspace model (niri-specific):
 *   - Dynamic, per-output. Count grows as needed.
 *   - niri always appends one empty workspace at the end of each output.
 *   - `is_focused`  → the workspace with keyboard focus (only one globally)
 *   - `is_active`   → the visible workspace on its output (one per output)
 *   - `idx`         → 0-based position within the output's workspace list
 *
 * Window model:
 *   - All tiled in columns or floating. No pixel geometry via IPC.
 *   - Identified by numeric `id`, not address.
 *   - `app_id` is the wayland app-id (use for icon lookup)
 */
Singleton {
    id: root

    // === Workspaces ===
    property var workspaces: []        // All workspaces, all outputs
    property var workspaceById: ({})
    property var focusedWorkspace: null  // The workspace with keyboard input

    // === Windows ===
    property var windows: []
    property var windowById: ({})
    property var focusedWindow: null

    // === Outputs ===
    property var outputs: ({})  // Map: output name → output object

    // === Keyboard layout ===
    property var keyboardLayouts: []        // List of layout name strings
    property int activeKeyboardLayoutIdx: 0
    property string activeKeyboardLayoutName: keyboardLayouts[activeKeyboardLayoutIdx] ?? ""

    // =========================================================
    // Public helpers
    // =========================================================

    /** Workspaces belonging to a given output */
    function workspacesForOutput(outputName) {
        return root.workspaces.filter(ws => ws.output === outputName)
    }

    /** The focused (active) workspace on a given output */
    function activeWorkspaceForOutput(outputName) {
        return root.workspaces.find(ws => ws.output === outputName && ws.is_active) ?? null
    }

    /** Windows that live on a given workspace id */
    function windowsForWorkspace(workspaceId) {
        return root.windows.filter(w => w.workspace_id === workspaceId)
    }

    /**
     * Best representative window for a workspace (for app-icon display).
     * Prefers the focused window, falls back to first.
     */
    function representativeWindowForWorkspace(workspaceId) {
        const wins = root.windows.filter(w => w.workspace_id === workspaceId)
        return wins.find(w => w.is_focused) ?? wins[0] ?? null
    }

    /**
     * Fire a niri action by splitting on spaces into individual args.
     * e.g. dispatch("focus-workspace 2") → ["niri","msg","action","focus-workspace","2"]
     * Simple no-arg actions: dispatch("focus-column-left")
     */
    function dispatch(action) {
        Quickshell.execDetached(["niri", "msg", "action"].concat(action.split(" ")))
    }

    /**
     * Focus a specific workspace by its 0-based idx on a given output.
     * niri msg action focus-workspace takes a 1-based index.
     */
    function focusWorkspaceByIdx(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx + 1)])
    }

    // =========================================================
    // Internal helpers
    // =========================================================

    function updateWorkspaces()      { getWorkspaces.running = true }
    function updateWindows()         { getWindows.running = true }
    function updateOutputs()         { getOutputs.running = true }
    function updateKeyboardLayouts() { getKeyboardLayouts.running = true }

    function setWorkspaces(wsList) {
        let byId = {}, focused = null
        for (const ws of wsList) {
            byId[ws.id] = ws
            if (ws.is_focused) focused = ws
        }
        root.workspaces    = wsList
        root.workspaceById = byId
        root.focusedWorkspace = focused
    }

    function setWindows(winList) {
        let byId = {}, focused = null
        for (const w of winList) {
            byId[w.id] = w
            if (w.is_focused) focused = w
        }
        root.windows    = winList
        root.windowById = byId
        root.focusedWindow = focused
    }

    Component.onCompleted: {
        updateWorkspaces()
        updateWindows()
        updateOutputs()
        updateKeyboardLayouts()
        eventStream.running = true
    }

    // =========================================================
    // Event stream (long-running process)
    // niri outputs one compact JSON object per line.
    // =========================================================

    Process {
        id: eventStream
        command: ["niri", "msg", "-j", "event-stream"]

        stdout: SplitParser {
            onRead: (line) => {
                if (!line.trim()) return
                try {
                    root.handleEvent(JSON.parse(line))
                } catch (e) {
                    console.error("[NiriData] event parse error:", e, "|", line)
                }
            }
        }

        // Restart automatically if niri restarts
        onExited: Qt.callLater(() => { eventStream.running = true })
    }

    function handleEvent(ev) {
        if (ev.WorkspacesChanged) {
            root.setWorkspaces(ev.WorkspacesChanged.workspaces)

        } else if (ev.WorkspaceActivated || ev.WorkspaceActiveWindowChanged) {
            // Re-query for accurate is_active / active_window_id fields
            updateWorkspaces()

        } else if (ev.WindowsChanged) {
            root.setWindows(ev.WindowsChanged.windows)

        } else if (ev.WindowOpenedOrChanged) {
            // Patch a single window in-place for lower latency
            const w = ev.WindowOpenedOrChanged.window
            const idx = root.windows.findIndex(x => x.id === w.id)
            const newList = [...root.windows]
            if (idx >= 0) newList[idx] = w
            else newList.push(w)
            root.setWindows(newList)

        } else if (ev.WindowClosed) {
            root.setWindows(root.windows.filter(w => w.id !== ev.WindowClosed.id))

        } else if (ev.WindowFocusChanged) {
            const focusedId = ev.WindowFocusChanged.id
            const newList = root.windows.map(w => Object.assign({}, w, {is_focused: w.id === focusedId}))
            root.setWindows(newList)

        } else if (ev.KeyboardLayoutsChanged) {
            root.keyboardLayouts          = ev.KeyboardLayoutsChanged.keyboard_layouts.names
            root.activeKeyboardLayoutIdx  = ev.KeyboardLayoutsChanged.keyboard_layouts.current_idx

        } else if (ev.KeyboardLayoutSwitched) {
            root.activeKeyboardLayoutIdx = ev.KeyboardLayoutSwitched.idx
        }
    }

    // =========================================================
    // One-shot query processes
    // =========================================================

    Process {
        id: getWorkspaces
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.setWorkspaces(JSON.parse(text)) }
                catch (e) { console.error("[NiriData] workspaces:", e) }
            }
        }
    }

    Process {
        id: getWindows
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.setWindows(JSON.parse(text)) }
                catch (e) { console.error("[NiriData] windows:", e) }
            }
        }
    }

    Process {
        id: getOutputs
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.outputs = JSON.parse(text) }
                catch (e) { console.error("[NiriData] outputs:", e) }
            }
        }
    }

    Process {
        id: getKeyboardLayouts
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kl = JSON.parse(text)
                    root.keyboardLayouts         = kl.names
                    root.activeKeyboardLayoutIdx = kl.current_idx
                } catch (e) { console.error("[NiriData] keyboard-layouts:", e) }
            }
        }
    }
}
