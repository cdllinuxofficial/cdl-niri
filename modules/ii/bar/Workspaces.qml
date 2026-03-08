import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

/**
 * Workspace indicator — niri edition.
 *
 * Niri workflow differences vs Hyprland:
 *  - Workspaces are dynamic and per-output (no fixed numbered slots).
 *  - niri always appends one empty workspace at the end of each output's list.
 *  - Navigation is up/down between workspaces (not numbered 1-10).
 *  - We show all workspaces for the current output as a dynamic strip.
 *
 * Visual behaviour (unchanged from end4 aesthetic):
 *  - Occupied workspaces show a secondary-container pill.
 *  - Active workspace shows the primary-color pill.
 *  - App icon or dot shown per workspace depending on config.
 */
Item {
    id: root
    property bool vertical: false
    property int widgetPadding: 4
    property bool borderless: Config.options.bar.borderless

    // The screen this bar lives on
    readonly property string outputName: QsWindow.window?.screen?.name ?? ""

    // Workspaces for this output only, from NiriData
    readonly property var outputWorkspaces: NiriData.workspacesForOutput(outputName)

    // The active (focused & visible) workspace index within outputWorkspaces
    readonly property int activeIdx: {
        const active = outputWorkspaces.findIndex(ws => ws.is_active)
        return active >= 0 ? active : 0
    }

    // How many workspaces to display (all of them for this output)
    readonly property int wsCount: outputWorkspaces.length

    property int workspaceButtonWidth: 26
    property real activeWorkspaceMargin: 2

    implicitWidth: root.vertical
        ? Appearance.sizes.verticalBarWidth
        : (root.workspaceButtonWidth * Math.max(root.wsCount, 1))
    implicitHeight: root.vertical
        ? (root.workspaceButtonWidth * Math.max(root.wsCount, 1))
        : Appearance.sizes.barHeight

    // Scroll to switch workspaces (niri: focus-workspace-down/up)
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                NiriData.dispatch("focus-workspace-down")
            else
                NiriData.dispatch("focus-workspace-up")
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    // Background pills for occupied workspaces
    Grid {
        z: 1
        anchors.centerIn: parent
        rowSpacing: 0
        columnSpacing: 0
        columns: root.vertical ? 1 : root.wsCount
        rows:    root.vertical ? root.wsCount : 1

        Repeater {
            model: root.outputWorkspaces

            Rectangle {
                id: wsBg
                required property var modelData
                required property int index

                readonly property bool occupied: NiriData.windowsForWorkspace(modelData.id).length > 0
                readonly property bool isActive: modelData.is_active

                // Pill rounding: join adjacent occupied pills
                readonly property bool prevOccupied: index > 0
                    && NiriData.windowsForWorkspace(root.outputWorkspaces[index - 1]?.id ?? -1).length > 0
                readonly property bool nextOccupied: index < root.wsCount - 1
                    && NiriData.windowsForWorkspace(root.outputWorkspaces[index + 1]?.id ?? -1).length > 0

                readonly property real fullRadius: workspaceButtonWidth / 2
                topLeftRadius:     (root.vertical ? nextOccupied : prevOccupied) ? 0 : fullRadius
                bottomLeftRadius:  (root.vertical ? prevOccupied : prevOccupied) ? 0 : fullRadius
                topRightRadius:    (root.vertical ? prevOccupied : nextOccupied) ? 0 : fullRadius
                bottomRightRadius: (root.vertical ? nextOccupied : nextOccupied) ? 0 : fullRadius

                implicitWidth:  workspaceButtonWidth
                implicitHeight: workspaceButtonWidth
                color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
                opacity: (occupied && !(!ToplevelManager.activeToplevel?.activated && isActive)) ? 1 : 0

                Behavior on opacity     { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                Behavior on topLeftRadius     { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
                Behavior on bottomRightRadius { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
            }
        }
    }

    // Active workspace highlight (primary colour pill)
    Rectangle {
        z: 2
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary

        anchors {
            verticalCenter:   root.vertical ? undefined : parent.verticalCenter
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        }

        AnimatedTabIndexPair {
            id: idxPair
            index: root.activeIdx
        }

        property real pos:       Math.min(idxPair.idx1, idxPair.idx2) * workspaceButtonWidth + root.activeWorkspaceMargin
        property real len:       Math.abs(idxPair.idx1 - idxPair.idx2) * workspaceButtonWidth + workspaceButtonWidth - root.activeWorkspaceMargin * 2
        property real thickness: workspaceButtonWidth - root.activeWorkspaceMargin * 2

        x:             root.vertical ? null : pos
        y:             root.vertical ? pos  : null
        implicitWidth: root.vertical ? thickness : len
        implicitHeight: root.vertical ? len : thickness
    }

    // Clickable workspace buttons with icons / numbers / dots
    Grid {
        z: 3
        anchors.fill: parent
        columns: root.vertical ? 1 : root.wsCount
        rows:    root.vertical ? root.wsCount : 1
        columnSpacing: 0
        rowSpacing: 0

        Repeater {
            model: root.outputWorkspaces

            Button {
                id: wsBtn
                required property var modelData
                required property int index

                readonly property bool isActive: modelData.is_active
                readonly property var  repWindow: NiriData.representativeWindowForWorkspace(modelData.id)
                readonly property string iconSource: repWindow
                    ? Quickshell.iconPath(AppSearch.guessIcon(repWindow.app_id), "image-missing")
                    : ""

                implicitWidth:  root.vertical ? Appearance.sizes.verticalBarWidth : workspaceButtonWidth
                implicitHeight: root.vertical ? workspaceButtonWidth : Appearance.sizes.barHeight

                // Click to focus this workspace (0-based idx → focusWorkspaceByIdx handles 1-based conversion)
                onPressed: NiriData.focusWorkspaceByIdx(modelData.idx)

                background: Item {
                    // Dot (default)
                    Rectangle {
                        id: dot
                        anchors.centerIn: parent
                        width:  workspaceButtonWidth * 0.18
                        height: width
                        radius: width / 2
                        opacity: (Config.options?.bar.workspaces.showAppIcons && wsBtn.repWindow) ? 0 : 1
                        visible: opacity > 0
                        color: wsBtn.isActive
                            ? Appearance.m3colors.m3onPrimary
                            : (NiriData.windowsForWorkspace(wsBtn.modelData.id).length > 0
                                ? Appearance.m3colors.m3onSecondaryContainer
                                : Appearance.colors.colOnLayer1Inactive)
                        Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                    }

                    // App icon
                    IconImage {
                        id: wsIcon
                        anchors.centerIn: parent
                        source: wsBtn.iconSource
                        implicitSize: workspaceButtonWidth * 0.69
                        opacity: (Config.options?.bar.workspaces.showAppIcons && wsBtn.repWindow) ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                    }

                    // Workspace index label (shown when alwaysShowNumbers is on)
                    StyledText {
                        anchors.centerIn: parent
                        z: 3
                        opacity: Config.options?.bar.workspaces.alwaysShowNumbers ? 1 : 0
                        visible: opacity > 0
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: wsBtn.modelData.name ?? (wsBtn.index + 1)
                        elide: Text.ElideRight
                        color: wsBtn.isActive
                            ? Appearance.m3colors.m3onPrimary
                            : (NiriData.windowsForWorkspace(wsBtn.modelData.id).length > 0
                                ? Appearance.m3colors.m3onSecondaryContainer
                                : Appearance.colors.colOnLayer1Inactive)
                        Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                    }
                }
            }
        }
    }
}
