// core/MediaService.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    // =========================================================================
    // 1. MPRIS PLAYER STATE TRACKING
    // =========================================================================
    readonly property var activePlayer: {
        let list = Mpris.players.values;
        if (!list || list.length === 0)
            return null;
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying)
                return list[i];
        }
        for (let i = 0; i < list.length; i++) {
            if (list[i].trackTitle && list[i].trackTitle.length > 0)
                return list[i];
        }
        return null;
    }

    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property bool hasActiveTrack: activePlayer !== null && (activePlayer.isPlaying || (activePlayer.trackTitle && activePlayer.trackTitle.length > 0))
    readonly property string title: activePlayer?.trackTitle || "No Media"
    readonly property string artist: activePlayer?.trackArtist || ""
    readonly property string album: activePlayer?.trackAlbum || (activePlayer?.identity || "")
    readonly property string artUrl: activePlayer?.trackArtUrl || ""
    readonly property real length: activePlayer?.length || 0
    readonly property bool canSeek: activePlayer?.canSeek ?? false

    // Position tracking with smooth interpolation
    property real currentPosition: activePlayer?.position ?? 0

    Connections {
        target: root.activePlayer
        function onPositionChanged() {
            if (root.activePlayer && Math.abs(root.activePlayer.position - root.currentPosition) > 1.0) {
                root.currentPosition = root.activePlayer.position;
            }
        }
        function onPlaybackStateChanged() {
            if (root.activePlayer)
                root.currentPosition = root.activePlayer.position ?? 0;
        }
        function onTrackTitleChanged() {
            if (root.activePlayer)
                root.currentPosition = root.activePlayer.position ?? 0;
        }
    }

    onActivePlayerChanged: {
        root.currentPosition = root.activePlayer?.position ?? 0;
        resetCava();
    }

    Timer {
        id: progressTimer
        interval: 250
        running: root.isPlaying
        repeat: true
        onTriggered: {
            if (!root.activePlayer)
                return;
            let len = root.length;
            let pPos = root.activePlayer.position;
            if (pPos !== undefined && Math.abs(pPos - root.currentPosition) > 2.0) {
                root.currentPosition = pPos;
            } else {
                let nextPos = root.currentPosition + 0.25;
                if (len > 0 && nextPos > len)
                    nextPos = len;
                root.currentPosition = nextPos;
            }
        }
    }

    // =========================================================================
    // 2. ALBUM ART ACCENT COLOR & CACHE
    // =========================================================================
    property var accentColorCache: ({})
    property color accentColor: "#ffffff"
    readonly property color accentHoverColor: Qt.lighter(accentColor, 1.18)
    readonly property color accentPressedColor: Qt.darker(accentColor, 1.2)

    readonly property bool useDarkPlayIcon: {
        let r = accentColor.r;
        let g = accentColor.g;
        let b = accentColor.b;
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        return luminance > 0.45;
    }

    Process {
        id: accentProc
        property string pendingUrl: ""
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let col = data.trim();
                if (col.length > 0 && col.startsWith("#")) {
                    let url = accentProc.pendingUrl;
                    if (url) {
                        let c = root.accentColorCache;
                        c[url] = col;
                        root.accentColorCache = c;
                    }
                    if (url === root.artUrl || !root.artUrl) {
                        root.accentColor = col;
                    }
                }
            }
        }
    }

    function updateAccentColor() {
        let url = root.artUrl;
        if (!url || url.length === 0) {
            root.accentColor = "#ffffff";
            return;
        }
        if (root.accentColorCache && root.accentColorCache[url]) {
            root.accentColor = root.accentColorCache[url];
            return;
        }
        accentProc.pendingUrl = url;
        accentProc.command = [
            "python3",
            Quickshell.shellDir + "/core/extract_accent.py",
            url,
            "#ffffff"
        ];
        accentProc.running = true;
    }

    onArtUrlChanged: updateAccentColor()
    Component.onCompleted: updateAccentColor()

    // =========================================================================
    // 3. PERSISTENT CAVA VISUALIZER CONNECTION
    // =========================================================================
    // Stays open continuously while music is playing
    property bool cavaConnected: false
    property var cavaValues: [4.0, 4.0, 4.0, 4.0, 4.0, 4.0]
    property var cavaBars: []

    Process {
        id: cavaProc
        running: root.isPlaying
        command: ["bash", Quickshell.shellDir + "/core/cava_visualizer.sh"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let line = data.trim();
                if (!line)
                    return;
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
                    root.cavaBars = arr;
                    let vals = [];
                    let len = arr.length - 1;
                    for (let b = 0; b < 6; b++) {
                        let idx = Math.floor(b * len / 5);
                        let v = arr[idx] || 0;
                        let h = Math.max(3.5, Math.min(18.0, 3.5 + (v / 100.0) * 14.5));
                        vals.push(h);
                    }
                    root.cavaValues = vals;
                    if (!root.cavaConnected) {
                        root.cavaConnected = true;
                    }
                }
            }
        }
    }

    function resetCava() {
        cavaConnected = false;
        cavaValues = [4.0, 4.0, 4.0, 4.0, 4.0, 4.0];
        cavaBars = [];
    }

    onIsPlayingChanged: {
        resetCava();
    }


    // =========================================================================
    // 4. PLAYBACK CONTROLS & UTILITIES
    // =========================================================================
    function togglePlaying() {
        root.activePlayer?.togglePlaying();
    }

    function previous() {
        root.activePlayer?.previous();
    }

    function next() {
        root.activePlayer?.next();
    }

    function seek(targetSeconds) {
        if (root.activePlayer && root.activePlayer.canSeek) {
            root.activePlayer.position = targetSeconds;
        }
        root.currentPosition = targetSeconds;
    }

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds < 0)
            return "0:00";
        let m = Math.floor(seconds / 60);
        let s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" + s : s);
    }
}
