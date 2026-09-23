import QtQuick

Item {
    id: root

    property string source: ""
    property real implicitSize: Theme.defaultIconSize
    property alias iconSize: root.implicitSize
    property alias asynchronous: img.asynchronous
    property alias status: img.status

    implicitWidth: implicitSize
    implicitHeight: implicitSize
    width: implicitWidth
    height: implicitHeight

    // Rasterize SVGs matching the monitor's exact physical pixel density (DPR).
    // Disabling mipmap prevents blurry box-filter downsampling on 1080p (1.0x) displays.
    readonly property real dpr: (root.Screen && root.Screen.devicePixelRatio > 0) ? root.Screen.devicePixelRatio : 1.0
    readonly property int renderResolution: {
        let s = Math.max(root.width, root.height);
        if (s <= 0) s = root.implicitSize;
        if (s <= 0) s = 22;
        return Math.round(s * root.dpr);
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectFit
        sourceSize.width: root.renderResolution
        sourceSize.height: root.renderResolution
        smooth: true
        mipmap: false
        asynchronous: false
    }
}
