// core/LottieIcon.qml
import QtQuick
import Qt.labs.lottieanimation 1.0
import "."

Item {
    id: root

    // File path or URL to the .json Lottie animation file
    property var source: ""

    // Sizing controls (defaults to standard Theme icon size if not specified)
    property real size: Theme.defaultIconSize
    property alias implicitSize: root.size
    property alias iconSize: root.size

    // Playback controls
    property bool playing: true
    property bool autoPlay: true
    property int loops: LottieAnimation.Infinite
    property alias speed: anim.speed
    property alias status: anim.status
    property alias frameRate: anim.frameRate
    property alias startFrame: anim.startFrame
    property alias endFrame: anim.endFrame
    property alias currentFrame: anim.currentFrame

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
        anchors.fill: parent
        source: root.resolvedSource
        loops: root.loops
        autoPlay: root.autoPlay && root.playing
        running: root.playing
        fillMode: Image.PreserveAspectFit
    }

    // Methods for programmatic control
    function play() {
        root.playing = true;
        anim.play();
    }

    function pause() {
        root.playing = false;
        anim.pause();
    }

    function toggle() {
        if (anim.status === LottieAnimation.Ready || anim.status === LottieAnimation.Loading) {
            if (anim.playing) anim.pause();
            else anim.play();
        }
    }

    function gotoAndPlay(frame) {
        anim.gotoAndPlay(frame);
    }

    function gotoAndStop(frame) {
        anim.gotoAndStop(frame);
    }
}
