import QtQuick

// Gemeinsame Hover-Logik für Leistenbutton, Zwischenraum und Popup.
QtObject {
    id: controller
    property bool active: false
    property bool buttonHovered: false
    property bool popupHovered: false
    property int closeDelay: 300
    signal openRequested
    signal closeRequested

    onButtonHoveredChanged: {
        if (buttonHovered) {
            closeTimer.stop();
            if (!active)
                openRequested();
        } else if (active) {
            closeTimer.restart();
        }
    }
    onPopupHoveredChanged: {
        if (active) {
            if (popupHovered)
                closeTimer.stop();
            else
                closeTimer.restart();
        }
    }
    onActiveChanged: {
        if (!active)
            closeTimer.stop();
    }
    property Timer closeTimer: Timer {
        interval: controller.closeDelay
        onTriggered: {
            if (controller.active && !controller.buttonHovered && !controller.popupHovered)
                controller.closeRequested();
        }
    }
}
