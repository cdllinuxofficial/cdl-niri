import qs.services
import QtQuick
import Quickshell
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === NiriData.focusedWorkspace?.output)
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    icon: Hyprsunset.active ? "routine" : "light_mode"
    rotateIcon: true
    scaleIcon: true
    name: Translation.tr("Brightness")
    value: root.brightnessMonitor?.brightness ?? 50
}
