import "../../theme"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ScrollView {
    id: view
    required property var shellRoot
    implicitHeight: Math.min(590, body.implicitHeight)
    clip: true
    contentWidth: availableWidth
    ColumnLayout {
        id: body
        width: view.availableWidth
        spacing: 10
        AudioDeviceCard {
            id: outputCard
            Layout.fillWidth: true
            opacity: inputCard.expanded ? 0.1 : 1
            Behavior on opacity {
                NumberAnimation { duration: 140 }
            }
            title: "Ausgabe"
            node: view.shellRoot.sink
            devices: view.shellRoot.outputs
            onDeviceSelected: device => Pipewire.preferredDefaultAudioSink = device
            onExpandedChanged: {
                if (expanded)
                    inputCard.expanded = false;
            }
        }
        AudioDeviceCard {
            id: inputCard
            Layout.fillWidth: true
            opacity: outputCard.expanded ? 0.1 : 1
            Behavior on opacity {
                NumberAnimation { duration: 140 }
            }
            title: "Eingabe"
            node: view.shellRoot.mic
            devices: view.shellRoot.inputs
            onDeviceSelected: device => Pipewire.preferredDefaultAudioSource = device
            onExpandedChanged: {
                if (expanded)
                    outputCard.expanded = false;
            }
        }
    }
}
