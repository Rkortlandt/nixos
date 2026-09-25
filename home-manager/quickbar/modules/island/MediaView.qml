// modules/island/MediaView.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../core"

Item {
    id: root

    property var player: MediaService.activePlayer
    property bool isExpanded: false

    signal toggleExpand()

    readonly property string title: MediaService.title
    readonly property string artist: MediaService.artist
    readonly property string album: MediaService.album
    readonly property string artUrl: MediaService.artUrl
    readonly property bool isPlaying: MediaService.isPlaying
    readonly property real currentPosition: MediaService.currentPosition
    readonly property color accentColor: MediaService.accentColor
    readonly property color accentHoverColor: MediaService.accentHoverColor
    readonly property bool useDarkPlayIcon: MediaService.useDarkPlayIcon
    readonly property var cavaValues: MediaService.cavaValues
    readonly property var cavaBars: MediaService.cavaBars
    readonly property bool cavaConnected: MediaService.cavaConnected

    function formatTime(seconds) {
        return MediaService.formatTime(seconds);
    }

    // Dynamic sizing based on mode
    implicitWidth: isExpanded ? 420 : compactRow.implicitWidth
    implicitHeight: isExpanded ? 124 : Theme.defaultHeight

    // =========================================================================
    // 1. COMPACT MODE (Default Pill Content)
    // =========================================================================
    Item {
        id: compactContainer
        anchors.fill: parent
        opacity: root.isExpanded ? 0.0 : 1.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        // --- Default Compact Row ---
        Row {
            id: compactRow
            anchors.centerIn: parent
            spacing: 8

            readonly property real maxTextWidth: 240
            readonly property bool showArtist: (root.artist && root.artist.length > 0) && ((maxTextWidth - titleMeasure.implicitWidth - 14) >= 55)

            // Hidden measurement for full unconstrained title width
            Text {
                id: titleMeasure
                text: root.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: Theme.fontBold
                visible: false
            }

            // Song Title Text
            Text {
                id: titleText
                text: root.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: Theme.fontBold
                color: Theme.normalText
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(implicitWidth, compactRow.showArtist ? (compactRow.maxTextWidth - Math.min(artistText.implicitWidth, 110) - 14) : compactRow.maxTextWidth)
            }

            // Bullet Separator (only when artist is visible)
            Text {
                id: bulletText
                text: "•"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                color: root.accentColor
                anchors.verticalCenter: parent.verticalCenter
                visible: compactRow.showArtist
            }

            // Artist Name (only when there is adequate space)
            Text {
                id: artistText
                text: root.artist
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: false
                color: Theme.normalText
                opacity: 0.85
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(implicitWidth, compactRow.maxTextWidth - titleText.width - 14)
                visible: compactRow.showArtist
            }

            // Real Cava Equalizer Visualizer (6 bars)
            Row {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: 6
                    Rectangle {
                        width: 2.5
                        height: (root.isPlaying && MediaService.cavaConnected) ? (root.cavaValues[index] ?? 4.0) : 4.0
                        radius: 1.5
                        color: root.isPlaying ? root.accentColor : "#666666"
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on height {
                            NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 2. EXPANDED MODE (Full Details Card with 2x Album Art & Cava Progress)
    // =========================================================================
    MediaPlayer {
        id: expandedContainer
        anchors.fill: parent
        anchors.margins: 12
        artSize: 96
        artBorderWidth: 3
        totalBars: 28
        opacity: root.isExpanded ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }
}
