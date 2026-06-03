import QtQuick

Rectangle {
    color: "transparent"
    width: clockText.implicitWidth + 10
    height: parent.height

    Text {
        id: clockText
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 14
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // "%l:%M" equivalent in QML formatting
            clockText.text = Qt.formatDateTime(new Date(), "h:mm")
        }
    }
}
