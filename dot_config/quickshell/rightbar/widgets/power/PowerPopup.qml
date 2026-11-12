import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

Item {
    id: view
    required property var shellRoot
    property bool pendingLogout: false
    implicitWidth: pendingLogout ? 240 : 2 * Theme.buttonSize + 12
    implicitHeight: body.implicitHeight
    function buttonPositions() {
        const lock = lockAction.mapToItem(view, 0, 0);
        const logout = logoutAction.mapToItem(view, 0, 0);
        return {
            lock: {
                x: lock.x,
                y: lock.y,
                size: lockAction.width
            },
            logout: {
                x: logout.x,
                y: logout.y,
                size: logoutAction.width
            }
        };
    }
    ColumnLayout {
        id: body
        width: parent.width
        spacing: 12
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 12
            IconButton {
                id: lockAction
                Layout.preferredWidth: Theme.buttonSize
                Layout.preferredHeight: Theme.buttonSize
                Layout.maximumWidth: Theme.buttonSize
                Layout.maximumHeight: Theme.buttonSize
                iconName: "lock"
                description: "Bildschirm sperren"
                onClicked: {
                    view.shellRoot.command({
                        action: "lock"
                    });
                    view.shellRoot.closePopup();
                }
            }
            IconButton {
                id: logoutAction
                Layout.preferredWidth: Theme.buttonSize
                Layout.preferredHeight: Theme.buttonSize
                Layout.maximumWidth: Theme.buttonSize
                Layout.maximumHeight: Theme.buttonSize
                iconName: "logout"
                description: "Abmelden"
                selected: view.pendingLogout
                onClicked: view.pendingLogout = !view.pendingLogout
            }
        }
        Text {
            visible: view.pendingLogout
            Layout.fillWidth: true
            text: "Von Hyprland abmelden?"
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: 13
            wrapMode: Text.Wrap
        }
        RowLayout {
            visible: view.pendingLogout
            Layout.fillWidth: true
            spacing: 8
            ActionButton {
                Layout.fillWidth: true
                text: "Abbrechen"
                onClicked: view.pendingLogout = false
            }
            ActionButton {
                Layout.fillWidth: true
                text: "Bestätigen"
                destructive: true
                onClicked: {
                    view.shellRoot.command({
                        action: "logout"
                    });
                    view.shellRoot.closePopup();
                }
            }
        }
    }
}
