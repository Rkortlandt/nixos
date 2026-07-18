import QtQuick
import Quickshell.Io

Item {
    width: 100
    height: parent.height

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: cpuPoll.running = true
    }

    Process {
        id: cpuPoll
        command: ["bash", "-c", "/path/to/scripts/system.sh --cpu-usage"]
        running: true

        property int usage: 0

        // Hook up a collector to read the stdout data stream cleanly
        stdout: StdioCollector {
            onStreamFinished: {
                cpuPoll.usage = parseInt(this.text.trim())
            }
        }


    }

    Text {
        anchors.centerIn: parent
        text: "CPU: " + cpuPoll.usage + "%"
        color: "white"
    }
}
