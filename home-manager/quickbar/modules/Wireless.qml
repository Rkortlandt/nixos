// modules/Wireless.qml
import QtQuick
import "../core"

Rectangle {
    id: root

    readonly property real btnWidth: Theme.defaultHeight
    readonly property real btnHeight: Theme.defaultHeight - 4
    readonly property real paddingOuter: 4
    readonly property real spacingBetween: 2

    implicitHeight: Theme.defaultHeight
    implicitWidth: (btnWidth * 2) + spacingBetween + (paddingOuter * 2)
    radius: Theme.defaultHeight / 2.2
    color: Theme.normalBg

    // Network & Bluetooth tracking via ConnectivityService
    readonly property string wifiIcon: {
        if (!ConnectivityService.wifiEnabled)
            return Qt.resolvedUrl("../assets/icons/Wifi-Disabled.svg");
        if (ConnectivityService.wifiScanning)
            return Qt.resolvedUrl("../assets/icons/Wifi-Acquiring.svg");
        if (!ConnectivityService.wifiActiveSsid || ConnectivityService.wifiActiveSsid.length === 0)
            return Qt.resolvedUrl("../assets/icons/Wifi-Disabled.svg");
        if (ConnectivityService.wifiActiveSignal >= 75)
            return Qt.resolvedUrl("../assets/icons/Wifi-High.svg");
        if (ConnectivityService.wifiActiveSignal >= 50)
            return Qt.resolvedUrl("../assets/icons/Wifi-Mid.svg");
        if (ConnectivityService.wifiActiveSignal >= 25)
            return Qt.resolvedUrl("../assets/icons/Wifi-Low.svg");
        return Qt.resolvedUrl("../assets/icons/Wifi-Zero.svg");
    }

    readonly property string bluetoothIcon: ConnectivityService.btPowered
        ? Qt.resolvedUrl("../assets/icons/Bluetooth.svg")
        : Qt.resolvedUrl("../assets/icons/Bluetooth-Disabled.svg")

    // Sliding Selection Pill on the Bar
    Rectangle {
        id: barSelectionPill
        y: (root.height - height) / 2
        height: root.btnHeight
        width: root.btnWidth
        radius: height / 2
        color: Theme.primaryBg

        opacity: ConnectivityService.isOpen ? 1.0 : 0.0
        scale: ConnectivityService.isOpen ? 1.0 : 0.85

        x: ConnectivityService.activeTab === "wifi"
            ? root.paddingOuter
            : (root.paddingOuter + root.btnWidth + root.spacingBetween)

        Behavior on x {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: root.spacingBetween

        // Wi-Fi Button
        Item {
            width: root.btnWidth
            height: root.btnHeight

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: wifiMouse.containsMouse && (!ConnectivityService.isOpen || ConnectivityService.activeTab !== "wifi")
                    ? Theme.normalHoverBg
                    : "transparent"
            }

            MouseArea {
                id: wifiMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ConnectivityService.toggle("wifi")
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: root.wifiIcon
            }
        }

        // Bluetooth Button
        Item {
            width: root.btnWidth
            height: root.btnHeight

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: btMouse.containsMouse && (!ConnectivityService.isOpen || ConnectivityService.activeTab !== "bluetooth")
                    ? Theme.normalHoverBg
                    : "transparent"
            }

            MouseArea {
                id: btMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ConnectivityService.toggle("bluetooth")
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: root.bluetoothIcon
            }
        }
    }
}
