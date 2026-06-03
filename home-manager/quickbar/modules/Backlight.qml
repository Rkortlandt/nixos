import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: backlightRoot
    width: backlightLayout.implicitWidth
    height: parent.height

    property real currentBrightness: 0
    property real maxBrightness: 100

    Process {
        id: currentBrightnessProcess
        command: ["brightnessctl", "g"]
        running: true
        onExited: {
            backlightRoot.currentBrightness = parseFloat(stdout.trim())
        }
    }

    Process {
        id: maxBrightnessProcess
        command: ["brightnessctl", "m"]
        running: true
        onExited: {
            backlightRoot.maxBrightness = parseFloat(stdout.trim())
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: currentBrightnessProcess.running = true
    }

    Process { id: setBrightnessProcess }

    WheelHandler {
        onWheel: (event) => {
            let adjustment = event.angleDelta.y > 0 ? "+5%" : "5%-"
            setBrightnessProcess.command = ["brightnessctl", "set", adjustment]
            setBrightnessProcess.running = true
            currentBrightnessProcess.running = true
        }
    }

    RowLayout {
        id: backlightLayout
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: "󰃠"
            color: "white"
        }

        Text {
            text: Math.ceil((backlightRoot.currentBrightness / backlightRoot.maxBrightness) * 100) + "%"
            color: "white"
        }
    }
}
