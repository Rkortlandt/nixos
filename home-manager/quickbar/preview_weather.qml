import QtQuick
import Quickshell
import "modules/island/menu" as Menu

PanelWindow {
    id: win
    visible: true
    implicitWidth: 700
    implicitHeight: 260
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: "#0a0a0c"
        radius: 20
        border.color: "#333333"
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: 20

            // 1. Rainy card with rain measure chip
            Menu.Weather {
                width: 320
                height: 197
                variant: "rainy"
            }

            // 2. Overcast card with smooth text gradient
            Menu.Weather {
                width: 320
                height: 197
                variant: "overcast"
            }
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Click anywhere to close preview | Auto-closes in 60s"
            color: "#666666"
            font.pixelSize: 11
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }
    }

    Timer {
        interval: 60000
        running: true
        onTriggered: Qt.quit()
    }
}
