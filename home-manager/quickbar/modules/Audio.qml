import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: audioRoot
    width: audioLayout.implicitWidth
    height: parent.height

    // State properties (populated by Process below)
    property real volume: 0.5
    property bool isMuted: false
    property bool showAux: hoverHandler.hovered

    HoverHandler { id: hoverHandler }

    WheelHandler {
        onWheel: (event) => {
            let delta = event.angleDelta.y > 0 ? 0.05 : -0.05
            let newVol = Math.max(0, Math.min(1, volume + delta))
            setVolProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", newVol.toString()]
            setVolProcess.running = true
        }
    }

    RowLayout {
        id: audioLayout
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: Math.floor(audioRoot.volume * 100) + "%"
            color: "white"
        }

        // Simulating the revealer for extra controls
        RowLayout {
            visible: audioRoot.showAux
            
            Rectangle {
                width: 25; height: 25
                color: "transparent"
                Text { anchors.centerIn: parent; text: "󰍭"; color: "white" } // Mic Mute icon
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        toggleMuteProcess.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
                        toggleMuteProcess.running = true
                    }
                }
            }
        }
    }

    Process { id: setVolProcess }
    Process { id: toggleMuteProcess }
}
