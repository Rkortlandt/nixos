// core/StablePercentText.qml
import QtQuick

Text {
    id: root

    property int value: 0
    property string suffix: "%"
    property int extraPadding: 2

    text: value + suffix
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: Theme.fontBold
    font.features: { "tnum": 1 }
    color: Theme.normalText

    TextMetrics {
        id: m1
        font: root.font
        text: "8" + root.suffix
    }
    TextMetrics {
        id: m2
        font: root.font
        text: "88" + root.suffix
    }
    TextMetrics {
        id: m3
        font: root.font
        text: "100" + root.suffix
    }

    readonly property int digitBracket: Math.abs(root.value) >= 100 ? 3 : (Math.abs(root.value) >= 10 ? 2 : 1)

    width: Math.ceil((digitBracket === 3 ? m3.width : (digitBracket === 2 ? m2.width : m1.width)) + extraPadding)
    horizontalAlignment: Text.AlignRight
}
