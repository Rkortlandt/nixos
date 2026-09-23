import QtQuick
import Quickshell

Rectangle {
    id: root

    // Required trigger button object (e.g. IconButton, IconTextButton, TextButton, Button)
    required property Item button
    property alias trigger: root.button
    readonly property alias triggerButton: root.button

    // Sizing & Appearance
    property real customRadius: -1
    property real baseRadius: {
        if (root.button && "radius" in root.button && root.button.radius > 0)
            return root.button.radius;
        return height > 0 ? height / 2.2 : Theme.defaultHeight / 2.2;
    }
    radius: customRadius >= 0 ? customRadius : baseRadius
    antialiasing: true

    property color backgroundColor: {
        if (root.button && "backgroundColor" in root.button) return root.button.backgroundColor;
        let style = (root.button && "buttonStyle" in root.button) ? root.button.buttonStyle : Button.Style.Normal;
        switch (style) {
        case Button.Style.Normal:
            return Theme.normalBg;
        case Button.Style.Primary:
            return Theme.secondaryBg;
        case Button.Style.Secondary:
            return Theme.secondaryBg;
        default:
            return Theme.normalBg;
        }
    }
    color: backgroundColor

    // Corner squaring control (when true, inner corners blend/square with revealed content)
    property bool squareCorners: false

    // Dynamic animated corner radii synchronized with revealer progress
    readonly property real animatedRadius: root.radius * (1.0 - revealer.transitionProgress)

    Binding {
        target: root.button
        property: "topRightRadius"
        value: (root.squareCorners && (root.transitionType === Revealer.TransitionType.SlideRight || root.transitionType === Revealer.TransitionType.SlideUp))
            ? root.animatedRadius
            : root.radius
        when: root.button !== null && ("topRightRadius" in root.button)
    }

    Binding {
        target: root.button
        property: "bottomRightRadius"
        value: (root.squareCorners && (root.transitionType === Revealer.TransitionType.SlideRight || root.transitionType === Revealer.TransitionType.SlideDown))
            ? root.animatedRadius
            : root.radius
        when: root.button !== null && ("bottomRightRadius" in root.button)
    }

    Binding {
        target: root.button
        property: "topLeftRadius"
        value: (root.squareCorners && (root.transitionType === Revealer.TransitionType.SlideLeft || root.transitionType === Revealer.TransitionType.SlideUp))
            ? root.animatedRadius
            : root.radius
        when: root.button !== null && ("topLeftRadius" in root.button)
    }

    Binding {
        target: root.button
        property: "bottomLeftRadius"
        value: (root.squareCorners && (root.transitionType === Revealer.TransitionType.SlideLeft || root.transitionType === Revealer.TransitionType.SlideDown))
            ? root.animatedRadius
            : root.radius
        when: root.button !== null && ("bottomLeftRadius" in root.button)
    }

    // Forward click and scroll events from the button
    Connections {
        target: root.button
        ignoreUnknownSignals: true

        function onClicked(mouse) {
            if (!root.revealOnHover) {
                root.toggle();
                root.toggled(root.revealed);
            }
            root.buttonClicked(mouse);
        }

        function onScrolled(wheel) {
            root.scrolled(wheel);
            root.buttonScrolled(wheel);
        }
    }

    function setupCustomButton() {
        if (root.button) {
            root.button.parent = buttonSlot;
            root.button.x = 0;
            root.button.y = Qt.binding(() => (buttonSlot.height - root.button.height) / 2);
        }
    }

    onButtonChanged: setupCustomButton()

    // Revealer properties
    property alias revealer: revealer
    property alias revealed: revealer.revealed
    property alias transitionType: revealer.transitionType
    property alias duration: revealer.duration
    property alias easingType: revealer.easingType

    // Hover activation
    property bool revealOnHover: false
    property alias hoverReveal: root.revealOnHover

    // Exclusive group (supports RevealerGroup instance or string group name)
    property var group: null

    onGroupChanged: {
        if (!group) return;
        if (typeof group === "string") {
            RevealerManager.register(root, group);
        } else if (group && group.register) {
            group.register(root);
        }
    }

    HoverHandler {
        id: rootHoverHandler
        enabled: root.revealOnHover
        onHoveredChanged: {
            if (root.revealOnHover) {
                root.revealed = rootHoverHandler.hovered;
            }
        }
    }

    // Content properties
    property alias contentSpacing: contentRow.spacing
    default property alias contentData: contentRow.data
    readonly property alias contentItem: contentRow

    // Signals
    signal toggled(bool revealed)
    signal buttonClicked(var mouse)
    signal scrolled(var wheel)
    signal buttonScrolled(var wheel)

    function toggle() {
        revealer.toggle();
    }

    readonly property bool isReverse: transitionType === Revealer.TransitionType.SlideLeft
                                   || transitionType === Revealer.TransitionType.SlideUp
    readonly property bool isVertical: transitionType === Revealer.TransitionType.SlideDown
                                    || transitionType === Revealer.TransitionType.SlideUp

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Grid {
        id: layout
        spacing: 0
        rows: root.isVertical ? -1 : 1
        columns: root.isVertical ? 1 : -1
        layoutDirection: (root.transitionType === Revealer.TransitionType.SlideLeft)
            ? Qt.RightToLeft
            : Qt.LeftToRight

        Item {
            id: buttonSlot
            implicitWidth: root.button ? root.button.implicitWidth : 0
            implicitHeight: root.button ? root.button.implicitHeight : 0
            width: implicitWidth
            height: implicitHeight
        }

        Revealer {
            id: revealer
            transitionType: Revealer.TransitionType.SlideRight

            WheelHandler {
                onWheel: event => root.scrolled(event)
            }

            Row {
                id: contentRow
                spacing: 0
                anchors.verticalCenter: parent.verticalCenter

                onChildrenChanged: {
                    for (let i = 0; i < contentRow.children.length; ++i) {
                        let child = contentRow.children[i];
                        if (child && child.visibleChanged) {
                            try { child.visibleChanged.disconnect(root.updateContentRadii); } catch (e) {}
                            child.visibleChanged.connect(root.updateContentRadii);
                        }
                    }
                    root.updateContentRadii();
                }
            }
        }
    }

    function getVisualTarget(item) {
        if (!item) return null;
        if ("topRightRadius" in item) return item;
        if (item.contentItem && item.contentItem.children) {
            for (let i = 0; i < item.contentItem.children.length; ++i) {
                let target = getVisualTarget(item.contentItem.children[i]);
                if (target) return target;
            }
        }
        if (item.children) {
            for (let i = 0; i < item.children.length; ++i) {
                let target = getVisualTarget(item.children[i]);
                if (target) return target;
            }
        }
        return null;
    }

    function updateContentRadii() {
        let items = [];
        for (let i = 0; i < contentRow.children.length; ++i) {
            let child = contentRow.children[i];
            if (child.visible) items.push(child);
        }
        let count = items.length;
        for (let i = 0; i < count; ++i) {
            let rawItem = items[i];
            let item = getVisualTarget(rawItem) || rawItem;
            if ("bordered" in item) item.bordered = false;
            if (item.border) item.border.width = 0;

            if ("topRightRadius" in item) {
                if (!root.squareCorners) {
                    // When corner squaring is disabled, keep items with their normal full radius
                    item.topRightRadius = root.radius;
                    item.bottomRightRadius = root.radius;
                    item.topLeftRadius = root.radius;
                    item.bottomLeftRadius = root.radius;
                } else if (i === count - 1 && !root.isReverse) {
                    item.topRightRadius = root.radius;
                    item.bottomRightRadius = root.radius;
                    item.topLeftRadius = 0;
                    item.bottomLeftRadius = 0;
                } else if (i === 0 && root.isReverse) {
                    item.topLeftRadius = root.radius;
                    item.bottomLeftRadius = root.radius;
                    item.topRightRadius = 0;
                    item.bottomRightRadius = 0;
                } else {
                    item.topLeftRadius = 0;
                    item.topRightRadius = 0;
                    item.bottomLeftRadius = 0;
                    item.bottomRightRadius = 0;
                }
            }
        }
    }

    onSquareCornersChanged: updateContentRadii()
    onRadiusChanged: updateContentRadii()
    Component.onCompleted: {
        setupCustomButton();
        if (root.group) {
            if (typeof root.group === "string") {
                RevealerManager.register(root, root.group);
            } else if (root.group.register) {
                root.group.register(root);
            }
        }
        updateContentRadii();
    }
}
