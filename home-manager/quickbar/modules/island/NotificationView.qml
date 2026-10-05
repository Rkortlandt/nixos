// modules/island/NotificationView.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../core"

FocusScope {
    id: root
    anchors.fill: parent
    focus: NotificationService.isOpen

    Keys.onEscapePressed: event => {
        NotificationService.close();
        event.accepted = true;
    }

    // Catch clicks inside notification card so they do not fall through to the dismissal backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // =====================================================================
        // 1. HEADER ROW: BACK BUTTON, TITLE + COUNT, CLEAR ALL & CLOSE BUTTON
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Back button to Main Menu
            IconButton {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                customRadius: 6
                buttonStyle: Button.Style.Normal
                backgroundColor: Theme.cardBg
                hoverColor: Theme.cardHoverBg
                iconSize: 18
                source: Quickshell.shellDir + "/assets/icons/Back.svg"
                onClicked: {
                    MenuService.open();
                }
            }

            // Title & Count container
            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                IconImage {
                    implicitSize: 16
                    source: Quickshell.shellDir + "/assets/icons/Notification.svg"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Notifications"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.normalText
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Count Badge
                Rectangle {
                    visible: NotificationService.count > 0
                    width: Math.max(18, countText.implicitWidth + 8)
                    height: 18
                    radius: 9
                    color: Theme.primaryBg
                    border.color: Theme.primaryBorder
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: NotificationService.count.toString()
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: "#ffffff"
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Clear All Button
            TextButton {
                visible: NotificationService.count > 0
                Layout.preferredHeight: 28
                customRadius: 8
                buttonStyle: Button.Style.Normal
                backgroundColor: Theme.cardBg
                hoverColor: Theme.cardHoverBg
                bordered: true
                borderColor: Theme.cardBorder
                text: "Clear All"
                textColor: "#aaaaaa"
                font.pixelSize: 11
                font.bold: true
                paddingHorizontal: 10
                onClicked: {
                    NotificationService.clearAll();
                }
            }

            // Square Close Button
            IconButton {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                customRadius: 6
                buttonStyle: Button.Style.Normal
                backgroundColor: Theme.cardBg
                hoverColor: Theme.cardHoverBg
                iconSize: 22
                source: Quickshell.shellDir + "/assets/icons/Close.svg"
                onClicked: {
                    NotificationService.close();
                }
            }
        }

        // =====================================================================
        // 2. NOTIFICATIONS LIST
        // =====================================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state message
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: NotificationService.count === 0

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitSize: 38
                    source: Quickshell.shellDir + "/assets/icons/Bell.svg"
                    opacity: 0.3
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No Notifications"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: "#777777"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "You're all caught up!"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: "#555555"
                }
            }

            ListView {
                id: notifListView
                anchors.fill: parent
                clip: true
                spacing: 8
                visible: NotificationService.count > 0
                boundsBehavior: Flickable.StopAtBounds

                model: NotificationService.notifications

                WheelHandler {
                    orientation: Qt.Vertical
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        let scrollDelta = 0;
                        if (event.pixelDelta.y !== 0) {
                            scrollDelta = event.pixelDelta.y * 4.5;
                        } else if (event.angleDelta.y !== 0) {
                            scrollDelta = (event.angleDelta.y / 120.0) * 140;
                        }
                        let maxScroll = Math.max(0, notifListView.contentHeight - notifListView.height);
                        notifListView.contentY = Math.max(0, Math.min(maxScroll, notifListView.contentY - scrollDelta));
                    }
                }

                // Subtle scrollbar pill indicator
                Rectangle {
                    id: scrollIndicator
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    width: 3
                    radius: 1.5
                    color: "#44ffffff"
                    visible: notifListView.contentHeight > notifListView.height
                    height: Math.max(24, (notifListView.height / Math.max(1, notifListView.contentHeight)) * notifListView.height)
                    y: (notifListView.contentY / Math.max(1, notifListView.contentHeight - notifListView.height)) * (notifListView.height - height)
                }

                delegate: Rectangle {
                    id: notifCard
                    width: notifListView.width - (notifListView.contentHeight > notifListView.height ? 8 : 0)
                    implicitHeight: cardCol.implicitHeight + 20
                    radius: 12
                    color: Theme.cardBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    readonly property var notif: modelData
                    readonly property bool isCritical: notif?.urgency === 2

                    // Urgency accent strip on left
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        radius: 1.5
                        color: isCritical ? "#ef4444" : Theme.primaryBorder
                    }

                    ColumnLayout {
                        id: cardCol
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        anchors.topMargin: 10
                        anchors.bottomMargin: 10
                        spacing: 4

                        // Header row: Icon, App Name, Time, Dismiss Button
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            // App Icon
                            Item {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18

                                Image {
                                    id: cardIcon
                                    anchors.fill: parent
                                    source: (notif?.appIcon && notif.appIcon.length > 0) ? (notif.appIcon.startsWith("/") || notif.appIcon.startsWith("image://") ? notif.appIcon : Quickshell.iconPath(notif.appIcon, "dialog-information")) : ""
                                    sourceSize.width: 36
                                    sourceSize.height: 36
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    visible: status === Image.Ready
                                }

                                IconImage {
                                    anchors.fill: parent
                                    visible: !cardIcon.visible
                                    source: Quickshell.shellDir + "/assets/icons/Notification.svg"
                                    implicitSize: 16
                                }
                            }

                            // App Name
                            Text {
                                text: notif?.appName || "Notification"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accentText
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            // Dismiss button
                            IconButton {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                customRadius: 10
                                buttonStyle: Button.Style.Normal
                                backgroundColor: "transparent"
                                hoverColor: "#333333"
                                iconSize: 12
                                source: Quickshell.shellDir + "/assets/icons/Close.svg"
                                onClicked: {
                                    NotificationService.dismiss(notif);
                                }
                            }
                        }

                        // Summary
                        Text {
                            Layout.fillWidth: true
                            text: notif?.summary || ""
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.normalText
                            wrapMode: Text.Wrap
                            visible: text.length > 0
                        }

                        // Body
                        Text {
                            Layout.fillWidth: true
                            text: notif?.body || ""
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: "#bbbbbb"
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            maximumLineCount: 3
                            visible: text.length > 0
                        }

                        // Action Buttons Row
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            spacing: 6
                            visible: notif?.actions && notif.actions.length > 0

                            Repeater {
                                model: notif?.actions || []

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
                }
            }
        }
    }
}
