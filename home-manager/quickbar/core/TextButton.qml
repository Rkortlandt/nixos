import QtQuick
import Quickshell

Button {
    id: root

    property string text: ""
    property alias label: label
    property alias horizontalAlignment: label.horizontalAlignment
    property alias verticalAlignment: label.verticalAlignment
    property alias elide: label.elide
    property alias wrapMode: label.wrapMode

    Text {
        id: label
        text: root.text
        font: root.font
        color: root.textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
