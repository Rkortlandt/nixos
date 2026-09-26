// modules/island/MainMenuView.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../core"

FocusScope {
    id: root
    anchors.fill: parent
    focus: MenuService.isOpen

    Keys.onEscapePressed: event => {
        MenuService.close();
        event.accepted = true;
    }

    // Catch clicks inside the menu card so they do not fall through to the dismissal backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    SystemClock {
        id: sysClock
        precision: SystemClock.Seconds
    }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // =============================================================
        // 1. TOP HEADER: DIGITAL CLOCK & DATE (12-hour format)
        // =============================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.bottomMargin: 2

            // Digital Clock
            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: clockHoursMins
                    text: Qt.formatDateTime(sysClock.date, "h:mm ap").replace(/\s*[ap]m/i, "")
                    font.family: Theme.fontFamily
                    font.pixelSize: 34
                    font.bold: true
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: Qt.formatDateTime(sysClock.date, "AP")
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: "#ffffff"
                    }

                    Text {
                        text: Qt.formatDateTime(sysClock.date, "ss")
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: "#777777"
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Date & Subtitle
            Column {
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: Qt.formatDateTime(sysClock.date, "dddd, d MMMM").toUpperCase()
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.normalText
                    horizontalAlignment: Text.AlignRight
                    anchors.right: parent.right
                }

                Text {
                    text: Qt.formatDateTime(sysClock.date, "MM/dd/yyyy")
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: "#777777"
                    horizontalAlignment: Text.AlignRight
                    anchors.right: parent.right
                }
            }
        }

        // =============================================================
        // 2. QUICK TOGGLES: WI-FI, BLUETOOTH, CAFE MODE, KBD BACKLIGHT
        // =============================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // --- WI-FI BUTTON ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 14
                color: wifiCardMouse.containsMouse ? "#1a1a1a" : "transparent"
                border.color: Theme.cardBorder
                border.width: 1

                MouseArea {
                    id: wifiCardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ConnectivityService.open("wifi")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 12
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: ConnectivityService.wifiEnabled ? Theme.primaryBg : (wifiCircleMouse.containsMouse ? "#222222" : "transparent")
                        border.color: ConnectivityService.wifiEnabled ? Theme.primaryBorder : Theme.cardBorder

                        MouseArea {
                            id: wifiCircleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                mouse.accepted = true;
                                ConnectivityService.toggleWifi();
                            }
                        }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 24
                            source: ConnectivityService.wifiEnabled ? (Quickshell.shellDir + "/assets/icons/Wifi-High.svg") : (Quickshell.shellDir + "/assets/icons/Wifi-Disabled.svg")
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: ConnectivityService.wifiActiveSsid || "Wi-Fi"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.normalText
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: ConnectivityService.wifiEnabled ? (ConnectivityService.wifiActiveSsid ? "CONNECTED" : "ON") : "OFF"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            color: ConnectivityService.wifiEnabled ? Theme.accentText : "#777777"
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }
            }

            // --- BLUETOOTH BUTTON ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 14
                color: btCardMouse.containsMouse ? "#1a1a1a" : "transparent"
                border.color: Theme.cardBorder
                border.width: 1

                MouseArea {
                    id: btCardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ConnectivityService.open("bluetooth")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 12
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: ConnectivityService.btPowered ? Theme.primaryBg : (btCircleMouse.containsMouse ? "#222222" : "transparent")
                        border.color: ConnectivityService.btPowered ? Theme.primaryBorder : Theme.cardBorder

                        MouseArea {
                            id: btCircleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                mouse.accepted = true;
                                ConnectivityService.toggleBt();
                            }
                        }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 24
                            source: ConnectivityService.btPowered ? (ConnectivityService.btHasConnectedDevice ? (Quickshell.shellDir + "/assets/icons/Bluetooth-Connected.svg") : (Quickshell.shellDir + "/assets/icons/Bluetooth.svg")) : (Quickshell.shellDir + "/assets/icons/Bluetooth-Disabled.svg")
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: "Bluetooth"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.normalText
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: ConnectivityService.btPowered ? "ON" : "OFF"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            color: ConnectivityService.btPowered ? Theme.accentText : "#777777"
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }
            }

            // --- CAFE MODE BUTTON (Half Width) ---
            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 52
                radius: 14
                color: MenuService.cafeMode ? Theme.accentBg : (cafeMouse.containsMouse ? "#1a1a1a" : "transparent")
                border.color: MenuService.cafeMode ? Theme.accentBorder : Theme.cardBorder
                border.width: 1

                MouseArea {
                    id: cafeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MenuService.toggleCafeMode()
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 24
                    source: Quickshell.shellDir + "/assets/icons/Coffee.svg"
                }
            }

            // --- KEYBOARD BACKLIGHT BUTTON (Half Width) ---
            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 52
                radius: 14
                color: BacklightService.kbdBrightness > 0 ? Theme.primaryBg : (kbdMouse.containsMouse ? "#1a1a1a" : "transparent")
                border.color: BacklightService.kbdBrightness > 0 ? Theme.primaryBorder : Theme.cardBorder
                border.width: 1

                MouseArea {
                    id: kbdMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BacklightService.toggleKbd()
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 24
                    source: Quickshell.shellDir + "/assets/icons/Keyboard-Brightness.svg"
                }
            }
        }

        // =============================================================
        // 3. MEDIA PLAYER (Shared MediaPlayer Component)
        // =============================================================
        MediaPlayer {
            Layout.fillWidth: true
            Layout.preferredHeight: 96
            artSize: 86
            artBorderWidth: 2
            totalBars: 30
        }

        // =============================================================
        // 4. TWO BLANK PLACEHOLDER SECTIONS (Timer & System Stats)
        // =============================================================
        RowLayout {
            id: cardsRow
            Layout.fillWidth: true
            spacing: 10

            readonly property real totalRowWidth: mainCol.width > 0 ? mainCol.width : (root.width > 0 ? root.width - 36 : 464)
            readonly property real availableWidth: Math.max(0, totalRowWidth - cardsRow.spacing)
            readonly property real leftWidth: availableWidth * (2.0 / 3.0)
            readonly property real rightWidth: availableWidth * (1.0 / 3.0)
            readonly property real calculatedHeight: leftWidth > 0 ? Math.round(leftWidth / 1.625) : 110

            Layout.preferredHeight: calculatedHeight

            // Left Weather Card (2/3 of area - spacing)
            Weather {
                Layout.preferredWidth: cardsRow.leftWidth
                Layout.preferredHeight: cardsRow.calculatedHeight
                Layout.fillHeight: true
            }

            // Right Placeholder Card (1/3 of area - spacing)
            Rectangle {
                Layout.preferredWidth: cardsRow.rightWidth
                Layout.preferredHeight: cardsRow.calculatedHeight
                Layout.fillHeight: true
                radius: 18
                color: "transparent"
                border.color: Theme.cardBorder
                border.width: 1
            }
        }
        // Bottom Pagination Dots Indicator
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            Layout.topMargin: 2

            Rectangle {
                width: 14
                height: 4
                radius: 2
                color: "#ffffff"
            }

            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: "#444444"
            }

            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: "#444444"
            }
        }

        // =============================================================
        // 5. FOOTER: ACTIONS (Launcher, Lock, Notifications, Power)
        // =============================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            // App Launcher
            IconButton {
                implicitWidth: 44
                implicitHeight: 44
                customRadius: 14
                buttonStyle: Button.Style.Normal
                backgroundColor: "transparent"
                hoverColor: "#1a1a1a"
                bordered: true
                borderColor: Theme.cardBorder
                iconSize: 18
                source: Quickshell.shellDir + "/assets/icons/App-Menu.svg"
                onClicked: {
                    MenuService.close();
                    launcherProc.running = true;
                }
            }

            // Lock Screen
            IconButton {
                implicitWidth: 44
                implicitHeight: 44
                customRadius: 14
                buttonStyle: Button.Style.Normal
                backgroundColor: "transparent"
                hoverColor: "#1a1a1a"
                bordered: true
                borderColor: Theme.cardBorder
                iconSize: 18
                source: Quickshell.shellDir + "/assets/icons/Locked.svg"
                onClicked: {
                    MenuService.close();
                    lockProc.running = true;
                }
            }

            // Notifications
            IconButton {
                implicitWidth: 44
                implicitHeight: 44
                customRadius: 14
                buttonStyle: Button.Style.Normal
                backgroundColor: "transparent"
                hoverColor: "#1a1a1a"
                bordered: true
                borderColor: Theme.cardBorder
                iconSize: 18
                source: Quickshell.shellDir + "/assets/icons/Notification.svg"
                onClicked: {
                    MenuService.close();
                }
            }

            // Power / Session
            IconButton {
                implicitWidth: 44
                implicitHeight: 44
                customRadius: 14
                buttonStyle: Button.Style.Normal
                backgroundColor: "transparent"
                hoverColor: "#3a1818"
                bordered: true
                borderColor: Theme.cardBorder
                iconSize: 18
                source: Quickshell.shellDir + "/assets/icons/Shutdown.svg"
                onClicked: {
                    MenuService.close();
                    powerProc.running = true;
                }
            }
        }
    }

    Process {
        id: launcherProc
        command: ["tofi-drun", "--drun-launch=true"]
    }

    Process {
        id: lockProc
        command: ["hyprlock"]
    }

    Process {
        id: powerProc
        command: ["systemctl", "poweroff"]
    }
}
