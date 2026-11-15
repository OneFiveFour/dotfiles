import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: view
    required property var shellRoot
    property var pending: null
    property bool force: false
    implicitHeight: Math.min(540, body.implicitHeight)
    clip: true
    contentWidth: availableWidth
    ColumnLayout {
        id: body
        width: view.availableWidth
        spacing: 10
        Text {
            visible: view.pending !== null
            Layout.fillWidth: true
            text: view.pending ? view.pending.name + " wirklich " + (view.force ? "zwangsweise beenden?" : "beenden?") : ""
            wrapMode: Text.Wrap
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 12
            textFormat: Text.PlainText
        }
        Text {
            visible: view.pending !== null
            Layout.fillWidth: true
            text: "Ungespeicherte Änderungen können verloren gehen."
            color: Theme.danger
            font.family: Theme.font
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
        RowLayout {
            visible: view.pending !== null
            ActionButton {
                text: "Abbrechen"
                onClicked: view.pending = null
            }
            ActionButton {
                text: "Bestätigen"
                destructive: true
                onClicked: {
                    view.shellRoot.command({
                        action: "terminate",
                        pid: view.pending.pid,
                        start: view.pending.start,
                        force: view.force
                    });
                    view.pending = null;
                }
            }
        }
        Text {
            visible: view.shellRoot.applications.length === 0 && view.pending === null
            text: "Keine laufenden Apps erkannt."
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 13
        }
        Repeater {
            model: view.pending ? [] : view.shellRoot.applications
            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: appRow.implicitHeight + 24
                radius: 12
                color: Theme.surface
                RowLayout {
                    id: appRow
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.bold: true
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.state + " · PID " + modelData.pid
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                        }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6
                        IconButton {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            iconName: "close"
                            description: "Beenden"
                            onClicked: {
                                view.pending = modelData;
                                view.force = false;
                            }
                        }
                        IconButton {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            iconName: "force-stop"
                            description: "Beenden erzwingen"
                            onClicked: {
                                view.pending = modelData;
                                view.force = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
