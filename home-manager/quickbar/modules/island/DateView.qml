import QtQuick
import "../../core"
import "../.."

Row {
    id: root
    spacing: 8

    Text {
        text: Time.date
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: Theme.fontBold
        color: Theme.normalText
        anchors.verticalCenter: parent.verticalCenter
    }
}
