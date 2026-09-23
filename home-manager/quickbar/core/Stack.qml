import QtQuick

Item {
    id: root

    enum Direction {
        Auto,
        Up,
        Down
    }

    property int direction: Stack.Direction.Auto
    property int orientation: Qt.Vertical
    property int currentIndex: 0
    property int duration: 150
    property int easingType: Easing.OutCubic
    property bool wrap: false

    clip: true

    readonly property int count: container.children.length
    readonly property Item currentItem: (currentIndex >= 0 && currentIndex < container.children.length)
        ? container.children[currentIndex]
        : null

    property int outgoingIndex: -1
    property int slideDirection: 1
    property real slideProgress: 1.0

    // Sizing: adapt to active child's natural size
    implicitWidth: {
        if (currentItem && currentItem.implicitWidth > 0) return currentItem.implicitWidth;
        if (container.children.length > 0 && container.children[0].implicitWidth > 0) return container.children[0].implicitWidth;
        return 0;
    }
    implicitHeight: {
        if (currentItem && currentItem.implicitHeight > 0) return currentItem.implicitHeight;
        if (container.children.length > 0 && container.children[0].implicitHeight > 0) return container.children[0].implicitHeight;
        return Theme.defaultHeight;
    }

    width: implicitWidth
    height: implicitHeight

    NumberAnimation {
        id: slideAnim
        target: root
        property: "slideProgress"
        from: 0.0
        to: 1.0
        duration: root.duration
        easing.type: root.easingType

        onFinished: {
            root.outgoingIndex = -1;
            root.updateChildrenGeometry();
        }
    }

    function transitionTo(newIndex, forcedDirection) {
        if (newIndex < 0 || newIndex >= root.count || newIndex === root.currentIndex) return;

        let oldIndex = root.currentIndex;
        root.outgoingIndex = oldIndex;
        root.currentIndex = newIndex;

        if (forcedDirection !== undefined) {
            root.slideDirection = forcedDirection;
        } else if (root.direction === Stack.Direction.Up) {
            root.slideDirection = 1;
        } else if (root.direction === Stack.Direction.Down) {
            root.slideDirection = -1;
        } else {
            root.slideDirection = (newIndex > oldIndex) ? 1 : -1;
        }

        root.slideProgress = 0.0;
        root.updateChildrenGeometry();
        slideAnim.restart();
    }

    function set(index) {
        root.transitionTo(index);
    }

    function get(index) {
        if (index >= 0 && index < root.count) {
            return container.children[index];
        }
        return null;
    }

    function next() {
        if (root.count <= 1) return;
        let nextIndex = root.currentIndex + 1;
        if (nextIndex >= root.count) {
            if (!root.wrap) return;
            nextIndex = 0;
        }
        root.transitionTo(nextIndex);
    }

    function previous() {
        if (root.count <= 1) return;
        let prevIndex = root.currentIndex - 1;
        if (prevIndex < 0) {
            if (!root.wrap) return;
            prevIndex = root.count - 1;
        }
        root.transitionTo(prevIndex);
    }

    function updateChildrenGeometry() {
        let n = container.children.length;
        let isVert = (root.orientation === Qt.Vertical);
        let h = root.height > 0 ? root.height : root.implicitHeight;
        let w = root.width > 0 ? root.width : root.implicitWidth;

        for (let i = 0; i < n; ++i) {
            let child = container.children[i];
            if (i === root.currentIndex) {
                child.visible = true;
                if (root.outgoingIndex === -1) {
                    child.x = 0;
                    child.y = 0;
                } else if (isVert) {
                    child.x = 0;
                    child.y = (root.slideDirection === 1)
                        ? Math.round((1.0 - root.slideProgress) * h)
                        : Math.round(-(1.0 - root.slideProgress) * h);
                } else {
                    child.y = 0;
                    child.x = (root.slideDirection === 1)
                        ? Math.round((1.0 - root.slideProgress) * w)
                        : Math.round(-(1.0 - root.slideProgress) * w);
                }
            } else if (i === root.outgoingIndex) {
                child.visible = true;
                if (isVert) {
                    child.x = 0;
                    child.y = (root.slideDirection === 1)
                        ? Math.round(-root.slideProgress * h)
                        : Math.round(root.slideProgress * h);
                } else {
                    child.y = 0;
                    child.x = (root.slideDirection === 1)
                        ? Math.round(-root.slideProgress * w)
                        : Math.round(root.slideProgress * w);
                }
            } else {
                child.visible = false;
            }
        }
    }

    onSlideProgressChanged: updateChildrenGeometry()
    onWidthChanged: updateChildrenGeometry()
    onHeightChanged: updateChildrenGeometry()

    default property alias contentData: container.data
    readonly property alias contentItem: container

    Item {
        id: container
        anchors.fill: parent

        onChildrenChanged: root.updateChildrenGeometry()
    }

    Component.onCompleted: updateChildrenGeometry()
}
