import QtQuick
import "../../core"
import "../.."

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: MenuService.toggle()
    }

    Row {
        id: row
        spacing: 8
        anchors.centerIn: parent

        Text {
            text: Time.date
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: Theme.fontBold
            color: Theme.normalText
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
