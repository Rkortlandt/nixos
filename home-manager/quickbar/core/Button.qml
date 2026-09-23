import QtQuick
import Quickshell

Rectangle {
    id: root

    enum Style {
        Normal,
        Primary,
        Secondary,
        Gradient,
        Custom,
        Accent
    }

    // Styling properties
    property int buttonStyle: Button.Style.Normal
    property bool bordered: false
    property alias borderBool: root.bordered
    property alias hasBorder: root.bordered

    readonly property color defaultBgColor: {
        switch (root.buttonStyle) {
        case Button.Style.Primary:
            return Theme.primaryBg;
        case Button.Style.Secondary:
            return Theme.secondaryBg;
        case Button.Style.Accent:
            return Theme.accentBg;
        case Button.Style.Normal:
        case Button.Style.Gradient:
        case Button.Style.Custom:
        default:
            return Theme.normalBg;
        }
    }

    readonly property color defaultHoverBgColor: {
        switch (root.buttonStyle) {
        case Button.Style.Primary:
            return Theme.primaryHoverBg;
        case Button.Style.Secondary:
            return Theme.secondaryHoverBg;
        case Button.Style.Accent:
            return Theme.accentHoverBg;
        case Button.Style.Normal:
        default:
            return Theme.normalHoverBg;
        }
    }

    readonly property color defaultPressedBgColor: {
        switch (root.buttonStyle) {
        case Button.Style.Primary:
            return Theme.primaryPressedBg;
        case Button.Style.Secondary:
            return Theme.secondaryPressedBg;
        case Button.Style.Accent:
            return Theme.accentPressedBg;
        case Button.Style.Normal:
        default:
            return Theme.normalPressedBg;
        }
    }

    readonly property color defaultTextColor: {
        switch (root.buttonStyle) {
        case Button.Style.Primary:
            return Theme.primaryText;
        case Button.Style.Secondary:
            return Theme.secondaryText;
        case Button.Style.Accent:
            return Theme.accentText;
        case Button.Style.Gradient:
            return Theme.gradientText;
        case Button.Style.Normal:
        default:
            return Theme.normalText;
        }
    }

    readonly property color defaultBorderColor: {
        switch (root.buttonStyle) {
        case Button.Style.Primary:
            return Theme.primaryBorder;
        case Button.Style.Secondary:
            return Theme.secondaryBorder;
        case Button.Style.Accent:
            return Theme.accentBorder;
        case Button.Style.Gradient:
            return Theme.gradientBorder;
        case Button.Style.Normal:
        default:
            return Theme.normalBorder;
        }
    }

    property color backgroundColor: defaultBgColor
    property color hoverColor: defaultHoverBgColor
    property color pressedColor: defaultPressedBgColor
    property color textColor: defaultTextColor
    property color borderColor: defaultBorderColor
    property int borderWidth: 1

    // Gradient properties
    property color gradientStartColor: Theme.gradientStart
    property color gradientEndColor: Theme.gradientEnd
    property int gradientOrientation: Gradient.Horizontal
    property Gradient backgroundGradient: null
    property Gradient hoverGradient: null
    property Gradient pressedGradient: null

    readonly property bool hasGradient: (root.buttonStyle === Button.Style.Gradient) || (root.backgroundGradient !== null)

    Gradient {
        id: defaultStyleGradient
        orientation: root.gradientOrientation
        GradientStop {
            position: 0.0
            color: root.gradientStartColor
        }
        GradientStop {
            position: 1.0
            color: root.gradientEndColor
        }
    }

    gradient: !hasGradient ? null : mouseArea.pressed && root.pressedGradient ? root.pressedGradient : mouseArea.containsMouse && root.hoverGradient ? root.hoverGradient : root.backgroundGradient ? root.backgroundGradient : defaultStyleGradient

    // Rounding & Sizing properties
    property real baseRadius: height / 2.2
    property real radiusMultiplier: 1.0
    property real customRadius: -1
    radius: customRadius >= 0 ? customRadius : (baseRadius * radiusMultiplier)
    antialiasing: true

    property real paddingHorizontal: 8
    property real paddingVertical: 0

    implicitHeight: Theme.defaultHeight
    implicitWidth: Math.max(implicitHeight, contentContainer.implicitWidth + (paddingHorizontal * 2))

    // Visual appearance bindings
    color: hasGradient ? "transparent" : !enabled ? Qt.darker(root.backgroundColor, 1.2) : mouseArea.pressed ? root.pressedColor : mouseArea.containsMouse ? root.hoverColor : root.backgroundColor

    border.color: root.bordered ? root.borderColor : "transparent"
    border.width: root.bordered ? root.borderWidth : 0
    opacity: enabled ? 1.0 : 0.6

    // Font properties shared by text-bearing buttons
    property font font: Qt.font({
        family: Theme.fontFamily,
        pixelSize: Theme.fontSize,
        bold: Theme.fontBold
    })

    // Signals
    signal clicked(var mouse)
    signal rightClicked(var mouse)
    signal pressed(var mouse)
    signal released(var mouse)
    signal scrolled(var wheel)

    // Interaction states
    property alias containsMouse: mouseArea.containsMouse
    property alias isPressed: mouseArea.pressed
    property alias mouseArea: mouseArea

    // Content container for embedded child elements
    default property alias contentData: contentContainer.data
    readonly property alias contentItem: contentContainer

    // Hover & pressed overlay for gradient buttons
    Rectangle {
        id: stateOverlay
        anchors.fill: parent
        radius: root.radius
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        color: mouseArea.pressed ? "#30000000" : (mouseArea.containsMouse ? "#25ffffff" : "transparent")
        visible: root.hasGradient && !root.hoverGradient && !root.pressedGradient
    }

    Item {
        id: contentContainer
        anchors.centerIn: parent
        implicitWidth: children.length === 1 ? (children[0].implicitWidth > 0 ? children[0].implicitWidth : children[0].width) : childrenRect.width
        implicitHeight: children.length === 1 ? (children[0].implicitHeight > 0 ? children[0].implicitHeight : children[0].height) : childrenRect.height
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked(mouse);
            } else {
                root.clicked(mouse);
            }
        }
        onPressed: mouse => root.pressed(mouse)
        onReleased: mouse => root.released(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }
}
