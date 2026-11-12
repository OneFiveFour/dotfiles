import "../../theme"
import "../../components"
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
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Ausgabe"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
            }
            Text {
                text: view.shellRoot.sink && view.shellRoot.sink.audio ? Math.round(view.shellRoot.sink.audio.volume * 100) + " %" : "Kein Gerät"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 13
            }
        }
        StyledSlider {
            Layout.fillWidth: true
            enabled: !!view.shellRoot.sink
            value: view.shellRoot.sink && view.shellRoot.sink.audio ? view.shellRoot.sink.audio.volume : 0
            onMoved: {
                if (view.shellRoot.sink && view.shellRoot.sink.audio)
                    view.shellRoot.sink.audio.volume = value;
            }
        }
        ActionButton {
            Layout.fillWidth: true
            enabled: !!view.shellRoot.sink
            text: view.shellRoot.sink && view.shellRoot.sink.audio && view.shellRoot.sink.audio.muted ? "Ton einschalten" : "Stummschalten"
            onClicked: {
                if (view.shellRoot.sink && view.shellRoot.sink.audio)
                    view.shellRoot.sink.audio.muted = !view.shellRoot.sink.audio.muted;
            }
        }
        Repeater {
            model: view.shellRoot.outputs
            ActionButton {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.description || modelData.name
                selected: view.shellRoot.sink === modelData
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
            Layout.topMargin: 6
            Layout.bottomMargin: 6
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Mikrofon"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
            }
            Text {
                text: view.shellRoot.mic && view.shellRoot.mic.audio ? Math.round(view.shellRoot.mic.audio.volume * 100) + " %" : "Kein Gerät"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 13
            }
        }
        StyledSlider {
            Layout.fillWidth: true
            enabled: !!view.shellRoot.mic
            value: view.shellRoot.mic && view.shellRoot.mic.audio ? view.shellRoot.mic.audio.volume : 0
            onMoved: {
                if (view.shellRoot.mic && view.shellRoot.mic.audio)
                    view.shellRoot.mic.audio.volume = value;
            }
        }
        ActionButton {
            Layout.fillWidth: true
            enabled: !!view.shellRoot.mic
            text: view.shellRoot.mic && view.shellRoot.mic.audio && view.shellRoot.mic.audio.muted ? "Mikrofon einschalten" : "Mikrofon stummschalten"
            onClicked: {
                if (view.shellRoot.mic && view.shellRoot.mic.audio)
                    view.shellRoot.mic.audio.muted = !view.shellRoot.mic.audio.muted;
            }
        }
        Repeater {
            model: view.shellRoot.inputs
            ActionButton {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.description || modelData.name
                selected: view.shellRoot.mic === modelData
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }
}
