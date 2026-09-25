// modules/Backlight.qml
import QtQuick
import Quickshell
import "../core"

IconTextButton {
    id: root

    // Gentle scroll accumulator (2% screen brightness per full notch)
    property real brightnessScrollAccumulator: 0
    Timer {
        id: brightnessScrollTimer
        interval: 250
        onTriggered: root.brightnessScrollAccumulator = 0
    }

    onScrolled: wheel => {
        let delta = ScrollHelper.getDelta(wheel, 2.0);
        if (delta === 0) return;

        root.brightnessScrollAccumulator += delta;
        brightnessScrollTimer.restart();
        if (Math.abs(root.brightnessScrollAccumulator) >= 1.0) {
            let change = Math.round(root.brightnessScrollAccumulator);
            BacklightService.adjustScreen(change);
            root.brightnessScrollAccumulator -= change;
        }
    }

    // Button visual properties
    iconSource: Quickshell.shellDir + "/assets/icons/Brightness.svg"
    text: Math.round(BacklightService.screenPercent) + "%"
    buttonStyle: Button.Style.Normal
    backgroundColor: Theme.normalBg

    onClicked: BacklightService.toggleKbd()
}
