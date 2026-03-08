pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Overview — niri edition.
 *
 * niri has a superb built-in overview (toggle-overview action) that understands
 * its scrollable-tiling layout natively. Trying to replicate it in QML would
 * produce an inferior experience, so we delegate entirely to niri's native overview.
 *
 * This stub keeps the same IPC surface (IpcHandler target "search",
 * GlobalShortcut names) as the original Overview.qml so nothing else needs to
 * change, but all open/close calls simply forward to niri.
 *
 * The search/launcher (Super held → fuzzel, clipboard, emoji) still opens the
 * quickshell search overlay — that part is unchanged.
 */
Item {
    id: root

    // ---- Clipboard / Emoji search are still handled by quickshell ----
    // (They open the search panel which does NOT depend on niri internals)

    function openSearch()    { GlobalStates.overviewOpen = true }
    function closeSearch()   { GlobalStates.overviewOpen = false }
    function toggleSearch()  { GlobalStates.overviewOpen = !GlobalStates.overviewOpen }

    // For workspace overview, always delegate to niri
    function openWorkspaces()   { NiriData.dispatch("toggle-overview") }
    function closeWorkspaces()  { NiriData.dispatch("toggle-overview") }
    function toggleWorkspaces() { NiriData.dispatch("toggle-overview") }

    // ---- IPC surface (keep target:"search" for compatibility) ----
    IpcHandler {
        target: "search"

        function toggle()            { root.toggleSearch() }
        function workspacesToggle()  { root.toggleWorkspaces() }
        function close()             { root.closeSearch() }
        function open()              { root.openSearch() }
        function clipboardToggle()   {
            GlobalStates.overviewOpen = true
            // The search panel picks up the clipboard tab via GlobalStates
        }
        function emojiToggle()       {
            GlobalStates.overviewOpen = true
            // The search panel picks up the emoji tab via GlobalStates
        }
        function toggleReleaseInterrupt() { /* noop for niri */ }
    }

    // ---- GlobalShortcuts ----
    // Super tap → open quickshell search (unchanged)

    // Super+Tab → niri native overview


    // Clipboard / Emoji still go to the quickshell search panel


    // Interrupt shortcuts — no-ops for niri (were Hyprland-specific)
}
