pragma Singleton
import QtQuick

QtObject {
    readonly property color background: "#171b24"
    readonly property color panel: glassBackground
    readonly property color surface: Qt.rgba(0.169, 0.200, 0.263, 0.38)
    readonly property color hover: Qt.rgba(0.216, 0.259, 0.349, 0.60)
    readonly property color selected: Qt.rgba(0.259, 0.294, 0.439, 0.65)
    readonly property color border: "#3d485e"
    readonly property color text: "#d9deed"
    readonly property color muted: "#9ba8c1"
    readonly property color accent: "#b5bdf9"
    readonly property color danger: "#f5a5af"
    readonly property string font: "Noto Sans"
    readonly property int barWidth: 76
    readonly property int buttonSize: 52
    readonly property int radius: 16
    // Gemeinsamer Glashintergrund fuer Inseln, Popups und Benachrichtigungen.
    // Deckkraft 0 = transparent, 1 = undurchsichtig.
    readonly property real glassOpacity: 0.48
    readonly property color glassBackground: Qt.rgba(background.r, background.g, background.b, glassOpacity)
    readonly property real islandOpacity: glassOpacity
    readonly property int islandInset: 6
    readonly property int islandPadding: 6
    readonly property int islandRadius: 18
    readonly property color islandBackground: Qt.rgba(background.r, background.g, background.b, islandOpacity)
    readonly property color islandBorder: Qt.rgba(1, 1, 1, 0.12)
}
