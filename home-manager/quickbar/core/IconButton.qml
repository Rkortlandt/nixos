import QtQuick
import Quickshell

Button {
    id: root

    // IconButton rounding: base * multiplier (0.75 by default)
    radiusMultiplier: 0.75

    property string iconSource: ""
    property alias source: root.iconSource
    property int iconSize: Theme.defaultIconSize
    property alias icon: iconItem

    // Keep square by default for consistent bar aesthetics
    implicitWidth: Math.max(implicitHeight, iconItem.implicitWidth + (paddingHorizontal))

    IconImage {
        id: iconItem
        source: root.iconSource
        implicitSize: root.iconSize
    }
}
