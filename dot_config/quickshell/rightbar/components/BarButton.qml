import "../theme"
import QtQuick
import QtQuick.Controls

Rectangle {
    id: button
    property string icon: ""
    property string label: ""
    property bool selected: false
    property bool marked: false
    readonly property bool hovered: mouse.containsMouse
    signal clicked
    signal rightClicked
    signal scrolled(real delta)
    width: Theme.buttonSize
    height: Theme.buttonSize
    radius: 14
    color: selected ? Theme.selected : mouse.containsMouse ? Theme.surface : "transparent"
    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }
    Image {
        anchors.centerIn: parent
        width: 24
        height: 24
        source: "../assets/icons/" + button.icon + ".svg"
        sourceSize: Qt.size(24, 24)
    }
    Rectangle {
        visible: button.marked
        width: 6
        height: 6
        radius: 3
        color: Theme.accent
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => event.button === Qt.RightButton ? button.rightClicked() : button.clicked()
        onWheel: event => button.scrolled(event.angleDelta.y)
    }
    ToolTip {
        visible: mouse.containsMouse && !button.selected
        delay: 650
        text: button.label
        padding: 10
        contentItem: Text {
            text: button.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 12
        }
        background: Rectangle {
            color: Theme.panel
            radius: 8
            border.width: 1
            border.color: Theme.border
        }
    }
}
