import QtQuick

Rectangle {
    id: root

    // Range & value
    property real value: 0.5
    property real from: 0.0
    property real to: 1.0
    property real stepSize: 0.0

    // Appearance
    property color trackColor: "#40ffffff"
    property color fillColor: "#ffffff"
    property real customRadius: -1
    radius: customRadius >= 0 ? customRadius : (height / 2)
    color: trackColor

    implicitWidth: 120
    implicitHeight: 10

    // Normalised position (0.0 to 1.0)
    readonly property real position: {
        let range = root.to - root.from;
        if (range <= 0) return 0.0;
        return Math.max(0.0, Math.min(1.0, (root.value - root.from) / range));
    }

    // Signals
    signal moved()
    signal valueModified(real val)

    // Inner filled bar
    Rectangle {
        id: fill
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: Math.round(parent.width * root.position)
        radius: root.radius
        color: root.fillColor
    }

    function updateValueFromMouse(mouseX) {
        let range = root.to - root.from;
        if (range <= 0 || width <= 0) return;

        let ratio = Math.max(0.0, Math.min(1.0, mouseX / width));
        let rawVal = root.from + (ratio * range);

        if (root.stepSize > 0) {
            rawVal = Math.round((rawVal - root.from) / root.stepSize) * root.stepSize + root.from;
        }

        rawVal = Math.max(root.from, Math.min(root.to, rawVal));
        if (root.value !== rawVal) {
            root.value = rawVal;
            root.moved();
            root.valueModified(rawVal);
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.enabled

        onPressed: mouse => root.updateValueFromMouse(mouse.x)
        onPositionChanged: mouse => {
            if (pressed) {
                root.updateValueFromMouse(mouse.x);
            }
        }

        onWheel: wheel => {
            let step = root.stepSize > 0 ? root.stepSize : (root.to - root.from) * 0.05;
            let delta = ScrollHelper.getDelta(wheel, step);
            if (delta === 0) return;
            let newVal = Math.max(root.from, Math.min(root.to, root.value + delta));
            if (root.value !== newVal) {
                root.value = newVal;
                root.moved();
                root.valueModified(newVal);
            }
        }
    }
}
