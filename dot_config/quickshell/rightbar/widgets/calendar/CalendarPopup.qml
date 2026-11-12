import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

Item {
    id: view
    property date today: new Date()
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selected: today
    readonly property var months: ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"]
    readonly property int offset: (month.getDay() + 6) % 7
    implicitHeight: body.implicitHeight
    function shift(delta) {
        month = new Date(month.getFullYear(), month.getMonth() + delta, 1);
    }
    ColumnLayout {
        id: body
        width: parent.width
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            ActionButton {
                text: "‹"
                implicitWidth: 36
                onClicked: view.shift(-1)
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: view.months[view.month.getMonth()] + " " + view.month.getFullYear()
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 14
                font.bold: true
            }
            ActionButton {
                text: "›"
                implicitWidth: 36
                onClicked: view.shift(1)
            }
        }
        GridLayout {
            columns: 7
            rowSpacing: 4
            columnSpacing: 4
            Layout.fillWidth: true
            Repeater {
                model: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
                Text {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }
            Repeater {
                model: 42
                Rectangle {
                    required property int index
                    readonly property date dateValue: new Date(view.month.getFullYear(), view.month.getMonth(), index - view.offset + 1)
                    readonly property bool current: dateValue.toDateString() === view.today.toDateString()
                    readonly property bool picked: dateValue.toDateString() === view.selected.toDateString()
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    radius: 9
                    color: picked ? Theme.selected : dayMouse.containsMouse ? Theme.surface : "transparent"
                    border.color: current ? Theme.accent : "transparent"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: parent.dateValue.getDate()
                        color: parent.dateValue.getMonth() === view.month.getMonth() ? Theme.text : Theme.muted
                        opacity: parent.dateValue.getMonth() === view.month.getMonth() ? 1 : 0.45
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: view.selected = parent.dateValue
                    }
                }
            }
        }
        ActionButton {
            Layout.fillWidth: true
            text: "Heute"
            onClicked: {
                view.today = new Date();
                view.selected = view.today;
                view.month = new Date(view.today.getFullYear(), view.today.getMonth(), 1);
            }
        }
    }
}
