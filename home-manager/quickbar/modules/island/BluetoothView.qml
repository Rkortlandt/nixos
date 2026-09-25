// modules/island/BluetoothView.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../core"

Item {
    id: root
    anchors.fill: parent

    // --- Disabled State ---
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        visible: !ConnectivityService.btPowered

        IconImage {
            implicitSize: 48
            source: Quickshell.shellDir + "/assets/icons/Bluetooth-Disabled.svg"
            opacity: 0.5
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "Bluetooth is Disabled"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            color: Theme.normalText
            opacity: 0.7
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            buttonStyle: Button.Style.Primary
            paddingHorizontal: 16
            implicitHeight: 32
            customRadius: 16
            Layout.alignment: Qt.AlignHCenter
            onClicked: ConnectivityService.toggleBt()

            Text {
                anchors.centerIn: parent
                text: "Turn On Bluetooth"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                color: Theme.primaryText
            }
        }
    }

    // --- Enabled State ---
    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        visible: ConnectivityService.btPowered

        // Controls Row (Power Toggle + Dead Space)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Rounded Pill Power Toggle
            Rectangle {
                Layout.preferredWidth: 124
                Layout.preferredHeight: 28
                radius: 14
                color: ConnectivityService.btPowered ? Theme.primaryBg : (btPwrMouse.containsMouse ? Theme.cardHoverBg : Theme.itemBg)
                border.color: ConnectivityService.btPowered ? Theme.primaryBorder : Theme.cardBorder
                border.width: 1

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                MouseArea {
                    id: btPwrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ConnectivityService.toggleBt()
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    IconImage {
                        implicitSize: 18
                        source: ConnectivityService.btPowered ? (ConnectivityService.btHasConnectedDevice ? (Quickshell.shellDir + "/assets/icons/Bluetooth-Connected.svg") : (Quickshell.shellDir + "/assets/icons/Bluetooth.svg")) : (Quickshell.shellDir + "/assets/icons/Bluetooth-Disabled.svg")
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: ConnectivityService.btPowered ? "Bluetooth On" : "Bluetooth Off"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                        color: Theme.normalText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Square Scan for Devices Icon Button
            IconButton {
                id: btScanBtn
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                customRadius: 6
                buttonStyle: ConnectivityService.btScanning ? Button.Style.Accent : Button.Style.Normal
                backgroundColor: ConnectivityService.btScanning ? Theme.accentBg : Theme.cardBg
                hoverColor: ConnectivityService.btScanning ? Theme.accentHoverBg : Theme.cardHoverBg
                iconSize: 24
                source: Quickshell.shellDir + "/assets/icons/Loading.svg"
                onClicked: ConnectivityService.toggleBtDiscovery()

                RotationAnimation {
                    target: btScanBtn.icon
                    property: "rotation"
                    running: ConnectivityService.btScanning
                    from: 0
                    to: 360
                    loops: Animation.Infinite
                    duration: 800
                }
            }
        }

        // Devices Scroll Area
        Flickable {
            id: btFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: btCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 5000
            maximumFlickVelocity: 4000
            pixelAligned: true

            WheelHandler {
                orientation: Qt.Vertical
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    let delta = event.angleDelta.y;
                    let scrollDelta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : delta * 0.8;
                    let maxScroll = Math.max(0, btFlickable.contentHeight - btFlickable.height);
                    btFlickable.contentY = Math.max(0, Math.min(maxScroll, btFlickable.contentY - scrollDelta));
                }
            }

            ColumnLayout {
                id: btCol
                width: parent.width
                spacing: 8

                function isRealName(dev) {
                    if (!dev)
                        return false;
                    let n = (dev.name || "").trim();
                    let a = (dev.alias || "").trim();
                    let isMac = /^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/;
                    if (a.length > 0 && !isMac.test(a))
                        return true;
                    if (n.length > 0 && !isMac.test(n))
                        return true;
                    return false;
                }

                function getDeviceLabel(dev) {
                    if (!dev)
                        return "";
                    let n = (dev.name || "").trim();
                    let a = (dev.alias || "").trim();
                    let isMac = /^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/;
                    if (a.length > 0 && !isMac.test(a))
                        return a;
                    if (n.length > 0 && !isMac.test(n))
                        return n;
                    return dev.address || a || n || "";
                }

                readonly property var allDevices: (ConnectivityService.btAdapter && ConnectivityService.btAdapter.devices) ? ConnectivityService.btAdapter.devices.values : []
                readonly property var pairedList: {
                    let paired = allDevices.filter(d => d.paired);
                    return paired.slice().sort((a, b) => {
                        if (a.connected && !b.connected)
                            return -1;
                        if (!a.connected && b.connected)
                            return 1;

                        let hasNameA = btCol.isRealName(a);
                        let hasNameB = btCol.isRealName(b);

                        if (hasNameA && !hasNameB)
                            return -1;
                        if (!hasNameA && hasNameB)
                            return 1;

                        let labelA = btCol.getDeviceLabel(a);
                        let labelB = btCol.getDeviceLabel(b);
                        return labelA.localeCompare(labelB, undefined, {
                            sensitivity: 'base'
                        });
                    });
                }
                readonly property var availableList: {
                    let unpair = allDevices.filter(d => !d.paired);
                    return unpair.slice().sort((a, b) => {
                        let hasNameA = btCol.isRealName(a);
                        let hasNameB = btCol.isRealName(b);

                        if (hasNameA && !hasNameB)
                            return -1;
                        if (!hasNameA && hasNameB)
                            return 1;

                        let labelA = btCol.getDeviceLabel(a);
                        let labelB = btCol.getDeviceLabel(b);
                        return labelA.localeCompare(labelB, undefined, {
                            sensitivity: 'base'
                        });
                    });
                }

                // --- PAIRED DEVICES SECTION ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: btCol.pairedList.length > 0

                    Text {
                        text: "PAIRED DEVICES"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: "#888888"
                        horizontalAlignment: Text.AlignLeft
                        Layout.leftMargin: 4
                    }

                    Repeater {
                        model: btCol.pairedList

                        Item {
                            id: pairedDelegate
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36

                            readonly property var dev: modelData
                            readonly property bool isDevConnecting: ConnectivityService.btConnectingAddr === dev.address

                            RowLayout {
                                anchors.fill: parent
                                spacing: 4

                                // Main Clickable Device Row
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 8
                                    color: dev.connected ? Theme.primaryBg : (devMouse.containsMouse ? Theme.itemHoverBg : Theme.itemBg)
                                    border.color: dev.connected ? Theme.primaryBorder : "transparent"
                                    border.width: dev.connected ? 1 : 0

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    MouseArea {
                                        id: devMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (dev.connected) {
                                                ConnectivityService.disconnectBt(dev.address);
                                            } else {
                                                ConnectivityService.connectBt(dev.address);
                                            }
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        IconImage {
                                            implicitSize: 18
                                            source: dev.connected ? (Quickshell.shellDir + "/assets/icons/Bluetooth-Connected.svg") : (Quickshell.shellDir + "/assets/icons/Bluetooth.svg")
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: btCol.getDeviceLabel(dev)
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize
                                            font.bold: dev.connected
                                            color: Theme.normalText
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignLeft
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: dev.batteryPercentage !== undefined && dev.batteryPercentage > -1 ? Math.floor(dev.batteryPercentage * 100) + "%" : (dev.battery !== undefined && dev.battery > -1 ? Math.floor(dev.battery) + "%" : "")
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            color: "#aaaaaa"
                                            visible: text.length > 0
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: "Connecting..."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            color: Theme.accentText
                                            visible: pairedDelegate.isDevConnecting
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }
                                }

                                // Square Forget/Unpair Button
                                IconButton {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    customRadius: 6
                                    buttonStyle: Button.Style.Normal
                                    backgroundColor: "transparent"
                                    hoverColor: Theme.cardHoverBg
                                    iconSize: 18
                                    source: Quickshell.shellDir + "/assets/icons/Close.svg"
                                    onClicked: ConnectivityService.unpairBt(dev.address)
                                }
                            }
                        }
                    }
                }

                // --- AVAILABLE DEVICES SECTION ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: btCol.availableList.length > 0

                    Text {
                        text: "AVAILABLE DEVICES"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: "#888888"
                        horizontalAlignment: Text.AlignLeft
                        Layout.leftMargin: 4
                        Layout.topMargin: 4
                    }

                    Repeater {
                        model: btCol.availableList

                        Item {
                            id: availDelegate
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36

                            readonly property var dev: modelData
                            readonly property bool isPairing: ConnectivityService.btPairingAddr === dev.address

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: availMouse.containsMouse ? Theme.itemHoverBg : Theme.itemBg

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                MouseArea {
                                    id: availMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ConnectivityService.pairBt(dev.address)
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    IconImage {
                                        implicitSize: 12
                                        source: Quickshell.shellDir + "/assets/icons/Bluetooth.svg"
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: btCol.getDeviceLabel(dev)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                        color: Theme.normalText
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignLeft
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: availDelegate.isPairing ? "Pairing..." : "Pair"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.accentText
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty search state
                Text {
                    text: "Searching for nearby devices..."
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: "#888888"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12
                    visible: ConnectivityService.btScanning && btCol.availableList.length === 0
                }
            }
        }
    }
}
