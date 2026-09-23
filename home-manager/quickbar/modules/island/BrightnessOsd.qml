import QtQuick
import "../../core"

Row {
    id: root
    spacing: 10

    property real brightnessPercent: 100
    signal interaction()

    IconImage {
        implicitSize: 18
        source: Qt.resolvedUrl("../../assets/icons/Brightness.svg")
        anchors.verticalCenter: parent.verticalCenter
    }

    Slider {
        id: brightnessSlider
        implicitWidth: 160
        implicitHeight: 8
        anchors.verticalCenter: parent.verticalCenter
        value: root.brightnessPercent / 100.0
        onMoved: {
            root.interaction();
        }
    }

    Text {
        text: Math.round(root.brightnessPercent) + "%"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: Theme.fontBold
        color: Theme.normalText
        anchors.verticalCenter: parent.verticalCenter
    }
}
