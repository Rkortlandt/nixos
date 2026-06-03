import QtQuick
import Quickshell.Hyprland

Row {
    spacing: 2

    Repeater {
        // Filter for default workspaces (id > 0)
        model: Hyprland.workspaces.values.filter(ws => ws.id > 0)

        delegate: Rectangle {
            width: 25
            height: 25
            color: Hyprland.focusedWorkspace.id === modelData.id ? "#89b4fa" : "#313244"
            radius: 4

            Text {
                anchors.centerIn: parent
                text: modelData.id
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + modelData.id)
            }
        }
    }
}
