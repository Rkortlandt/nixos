import QtQuick
import Quickshell
import "../../../core"

Row {
    id: root
    spacing: 10

    property string deviceName: ""
    property bool connected: false

    IconImage {
        implicitSize: 18
        source: root.connected ? (Quickshell.shellDir + "/assets/icons/Bluetooth-Connected.svg") : (Quickshell.shellDir + "/assets/icons/Bluetooth-Disabled.svg")
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: root.connected ? (root.deviceName.length > 0 ? ("Connected: " + root.deviceName) : "Bluetooth Connected") : (root.deviceName.length > 0 ? ("Disconnected: " + root.deviceName) : "Bluetooth Disconnected")
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: Theme.fontBold
        color: Theme.normalText
        anchors.verticalCenter: parent.verticalCenter
    }
}
