// core/NotificationService.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool isOpen: false

    // Quickshell's built-in NotificationServer
    readonly property NotificationServer server: NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notif => {
            if (!notif)
                return;
            // Mark as tracked so Quickshell retains it in trackedNotifications
            notif.tracked = true;
            root.latestNotification = notif;
            root.updateList();
            root.notificationReceived(notif);
        }
    }

    property var latestNotification: null
    property var notifications: []
    readonly property int count: notifications.length

    function updateList() {
        if (server && server.trackedNotifications && server.trackedNotifications.values) {
            let list = server.trackedNotifications.values.slice();
            // Show newest notification at the top
            root.notifications = list.reverse();
        } else {
            root.notifications = [];
        }
    }

    Connections {
        target: server.trackedNotifications ?? null
        function onValuesChanged() {
            root.updateList();
        }
    }

    Component.onCompleted: {
        root.updateList();
    }

    signal notificationReceived(var notification)

    function dismiss(notif) {
        if (notif) {
            if (typeof notif.dismiss === "function") {
                notif.dismiss();
            } else {
                notif.tracked = false;
            }
        }
        root.updateList();
    }

    function clearAll() {
        if (server && server.trackedNotifications && server.trackedNotifications.values) {
            let list = server.trackedNotifications.values.slice();
            for (let i = 0; i < list.length; i++) {
                let n = list[i];
                if (n) {
                    if (typeof n.dismiss === "function") {
                        n.dismiss();
                    } else {
                        n.tracked = false;
                    }
                }
            }
        }
        root.updateList();
    }

    function open() {
        ConnectivityService.close();
        MenuService.close();
        LauncherService.close();
        WallpaperService.close();
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
        target: "notifications"
        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function clear(): void {
            root.clearAll();
        }
    }
}
