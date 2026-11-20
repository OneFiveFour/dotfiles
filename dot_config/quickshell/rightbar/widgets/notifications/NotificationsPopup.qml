import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: view
    required property var shellRoot
    implicitHeight: Math.min(560, body.implicitHeight)
    clip: true
    contentWidth: availableWidth
    ColumnLayout {
        id: body
        width: view.availableWidth
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: Theme.buttonSize
            Text {
                Layout.fillWidth: true
                text: view.shellRoot.history.length === 0 ? "Keine Benachrichtigungen" : ""
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 13
                wrapMode: Text.Wrap
            }
            IconButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter
                iconName: "done-all"
                description: "Alle Benachrichtigungen leeren"
                enabled: view.shellRoot.history.length > 0
                opacity: enabled ? 1 : 0.4
                onClicked: view.shellRoot.clearNotifications()
            }
        }
        Repeater {
            model: view.shellRoot.history
            Rectangle {
                id: notificationCard
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: notificationColumn.implicitHeight + 24
                radius: 12
                color: Theme.surface
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: view.shellRoot.activateNotification(notificationCard.modelData, null)
                }
                ColumnLayout {
                    id: notificationColumn
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 7
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: modelData.appName
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                        ActionButton {
                            text: "×"
                            implicitHeight: 26
                            implicitWidth: 26
                            leftPadding: 0
                            rightPadding: 0
                            onClicked: modelData.dismiss()
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 7
                            Text {
                                Layout.fillWidth: true
                                text: modelData.summary
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.bold: true
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: modelData.body
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText
                            }
                        }
                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.maximumWidth: 110
                            visible: modelData.actions.some(action => (action.text || "").trim().length > 0 || action.identifier === "default")
                            spacing: 6
                            Repeater {
                                model: modelData.actions
                                ActionButton {
                                    required property var modelData
                                    readonly property string actionLabel: (modelData.text || "").trim()
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: 110
                                    Layout.minimumHeight: 40
                                    Layout.preferredHeight: 40
                                    Layout.maximumHeight: 40
                                    visible: actionLabel.length > 0 || modelData.identifier === "default"
                                    text: actionLabel || (modelData.identifier === "default" ? "Öffnen" : "")
                                    onClicked: {
                                        view.shellRoot.activateNotification(notificationCard.modelData, modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
