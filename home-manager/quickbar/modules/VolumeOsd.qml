// modules/VolumeOsd.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../core"

Scope {
    id: root

    readonly property var audioSink: Pipewire.defaultAudioSink
    property bool shouldShowOsd: false

    // Volume icon helper
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

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null
        ignoreUnknownSignals: true

        function onVolumeChanged() {
            root.shouldShowOsd = true;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.shouldShowOsd = false
    }

    // Volume OSD popup Window
    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            anchors.top: true
            exclusiveZone: 0

            implicitWidth: 400
            implicitHeight: 50
            color: "transparent"

            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#80000000"

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 15
                    }
                    IconImage {
                        implicitSize: 30
                        source: root.getVolumeIcon(root.audioSink?.audio?.volume ?? 0, root.audioSink?.audio?.muted ?? false)
                    }

                    Slider {
                        Layout.fillWidth: true
                        value: root.audioSink?.audio?.volume ?? 0
                    }
                }
            }
        }
    }
}
