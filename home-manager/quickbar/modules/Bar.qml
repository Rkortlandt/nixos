import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: window
    
    // Equivalent to namespace="my-bar" and exclusivitiy=EXCLUSIVE
    WlrLayershell.namespace: "my-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.anchor: WlrAnchor.Top | WlrAnchor.Left | WlrAnchor.Right
    exclusiveZone: height 

    height: 30
    color: "transparent" // Replace with your Adwaita/SCSS background color

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        // === LEFT SIDE ===
        Row {
            Layout.alignment: Qt.AlignLeft
            spacing: 4

            // Placeholders for your applets
            // InlineCalculator {}
            
            // Replicating the Revealer logic (hiding when calculator shows)
            Row {
                id: leftModules
                spacing: 4
                visible: !calculator.visible // Assuming a calculator property

                Workspace {}
                Audio {}
                // SpecialWorkspaces {}
                SystemInfo {}
            }
        }

        // === CENTER ===
        Item {
            Layout.fillWidth: true
            // Empty, reserves space in the middle
        }

        // === RIGHT SIDE ===
        Row {
            Layout.alignment: Qt.AlignRight
            spacing: 4

            // BarMprisPlayer {}
            Wireless {}
            Backlight {}
            Clock {}
        }
    }
}
