import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

/**
 * Active window title + app name — niri edition.
 *
 * Uses NiriData.focusedWindow instead of HyprlandData + ToplevelManager.
 * niri exposes title and app_id directly; no address mapping needed.
 *
 * Per-output awareness: only show the focused window when the focused
 * workspace lives on this bar's output.
 */
Item {
    id: root

    readonly property string outputName: QsWindow.window?.screen?.name ?? ""

    // Is the globally focused workspace on this output?
    readonly property bool focusingThisOutput: {
        const fw = NiriData.focusedWorkspace
        return fw !== null && fw.output === root.outputName
    }

    readonly property var focusedWindow: root.focusingThisOutput ? NiriData.focusedWindow : null

    // Fallback: biggest window on the active workspace of this output
    readonly property var activeWorkspace: NiriData.activeWorkspaceForOutput(root.outputName)
    readonly property var fallbackWindow: activeWorkspace
        ? NiriData.representativeWindowForWorkspace(activeWorkspace.id)
        : null

    implicitWidth: colLayout.implicitWidth

    ColumnLayout {
        id: colLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: -4

        // App name / class
        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            text: root.focusedWindow?.app_id
                ?? root.fallbackWindow?.app_id
                ?? Translation.tr("Desktop")
        }

        // Window title
        StyledText {
            Layout.fillWidth: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            text: root.focusedWindow?.title
                ?? root.fallbackWindow?.title
                ?? (root.activeWorkspace?.name
                    ?? (Translation.tr("Workspace") + " " + ((root.activeWorkspace?.idx ?? 0) + 1)))
        }
    }
}
