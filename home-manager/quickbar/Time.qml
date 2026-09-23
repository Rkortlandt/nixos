// Time.qml
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string time: {
        return Qt.formatDateTime(clock.date, "h:mm ap").replace(/\s*[ap]m/i, "");
    }

    readonly property string date: {
        return Qt.formatDateTime(clock.date, "dddd MMMM, d");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
