// Bar.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "core"
import "modules"

Scope {
    id: root

    property string focusedMonitorName: ""

    Process {
        id: initMonProc
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let mons = JSON.parse(this.text);
                    for (let m of mons) {
                        if (m.focused) {
                            root.focusedMonitorName = m.name;
                            break;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event)
                return;
            if (event.name === "focusedmon") {
                let mon = event.data.split(",")[0];
                if (mon)
                    root.focusedMonitorName = mon;
            } else if (event.name === "workspace" || event.name === "workspacev2") {
                if (Hyprland.focusedWorkspace?.monitor?.name) {
                    root.focusedMonitorName = Hyprland.focusedWorkspace.monitor.name;
                }
            }
        }
    }

    // ==========================================
    // === MAIN BAR (Duplicated across all screens)
    // ==========================================
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                }
                margins {
                    top: 4
                    left: 4
                    right: 4
                }
                implicitHeight: Theme.defaultHeight
                exclusiveZone: implicitHeight
                color: "transparent"

                // Mask out the center so mouse clicks pass through to dynamic island and desktop
                mask: Region {
                    Region {
                        item: leftRow
                    }
                    Region {
                        item: rightRow
                    }
                }

                Row {
                    id: leftRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Workspaces {}
                    Volume {}
                    Microphone {}
                    SystemInfo {}
                }

                Row {
                    id: rightRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Wireless {}
                    Backlight {}
                    Clock {}
                }
            }
        }
    }

    // ==========================================
    // === DYNAMIC ISLAND (Only visible on focused monitor)
    // ==========================================
    Variants {
        model: Quickshell.screens
        delegate: Component {
            DynamicIsland {
                required property var modelData
                screen: modelData
                isScreenFocused: (root.focusedMonitorName === "" && modelData === Quickshell.screens[0]) || (modelData.name === root.focusedMonitorName)
            }
        }
    }
}
