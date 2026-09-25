// core/MediaPlayer.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import "."

Row {
    id: root

    property real artSize: 86
    property real artCornerRadius: 12
    property real artBorderWidth: 2
    property int totalBars: 28

    spacing: 14

    // --- Left: Album Art Cover ---
    SquircleArt {
        id: albumArt
        artUrl: MediaService.artUrl
        artSize: root.artSize
        cornerRadius: root.artCornerRadius
        borderWidth: root.artBorderWidth
        borderColor: MediaService.accentColor
        anchors.verticalCenter: parent.verticalCenter
    }

    // --- Right: Details Column & Cava Progress Controls ---
    Column {
        id: detailsCol
        width: parent.width - root.artSize - root.spacing
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // Top Row: Track Information + Play/Pause Button
        Row {
            width: parent.width
            spacing: 8

            // Track Details (Title, Artist, Album)
            Column {
                width: parent.width - playBtnItem.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: MediaService.title
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.normalText
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: MediaService.artist || "Unknown Artist"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: false
                    color: Theme.normalText
                    opacity: 0.8
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: MediaService.album
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: false
                    color: Theme.normalText
                    opacity: 0.45
                    elide: Text.ElideRight
                }
            }

            // Play / Pause Button with Accent Color
            Item {
                id: playBtnItem
                width: 36
                height: 36
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: bigPlayMouse.containsMouse ? MediaService.accentHoverColor : MediaService.accentColor
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 20
                    source: {
                        if (MediaService.isPlaying) {
                            return MediaService.useDarkPlayIcon ? (Quickshell.shellDir + "/assets/icons/Pause-Black.svg") : (Quickshell.shellDir + "/assets/icons/Pause.svg");
                        } else {
                            return MediaService.useDarkPlayIcon ? (Quickshell.shellDir + "/assets/icons/Play-Black.svg") : (Quickshell.shellDir + "/assets/icons/Play.svg");
                        }
                    }
                }

                MouseArea {
                    id: bigPlayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        mouse.accepted = true;
                        MediaService.togglePlaying();
                    }
                }
            }
        }

        // Bottom Row: [Prev] [Timestamp] [Interactive Cava Progress Bar] [Timestamp] [Next]
        Row {
            width: parent.width
            spacing: 6
            anchors.horizontalCenter: parent.horizontalCenter

            // Previous Button
            Item {
                width: 26
                height: 26
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: bigPrevMouse.containsMouse ? "#2affffff" : "transparent"
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 16
                    source: Quickshell.shellDir + "/assets/icons/Skip-Backward.svg"
                }

                MouseArea {
                    id: bigPrevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        mouse.accepted = true;
                        MediaService.previous();
                    }
                }
            }

            // Elapsed Time
            Text {
                text: MediaService.formatTime(MediaService.currentPosition)
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.normalText
                opacity: 0.6
                anchors.verticalCenter: parent.verticalCenter
                width: 26
            }

            // Interactive Cava Progress Bar (Grey Dots -> Active Cava Equalizer Bars)
            Item {
                id: cavaProgressBar
                width: parent.width - (26 * 2) - (26 * 2) - (6 * 4)
                height: 28
                anchors.verticalCenter: parent.verticalCenter

                readonly property real progressFraction: (MediaService.length > 0)
                    ? Math.min(1.0, Math.max(0.0, MediaService.currentPosition / MediaService.length))
                    : 0.0

                Row {
                    anchors.centerIn: parent
                    spacing: (parent.width - (root.totalBars * 2.5)) / (root.totalBars - 1)
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: root.totalBars

                        Rectangle {
                            id: barDot
                            readonly property real barFraction: index / (root.totalBars - 1)
                            readonly property bool isPlayed: barFraction <= cavaProgressBar.progressFraction
                            readonly property real rawVal: (MediaService.cavaConnected && MediaService.cavaBars && MediaService.cavaBars.length > index)
                                ? MediaService.cavaBars[index]
                                : 0
                            readonly property real cavaHeight: (MediaService.isPlaying && MediaService.cavaConnected)
                                ? Math.max(3.0, Math.min(27.0, 3.0 + (rawVal / 100.0) * 24.0))
                                : 3.0

                            width: 2.5
                            height: isPlayed ? cavaHeight : 3.0
                            radius: 1.5
                            color: isPlayed ? MediaService.accentColor : "#44ffffff"
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on height {
                                NumberAnimation {
                                    duration: 90
                                    easing.type: Easing.OutQuad
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }
                    }
                }

                // Interactive seek MouseArea
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    function seekAt(mouseX) {
                        let frac = Math.max(0.0, Math.min(1.0, mouseX / width));
                        if (MediaService.length > 0) {
                            let targetPos = frac * MediaService.length;
                            MediaService.seek(targetPos);
                        }
                    }

                    onClicked: mouse => seekAt(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            seekAt(mouse.x);
                    }
                }
            }

            // Total Length Time
            Text {
                text: MediaService.formatTime(MediaService.length)
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.normalText
                opacity: 0.6
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                width: 26
            }

            // Next Button
            Item {
                width: 26
                height: 26
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: bigNextMouse.containsMouse ? "#2affffff" : "transparent"
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 16
                    source: Quickshell.shellDir + "/assets/icons/Skip-Forward.svg"
                }

                MouseArea {
                    id: bigNextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        mouse.accepted = true;
                        MediaService.next();
                    }
                }
            }
        }
    }
}
