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
            ActionButton {
                Layout.fillWidth: true
                text: view.shellRoot.doNotDisturb ? "Nicht stören: an" : "Nicht stören: aus"
                selected: view.shellRoot.doNotDisturb
                onClicked: view.shellRoot.doNotDisturb = !view.shellRoot.doNotDisturb
            }
            ActionButton {
                text: "Leeren"
                enabled: view.shellRoot.history.length > 0
                onClicked: view.shellRoot.clearNotifications()
            }
        }
        Text {
            visible: view.shellRoot.history.length === 0
            Layout.fillWidth: true
            text: "Keine Benachrichtigungen"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 13
            topPadding: 16
            bottomPadding: 16
        }
        Repeater {
            model: view.shellRoot.history
            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: notificationColumn.implicitHeight + 24
                radius: 12
                color: Theme.surface
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
                    Flow {
                        Layout.fillWidth: true
                        height: childrenRect.height
                        spacing: 6
                        Repeater {
                            model: modelData.actions
                            ActionButton {
                                required property var modelData
                                text: modelData.text
                                onClicked: {
                                    modelData.invoke();
                                    view.shellRoot.closePopup();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
