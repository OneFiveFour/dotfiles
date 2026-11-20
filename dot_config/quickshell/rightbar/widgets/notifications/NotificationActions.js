.pragma library

function defaultAction(notification) {
    return notification.actions.find(action => action.identifier === "default") || null;
}

function source(notification) {
    return { desktopEntry: notification.desktopEntry || "",
        appName: notification.appName || "", appIcon: notification.appIcon || "" };
}

// Capture metadata before invoke(): Quickshell may destroy the notification there.
function activate(notification, action, close, defer, send) {
    if (!notification)
        return;
    const origin = source(notification);
    const selected = action || defaultAction(notification);
    const opening = !action || action.identifier === "default";
    close();
    // Release the popup's exclusive keyboard focus before the app handles the action.
    defer(function() {
        if (selected)
            selected.invoke();
        if (opening)
            send({ action: "open-notification", source: origin, launch: !selected });
    });
}
