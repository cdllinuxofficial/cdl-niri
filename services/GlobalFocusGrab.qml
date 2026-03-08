pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

/**
 * Manages focus grab shared by all windows.
 * "Persistent" = always included but not closed on dismiss (bar, OSK).
 * "Dismissable" = sidebars etc.
 *
 * Niri port: HyprlandFocusGrab removed — no niri equivalent.
 * Panels close via their own click-outside MouseArea.
 */
Singleton {
    id: root

    signal dismissed()

    property list<var> persistent: []
    property list<var> dismissable: []

    function dismiss() {
        root.dismissable = [];
        root.dismissed();
    }

    Component.onCompleted: {
        console.log("[GlobalFocusGrab] Initialized (niri stub)");
    }

    function addPersistent(window) {
        if (root.persistent.indexOf(window) === -1) {
            root.persistent.push(window);
        }
    }

    function removePersistent(window) {
        var index = root.persistent.indexOf(window);
        if (index !== -1) {
            root.persistent.splice(index, 1);
        }
    }

    function addDismissable(window) {
        if (root.dismissable.indexOf(window) === -1) {
            root.dismissable.push(window);
        }
    }

    function removeDismissable(window) {
        var index = root.dismissable.indexOf(window);
        if (index !== -1) {
            root.dismissable.splice(index, 1);
        }
    }

    function hasActive(element) {
        return element?.activeFocus || Array.from(
            element?.children
        ).some(
            (child) => hasActive(child)
        );
    }
}
