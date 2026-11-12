import "../theme"
import QtQuick
import QtQuick.Controls

Slider {
    id: control
    from: 0
    to: 1
    stepSize: 0.01
    implicitHeight: 32
    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        height: 5
        radius: 3
        color: Theme.surface
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 3
            color: Theme.accent
        }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 16
        height: 16
        radius: 8
        color: control.pressed ? Theme.text : Theme.accent
    }
}
