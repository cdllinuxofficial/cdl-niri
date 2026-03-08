import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.sidebarRightOpen

        function hide() {
            GlobalStates.sidebarRightOpen = false;
        }

        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:sidebarRight"
        WlrLayershell.keyboardFocus: GlobalStates.sidebarRightOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            right: true
            bottom: true
            left: true
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: panelWindow.hide()
        }

        Loader {
            id: sidebarContentLoader
            active: GlobalStates.sidebarRightOpen || Config?.options.sidebar.keepRightSidebarLoaded
            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
                topMargin: Appearance.sizes.hyprlandGapsOut
                rightMargin: Appearance.sizes.hyprlandGapsOut
                bottomMargin: Appearance.sizes.hyprlandGapsOut
            }
            width: sidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin

            focus: GlobalStates.sidebarRightOpen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide();
                }
            }

            sourceComponent: SidebarRightContent {}
        }
    }

    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        function close(): void {
            GlobalStates.sidebarRightOpen = false;
        }

        function open(): void {
            GlobalStates.sidebarRightOpen = true;
        }
    }

}
