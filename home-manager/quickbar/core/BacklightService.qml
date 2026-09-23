// core/BacklightService.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Screen brightness
    property real screenBrightness: 100
    property real screenMaxBrightness: 100
    readonly property real screenPercent: (screenMaxBrightness > 0)
        ? (screenBrightness / screenMaxBrightness) * 100
        : 100

    // Keyboard backlight
    property int kbdBrightness: 0
    property int kbdMaxBrightness: 1
    readonly property real kbdPercent: (kbdMaxBrightness > 0)
        ? (kbdBrightness / kbdMaxBrightness) * 100
        : 0

    // Initialization flags to prevent spurious OSD popup on boot/launch
    property bool screenInitialized: false
    property bool kbdInitialized: false

    // Explicit adjustment signals for OSD display
    signal screenAdjusted(real percent)
    signal kbdAdjusted(real percent)

    // Dedicated high-speed event-driven sysfs & udev monitor process
    Process {
        id: monitorProc
        running: true
        command: ["bash", Qt.resolvedUrl("backlight_monitor.sh").toString().replace(/^file:\/\//, "")]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let line = data.trim();
                if (!line) return;
                let parts = line.split(" ");
                if (parts.length < 2) return;
                let key = parts[0];
                let val = parseInt(parts[1]);
                if (isNaN(val)) return;

                if (key === "MAX_SCREEN") {
                    if (val > 0) root.screenMaxBrightness = val;
                } else if (key === "MAX_KBD") {
                    if (val > 0) root.kbdMaxBrightness = val;
                } else if (key === "SCREEN") {
                    if (!root.screenInitialized) {
                        root.screenBrightness = val;
                        root.screenInitialized = true;
                    } else if (val !== root.screenBrightness) {
                        root.screenBrightness = val;
                        root.screenAdjusted(root.screenPercent);
                    }
                } else if (key === "KBD") {
                    if (!root.kbdInitialized) {
                        root.kbdBrightness = val;
                        root.kbdInitialized = true;
                    } else if (val !== root.kbdBrightness) {
                        root.kbdBrightness = val;
                        root.kbdAdjusted(root.kbdPercent);
                    }
                }
            }
        }
    }

    // Direct setter commands
    Process { id: setBrightnessProc }

    function adjustScreen(deltaPercent) {
        let adj = deltaPercent > 0 ? `+${deltaPercent}%` : `${Math.abs(deltaPercent)}%-`;
        setBrightnessProc.command = ["brightnessctl", "set", adj];
        setBrightnessProc.running = true;
    }

    function toggleKbd() {
        if (root.kbdBrightness > 0) {
            setBrightnessProc.command = ["brightnessctl", "--device=*kbd_backlight*", "set", "0"];
        } else {
            setBrightnessProc.command = ["brightnessctl", "--device=*kbd_backlight*", "set", "3"];
        }
        setBrightnessProc.running = true;
    }
}
