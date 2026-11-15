import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

ColumnLayout {
    id: card
    required property string title
    required property var node
    required property var devices
    property bool expanded: false
    readonly property var audio: node ? node.audio : null
    readonly property real level: audio ? Math.max(0, Math.min(1, audio.volume)) : 0
    signal deviceSelected(var device)
    spacing: 4

    function adjustVolume(value) {
        if (audio)
            audio.volume = Math.max(0, Math.min(1, value));
    }
    onNodeChanged: expanded = false

    Rectangle {
        id: header
        objectName: "audioCardHeader"
        Layout.fillWidth: true
        implicitHeight: 76
        radius: 12
        color: Theme.surface
        clip: true
        activeFocusOnTab: true
        Accessible.role: Accessible.Slider
        Accessible.name: card.title + ": " + deviceName.text
        Accessible.description: "Ziehen: Lautstärke. Klicken: Geräteauswahl. Rechtsklick: stummschalten."

        // Ein abgerundeter Füllbereich bleibt auch bei 0 und 100 Prozent innerhalb der Card.
        Rectangle {
            width: parent.width * card.level
            height: parent.height
            radius: 12
            color: card.audio && card.audio.muted ? Theme.hover : Theme.selected
        }
        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text {
                    text: card.title + (card.audio && card.audio.muted ? " · Stumm" : "")
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 11
                }
                Text {
                    id: deviceName
                    Layout.fillWidth: true
                    text: card.node ? card.node.description || card.node.name : "Kein Gerät verfügbar"
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.bold: true
                }
            }
            Text {
                text: card.audio ? Math.round(card.audio.volume * 100) + " %" : "–"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 13
            }
            Text {
                text: card.expanded ? "▴" : "▾"
                color: Theme.muted
                font.pixelSize: 14
            }
        }
        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            preventStealing: true
            cursorShape: draggingLevel ? Qt.SizeHorCursor : Qt.PointingHandCursor
            property real pressX: 0
            property real pressY: 0
            property real pressLevel: 0
            property bool draggingLevel: false
            onPressed: event => {
                header.forceActiveFocus();
                pressX = event.x;
                pressY = event.y;
                pressLevel = card.level;
                draggingLevel = false;
            }
            onPositionChanged: event => {
                if (!pressed || pressedButtons !== Qt.LeftButton || !card.audio)
                    return;
                if (!draggingLevel && Math.abs(event.x - pressX) >= Qt.styleHints.startDragDistance)
                    draggingLevel = true;
                if (draggingLevel)
                    card.adjustVolume(pressLevel + (event.x - pressX) / width);
            }
            onReleased: event => {
                if (event.button === Qt.RightButton) {
                    if (card.audio)
                        card.audio.muted = !card.audio.muted;
                } else if (!draggingLevel && Math.abs(event.x - pressX) < Qt.styleHints.startDragDistance && Math.abs(event.y - pressY) < Qt.styleHints.startDragDistance) {
                    card.expanded = !card.expanded;
                }
                draggingLevel = false;
            }
            onCanceled: draggingLevel = false
        }
        Keys.onLeftPressed: card.adjustVolume(card.level - 0.02)
        Keys.onRightPressed: card.adjustVolume(card.level + 0.02)
        Keys.onSpacePressed: card.expanded = !card.expanded
        Keys.onReturnPressed: card.expanded = !card.expanded
        Keys.onEscapePressed: event => {
            if (card.expanded)
                card.expanded = false;
            else
                event.accepted = false;
        }
        ToolTip.visible: pointer.containsMouse && !pointer.pressed
        ToolTip.delay: 900
        ToolTip.text: "Ziehen: Lautstärke · Klicken: Gerät wählen · Rechtsklick: stummschalten"
    }
    ColumnLayout {
        Layout.fillWidth: true
        visible: card.expanded
        spacing: 4
        Text {
            visible: card.devices.length === 0
            Layout.fillWidth: true
            Layout.margins: 12
            text: "Keine Geräte verfügbar"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 12
        }
        Repeater {
            model: card.devices
            Button {
                id: choice
                required property var modelData
                readonly property bool current: card.node === modelData
                objectName: "audioDeviceChoice"
                Layout.fillWidth: true
                implicitHeight: Math.max(44, contentItem.implicitHeight + 20)
                padding: 12
                hoverEnabled: true
                text: modelData.description || modelData.name
                contentItem: Text {
                    text: (choice.current ? "✓  " : "") + choice.text
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: choice.current ? Theme.accent : Theme.text
                    font.family: Theme.font
                    font.pixelSize: 12
                }
                background: Rectangle {
                    radius: 10
                    color: choice.down || choice.hovered ? Theme.hover : choice.current ? Theme.selected : Theme.surface
                    border.width: choice.activeFocus ? 1 : 0
                    border.color: Theme.accent
                }
                onClicked: {
                    card.deviceSelected(modelData);
                    card.expanded = false;
                }
            }
        }
    }
}
