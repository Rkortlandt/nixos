import QtQuick
import Quickshell
import "../../../core"

Row {
    id: root
    spacing: 10

    property bool kbdIsOn: false
    property int kbdBrightness: 0
    property int kbdMaxBrightness: 1
    readonly property real kbdPercent: (kbdMaxBrightness > 0) ? (kbdBrightness / kbdMaxBrightness) * 100 : (kbdIsOn ? 100 : 0)

    IconImage {
        implicitSize: 18
        source: Quickshell.shellDir + "/assets/icons/Keyboard-Brightness.svg"
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: "Keyboard: " + (root.kbdPercent > 0 ? "On" : "Off")
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: Theme.fontBold
        color: Theme.normalText
        anchors.verticalCenter: parent.verticalCenter
    }
}
