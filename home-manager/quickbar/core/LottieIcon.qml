// core/LottieIcon.qml
import QtQuick
import Qt.labs.lottieqt
import "."

Item {
    id: root

    // File path or URL to the .json Lottie animation file
    property var source: ""

    // Sizing controls
    property real size: Theme.defaultIconSize
    property alias implicitSize: root.size
    property alias iconSize: root.size

    // Playback controls & properties
    property alias autoPlay: anim.autoPlay
    property alias loops: anim.loops
    property alias status: anim.status
    property alias frameRate: anim.frameRate
    property alias startFrame: anim.startFrame
    property alias endFrame: anim.endFrame
    property alias direction: anim.direction
    property alias quality: anim.quality

    implicitWidth: size
    implicitHeight: size
    width: implicitWidth
    height: implicitHeight

    // Resolve local paths or URLs cleanly
    readonly property url resolvedSource: {
        let src = root.source ? root.source.toString() : "";
        if (!src) return "";
        if (src.startsWith("http://") || src.startsWith("https://") || src.startsWith("file://") || src.startsWith("qrc:/")) {
            return src;
        }
        if (src.startsWith("/")) {
            return "file://" + src;
        }
        return src;
    }

    LottieAnimation {
        id: anim
        anchors.centerIn: parent
        width: implicitWidth > 0 ? implicitWidth : root.width
        height: implicitHeight > 0 ? implicitHeight : root.height
        source: root.resolvedSource
        autoPlay: true
        loops: LottieAnimation.Infinite
        quality: LottieAnimation.HighQuality

        scale: (anim.width > 0 && anim.height > 0)
            ? Math.min(root.width / anim.width, root.height / anim.height)
            : 1.0
    }

    // Methods for programmatic control
    function play() {
        anim.play();
    }

    function pause() {
        anim.pause();
    }

    function toggle() {
        anim.togglePause();
    }

    function start() {
        anim.start();
    }

    function stop() {
        anim.stop();
    }

    function gotoAndPlay(frame) {
        anim.gotoAndPlay(frame);
    }

    function gotoAndStop(frame) {
        anim.gotoAndStop(frame);
    }
}
