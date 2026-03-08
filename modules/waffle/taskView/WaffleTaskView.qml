pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * On niri, workspace overview is handled by niri natively via
 * `niri msg action toggle-overview`.
 *
 * The QML task view (thumbnail grid) is not rendered.
 * The IpcHandler and GlobalShortcut are preserved so that keybind
 * calls from config.kdl still work.
 *
 * The search/launcher panel (GlobalStates.overviewOpen) continues
 * to work independently via the Overview.qml module.
 */
Scope {
    id: overviewScope

    IpcHandler {
        target: "search"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function workspacesToggle() {
            NiriData.dispatch("toggle-overview");
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
        function toggleReleaseInterrupt() {
            // noop on niri (no Super-held workspace numbers)
        }
        function clipboardToggle() {
            overviewScope.toggleClipboard();
        }
    }

}
