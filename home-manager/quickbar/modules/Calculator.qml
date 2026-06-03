import QtQuick
import QtQuick.Layouts

RowLayout {
    id: calcRoot
    spacing: 4
    
    // Equivalent to the `showCalculator` state
    property bool showCalculator: false

    // Slide animation (equivalent to RevealerTransitionType.SLIDE_RIGHT)
    Behavior on width { NumberAnimation { duration: 200 } }
    clip: true
    width: showCalculator ? implicitWidth : 0

    Rectangle {
        Layout.fillHeight: true
        width: 200
        color: "black" // class="black-bg"
        radius: 4
        border.color: "#0F5880"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4

            Text {
                text: ""
                color: "white"
            }

            TextInput {
                id: calcInput
                Layout.fillWidth: true
                color: "white"
                
                // Equivalent to placeholderText
                Text {
                    text: "Calculate..."
                    color: "gray"
                    visible: !calcInput.text
                }

                // Equivalent to Gtk.EventControllerKey
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        calcRoot.showCalculator = false;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        // Calculate logic (call your JS calculate function here)
                        // calcInput.text = calculate(calcInput.text).result;
                        event.accepted = true;
                    }
                    // Handle Up/Down for history here...
                }
            }
        }
    }
}
