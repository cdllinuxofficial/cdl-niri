pragma Singleton
import Quickshell
import qs.services
import qs.modules.common

/**
 * Session actions — niri edition.
 * Replaces Hyprland-specific process killing with niri IPC.
 */
Singleton {
    id: root

    function closeAllWindows() {
        // Close every window via niri action (fires and forgets per window)
        for (const w of NiriData.windows) {
            Quickshell.execDetached(["niri", "msg", "action", "close-window"])
        }
    }

    function changePassword() {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.changePassword}`])
    }

    function lock() {
        Quickshell.execDetached(["loginctl", "lock-session"])
    }

    function suspend() {
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"])
    }

    function logout() {
        // Kill niri (not Hyprland)
        Quickshell.execDetached(["bash", "-c", "niri msg action quit || pkill niri"])
    }

    function launchTaskManager() {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.taskManager}`])
    }

    function hibernate() {
        Quickshell.execDetached(["bash", "-c", "systemctl hibernate || loginctl hibernate"])
    }

    function poweroff() {
        Quickshell.execDetached(["bash", "-c", "systemctl poweroff || loginctl poweroff"])
    }

    function reboot() {
        Quickshell.execDetached(["bash", "-c", "reboot || loginctl reboot"])
    }

    function rebootToFirmware() {
        Quickshell.execDetached(["bash", "-c", "systemctl reboot --firmware-setup || loginctl reboot --firmware-setup"])
    }
}
