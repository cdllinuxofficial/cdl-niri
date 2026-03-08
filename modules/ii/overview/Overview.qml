pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false
    // Tracks whether niri overview was opened alongside the search bar
    property bool niriOverviewActive: false

    function openOverview() {
        if (GlobalStates.overviewOpen) return
        GlobalStates.overviewOpen = true
    }
    function closeOverview() {
        if (!GlobalStates.overviewOpen) return
        if (overviewScope.niriOverviewActive) {
            NiriData.dispatch("toggle-overview")
            overviewScope.niriOverviewActive = false
        }
        GlobalStates.overviewOpen = false
    }
    function toggleOverview() {
        GlobalStates.overviewOpen = !GlobalStates.overviewOpen
    }

    // Opens niri workspace overview + search bar together (bound to Mod+D)
    function toggleWithNiriOverview() {
        if (GlobalStates.overviewOpen && overviewScope.niriOverviewActive) {
            overviewScope.closeOverview()
        } else if (!GlobalStates.overviewOpen) {
            NiriData.dispatch("toggle-overview")
            overviewScope.niriOverviewActive = true
            GlobalStates.overviewOpen = true
        } else {
            // Search open without niri overview — just close search
            overviewScope.closeOverview()
        }
    }

    PanelWindow {
        id: panelWindow
        property string searchingText: ""

        visible: GlobalStates.overviewOpen

        WlrLayershell.namespace: "quickshell:overview"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        mask: Region {
            item: GlobalStates.overviewOpen ? columnLayout : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen) {
                    searchWidget.disableExpandAnimation()
                    overviewScope.dontAutoCancelSearch = false
                } else {
                    if (!overviewScope.dontAutoCancelSearch)
                        searchWidget.cancelSearch()
                }
            }
        }

        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight

        function setSearchingText(text) {
            searchWidget.setSearchingText(text)
            searchWidget.focusFirstItem()
        }

        Column {
            id: columnLayout
            visible: GlobalStates.overviewOpen
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            spacing: -8

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape)
                    overviewScope.closeOverview()
            }

            SearchWidget {
                id: searchWidget
                anchors.horizontalCenter: parent.horizontalCenter
                Synchronizer on searchingText {
                    property alias source: panelWindow.searchingText
                }
            }
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: overviewScope.closeOverview()
        }
    }

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            overviewScope.closeOverview()
            return
        }
        overviewScope.dontAutoCancelSearch = true
        panelWindow.setSearchingText(Config.options.search.prefix.clipboard)
        overviewScope.openOverview()
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            overviewScope.closeOverview()
            return
        }
        overviewScope.dontAutoCancelSearch = true
        panelWindow.setSearchingText(Config.options.search.prefix.emojis)
        overviewScope.openOverview()
    }

    IpcHandler {
        target: "search"

        function toggle()           { overviewScope.toggleOverview() }
        function workspacesToggle() { overviewScope.toggleWithNiriOverview() }
        function close()            { overviewScope.closeOverview() }
        function open()             { overviewScope.openOverview() }
        function clipboardToggle()  { overviewScope.toggleClipboard() }
        function emojiToggle()      { overviewScope.toggleEmojis() }
        function toggleReleaseInterrupt() { /* noop on niri */ }
    }
}
