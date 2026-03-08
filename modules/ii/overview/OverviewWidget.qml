import QtQuick

// Niri port stub — HyprlandMonitor type and all HyprlandData/Hyprland.dispatch
// calls from the original are incompatible with niri. This file is never
// instantiated (Overview.qml delegates to niri native toggle-overview), but
// must parse cleanly without import Quickshell.Hyprland.
Item {}
