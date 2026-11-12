import QtQuick
import QtQuick.Controls
import "../theme"

Item {
    id: indicator
    property var report: null
    readonly property int bars: report ? report.bars : 0
    implicitWidth: 26
    implicitHeight: 24
    visible: report !== null
    Accessible.name: report ? "Akku: " + report.label : "Akkustand unbekannt"
    Image {
        anchors.centerIn: parent
        width: 26
        height: 24
        source: indicator.bars > 0 ? "../assets/icons/battery-" + indicator.bars + ".svg" : ""
        sourceSize: Qt.size(26, 24)
    }
    HoverHandler {
        id: hover
    }
    ToolTip {
        visible: hover.hovered && indicator.report !== null
        delay: 450
        padding: 10
        contentItem: Text {
            text: indicator.report ? "Akku: " + indicator.report.label : ""
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
