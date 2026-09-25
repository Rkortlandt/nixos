// modules/SystemInfo.qml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../core"

RevealerButton {
    id: root

    // System stats tracking
    property int cpuUsage: 0
    property int ramUsage: 0
    property int cpuTemp: 0

    Process {
        id: statsProc
        command: ["bash", Quickshell.shellDir + "/core/system_stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(" ");
                if (parts.length >= 3) {
                    let c = parseInt(parts[0]);
                    let r = parseInt(parts[1]);
                    let t = parseInt(parts[2]);
                    if (!isNaN(c)) root.cpuUsage = c;
                    if (!isNaN(r)) root.ramUsage = r;
                    if (!isNaN(t)) root.cpuTemp = t;
                }
            }
        }
    }

    onRevealedChanged: {
        if (root.revealed) {
            statsProc.running = true;
        }
    }

    Timer {
        interval: 2500
        running: root.revealed
        repeat: true
        onTriggered: {
            statsProc.running = true;
        }
    }

    // Battery icon helper
    function getBatteryIcon(pct, state) {
        if (state === UPowerDeviceState.Charging)
            return Quickshell.shellDir + "/assets/icons/Battery-Charging.svg";
        if (pct >= 0.70)
            return Quickshell.shellDir + "/assets/icons/Battery-Full.svg";
        if (pct >= 0.20)
            return Quickshell.shellDir + "/assets/icons/Battery-Mid.svg";
        if (pct >= 0.10)
            return Quickshell.shellDir + "/assets/icons/Battery-Low.svg";
        return Quickshell.shellDir + "/assets/icons/Battery-Critical.svg";
    }

    button: IconTextButton {
        iconSource: root.getBatteryIcon(UPower.displayDevice?.percentage ?? 1, UPower.displayDevice?.state ?? UPowerDeviceState.Unknown)
        iconPosition: IconTextButton.IconPosition.TextBeforeIcon
        text: Math.round((UPower.displayDevice?.percentage ?? 1) * 100) + "%"
        buttonStyle: Button.Style.Normal
    }

    // Throttled scroll navigation across stack
    property real sysInfoScrollAccumulator: 0
    property bool sysInfoCooldown: false

    Timer {
        id: sysInfoCooldownTimer
        interval: 150
        onTriggered: {
            root.sysInfoCooldown = false;
            root.sysInfoScrollAccumulator = 0;
        }
    }

    Stack {
        id: sysStack
        wrap: true
        anchors.verticalCenter: parent.verticalCenter

        IconTextButton {
            iconSource: Quickshell.shellDir + "/assets/icons/Cpu.svg"
            text: "CPU: " + root.cpuUsage + "%"
            buttonStyle: Button.Style.Normal
            onClicked: sysStack.next()
        }

        IconTextButton {
            iconSource: Quickshell.shellDir + "/assets/icons/Ram.svg"
            text: "RAM: " + root.ramUsage + "%"
            buttonStyle: Button.Style.Normal
            onClicked: sysStack.next()
        }

        IconTextButton {
            iconSource: Quickshell.shellDir + "/assets/icons/Temp.svg"
            text: "Temp: " + root.cpuTemp + "°C"
            buttonStyle: Button.Style.Normal
            onClicked: sysStack.next()
        }
    }
}
