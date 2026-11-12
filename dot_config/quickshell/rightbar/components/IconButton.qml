import "../theme"
import QtQuick
import QtQuick.Controls

Button {
    id: button
    property string iconName: ""
    property string description: ""
    property bool selected: false
    property bool loading: false
    hoverEnabled: true
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
    padding: 0
    implicitWidth: Theme.buttonSize
    implicitHeight: Theme.buttonSize
    Accessible.name: description
    background: Rectangle {
        radius: 10
        color: button.down ? Theme.hover : button.selected ? Theme.selected : button.hovered ? Theme.hover : Theme.glassBackground
        border.width: button.activeFocus ? 1 : 0
        border.color: Theme.accent
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }
    contentItem: Item {
        LoadingSpinner {
            anchors.centerIn: parent
            width: 24
            height: 24
            visible: button.loading
            running: button.loading
        }
        Image {
            visible: !button.loading
            anchors.centerIn: parent
            width: 24
            height: 24
            source: "../assets/icons/" + button.iconName + ".svg"
            sourceSize: Qt.size(24, 24)
        }
    }
    ToolTip {
        visible: button.hovered
        delay: 650
        text: button.description
        padding: 10
        contentItem: Text {
            text: button.description
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
