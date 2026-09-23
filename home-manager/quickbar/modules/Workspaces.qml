// modules/Workspaces.qml
import QtQuick
import Quickshell.Hyprland
import "../core"

ButtonGroup {
    id: root

    // Sensitivity throttling helper for mouse wheel
    property real wsScrollAccumulator: 0
    property bool wsScrollCooldown: false

    Timer {
        id: wsCooldownTimer
        interval: 150
        onTriggered: {
            root.wsScrollCooldown = false;
            root.wsScrollAccumulator = 0;
        }
    }

    function handleWorkspaceScroll(wheel) {
        let delta = ScrollHelper.getDelta(wheel, 1.0);
        if (delta === 0 || root.wsScrollCooldown) return;

        root.wsScrollAccumulator += delta;
        if (root.wsScrollAccumulator >= 0.8) {
            Hyprland.dispatch("workspace e-1");
            root.wsScrollCooldown = true;
            wsCooldownTimer.restart();
        } else if (root.wsScrollAccumulator <= -0.8) {
            Hyprland.dispatch("workspace e+1");
            root.wsScrollCooldown = true;
            wsCooldownTimer.restart();
        }
    }

    Repeater {
        model: {
            if (!Hyprland.workspaces || !Hyprland.workspaces.values) return [];
            return Hyprland.workspaces.values
                .filter(ws => ws && ws.id > 0)
                .sort((a, b) => a.id - b.id);
        }

        TextButton {
            text: modelData.id.toString()
            paddingHorizontal: 10
            buttonStyle: Button.Style.Normal
            backgroundColor: Theme.normalBg
            textColor: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData.id)
                ? Theme.workspaceActive
                : Theme.workspaceInactive
            onClicked: Hyprland.dispatch("workspace " + modelData.id)
            onScrolled: wheel => root.handleWorkspaceScroll(wheel)
        }
    }
}
