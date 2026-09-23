import QtQuick

Item {
    id: root

    enum TransitionType {
        SlideRight,
        SlideLeft,
        SlideDown,
        SlideUp
    }

    // Revealer state
    property bool revealed: false
    property alias reveal: root.revealed
    property alias revealChild: root.revealed

    // Hover activation
    property bool revealOnHover: false
    property alias hoverReveal: root.revealOnHover

    // Exclusive group (supports RevealerGroup instance or string group name)
    property var group: null

    onGroupChanged: {
        if (!group)
            return;
        if (typeof group === "string") {
            RevealerManager.register(root, group);
        } else if (group && group.register) {
            group.register(root);
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.revealOnHover
        onHoveredChanged: {
            if (root.revealOnHover) {
                root.revealed = hoverHandler.hovered;
            }
        }
    }

    Component.onCompleted: {
        if (root.group) {
            if (typeof root.group === "string") {
                RevealerManager.register(root, root.group);
            } else if (root.group.register) {
                root.group.register(root);
            }
        }
    }

    // Transition configuration
    property int transitionType: Revealer.TransitionType.SlideRight
    property int duration: 150
    property int easingType: Easing.OutCubic

    // Progress goes from 0.0 (fully hidden) to 1.0 (fully revealed)
    property real transitionProgress: revealed ? 1.0 : 0.0

    readonly property bool isHorizontal: transitionType === Revealer.TransitionType.SlideRight || transitionType === Revealer.TransitionType.SlideLeft

    clip: true
    visible: transitionProgress > 0.0 || revealed

    // Collapses layout dimension to 0 when hidden so surrounding elements slide naturally
    implicitWidth: isHorizontal ? Math.round(contentContainer.implicitWidth * transitionProgress) : contentContainer.implicitWidth

    implicitHeight: isHorizontal ? contentContainer.implicitHeight : Math.round(contentContainer.implicitHeight * transitionProgress)

    width: implicitWidth
    height: implicitHeight

    function toggle() {
        root.revealed = !root.revealed;
    }

    // Container for child content
    default property alias contentData: contentContainer.data
    readonly property alias contentItem: contentContainer

    Item {
        id: contentContainer

        implicitWidth: children.length === 1 ? (children[0].implicitWidth > 0 ? children[0].implicitWidth : children[0].width) : childrenRect.width

        implicitHeight: children.length === 1 ? (children[0].implicitHeight > 0 ? children[0].implicitHeight : children[0].height) : childrenRect.height

        width: implicitWidth
        height: implicitHeight

        x: {
            if (root.transitionType === Revealer.TransitionType.SlideRight) {
                return root.width - implicitWidth;
            }
            return 0;
        }

        y: {
            if (root.transitionType === Revealer.TransitionType.SlideDown) {
                return root.height - implicitHeight;
            }
            return 0;
        }
    }

    Behavior on transitionProgress {
        NumberAnimation {
            duration: root.duration
            easing.type: root.easingType
        }
    }
}
