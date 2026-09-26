import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../../core"

Row {
    id: root
    spacing: 10

    readonly property var audioSink: Pipewire.defaultAudioSink
    signal interaction

    function getVolumeIcon(vol, muted) {
        if (muted)
            return Quickshell.shellDir + "/assets/icons/Speaker-Muted.svg";
        if (vol > 0.8)
            return Quickshell.shellDir + "/assets/icons/Speaker-High.svg";
        if (vol > 0.5)
            return Quickshell.shellDir + "/assets/icons/Speaker-Mid.svg";
        if (vol > 0.0)
            return Quickshell.shellDir + "/assets/icons/Speaker-Low.svg";
        return Quickshell.shellDir + "/assets/icons/Speaker-Zero.svg";
    }

    IconImage {
        implicitSize: 18
        source: root.getVolumeIcon(root.audioSink?.audio?.volume ?? 0, root.audioSink?.audio?.muted ?? false)
        anchors.verticalCenter: parent.verticalCenter
    }

    Slider {
        id: osdSlider
        implicitWidth: 160
        implicitHeight: 8
        anchors.verticalCenter: parent.verticalCenter
        value: root.audioSink?.audio?.volume ?? 0
        onMoved: {
            if (root.audioSink?.audio) {
                root.audioSink.audio.volume = value;
            }
            root.interaction();
        }
    }

    StablePercentText {
        value: Math.round((root.audioSink?.audio?.volume ?? 0) * 100)
        font.pixelSize: Theme.fontSize
        font.bold: Theme.fontBold
        color: Theme.normalText
        anchors.verticalCenter: parent.verticalCenter
    }
}
