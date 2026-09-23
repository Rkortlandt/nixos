// core/MenuService.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isOpen: false
    property bool cafeMode: false

    Process {
        id: cafeInhibitProc
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Quickbar", "--why=Cafe Mode", "sleep", "infinity"]
    }

    function toggleCafeMode() {
        root.cafeMode = !root.cafeMode;
        if (root.cafeMode) {
            cafeInhibitProc.running = true;
        } else {
            cafeInhibitProc.running = false;
        }
    }

    function open() {
        ConnectivityService.close();
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

    IpcHandler {
        target: "menu"
        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
    }
}
