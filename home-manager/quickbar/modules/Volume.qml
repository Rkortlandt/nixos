// modules/Volume.qml
import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../core"

RevealerButton {
    id: root

    readonly property var audioSink: Pipewire.defaultAudioSink
    property int volumeRevealerMode: 0

    // Volume icon resolver
    function getVolumeIcon(vol, muted) {
        if (muted)
            return Qt.resolvedUrl("../assets/icons/Speaker-Muted.svg");
        if (vol > 0.8)
            return Qt.resolvedUrl("../assets/icons/Speaker-High.svg");
        if (vol > 0.5)
            return Qt.resolvedUrl("../assets/icons/Speaker-Mid.svg");
        if (vol > 0.0)
            return Qt.resolvedUrl("../assets/icons/Speaker-Low.svg");
        return Qt.resolvedUrl("../assets/icons/Speaker-Zero.svg");
    }

    // Friendly device label resolver
    function getDeviceLabel(node) {
        if (!node)
            return "";
        let desc = (node.description || node.nickname || node.name || "Output").trim();
        if (desc.includes("Analog Stereo") || desc.includes("HD Audio Controller")) {
            return "Speakers";
        }
        return desc;
    }

    button: IconTextButton {
        iconSource: root.getVolumeIcon(root.audioSink?.audio?.volume ?? 0, root.audioSink?.audio?.muted ?? false)
        text: Math.round((root.audioSink?.audio?.volume ?? 0) * 100) + "%"
        buttonStyle: Button.Style.Normal
    }
    revealOnHover: true
    group: "barRevealers"

    // Proportional scroll volume adjustment
    onScrolled: wheel => {
        let delta = ScrollHelper.getDelta(wheel);
        if (delta === 0 || !root.audioSink?.audio)
            return;

        let current = root.audioSink.audio.volume ?? 0;
        let newVol = Math.max(0.0, Math.min(1.0, current + delta));
        root.audioSink.audio.volume = newVol;
        if (delta > 0 && root.audioSink.audio.muted) {
            root.audioSink.audio.muted = false;
        }
    }

    // Clicking trigger button cycles between device selection (0) and mute control (1)
    onButtonClicked: {
        root.volumeRevealerMode = (root.volumeRevealerMode === 0) ? 1 : 0;
    }

    // Mode 0: Audio Output Device Selection Revealer
    Revealer {
        id: volDeviceRevealer
        revealed: root.volumeRevealerMode === 0
        transitionType: Revealer.TransitionType.SlideRight
        duration: 150

        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: {
                    if (!Pipewire.nodes || !Pipewire.nodes.values)
                        return [];
                    return Pipewire.nodes.values.filter(node => node && node.isSink && !node.isStream);
                }

                TextButton {
                    id: deviceBtn
                    property bool isSelected: (root.audioSink && root.audioSink.id === modelData.id)
                    text: root.getDeviceLabel(modelData)
                    paddingHorizontal: 8
                    buttonStyle: isSelected ? Button.Style.Primary : Button.Style.Normal
                    textColor: Theme.normalText

                    onClicked: {
                        Pipewire.preferredDefaultAudioSink = modelData;
                        setSinkProc.command = ["wpctl", "set-default", modelData.id.toString()];
                        setSinkProc.running = true;
                    }
                }
            }
        }
    }

    // Mode 1: Quick Mute / Unmute Control Revealer
    Revealer {
        id: volMuteRevealer
        revealed: root.volumeRevealerMode === 1
        transitionType: Revealer.TransitionType.SlideRight
        duration: 150

        IconButton {
            iconSource: (root.audioSink?.audio?.muted ?? false) ? Qt.resolvedUrl("../assets/icons/Speaker-High.svg") : Qt.resolvedUrl("../assets/icons/Speaker-Muted.svg")
            buttonStyle: Button.Style.Normal
            onClicked: {
                if (root.audioSink?.audio) {
                    root.audioSink.audio.muted = !root.audioSink.audio.muted;
                }
            }
        }
    }

    Process {
        id: setSinkProc
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
}
