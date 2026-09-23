import QtQuick

Grid {
    id: root

    property int orientation: Qt.Horizontal
    rows: orientation === Qt.Horizontal ? 1 : -1
    columns: orientation === Qt.Vertical ? 1 : -1
    spacing: 0

    // Optional radius override for outer corners; if negative, uses the button's own radius
    property real radius: -1

    property var _trackedChildren: []

    function updateButtons() {
        let visibleButtons = [];
        for (let i = 0; i < root.children.length; ++i) {
            let child = root.children[i];
            // Only include visual button items; skip non-visual utility items like Repeater
            if (child && child.visible && !("count" in child && "model" in child) && child.topLeftRadius !== undefined) {
                visibleButtons.push(child);
            }
        }

        let count = visibleButtons.length;
        if (count === 0) return;

        let isVertical = (root.orientation === Qt.Vertical);

        for (let i = 0; i < count; ++i) {
            let btn = visibleButtons[i];

            // Ensure no borders
            if ("bordered" in btn) {
                btn.bordered = false;
            }
            if (btn.border) {
                btn.border.width = 0;
            }

            // Determine radius for rounded corners
            let r = root.radius >= 0
                ? root.radius
                : (btn.customRadius !== undefined && btn.customRadius >= 0
                    ? btn.customRadius
                    : (btn.radius > 0
                        ? btn.radius
                        : (btn.height > 0
                            ? (btn.height / 2.2) * (btn.radiusMultiplier ?? 1.0)
                            : (btn.implicitHeight > 0
                                ? (btn.implicitHeight / 2.2) * (btn.radiusMultiplier ?? 1.0)
                                : 12))));

            if (count === 1) {
                btn.topLeftRadius = r;
                btn.topRightRadius = r;
                btn.bottomLeftRadius = r;
                btn.bottomRightRadius = r;
            } else if (isVertical) {
                if (i === 0) {
                    btn.topLeftRadius = r;
                    btn.topRightRadius = r;
                    btn.bottomLeftRadius = 0;
                    btn.bottomRightRadius = 0;
                } else if (i === count - 1) {
                    btn.topLeftRadius = 0;
                    btn.topRightRadius = 0;
                    btn.bottomLeftRadius = r;
                    btn.bottomRightRadius = r;
                } else {
                    btn.topLeftRadius = 0;
                    btn.topRightRadius = 0;
                    btn.bottomLeftRadius = 0;
                    btn.bottomRightRadius = 0;
                }
            } else {
                if (i === 0) {
                    btn.topLeftRadius = r;
                    btn.bottomLeftRadius = r;
                    btn.topRightRadius = 0;
                    btn.bottomRightRadius = 0;
                } else if (i === count - 1) {
                    btn.topLeftRadius = 0;
                    btn.bottomLeftRadius = 0;
                    btn.topRightRadius = r;
                    btn.bottomRightRadius = r;
                } else {
                    btn.topLeftRadius = 0;
                    btn.bottomLeftRadius = 0;
                    btn.topRightRadius = 0;
                    btn.bottomRightRadius = 0;
                }
            }
        }
    }

    onChildrenChanged: {
        for (let i = 0; i < root.children.length; ++i) {
            let child = root.children[i];
            if (child && root._trackedChildren.indexOf(child) === -1) {
                root._trackedChildren.push(child);
                if (child.visibleChanged) {
                    child.visibleChanged.connect(root.updateButtons);
                }
                if (child.heightChanged) {
                    child.heightChanged.connect(root.updateButtons);
                }
            }
        }
        root.updateButtons();
        Qt.callLater(root.updateButtons);
    }

    onRadiusChanged: root.updateButtons()
    onOrientationChanged: root.updateButtons()
    Component.onCompleted: {
        root.updateButtons();
        Qt.callLater(root.updateButtons);
    }
}
