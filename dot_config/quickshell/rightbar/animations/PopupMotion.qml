import "../theme"
import QtQuick

QtObject {
    id: motion
    required property Item targetItem
    property bool active: false
    property string revealKey: ""
    property bool enabled: Animations.enabled
    property string style: Animations.popupStyle
    property int duration: Animations.popupDuration
    property int easingType: Animations.popupEasing
    property real distance: Animations.popupDistance
    property real progress: 1
    readonly property bool animated: enabled && (style === "slide" || style === "fade") && duration > 0
    readonly property real travel: distance > 0 ? distance : (targetItem ? targetItem.width + 10 : 0)
    readonly property real offsetX: animated && style === "slide" ? (1 - progress) * travel : 0
    readonly property real alpha: animated && style === "fade" ? progress : 1
    readonly property bool running: enterAnimation.running

    // Bei erneutem Öffnen/Wechsel immer von einer definierten Position starten.
    function scheduleReveal() {
        enterAnimation.stop();
        startTimer.stop();
        progress = active && animated ? 0 : 1;
        if (active && animated)
            startTimer.start();
    }
    onActiveChanged: scheduleReveal()
    onRevealKeyChanged: scheduleReveal()
    onEnabledChanged: scheduleReveal()
    onStyleChanged: scheduleReveal()
    onDurationChanged: scheduleReveal()
    Component.onCompleted: scheduleReveal()

    property Timer startTimer: Timer {
        interval: 0
        onTriggered: {
            if (motion.active && motion.animated)
                enterAnimation.restart();
        }
    }
    property NumberAnimation enterAnimation: NumberAnimation {
        target: motion
        property: "progress"
        from: 0
        to: 1
        duration: Math.max(0, motion.duration)
        easing.type: motion.easingType
    }
}
