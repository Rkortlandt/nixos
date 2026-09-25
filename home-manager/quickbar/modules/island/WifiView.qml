// modules/island/WifiView.qml
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
        visible: !ConnectivityService.wifiEnabled

        IconImage {
            implicitSize: 48
            source: Quickshell.shellDir + "/assets/icons/Wifi-Disabled.svg"
            opacity: 0.5
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "Wi-Fi is Disabled"
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
            onClicked: ConnectivityService.toggleWifi()

            Text {
                anchors.centerIn: parent
                text: "Turn On Wi-Fi"
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
        visible: ConnectivityService.wifiEnabled

        // Controls Row (Power Toggle + Dead Space + Square Refresh Button on the right)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Rounded Pill Power Toggle
            Rectangle {
                Layout.preferredWidth: 104
                Layout.preferredHeight: 28
                radius: 14
                color: ConnectivityService.wifiEnabled ? Theme.primaryBg : (pwrMouse.containsMouse ? Theme.cardHoverBg : Theme.itemBg)
                border.color: ConnectivityService.wifiEnabled ? Theme.primaryBorder : Theme.cardBorder
                border.width: 1

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                MouseArea {
                    id: pwrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ConnectivityService.toggleWifi()
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    IconImage {
                        implicitSize: 18
                        source: ConnectivityService.wifiEnabled ? (Quickshell.shellDir + "/assets/icons/Wifi-High.svg") : (Quickshell.shellDir + "/assets/icons/Wifi-Disabled.svg")
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: ConnectivityService.wifiEnabled ? "Wi-Fi On" : "Wi-Fi Off"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                        color: Theme.normalText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Square Scan/Refresh Icon Button
            IconButton {
                id: wifiScanBtn
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                customRadius: 6
                buttonStyle: ConnectivityService.wifiScanning ? Button.Style.Accent : Button.Style.Normal
                backgroundColor: ConnectivityService.wifiScanning ? Theme.accentBg : Theme.cardBg
                hoverColor: ConnectivityService.wifiScanning ? Theme.accentHoverBg : Theme.cardHoverBg
                iconSize: 24
                source: Quickshell.shellDir + "/assets/icons/Loading.svg"
                onClicked: ConnectivityService.scanWifi()

                RotationAnimation {
                    target: wifiScanBtn.icon
                    property: "rotation"
                    running: ConnectivityService.wifiScanning
                    from: 0
                    to: 360
                    loops: Animation.Infinite
                    duration: 800
                }
            }
        }

        // Scrollable Networks List
        ListView {
            id: wifiListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: ConnectivityService.wifiList
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
                    let maxScroll = Math.max(0, wifiListView.contentHeight - wifiListView.height);
                    wifiListView.contentY = Math.max(0, Math.min(maxScroll, wifiListView.contentY - scrollDelta));
                }
            }

            delegate: Item {
                id: apDelegate
                width: wifiListView.width
                height: colLayout.implicitHeight

                readonly property var apData: modelData
                readonly property bool isConnecting: ConnectivityService.connectingSsid === apData.ssid
                readonly property bool isPrompting: ConnectivityService.passwordPromptSsid === apData.ssid

                function getSignalIcon(sig) {
                    if (sig >= 75)
                        return Quickshell.shellDir + "/assets/icons/Wifi-High.svg";
                    if (sig >= 50)
                        return Quickshell.shellDir + "/assets/icons/Wifi-Mid.svg";
                    if (sig >= 25)
                        return Quickshell.shellDir + "/assets/icons/Wifi-Low.svg";
                    return Quickshell.shellDir + "/assets/icons/Wifi-Zero.svg";
                }

                Column {
                    id: colLayout
                    width: parent.width
                    spacing: 4

                    // Main Network Item (Left-to-Right aligned)
                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: 8
                        color: apData.inUse ? Theme.primaryBg : (apMouse.containsMouse ? Theme.itemHoverBg : Theme.itemBg)
                        border.color: apData.inUse ? Theme.primaryBorder : "transparent"
                        border.width: apData.inUse ? 1 : 0

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        MouseArea {
                            id: apMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (apData.inUse) {
                                    ConnectivityService.disconnectWifi(apData.ssid);
                                } else {
                                    ConnectivityService.connectWifi(apData.ssid, "", apData.requiresPassword);
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            IconImage {
                                implicitSize: 16
                                source: apDelegate.getSignalIcon(apData.signal)
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: apData.ssid
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: apData.inUse
                                color: Theme.normalText
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignLeft
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            IconImage {
                                implicitSize: 11
                                source: Quickshell.shellDir + "/assets/icons/Locked.svg"
                                iconSize: 16
                                visible: apData.requiresPassword
                                opacity: 0.6
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: "Connecting..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.accentText
                                visible: apDelegate.isConnecting
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }

                    // Password Prompt Dropdown
                    Rectangle {
                        width: parent.width
                        height: apDelegate.isPrompting ? 36 : 0
                        visible: apDelegate.isPrompting
                        clip: true
                        radius: 8
                        color: Theme.cardBg
                        border.color: Theme.cardBorder
                        border.width: 1

                        Behavior on height {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 6

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TextInput {
                                    id: passInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    color: Theme.normalText
                                    clip: true
                                    focus: apDelegate.isPrompting

                                    onAccepted: {
                                        ConnectivityService.connectWifi(apData.ssid, text);
                                        text = "";
                                        ConnectivityService.passwordPromptSsid = "";
                                    }

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Enter password..."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        color: "#666666"
                                        visible: !passInput.text && !passInput.activeFocus
                                    }
                                }
                            }

                            Button {
                                Layout.preferredWidth: 56
                                Layout.fillHeight: true
                                customRadius: 6
                                buttonStyle: Button.Style.Accent
                                onClicked: {
                                    ConnectivityService.connectWifi(apData.ssid, passInput.text);
                                    passInput.text = "";
                                    ConnectivityService.passwordPromptSsid = "";
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Join"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.accentText
                                }
                            }

                            IconButton {
                                Layout.preferredWidth: 28
                                Layout.fillHeight: true
                                customRadius: 6
                                buttonStyle: Button.Style.Normal
                                backgroundColor: "transparent"
                                hoverColor: "#333333"
                                iconSize: 18
                                source: Quickshell.shellDir + "/assets/icons/Close.svg"
                                onClicked: ConnectivityService.passwordPromptSsid = ""
                            }
                        }
                    }
                }
            }
        }
    }
}
