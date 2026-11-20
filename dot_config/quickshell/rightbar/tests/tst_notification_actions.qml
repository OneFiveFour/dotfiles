import QtQuick
import QtTest
import "../widgets/notifications"
import "../widgets/notifications/NotificationActions.js" as Actions

TestCase {
    id: test
    name: "NotificationActions"
    width: 400
    height: 500
    visible: true
    when: windowShown
    property var events: []
    property var sent: []
    property var queued: []
    property var history: []
    property int cardClicks: 0
    property var clickedAction: null
    function clearNotifications() {}
    function activateNotification(notification, action) {
        cardClicks++;
        clickedAction = action;
    }
    function notification(actions) {
        return {appName: "Test", appIcon: "test", desktopEntry: "test.desktop",
            summary: "Test notification", body: "A message", actions: actions,
            dismiss: function() { events.push("dismiss"); }};
    }
    function action(identifier) {
        return {identifier: identifier, text: "", invoke: function() { events.push(identifier); }};
    }
    function activate(n, a) {
        Actions.activate(n, a, function() { events.push("close"); },
            function(callback) { queued.push(callback); }, function(data) { sent.push(data); });
    }
    function init() {
        events = []; sent = []; queued = []; history = []; cardClicks = 0; clickedAction = null;
    }
    function findText(item, text) {
        if (item.text === text && item.clicked !== undefined)
            return item;
        for (let child of item.children || []) {
            const result = findText(child, text);
            if (result) return result;
        }
        return null;
    }
    function test_default_waits_for_focus_release() {
        activate(notification([action("delete"), action("default")]), null);
        compare(events.join(","), "close");
        queued[0]();
        compare(events.join(","), "close,default");
        compare(sent[0].launch, false);
        compare(sent[0].source.desktopEntry, "test.desktop");
    }
    function test_nondefault_does_not_open_app() {
        activate(notification([]), action("mark-read")); queued[0]();
        compare(events.join(","), "close,mark-read"); compare(sent.length, 0);
    }
    function test_missing_default_never_invokes_destructive_action() {
        activate(notification([action("delete")]), null); queued[0]();
        compare(events.join(","), "close"); compare(sent[0].launch, true);
    }
    NotificationsPopup { id: popup; width: 390; height: 480; shellRoot: test }
    function test_card_and_button_clicks() {
        history = [notification([action("default")])]; wait(50);
        mouseClick(popup, 25, 110);
        compare(cardClicks, 1); compare(clickedAction, null);
        // The action button is above the full-card MouseArea and fires only once.
        mouseClick(popup, 325, 123);
        compare(cardClicks, 2); verify(clickedAction !== null);
        compare(clickedAction.identifier, "default");
        const dismiss = findText(popup, "×");
        verify(dismiss !== null);
        mouseClick(dismiss, dismiss.width / 2, dismiss.height / 2);
        compare(cardClicks, 2); compare(events.join(","), "dismiss");
    }
}
