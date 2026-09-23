// modules/island/ConnectivityView.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../core"

FocusScope {
    id: root

    focus: ConnectivityService.isOpen

    Keys.onEscapePressed: event => {
        ConnectivityService.close();
        event.accepted = true;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // =====================================================================
        // HEADER ROW: TABS & CLOSE BUTTON
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Tab Switcher Container with sliding pill indicator
            Rectangle {
                id: tabContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 16
                color: "#161616"
                border.color: "#282828"
                border.width: 1

                readonly property real tabWidth: (width - 4) / 2

                // Smooth Sliding Active Pill
                Rectangle {
                    id: selectionPill
                    y: 2
                    height: parent.height - 4
                    width: tabContainer.tabWidth
                    radius: 14
                    color: Theme.primaryBg

                    x: ConnectivityService.activeTab === "wifi" ? 2 : (parent.width - width - 2)

                    Behavior on x {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 0

                    // Wi-Fi Tab Button Touch Target
                    Item {
                        width: tabContainer.tabWidth
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: tabWifiMouse.containsMouse && ConnectivityService.activeTab !== "wifi" ? "#18ffffff" : "transparent"
                        }

                        MouseArea {
                            id: tabWifiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ConnectivityService.open("wifi")
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            IconImage {
                                implicitSize: 20
                                source: Qt.resolvedUrl("../../assets/icons/Wifi-High.svg")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Wi-Fi"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                                color: Theme.normalText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Bluetooth Tab Button Touch Target
                    Item {
                        width: tabContainer.tabWidth
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: tabBtMouse.containsMouse && ConnectivityService.activeTab !== "bluetooth" ? "#18ffffff" : "transparent"
                        }

                        MouseArea {
                            id: tabBtMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ConnectivityService.open("bluetooth")
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            IconImage {
                                implicitSize: 20
                                source: Qt.resolvedUrl("../../assets/icons/Bluetooth.svg")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Bluetooth"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                                color: Theme.normalText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // Square Close Button
            IconButton {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                customRadius: 6
                buttonStyle: Button.Style.Normal
                backgroundColor: "#161616"
                hoverColor: "#282828"
                iconSize: 22
                source: Qt.resolvedUrl("../../assets/icons/Close.svg")
                onClicked: ConnectivityService.close()
            }
        }

        // =====================================================================
        // CONTENT AREA (WI-FI vs BLUETOOTH)
        // =====================================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Loader {
                id: tabContentLoader
                anchors.fill: parent
                source: ConnectivityService.activeTab === "wifi" ? "WifiView.qml" : "BluetoothView.qml"
            }
        }
    }
}
