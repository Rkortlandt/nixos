// modules/Microphone.qml
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../core"

RevealerButton {
    id: root

    readonly property var audioSource: Pipewire.defaultAudioSource

    button: IconButton {
        iconSource: (root.audioSource?.audio?.muted ?? false)
            ? Quickshell.shellDir + "/assets/icons/Mic-Muted.svg"
            : Quickshell.shellDir + "/assets/icons/Mic.svg"
        buttonStyle: Button.Style.Normal
    }
    revealOnHover: true
    group: "barRevealers"

    // Proportional scroll mic adjustment
    onScrolled: wheel => {
        let delta = ScrollHelper.getDelta(wheel);
        if (delta === 0 || !root.audioSource?.audio)
            return;

        let current = root.audioSource.audio.volume ?? 0;
        let newVol = Math.max(0.0, Math.min(1.0, current + delta));
        root.audioSource.audio.volume = newVol;
        if (delta > 0 && root.audioSource.audio.muted) {
            root.audioSource.audio.muted = false;
        }
    }

    onButtonClicked: {
        if (root.audioSource?.audio) {
            root.audioSource.audio.muted = !root.audioSource.audio.muted;
        }
    }

    Item {
        implicitWidth: micSlider.implicitWidth + 8
        implicitHeight: root.implicitHeight

        Slider {
            id: micSlider
            implicitWidth: 90
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4
            value: root.audioSource?.audio?.volume ?? 0
            onMoved: {
                if (root.audioSource?.audio) {
                    root.audioSource.audio.volume = value;
                }
            }
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }
}
