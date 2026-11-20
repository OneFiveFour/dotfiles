import "../theme"
import "../animations"
import "../components"
import "../widgets/power"
import "../widgets/bluetooth"
import "../widgets/sound"
import "../widgets/notifications"
import "../widgets/notifications/NotificationActions.js" as NotificationActions
import "../widgets/apps"
import "../widgets/calendar"
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications

ShellRoot {
    id: root
    property var targetScreen: Quickshell.screens.find(s => s.name === "DP-4") ?? null
    property string popupName: ""
    property var anchorButton: notificationButton
    property var applications: []
    property var batteryReports: ({})
    property string errorText: ""
    property var pairRequest: null
    property bool agentReady: false
    property bool doNotDisturb: false
    property var toast: null
    property var adapter: Bluetooth.defaultAdapter
    property var sink: Pipewire.defaultAudioSink
    property var mic: Pipewire.defaultAudioSource
    property var outputs: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    property var inputs: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    property var history: notificationServer.trackedNotifications.values.slice().reverse()
    property var now: new Date()
    readonly property var monthNames: ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]
    readonly property var popupTitles: ({
            power: "",
            bluetooth: "Bluetooth",
            notifications: "Benachrichtigungen",
            sound: "Sound",
            apps: "Laufende Apps",
            calendar: "Kalender"
        })
    function command(data) {
        if (backend.running)
            backend.write(JSON.stringify(data) + "\n");
    }
    function closePopup() {
        popupName = "";
    }
    function openPopup(name, button) {
        if (popupName === name) {
            closePopup();
            return;
        }
        anchorButton = button;
        errorText = "";
        popupName = name;
        if (name === "apps")
            command({
                action: "refresh"
            });
    }
    function showByName(name) {
        const buttons = {
            power: powerButton,
            bluetooth: bluetoothButton,
            notifications: notificationButton,
            sound: soundButton,
            apps: appsButton,
            calendar: clockButton
        };
        if (buttons[name])
            openPopup(name, buttons[name]);
    }
    // Nur explizite Bedienung startet den Hinweis, keine PipeWire-Hintergrundupdates.
    readonly property real outputLevel: sink && sink.audio ? Math.max(0, Math.min(1, sink.audio.volume)) : 0
    function volumeInput() {
        if (popupName !== "sound" && sink && sink.audio)
            volumeHintTimer.restart();
    }
    onPopupNameChanged: {
        if (popupName === "sound")
            volumeHintTimer.stop();
    }
    onSinkChanged: volumeHintTimer.stop()
    Timer {
        id: volumeHintTimer
        interval: 1000
    }
    function volumeStep(delta) {
        if (sink && sink.audio) {
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (delta > 0 ? 0.02 : -0.02)));
            volumeInput();
        }
    }
    function clearNotifications() {
        history.slice().forEach(n => n.dismiss());
    }
    function activateNotification(notification, action) {
        if (notification)
            console.info("Notification activation:", notification.id, notification.appName,
                "desktop=" + notification.desktopEntry,
                "action=" + (action ? action.identifier : "card"));
        NotificationActions.activate(notification, action, function() {
            root.toast = null;
            root.closePopup();
        }, callback => Qt.callLater(callback), data => root.command(data));
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }
    Process {
        id: backend
        command: ["python3", Qt.resolvedUrl("../backend/main.py").toString().replace("file://", "")]
        stdinEnabled: true
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    if (data.kind === "apps")
                        root.applications = data.apps;
                    else if (data.kind === "battery")
                        root.batteryReports = data.reports;
                    else if (data.kind === "error")
                        root.errorText = data.text;
                    else if (data.kind === "notification-error") {
                        if (root.popupName !== "notifications")
                            root.openPopup("notifications", notificationButton);
                        root.errorText = data.text;
                    }
                    else if (data.kind === "agent-ready")
                        root.agentReady = true;
                    else if (data.kind === "pair") {
                        root.pairRequest = data;
                        if (root.popupName !== "bluetooth")
                            root.openPopup("bluetooth", bluetoothButton);
                    } else if (data.kind === "pair-clear")
                        root.pairRequest = null;
                } catch (e) {
                    console.warn("Backend:", e);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.errorText = "Die App-Verwaltung wurde beendet. Die Leiste bitte neu starten.";
        }
    }
    NotificationServer {
        id: notificationServer
        bodySupported: true
        actionsSupported: true
        persistenceSupported: true
        onNotification: notification => {
            notification.tracked = true;
            if (!root.doNotDisturb && !notification.lastGeneration) {
                root.toast = notification;
                toastTimer.restart();
            }
        }
    }
    Timer {
        id: toastTimer
        interval: 8000
        onTriggered: root.toast = null
    }
    IpcHandler {
        target: "panel"
        function toggle(name: string): void {
            root.showByName(name);
        }
        function close(): void {
            root.closePopup();
        }
        function status(): string {
            return JSON.stringify({
                popup: root.popupName,
                apps: root.applications.length,
                notifications: root.history.length,
                audio: !!root.sink,
                bluetooth: !!root.adapter,
                agent: root.agentReady,
                dnd: root.doNotDisturb,
                error: root.errorText
            });
        }
        function notificationStatus(): string {
            return JSON.stringify(root.history.map(n => ({
                id: n.id, appName: n.appName, desktopEntry: n.desktopEntry,
                appIcon: n.appIcon, resident: n.resident,
                actions: n.actions.map(a => ({identifier: a.identifier, text: a.text}))
            })));
        }
        function openNotification(id: int): bool {
            const notification = root.history.find(n => n.id === id);
            if (!notification)
                return false;
            root.activateNotification(notification, null);
            return true;
        }
        function volumeInput(): void {
            root.volumeInput();
        }
        function volumeHintStatus(): string {
            return JSON.stringify({ active: volumeHintTimer.running, level: root.outputLevel,
                opacity: volumeFill.opacity, fillHeight: volumeFill.height,
                availableHeight: topIsland.height - 2, popup: root.popupName });
        }
        function batteryStatus(): string {
            return JSON.stringify(root.batteryReports);
        }
        function motionStatus(): string {
            return JSON.stringify({
                active: popup.visible,
                style: popupMotion.style,
                enabled: popupMotion.enabled,
                progress: popupMotion.progress,
                offset: popupMotion.offsetX,
                opacity: popupMotion.alpha,
                running: popupMotion.running
            });
        }
        function powerLayout(): string {
            const barPoint = powerButton.mapToItem(bar.contentItem, 0, 0);
            const buttons = root.popupName === "power" && view.item ? view.item.buttonPositions() : null;
            if (buttons) {
                for (const key of ["lock", "logout"]) {
                    buttons[key].x += popupCard.x + view.x + popupMotion.offsetX;
                    buttons[key].y += popupCard.y + view.y;
                }
            }
            return JSON.stringify({
                powerInBar: {
                    x: barPoint.x,
                    y: barPoint.y,
                    size: powerButton.width
                },
                buttonsInPopup: buttons
            });
        }
        function capture(path: string): void {
            barVisual.grabToImage(result => result.saveToFile(path + "-bar.png"));
            if (popup.visible)
                popupCard.grabToImage(result => result.saveToFile(path + "-popup.png"));
        }
    }
    PanelWindow {
        id: bar
        screen: root.targetScreen
        visible: root.targetScreen !== null
        anchors {
            top: true
            bottom: true
            right: true
        }
        implicitWidth: Theme.barWidth
        color: "transparent"
        WlrLayershell.namespace: "rightbar"
        // Zwischen den Inseln werden Mausklicks an die Oberfläche darunter weitergegeben.
        mask: Region {
            item: topIsland
            radius: Theme.islandRadius
            Region {
                item: bottomIsland
                radius: Theme.islandRadius
            }
        }
        Item {
            id: barVisual
            anchors.fill: parent
            BarIsland {
                id: topIsland
                x: Theme.islandInset
                y: topButtons.y - Theme.islandPadding
                width: parent.width - 2 * Theme.islandInset
                height: topButtons.height + 2 * Theme.islandPadding
                // Hinter den Icons: Füllstand wächst von der Inselunterkante nach oben.
                Rectangle {
                    id: volumeFill
                    x: 1
                    y: topIsland.height - 1 - height
                    width: topIsland.width - 2
                    height: (topIsland.height - 2) * root.outputLevel
                    radius: Math.min(Theme.islandRadius - 1, height / 2)
                    // Gleicher Farbton wie im Sound-Popup, mit klarerer Deckkraft.
                    readonly property color fillTint: root.sink && root.sink.audio && root.sink.audio.muted ? Theme.hover : Theme.selected
                    color: Qt.rgba(fillTint.r, fillTint.g, fillTint.b, 1.0)
                    opacity: volumeHintTimer.running && root.popupName !== "sound" ? 1 : 0
                    visible: opacity > 0
                    Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }
            }
            BarIsland {
                id: bottomIsland
                x: Theme.islandInset
                y: bottomButtons.y - Theme.islandPadding
                width: parent.width - 2 * Theme.islandInset
                height: bottomButtons.height + 2 * Theme.islandPadding
            }
            Column {
                id: topButtons
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                BarButton {
                    id: powerButton
                    icon: "power"
                    label: "Klick: Ausschalten · Hover: Sperren / Abmelden"
                    selected: root.popupName === "power"
                    color: hovered ? Theme.surface : "transparent"
                    onClicked: {
                        root.command({
                            action: "poweroff"
                        });
                        root.closePopup();
                    }
                }
                BarButton {
                    id: bluetoothButton
                    icon: root.adapter && root.adapter.enabled ? "bluetooth" : "bluetooth-off"
                    label: root.adapter && root.adapter.enabled ? "Klick: Bluetooth ausschalten · Hover: Geräte" : "Klick: Bluetooth einschalten · Hover: Geräte"
                    selected: root.popupName === "bluetooth"
                    color: hovered ? Theme.surface : "transparent"
                    onClicked: {
                        if (root.adapter)
                            root.adapter.enabled = !root.adapter.enabled;
                        root.closePopup();
                    }
                    opacity: root.adapter && root.adapter.enabled ? 1 : 0.55
                }
                BarButton {
                    id: notificationButton
                    icon: root.doNotDisturb ? "notifications-off" : "notifications"
                    label: root.doNotDisturb ? "Klick: Nicht stören ausschalten · Hover: Benachrichtigungen" : "Klick: Nicht stören einschalten · Hover: Benachrichtigungen"
                    marked: root.history.length > 0
                    selected: root.popupName === "notifications"
                    color: hovered ? Theme.surface : "transparent"
                    onClicked: {
                        root.doNotDisturb = !root.doNotDisturb;
                        if (root.doNotDisturb)
                            root.toast = null;
                    }
                }
                BarButton {
                    id: soundButton
                    icon: root.sink && root.sink.audio && root.sink.audio.muted ? "muted" : "volume"
                    label: root.sink && root.sink.audio ? (root.sink.audio.muted ? "Klick: Ausgabe und Eingabe aktivieren" : "Klick: Ausgabe und Eingabe stummschalten") + " · Hover: Sound · Lautstärke: " + Math.round(root.sink.audio.volume * 100) + "%" : "Kein Ausgabegerät · Hover: Sound"
                    selected: root.popupName === "sound"
                    color: hovered ? Theme.surface : "transparent"
                    onClicked: {
                        const output = root.sink ? root.sink.audio : null;
                        const input = root.mic ? root.mic.audio : null;
                        const muted = output ? !output.muted : input ? !input.muted : false;
                        if (output)
                            output.muted = muted;
                        if (input)
                            input.muted = muted;
                    }
                    onScrolled: delta => root.volumeStep(delta)
                }
            }
            Column {
                id: bottomButtons
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                BarButton {
                    id: appsButton
                    icon: "apps"
                    label: "Laufende Apps"
                    selected: root.popupName === "apps"
                    onClicked: root.openPopup("apps", this)
                }
                Rectangle {
                    id: clockButton
                    width: Theme.buttonSize
                    height: 64
                    radius: 14
                    color: root.popupName === "calendar" ? Theme.selected : clockMouse.containsMouse ? Theme.surface : "transparent"
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.now.getDate() + ". " + root.monthNames[root.now.getMonth()]
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(root.now, "HH:mm")
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                    }
                    MouseArea {
                        id: clockMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openPopup("calendar", clockButton)
                    }
                }
            }
        }
    }
    HoverPopupController {
        active: root.popupName === "power"
        buttonHovered: powerButton.hovered
        popupHovered: popupHover.hovered
        onOpenRequested: root.openPopup("power", powerButton)
        onCloseRequested: root.closePopup()
    }
    HoverPopupController {
        active: root.popupName === "bluetooth"
        buttonHovered: bluetoothButton.hovered
        popupHovered: popupHover.hovered
        onOpenRequested: root.openPopup("bluetooth", bluetoothButton)
        onCloseRequested: root.closePopup()
    }
    HoverPopupController {
        active: root.popupName === "notifications"
        buttonHovered: notificationButton.hovered
        popupHovered: popupHover.hovered
        onOpenRequested: root.openPopup("notifications", notificationButton)
        onCloseRequested: root.closePopup()
    }
    HoverPopupController {
        active: root.popupName === "sound"
        buttonHovered: soundButton.hovered
        popupHovered: popupHover.hovered
        onOpenRequested: root.openPopup("sound", soundButton)
        onCloseRequested: root.closePopup()
    }
    HoverPopupController {
        active: root.popupName === "apps"
        buttonHovered: appsButton.hovered
        popupHovered: popupHover.hovered
        onOpenRequested: root.openPopup("apps", appsButton)
        onCloseRequested: root.closePopup()
    }
    HoverPopupController {
        active: root.popupName === "calendar"
        buttonHovered: clockMouse.containsMouse
        popupHovered: popupHover.hovered
        onOpenRequested: root.openPopup("calendar", clockButton)
        onCloseRequested: root.closePopup()
    }
    PanelWindow {
        id: popup
        screen: root.targetScreen
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        margins.right: Theme.barWidth
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "rightbar-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"
        visible: root.popupName !== "" && root.targetScreen !== null
        onVisibleChanged: {
            if (visible)
                focusArea.forceActiveFocus();
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.closePopup()
        }
        Rectangle {
            id: popupCard
            HoverHandler {
                id: popupHover
            }
            // Animation bleibt unabhängig von Layout, Inhalt und Positionierung.
            transform: Translate {
                x: popupMotion.offsetX
            }
            opacity: popupMotion.alpha
            PopupMotion {
                id: popupMotion
                targetItem: popupCard
                active: popup.visible
                revealKey: root.popupName
            }
            readonly property bool powerMenu: root.popupName === "power"
            readonly property real insetX: powerMenu ? 0 : 20
            // Ohne sichtbare Card die Power-Buttons direkt an der Button-Oberkante ausrichten.
            readonly property real insetY: compactPower ? 0 : powerMenu ? 8 : 20
            readonly property bool compactPower: powerMenu && view.item && !view.item.pendingLogout && root.errorText === ""
            width: powerMenu ? Math.max(2 * Theme.buttonSize + 12, view.item ? view.item.implicitWidth : 0) : 390
            height: Math.min(popup.height - 24, Math.max(powerMenu ? 0 : 80, (view.item ? view.item.implicitHeight : 100) + 2 * insetY + (root.errorText ? errorLabel.implicitHeight + 12 : 0)))
            anchors.right: parent.right
            // Leistenbutton beginnt 12px rechts vom Leistenrand: gleicher Abstand wie in der Reihe.
            anchors.rightMargin: powerMenu ? 0 : 10
            y: {
                const button = root.anchorButton;
                const point = button ? button.mapToItem(bar.contentItem, 0, 0) : Qt.point(0, 100);
                // Oben die erste Inhaltszeile, unten weiterhin die Card-Unterkante ausrichten.
                const bottomAligned = button === appsButton || button === clockButton;
                const desiredY = bottomAligned ? point.y + button.height - height : point.y - insetY;
                return Math.round(Math.max(powerMenu ? 0 : 10, Math.min(popup.height - height - (powerMenu ? 0 : 10), desiredY)));
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }
            color: compactPower ? "transparent" : Theme.panel
            radius: Theme.radius
            border.color: Theme.islandBorder
            border.width: compactPower ? 0 : 1
            FocusScope {
                id: focusArea
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.closePopup()
                Text {
                    id: errorLabel
                    x: popupCard.insetX
                    y: popupCard.insetY
                    width: parent.width - 2 * popupCard.insetX
                    visible: root.errorText !== ""
                    text: root.errorText
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Theme.danger
                    font.family: Theme.font
                    font.pixelSize: 12
                }
                Loader {
                    id: view
                    x: popupCard.insetX
                    y: root.errorText !== "" ? errorLabel.y + errorLabel.height + 12 : popupCard.insetY
                    width: parent.width - 2 * popupCard.insetX
                    height: parent.height - y - popupCard.insetY
                    sourceComponent: ({
                            power: powerComponent,
                            bluetooth: bluetoothComponent,
                            notifications: notificationComponent,
                            sound: soundComponent,
                            apps: appsComponent,
                            calendar: calendarComponent
                        })[root.popupName] ?? null
                }
            }
        }
    }
    Component {
        id: powerComponent
        PowerPopup {
            shellRoot: root
        }
    }
    Component {
        id: bluetoothComponent
        BluetoothPopup {
            shellRoot: root
        }
    }
    Component {
        id: notificationComponent
        NotificationsPopup {
            shellRoot: root
        }
    }
    Component {
        id: soundComponent
        SoundPopup {
            shellRoot: root
        }
    }
    Component {
        id: appsComponent
        AppsPopup {
            shellRoot: root
        }
    }
    Component {
        id: calendarComponent
        CalendarPopup {}
    }
    PanelWindow {
        id: toastWindow
        screen: bar.screen
        anchors {
            top: true
            right: true
        }
        margins {
            top: 16
            right: 88
        }
        implicitWidth: 360
        implicitHeight: toastContent.implicitHeight + 32
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: root.toast !== null && root.popupName !== "notifications" && bar.visible
        WlrLayershell.namespace: "rightbar-toast"
        Rectangle {
            anchors.fill: parent
            color: Theme.panel
            radius: Theme.radius
            border.color: Theme.islandBorder
            border.width: 1
            Column {
                id: toastContent
                x: 16
                y: 16
                width: parent.width - 32
                spacing: 8
                Text {
                    width: parent.width
                    text: root.toast ? root.toast.appName : ""
                    textFormat: Text.PlainText
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: root.toast ? root.toast.summary : ""
                    textFormat: Text.PlainText
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: root.toast ? root.toast.body : ""
                    textFormat: Text.PlainText
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.activateNotification(root.toast, null);
                }
            }
        }
    }
}
