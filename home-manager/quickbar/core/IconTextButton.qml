import QtQuick
import Quickshell

Button {
    id: root

    enum IconPosition {
        IconBeforeText,
        TextBeforeIcon
    }

    property int iconPosition: IconTextButton.IconPosition.IconBeforeText
    property string text: ""
    property string iconSource: ""
    property alias source: root.iconSource
    property int iconSize: Theme.defaultIconSize
    property int spacing: 0

    property alias label: label
    property alias icon: iconItem

    readonly property bool isPercentage: root.text.endsWith("%")
    readonly property int numericVal: {
        if (!isPercentage) return -1;
        let n = parseInt(root.text);
        return isNaN(n) ? -1 : Math.abs(n);
    }
    readonly property int digitBracket: numericVal >= 100 ? 3 : (numericVal >= 10 ? 2 : 1)

    TextMetrics {
        id: m1
        font: label.font
        text: "8%"
    }
    TextMetrics {
        id: m2
        font: label.font
        text: "88%"
    }
    TextMetrics {
        id: m3
        font: label.font
        text: "100%"
    }

    Row {
        id: layoutRo
        spacing: root.spacing
        layoutDirection: root.iconPosition === IconTextButton.IconPosition.TextBeforeIcon ? Qt.RightToLeft : Qt.LeftToRight

        IconImage {
            id: iconItem
            visible: root.iconSource !== ""
            source: root.iconSource
            implicitSize: root.iconSize
        }

        Text {
            id: label
            padding: 4
            visible: root.text !== ""
            text: root.text
            font.family: root.font.family
            font.pixelSize: root.font.pixelSize
            font.bold: root.font.bold
            font.weight: root.font.weight
            font.features: { "tnum": 1 }
            color: root.textColor
            horizontalAlignment: root.isPercentage ? Text.AlignHCenter : Text.AlignLeft
            width: root.isPercentage && root.numericVal >= 0 ? Math.ceil((root.digitBracket === 3 ? m3.width : (root.digitBracket === 2 ? m2.width : m1.width)) + (padding * 2) + 1) : implicitWidth
        }
    }
}
