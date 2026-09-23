// modules/island/MediaView.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../core"

Item {
    id: root

    property var player: null
    property bool isExpanded: false

    signal toggleExpand()

    readonly property string title: player?.trackTitle || "No Media"
    readonly property string artist: player?.trackArtist || ""
    readonly property string album: player?.trackAlbum || (player?.identity || "")
    readonly property string artUrl: player?.trackArtUrl || ""
    readonly property bool isPlaying: player?.isPlaying ?? false

    // Position tracking for continuous progress updates
    property real currentPosition: player?.position ?? 0

    Connections {
        target: root.player
        function onPositionChanged() {
            if (root.player && Math.abs(root.player.position - root.currentPosition) > 1.0) {
                root.currentPosition = root.player.position;
            }
        }
        function onPlaybackStateChanged() {
            if (root.player) root.currentPosition = root.player.position ?? 0;
        }
        function onTrackTitleChanged() {
            if (root.player) root.currentPosition = root.player.position ?? 0;
        }
    }

    onPlayerChanged: {
        root.currentPosition = root.player?.position ?? 0;
    }

    Timer {
        id: progressTimer
        interval: 250
        running: root.isPlaying && root.isExpanded && root.visible
        repeat: true
        onTriggered: {
            if (!root.player) return;
            let len = root.player.length || 0;
            let pPos = root.player.position;
            if (pPos !== undefined && Math.abs(pPos - root.currentPosition) > 2.0) {
                root.currentPosition = pPos;
            } else {
                let nextPos = root.currentPosition + 0.25;
                if (len > 0 && nextPos > len) nextPos = len;
                root.currentPosition = nextPos;
            }
        }
    }

    // Dynamic accent color extracted from album art via ImageMagick
    property color accentColor: Theme.accentBg
    readonly property color accentHoverColor: Qt.lighter(accentColor, 1.18)
    readonly property color accentPressedColor: Qt.darker(accentColor, 1.2)

    Process {
        id: accentProc
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let col = data.trim();
                if (col.length > 0 && col.startsWith("#")) {
                    root.accentColor = col;
                }
            }
        }
    }

    function updateAccentColor() {
        if (!root.artUrl || root.artUrl.length === 0) {
            root.accentColor = Theme.accentBg;
            return;
        }
        accentProc.command = [
            "python3",
            Qt.resolvedUrl("../../core/extract_accent.py").toString().replace(/^file:\/\//, ""),
            root.artUrl,
            Theme.accentBg.toString()
        ];
        accentProc.running = true;
    }

    onArtUrlChanged: updateAccentColor()
    Component.onCompleted: updateAccentColor()

    // Cava Audio Visualizer integration
    property var cavaValues: [4.0, 4.0, 4.0, 4.0, 4.0, 4.0]
    property var cavaBars: []

    Process {
        id: cavaProc
        running: root.isPlaying && root.visible
        command: ["bash", Qt.resolvedUrl("../../core/cava_visualizer.sh").toString().replace(/^file:\/\//, "")]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let line = data.trim();
                if (!line) return;
                let parts = line.split(";");
                let arr = [];
                let total = parts.length;
                for (let i = 0; i < total; i++) {
                    if (parts[i].length > 0) {
                        let v = parseInt(parts[i]);
                        arr.push(isNaN(v) ? 0 : v);
                    }
                }
                if (arr.length > 0) {
                    if (root.isExpanded) {
                        root.cavaBars = arr;
                    }
                    let vals = [];
                    let len = arr.length - 1;
                    for (let b = 0; b < 6; b++) {
                        let idx = Math.floor(b * len / 5);
                        let v = arr[idx] || 0;
                        let h = Math.max(3.5, Math.min(18.0, 3.5 + (v / 100.0) * 14.5));
                        vals.push(h);
                    }
                    root.cavaValues = vals;
                }
            }
        }
    }

    // Format seconds to mm:ss
    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds < 0) return "0:00";
        let m = Math.floor(seconds / 60);
        let s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" + s : s);
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
            spacing: 10

            // Song Title & Artist
            Text {
                id: songText
                text: root.artist
                    ? (root.title + " <font color=\"" + root.accentColor + "\">•</font> " + root.artist)
                    : root.title
                textFormat: Text.StyledText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: Theme.fontBold
                color: Theme.normalText
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(implicitWidth, 190)
            }

            // Real Cava Equalizer Visualizer (6 bars)
            Row {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: 6
                    Rectangle {
                        width: 2.5
                        height: root.isPlaying ? (root.cavaValues[index] ?? 4) : 4
                        radius: 1.5
                        color: root.isPlaying ? root.accentColor : "#666666"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // =========================================================================
    // 2. EXPANDED MODE (Full Details Card with 2x Album Art & Cava Progress)
    // =========================================================================
    Row {
        id: expandedContainer
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14
        opacity: root.isExpanded ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // --- Left: 2x Bigger Album Art Cover (96x96) ---
        SquircleArt {
            artUrl: root.artUrl
            artSize: 96
            cornerRadius: 12
            borderWidth: 3
            borderColor: root.accentColor
            anchors.verticalCenter: parent.verticalCenter
        }

        // --- Right: Details Column & Cava Progress Controls ---
        Column {
            width: parent.width - 96 - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Top Row: Track Information + Big Play/Pause Button
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
                        text: root.title
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.normalText
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.artist || "Unknown Artist"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: false
                        color: Theme.normalText
                        opacity: 0.8
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.album
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
                        color: bigPlayMouse.containsMouse ? root.accentHoverColor : root.accentColor
                    }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 20
                        source: Qt.resolvedUrl(root.isPlaying ? "../../assets/icons/Pause.svg" : "../../assets/icons/Play.svg")
                    }
                    MouseArea {
                        id: bigPlayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            mouse.accepted = true;
                            root.player?.togglePlaying();
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
                        source: Qt.resolvedUrl("../../assets/icons/Skip-Backward.svg")
                    }
                    MouseArea {
                        id: bigPrevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            mouse.accepted = true;
                            root.player?.previous();
                        }
                    }
                }

                // Elapsed Time
                Text {
                    text: root.formatTime(root.currentPosition)
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

                    readonly property real progressFraction: (root.player?.length > 0)
                        ? Math.min(1.0, Math.max(0.0, root.currentPosition / root.player.length))
                        : 0.0

                    readonly property int totalBars: 28

                    Row {
                        anchors.centerIn: parent
                        spacing: (parent.width - (cavaProgressBar.totalBars * 2.5)) / (cavaProgressBar.totalBars - 1)
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: cavaProgressBar.totalBars

                            Rectangle {
                                id: barDot
                                readonly property real barFraction: index / (cavaProgressBar.totalBars - 1)
                                readonly property bool isPlayed: barFraction <= cavaProgressBar.progressFraction
                                readonly property real rawVal: (root.cavaBars && root.cavaBars.length > index)
                                    ? root.cavaBars[index]
                                    : 0
                                readonly property real cavaHeight: root.isPlaying
                                    ? Math.max(3.0, Math.min(27.0, 3.0 + (rawVal / 100.0) * 24.0))
                                    : 3.0

                                width: 2.5
                                height: isPlayed ? cavaHeight : 3.0
                                radius: 1.5
                                color: isPlayed ? root.accentColor : "#44ffffff"
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
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
                            if (root.player && root.player.length > 0) {
                                let targetPos = frac * root.player.length;
                                root.currentPosition = targetPos;
                                if (root.player.canSeek) {
                                    root.player.position = targetPos;
                                }
                            }
                        }

                        onClicked: mouse => seekAt(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed) seekAt(mouse.x);
                        }
                    }
                }

                // Total Length Time
                Text {
                    text: root.formatTime(root.player?.length ?? 0)
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
                        source: Qt.resolvedUrl("../../assets/icons/Skip-Forward.svg")
                    }
                    MouseArea {
                        id: bigNextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            mouse.accepted = true;
                            root.player?.next();
                        }
                    }
                }
            }
        }
    }
}
