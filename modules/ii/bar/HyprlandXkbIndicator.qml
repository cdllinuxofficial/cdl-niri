// Renamed in spirit only — now uses NiriXkb instead of HyprlandXkb.
// File kept as HyprlandXkbIndicator.qml to avoid touching every import site.

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell

Item {
    id: root
    property bool vertical: false
    property color color: Appearance.colors.colOnSurfaceVariant

    readonly property bool multipleLayouts: NiriXkb.layoutCodes.length > 1

    function abbreviateLayoutCode(fullCode) {
        return fullCode.split(':').map(layout => {
            const baseLayout = layout.split('-')[0];
            return baseLayout.slice(0, 4);
        }).join('\n');
    }

    visible: multipleLayouts
    implicitWidth: visible ? (vertical ? 0 : label.implicitWidth) : 0
    implicitHeight: visible ? (vertical ? label.implicitHeight : 0) : 0

    StyledText {
        id: label
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: root.multipleLayouts ? root.abbreviateLayoutCode(NiriXkb.currentLayoutCode) : ""
        font.pixelSize: text.includes("\n") ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.small
        color: root.color
        animateChange: true
    }
}
