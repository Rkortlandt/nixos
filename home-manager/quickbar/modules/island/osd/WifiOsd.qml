import QtQuick
import Quickshell
import "../../../core"

Row {
    id: root
    spacing: 10

    property string ssid: ""
    property int signalStrength: 0
    property bool isConnected: ssid.length > 0

    readonly property string wifiIcon: {
        if (!root.isConnected)
            return Quickshell.shellDir + "/assets/icons/Wifi-Disabled.svg";
        if (root.signalStrength >= 75)
            return Quickshell.shellDir + "/assets/icons/Wifi-High.svg";
        if (root.signalStrength >= 50)
            return Quickshell.shellDir + "/assets/icons/Wifi-Mid.svg";
        if (root.signalStrength >= 25)
            return Quickshell.shellDir + "/assets/icons/Wifi-Low.svg";
        return Quickshell.shellDir + "/assets/icons/Wifi-Zero.svg";
    }

    IconImage {
        implicitSize: 18
        source: root.wifiIcon
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: root.isConnected ? root.ssid : "Wi-Fi Disconnected"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: Theme.fontBold
        color: Theme.normalText
        anchors.verticalCenter: parent.verticalCenter
    }
}
