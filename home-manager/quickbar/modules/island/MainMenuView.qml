// modules/island/MainMenuView.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../core"
import "../.."

Item {
    id: root
    anchors.fill: parent

    SystemClock {
        id: sysClock
        precision: SystemClock.Seconds
    }

    readonly property var activePlayer: {
        let list = Mpris.players.values;
        if (!list || list.length === 0) return null;
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i];
        }
        for (let i = 0; i < list.length; i++) {
            if (list[i].trackTitle && list[i].trackTitle.length > 0) return list[i];
        }
        return null;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // =============================================================
        // 1. TOP HEADER: DIGITAL CLOCK & DATE
        // =============================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.bottomMargin: 2

            // Digital Clock
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: Qt.formatDateTime(sysClock.date, "h:mm")
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    font.bold: true
                    color: "#ffffff"
                }

                Text {
                    text: Qt.formatDateTime(sysClock.date, "AP")
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                    color: "#ffffff"
                    anchors.baseline: parent.baseline
                }

                Text {
                    text: Qt.formatDateTime(sysClock.date, "ss")
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: "#777777"
                    anchors.baseline: parent.baseline
                }
            }

            Item { Layout.fillWidth: true }

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
                    text: "DASHBOARD"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                    color: "#666666"
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
                radius: 26
                color: ConnectivityService.wifiEnabled ? Theme.primaryBg : "#161616"
                border.color: ConnectivityService.wifiEnabled ? Theme.primaryBorder : "#262626"
                border.width: 1

                MouseArea {
                    id: wifiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ConnectivityService.toggleWifi()
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
                        color: ConnectivityService.wifiEnabled ? "#000000" : "#222222"

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 18
                            source: ConnectivityService.wifiEnabled ? Qt.resolvedUrl("../../assets/icons/Wifi-High.svg") : Qt.resolvedUrl("../../assets/icons/Wifi-Disabled.svg")
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
                radius: 26
                color: ConnectivityService.btPowered ? Theme.primaryBg : "#161616"
                border.color: ConnectivityService.btPowered ? Theme.primaryBorder : "#262626"
                border.width: 1

                MouseArea {
                    id: btMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ConnectivityService.toggleBt()
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
                        color: ConnectivityService.btPowered ? "#000000" : "#222222"

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 18
                            source: ConnectivityService.btPowered ? Qt.resolvedUrl("../../assets/icons/Bluetooth.svg") : Qt.resolvedUrl("../../assets/icons/Bluetooth-Disabled.svg")
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
                color: MenuService.cafeMode ? Theme.accentBg : (cafeMouse.containsMouse ? "#222222" : "#161616")
                border.color: MenuService.cafeMode ? Theme.accentBorder : "#262626"
                border.width: 1

                MouseArea {
                    id: cafeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MenuService.toggleCafeMode()
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitSize: 18
                        source: Qt.resolvedUrl("../../assets/icons/Coffee.svg")
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "CAFE"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        color: MenuService.cafeMode ? Theme.accentText : "#888888"
                    }
                }
            }

            // --- KEYBOARD BACKLIGHT BUTTON (Half Width) ---
            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 52
                radius: 14
                color: BacklightService.kbdBrightness > 0 ? Theme.primaryBg : (kbdMouse.containsMouse ? "#222222" : "#161616")
                border.color: BacklightService.kbdBrightness > 0 ? Theme.primaryBorder : "#262626"
                border.width: 1

                MouseArea {
                    id: kbdMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BacklightService.toggleKbd()
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitSize: 18
                        source: Qt.resolvedUrl("../../assets/icons/Keyboard-Brightness.svg")
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: BacklightService.kbdBrightness > 0 ? (BacklightService.kbdBrightness + "/3") : "OFF"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        color: BacklightService.kbdBrightness > 0 ? Theme.accentText : "#888888"
                    }
                }
            }
        }

        // =============================================================
        // 3. MEDIA PLAYER CARD
        // =============================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 112
            radius: 18
            color: "#161616"
            border.color: "#242424"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Top Row: Track details + Playback Controls
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    SquircleArt {
                        artUrl: root.activePlayer?.trackArtUrl ?? ""
                        artSize: 42
                        cornerRadius: 8
                        borderWidth: 2
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: root.activePlayer?.trackTitle || "No Media Playing"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.normalText
                            elide: Text.ElideRight
                            width: 220
                        }

                        Text {
                            text: root.activePlayer?.trackArtist || (root.activePlayer?.identity || "Ready")
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: "#888888"
                            elide: Text.ElideRight
                            width: 220
                        }
                    }

                    // Controls Row
                    Row {
                        spacing: 6
                        Layout.alignment: Qt.AlignVCenter

                        IconButton {
                            implicitWidth: 28
                            implicitHeight: 28
                            customRadius: 14
                            iconSize: 14
                            source: Qt.resolvedUrl("../../assets/icons/Skip-Backward.svg")
                            buttonStyle: Button.Style.Normal
                            backgroundColor: "transparent"
                            onClicked: root.activePlayer?.previous()
                        }

                        Item {
                            width: 32
                            height: 32

                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: "#ffffff"
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 16
                                source: Qt.resolvedUrl(root.activePlayer?.isPlaying ? "../../assets/icons/Pause.svg" : "../../assets/icons/Play.svg")
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activePlayer?.togglePlaying()
                            }
                        }

                        IconButton {
                            implicitWidth: 28
                            implicitHeight: 28
                            customRadius: 14
                            iconSize: 14
                            source: Qt.resolvedUrl("../../assets/icons/Skip-Forward.svg")
                            buttonStyle: Button.Style.Normal
                            backgroundColor: "transparent"
                            onClicked: root.activePlayer?.next()
                        }
                    }
                }

                // Bottom Row: Elapsed time, Progress bar, Total time
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: {
                            let pos = root.activePlayer?.position ?? 0;
                            let m = Math.floor(pos / 60);
                            let s = Math.floor(pos % 60);
                            return m + ":" + (s < 10 ? "0" + s : s);
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: "#777777"
                    }

                    // Progress Track
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: "#282828"

                        Rectangle {
                            height: parent.height
                            radius: 2
                            color: Theme.accentBg
                            width: {
                                let len = root.activePlayer?.length || 1;
                                let pos = root.activePlayer?.position || 0;
                                return Math.min(parent.width, Math.max(0, (pos / len) * parent.width));
                            }
                        }
                    }

                    Text {
                        text: {
                            let len = root.activePlayer?.length ?? 0;
                            let m = Math.floor(len / 60);
                            let s = Math.floor(len % 60);
                            return m + ":" + (s < 10 ? "0" + s : s);
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: "#777777"
                    }
                }
            }
        }

        // =============================================================
        // 4. TWO BLANK PLACEHOLDER SECTIONS (Timer & System Stats)
        // =============================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            spacing: 10

            // Left Placeholder Card (Timer / Recording)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 18
                color: "#161616"
                border.color: "#242424"
                border.width: 1
            }

            // Right Placeholder Card (System Stats)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 18
                color: "#161616"
                border.color: "#242424"
                border.width: 1
            }
        }

        // =============================================================
        // 5. FOOTER: ACTIONS (Launcher, Lock, Notifications, Power)
        // =============================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 8

            Item { Layout.fillWidth: true }

            // App Launcher
            IconButton {
                implicitWidth: 44
                implicitHeight: 44
                customRadius: 14
                buttonStyle: Button.Style.Normal
                backgroundColor: "#161616"
                hoverColor: "#252525"
                iconSize: 18
                source: Qt.resolvedUrl("../../assets/icons/Apps.svg")
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
                backgroundColor: "#161616"
                hoverColor: "#252525"
                iconSize: 18
                source: Qt.resolvedUrl("../../assets/icons/Locked.svg")
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
                backgroundColor: "#161616"
                hoverColor: "#252525"
                iconSize: 18
                source: Qt.resolvedUrl("../../assets/icons/Bell.svg")
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
                backgroundColor: "#161616"
                hoverColor: "#3a1818"
                iconSize: 18
                source: Qt.resolvedUrl("../../assets/icons/Shutdown.svg")
                onClicked: {
                    MenuService.close();
                    powerProc.running = true;
                }
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
