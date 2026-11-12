import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../theme"
import "../../components"
import "BluetoothIcons.js" as DeviceIcons
import "BatteryModel.js" as Batteries

Rectangle {
    id: card
    required property var device
    property var batteryReports: ({})
    readonly property var batteryReport: Batteries.forDevice(device, batteryReports)
    implicitHeight: body.implicitHeight + 24
    radius: 12
    color: Theme.surface

    RowLayout {
        id: body
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7

            Row {
                id: nameRow
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(24, deviceName.implicitHeight)
                spacing: 10

                Image {
                    width: 24
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter
                    source: "../../assets/icons/" + DeviceIcons.forDevice(card.device) + ".svg"
                    sourceSize: Qt.size(24, 24)
                }
                Text {
                    id: deviceName
                    width: Math.max(0, Math.min(implicitWidth, nameRow.width - 34 - (card.batteryReport ? 36 : 0)))
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.device.name || card.device.address
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.bold: true
                }
                BatteryIndicator {
                    width: 26
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter
                    report: card.batteryReport
                }
            }
            Text {
                Layout.fillWidth: true
                text: card.device.connected ? "Verbunden" : card.device.pairing ? "Kopplung läuft …" : card.device.state === BluetoothDeviceState.Connecting ? "Verbindung wird hergestellt …" : card.device.paired ? "Gekoppelt" : "Nicht gekoppelt"
                color: card.device.connected ? Theme.accent : Theme.muted
                font.family: Theme.font
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }
        IconButton {
            visible: !card.device.connected
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            iconName: card.device.pairing ? "close" : "connect"
            description: card.device.pairing ? "Kopplung abbrechen" : card.device.paired ? "Verbinden" : "Koppeln"
            loading: !card.device.pairing && card.device.state === BluetoothDeviceState.Connecting
            onClicked: {
                if (card.device.pairing)
                    card.device.cancelPair();
                else if (card.device.paired)
                    card.device.connect();
                else
                    card.device.pair();
            }
        }
    }
}
