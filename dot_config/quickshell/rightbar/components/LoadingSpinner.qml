import QtQuick
import "../theme"

Item {
    id: spinner
    property bool running: true
    implicitWidth: 24
    implicitHeight: 24
    Canvas {
        id: ring
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const radius = Math.min(width, height) / 2 - 2;
            ctx.lineWidth = 2.4;
            ctx.lineCap = "round";
            ctx.strokeStyle = Theme.border;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, radius, 0, 2 * Math.PI);
            ctx.stroke();
            ctx.strokeStyle = Theme.accent;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, radius, -Math.PI / 2, Math.PI);
            ctx.stroke();
        }
    }
    RotationAnimation on rotation {
        from: 0
        to: 360
        duration: 800
        loops: Animation.Infinite
        running: spinner.running && spinner.visible
    }
}
