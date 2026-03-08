import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * GlobalStates — niri edition.
 *
 * Removed: Quickshell.Hyprland import and the Super-key tracking
 * (workspaceNumber GlobalShortcut). niri has no equivalent of Hyprland's
 * hold-Super-to-show-numbers mechanism, so superDown is always false and
 * workspaceShowNumbers is unused (Workspaces.qml uses alwaysShowNumbers from
 * Config instead).
 */
Singleton {
    id: root
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool sessionOpen: false
    // superDown is always false on niri — kept for API compatibility
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool wallpaperSelectorOpen: false
    property bool workspaceShowNumbers: false

    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll()
            Notifications.markAllRead()
        }
    }
}
