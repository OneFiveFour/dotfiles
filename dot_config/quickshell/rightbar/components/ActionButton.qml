import "../theme"
import QtQuick
import QtQuick.Controls

Button {
    id: control
    property bool destructive: false
    property bool selected: false
    implicitHeight: 40
    hoverEnabled: true
    font.family: Theme.font
    font.pixelSize: 13
    leftPadding: 14
    rightPadding: 14
    background: Rectangle {
        radius: 10
        color: control.down ? Theme.hover : control.hovered ? Theme.hover : control.selected ? Theme.selected : Theme.surface
        border.width: control.activeFocus ? 1 : 0
        border.color: Theme.accent
    }
    contentItem: Text {
        text: control.text
        color: !control.enabled ? Theme.muted : control.destructive ? Theme.danger : Theme.text
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
