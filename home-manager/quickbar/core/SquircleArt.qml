// core/SquircleArt.qml
import QtQuick
import Quickshell.Widgets
import "../core"

ClippingRectangle {
    id: root

    property string artUrl: ""
    property real artSize: 48
    property real cornerRadius: 8
    property color borderColor: Theme.accentBg
    property real borderWidth: 3
    property real iconSize: artSize * 0.5
    property color fallbackBg: "#181818"

    width: artSize
    height: artSize
    implicitWidth: artSize
    implicitHeight: artSize

    radius: cornerRadius
    color: fallbackBg
    border.color: borderColor
    border.width: borderWidth

    // Album art rendered with bounded texture size for HiDPI
    Image {
        id: artImage
        anchors.fill: parent
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.round(root.artSize * ((root.Screen && root.Screen.devicePixelRatio > 0) ? root.Screen.devicePixelRatio : 2.0))
        sourceSize.height: Math.round(root.artSize * ((root.Screen && root.Screen.devicePixelRatio > 0) ? root.Screen.devicePixelRatio : 2.0))
        asynchronous: true
        visible: status === Image.Ready && root.artUrl !== ""
        smooth: true
        mipmap: false
    }

    // Fallback Music Icon
    IconImage {
        anchors.centerIn: parent
        implicitSize: root.iconSize
        source: Qt.resolvedUrl("../assets/icons/Music.svg")
        visible: !artImage.visible
    }
}
