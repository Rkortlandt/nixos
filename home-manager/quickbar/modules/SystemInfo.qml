import QtQuick
import Quickshell.Io

Item {
    width: 100
    height: parent.height

    // Fetch CPU Usage
    Process {
        id: cpuPoll
        command: ["bash", "-c", "/path/to/scripts/system.sh --cpu-usage"]
        running: true

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: cpuPoll.running = true
        }

        property int usage: 0
        onExited: {
            usage = parseInt(stdout.trim())
        }
    }

    Text {
        anchors.centerIn: parent
        text: "CPU: " + cpuPoll.usage + "%"
        color: "white"
    }
}
