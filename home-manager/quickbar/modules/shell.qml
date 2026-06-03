import QtQuick
import Quickshell

ShellRoot {
    // Replicate the monitor iteration logic from app.tsx
    Instantiator {
        model: Quickshell.screens
        delegate: Bar {
            screen: modelData
        }
    }
}
