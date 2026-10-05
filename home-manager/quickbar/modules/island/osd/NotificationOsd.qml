// modules/island/osd/NotificationOsd.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../core"

Item {
    id: root

    property var notification: null

    readonly property string appName: notification?.appName || "Notification"
    readonly property string summary: notification?.summary || ""
    readonly property string body: notification?.body || ""
    readonly property string icon: notification?.appIcon || notification?.image || ""
    readonly property bool isCritical: !!(notification && notification.urgency === 2)
    readonly property bool hasActions: !!(notification && notification.actions && notification.actions.length > 0)

    // Background click handler to open full notification center
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            NotificationService.open();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 12

        // App Icon container (squircle)
        Rectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            Layout.alignment: Qt.AlignVCenter
            radius: 12
            color: Theme.cardBg
            border.color: root.isCritical ? "#ef4444" : Theme.cardBorder
            border.width: 1

            Image {
                id: imgIcon
                anchors.centerIn: parent
                width: 26
                height: 26
                source: root.icon.length > 0 ? (root.icon.startsWith("/") || root.icon.startsWith("image://") ? root.icon : Quickshell.iconPath(root.icon, "dialog-information")) : ""
                sourceSize.width: 52
                sourceSize.height: 52
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                visible: status === Image.Ready
            }

            IconImage {
                anchors.centerIn: parent
                visible: !imgIcon.visible
                source: Quickshell.shellDir + "/assets/icons/Notification.svg"
                implicitSize: 22
            }
        }

        // Content Column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            // Header line: App Name, bullet, "now", Critical badge
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.appName
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.accentText
                }

                Text {
                    text: "•"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: "#555555"
                }

                Text {
                    text: "now"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: "#777777"
                }

                // Critical Urgency Badge
                Rectangle {
                    visible: root.isCritical
                    Layout.preferredHeight: 16
                    Layout.preferredWidth: critText.implicitWidth + 8
                    radius: 8
                    color: "#3a1515"
                    border.color: "#ef4444"
                    border.width: 1

                    Text {
                        id: critText
                        anchors.centerIn: parent
                        text: "Critical"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        color: "#ef4444"
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            // Summary / Title
            Text {
                Layout.fillWidth: true
                text: root.summary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.normalText
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text.length > 0
            }

            // Body text
            Text {
                Layout.fillWidth: true
                text: root.body
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: "#cccccc"
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                visible: text.length > 0
            }

            // Action buttons (if any)
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 3
                spacing: 6
                visible: root.hasActions

                Repeater {
                    model: root.notification?.actions || []

                    TextButton {
                        readonly property var action: modelData
                        Layout.preferredHeight: 24
                        customRadius: 6
                        buttonStyle: Button.Style.Normal
                        backgroundColor: Theme.cardHoverBg
                        hoverColor: Theme.primaryBg
                        bordered: true
                        borderColor: Theme.cardBorder
                        text: action.text || "Open"
                        textColor: Theme.normalText
                        font.pixelSize: 10
                        font.bold: true
                        paddingHorizontal: 8
                        onClicked: {
                            action.invoke();
                        }
                    }
                }
            }
        }

        // Quick dismiss button
        IconButton {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            implicitWidth: 26
            implicitHeight: 26
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 2
            customRadius: 13
            buttonStyle: Button.Style.Normal
            backgroundColor: "transparent"
            hoverColor: "#333333"
            iconSize: 12
            source: Quickshell.shellDir + "/assets/icons/Close.svg"
            onClicked: {
                NotificationService.dismiss(root.notification);
            }
        }
    }
}
