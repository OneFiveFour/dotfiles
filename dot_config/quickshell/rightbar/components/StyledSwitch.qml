import "../theme"
import QtQuick
import QtQuick.Controls

Switch {
    id: control
    implicitWidth: 48
    implicitHeight: 28
    padding: 0
    spacing: 0
    hoverEnabled: true
    opacity: enabled ? 1 : 0.4
    HoverHandler {
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    indicator: Rectangle {
        implicitWidth: 48
        implicitHeight: 28
        radius: 14
        color: control.checked ? Theme.selected : Theme.surface
        border.width: 1
        border.color: control.checked ? Theme.accent : Theme.border
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
        Rectangle {
            x: control.checked ? parent.width - width - 4 : 4
            y: 4
            width: 20
            height: 20
            radius: 10
            color: control.checked ? Theme.accent : Theme.muted
            Behavior on x {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
    contentItem: Item {}
}
