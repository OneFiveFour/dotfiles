import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import "BluetoothIcons.js" as DeviceIcons

ScrollView {
    id: view
    required property var shellRoot
    property var adapter: shellRoot.adapter
    property var devices: adapter ? adapter.devices.values.slice().sort((a, b) => (Number(b.connected) - Number(a.connected)) || (Number(b.paired) - Number(a.paired)) || a.name.localeCompare(b.name)) : []
    property bool scanOwned: false
    implicitHeight: Math.min(580, body.implicitHeight)
    clip: true
    contentWidth: availableWidth
    Component.onDestruction: {
        if (scanOwned && adapter)
            adapter.discovering = false;
    }
    Timer {
        interval: 20000
        running: view.scanOwned
        onTriggered: {
            if (view.adapter)
                view.adapter.discovering = false;
            view.scanOwned = false;
        }
    }
    ColumnLayout {
        id: body
        width: view.availableWidth
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            IconButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                iconName: "search"
                loading: !!view.adapter && view.adapter.discovering
                description: view.adapter && view.adapter.discovering ? "Suche stoppen" : "Geräte suchen"
                selected: !!view.adapter && view.adapter.discovering
                enabled: !!view.adapter && view.adapter.enabled
                opacity: enabled ? 1 : 0.4
                onClicked: {
                    view.adapter.discovering = !view.adapter.discovering;
                    view.scanOwned = view.adapter.discovering;
                }
            }
            Item {
                Layout.fillWidth: true
            }
        }
        Text {
            visible: !view.adapter
            Layout.fillWidth: true
            text: "Kein Bluetooth-Adapter verfügbar"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 12
        }
        Rectangle {
            visible: view.shellRoot.pairRequest !== null
            Layout.fillWidth: true
            implicitHeight: pairColumn.implicitHeight + 24
            radius: 12
            color: Theme.surface
            ColumnLayout {
                id: pairColumn
                x: 12
                y: 12
                width: parent.width - 24
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: view.shellRoot.pairRequest ? view.shellRoot.pairRequest.text : ""
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }
                TextField {
                    id: pin
                    visible: !!view.shellRoot.pairRequest && ["pin", "passkey"].includes(view.shellRoot.pairRequest.mode)
                    Layout.fillWidth: true
                    placeholderText: "Kopplungscode"
                    color: Theme.text
                    font.family: Theme.font
                    background: Rectangle {
                        radius: 8
                        color: Theme.background
                        border.color: Theme.border
                        border.width: 1
                    }
                }
                RowLayout {
                    visible: !!view.shellRoot.pairRequest && view.shellRoot.pairRequest.mode !== "display"
                    ActionButton {
                        text: "Ablehnen"
                        onClicked: view.shellRoot.command({
                            action: "pair-response",
                            accept: false
                        })
                    }
                    ActionButton {
                        text: "Bestätigen"
                        onClicked: {
                            view.shellRoot.command({
                                action: "pair-response",
                                accept: true,
                                value: pin.text
                            });
                            pin.text = "";
                        }
                    }
                }
            }
        }
        Text {
            visible: view.devices.length === 0
            Layout.fillWidth: true
            text: "Noch keine Geräte. Schalte Bluetooth ein und starte die Suche."
            wrapMode: Text.Wrap
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 13
        }
        Repeater {
            model: view.devices
            BluetoothDeviceCard {
                required property var modelData
                Layout.fillWidth: true
                device: modelData
                batteryReports: view.shellRoot.batteryReports
            }
        }
    }
}
