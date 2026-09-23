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
            font: root.font
            color: root.textColor
        }
    }
}
