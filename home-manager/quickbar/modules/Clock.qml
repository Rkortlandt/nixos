// modules/Clock.qml
import QtQuick
import ".."
import "../core"

TextButton {
    id: root

    text: Time.time
    buttonStyle: Button.Style.Normal
}
