// core/WallpaperService.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isOpen: false
    readonly property string homeDir: Quickshell.env("HOME") || "/home/ss-pro"
    readonly property string wallpaperDir: root.homeDir + "/nixos/home-manager/hyprland/hypr/Wallpapers"
    readonly property string hyprlandConfPath: root.homeDir + "/nixos/home-manager/hyprland/hypr/hyprland.conf"

    property var wallpapers: []
    property string currentWallpaper: ""
    property string targetWallpaperPath: ""

    // Scan Wallpapers directory and detect active swaybg wallpaper
    Process {
        id: scanProc
        command: [
            "sh", "-c",
            "active=$(ps -eo args | awk '/[s]waybg/ {for(i=1;i<=NF;i++) if($i==\"-i\" && (i+1)<=NF) print $(i+1)}' | tail -n 1); " +
            "if [ -z \"$active\" ] && [ -f \"$2\" ]; then " +
            "  active=$(awk '/exec-once[[:space:]]*=.*swaybg/ {for(i=1;i<=NF;i++) if($i==\"-i\" && (i+1)<=NF) print $(i+1)}' \"$2\" | tail -n 1); " +
            "fi; " +
            "active=$(printf '%s' \"$active\" | sed \"s|^~|$HOME|\"); " +
            "printf 'ACTIVE:%s\\n' \"$active\"; " +
            "find -L \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \\) | sort",
            "sh", root.wallpaperDir, root.hyprlandConfPath
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n");
                let list = [];
                let detectedActive = "";

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (!line)
                        continue;
                    if (line.startsWith("ACTIVE:")) {
                        detectedActive = line.substring(7).trim();
                        continue;
                    }
                    let slashIdx = line.lastIndexOf("/");
                    let fileName = slashIdx >= 0 ? line.substring(slashIdx + 1) : line;
                    let dotIdx = fileName.lastIndexOf(".");
                    let displayName = dotIdx > 0 ? fileName.substring(0, dotIdx) : fileName;
                    list.push({
                        name: displayName,
                        fileName: fileName,
                        path: line,
                        url: "file://" + line
                    });
                }

                root.wallpapers = list;
                if (detectedActive) {
                    root.currentWallpaper = detectedActive;
                }
            }
        }
    }

    // Apply wallpaper seamlessly with swaybg and update hyprland.conf exec-once line
    Process {
        id: applyProc
        command: [
            "sh", "-c",
            "wp=\"$1\"; conf=\"$2\"; " +
            "if [ ! -f \"$wp\" ]; then exit 1; fi; " +
            "old_pids=$(pgrep -x swaybg 2>/dev/null || true); " +
            "nohup swaybg -m fill -i \"$wp\" >/dev/null 2>&1 & " +
            "sleep 0.25; " +
            "if [ -n \"$old_pids\" ]; then kill $old_pids 2>/dev/null || true; fi; " +
            "if [ -w \"$conf\" ]; then " +
            "  pretty_wp=$(printf '%s' \"$wp\" | sed \"s|^$HOME|~|\"); " +
            "  sed -i \"s|^exec-once[[:space:]]*=.*swaybg.*|exec-once = swaybg -m fill -i $pretty_wp|\" \"$conf\"; " +
            "fi",
            "sh", root.targetWallpaperPath, root.hyprlandConfPath
        ]
    }

    function refresh() {
        if (!scanProc.running) {
            scanProc.running = true;
        }
    }

    function setWallpaper(path) {
        if (!path)
            return;
        root.currentWallpaper = path;
        root.targetWallpaperPath = path;
        if (applyProc.running) {
            applyProc.running = false;
        }
        applyProc.running = true;
    }

    function setRandom() {
        let list = root.wallpapers;
        if (!list || list.length === 0)
            return;
        if (list.length === 1) {
            root.setWallpaper(list[0].path);
            return;
        }
        let candidates = [];
        for (let i = 0; i < list.length; i++) {
            if (list[i].path !== root.currentWallpaper) {
                candidates.push(list[i]);
            }
        }
        if (candidates.length === 0)
            candidates = list;
        let pick = candidates[Math.floor(Math.random() * candidates.length)];
        root.setWallpaper(pick.path);
    }

    function open() {
        ConnectivityService.close();
        MenuService.close();
        LauncherService.close();
        NotificationService.close();
        root.refresh();
        isOpen = true;
    }

    function close() {
        isOpen = false;
    }

    function toggle() {
        if (isOpen) {
            close();
        } else {
            open();
        }
    }

    Component.onCompleted: {
        root.refresh();
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function random(): void {
            root.setRandom();
        }
    }
}
