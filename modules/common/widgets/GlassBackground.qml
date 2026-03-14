import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.modules.common
import qs.services

/**
 * Frosted glass panel background.
 *
 * Place inside any panel Rectangle. Supply the widget's position on screen
 * so the wallpaper slice aligns with what would be "behind" the panel:
 *
 *   GlassBackground {
 *       anchors.fill: parent
 *       screenX: myPanel.x    // x of parent relative to screen origin
 *       screenY: myPanel.y    // y of parent relative to screen origin
 *       radius: parent.radius
 *   }
 *
 * The parent must have clip: true (or layer.enabled) to crop the result.
 * Only visible when Appearance.glassMode is true.
 */
Rectangle {
    id: root

    property real screenX: 0
    property real screenY: 0
    property real blurIntensity: Config?.options.appearance.glass.blurEnabled ? 1.0 : 0.0
    property real overlayOpacity: 1 - (Config?.options.appearance.glass.backgroundOpacity ?? 0.55)
    property real radius: 0

    visible: Appearance.glassMode
    color: "transparent"

    // Round-corner clip via layer + OpacityMask
    layer.enabled: root.radius > 0
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width:  root.width
            height: root.height
            radius: root.radius
        }
    }

    // Full-screen wallpaper image shifted so only the panel's portion is visible
    Image {
        id: wallpaperImg
        visible: root.blurIntensity > 0
        x: -root.screenX
        y: -root.screenY
        width:  Quickshell.screens[0]?.width  ?? 1920
        height: Quickshell.screens[0]?.height ?? 1080
        source: Config?.options.background.wallpaperPath ?? ""
        fillMode: Image.PreserveAspectCrop
        cache: true

        layer.enabled: root.blurIntensity > 0
        layer.effect: MultiEffect {
            blurEnabled: root.blurIntensity > 0
            blurMax: 64
            blur: root.blurIntensity
            saturation: 0.15
        }
    }

    // Semi-transparent color overlay (tinted with theme colour)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            Appearance.colors.colLayer0Base.r,
            Appearance.colors.colLayer0Base.g,
            Appearance.colors.colLayer0Base.b,
            root.overlayOpacity
        )
    }
}
