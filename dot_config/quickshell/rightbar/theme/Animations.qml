pragma Singleton
import QtQuick

QtObject {
    // false oder "none": sofort anzeigen, ohne Animation.
    readonly property bool enabled: true
    // Verfügbare Varianten: "slide", "fade", "none".
    readonly property string popupStyle: "slide"
    readonly property int popupDuration: 180
    readonly property int popupEasing: Easing.OutCubic
    // 0: ganze Popup-Breite; positiver Wert: feste Strecke in Pixeln.
    readonly property real popupDistance: 0
}
