import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    width: 30
    height: parent.height

    property string activeTab: "wifi"

    Text {
        anchors.centerIn: parent
        text: "󰖩" // Wifi Icon
        color: "white"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: menuPopup.open()
    }

    // Equivalent to <popover>
    Popup {
        id: menuPopup
        y: parent.height + 4 // Position below the bar
        width: 300
        height: 400
        background: Rectangle {
            color: "#1e1e2e"
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8

            // Tab Switcher
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: activeTab === "wifi" ? "#89b4fa" : "#313244" // primary-bg
                    Text { anchors.centerIn: parent; text: "Wi-Fi"; color: "white" }
                    MouseArea { anchors.fill: parent; onClicked: activeTab = "wifi" }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: activeTab === "bluetooth" ? "#89b4fa" : "#313244"
                    Text { anchors.centerIn: parent; text: "Bluetooth"; color: "white" }
                    MouseArea { anchors.fill: parent; onClicked: activeTab = "bluetooth" }
                }
            }

            // Tab Content Wrapper
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Wifi List Content
                ScrollView {
                    anchors.fill: parent
                    visible: activeTab === "wifi"
                    // Implement a ListView here using nmcli JSON output or DBus
                }

                // Bluetooth List Content
                ScrollView {
                    anchors.fill: parent
                    visible: activeTab === "bluetooth"
                    // Implement a ListView here using bluetoothctl JSON output or DBus
                }
            }
        }
    }
}
