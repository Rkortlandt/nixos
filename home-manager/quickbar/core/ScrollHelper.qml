// core/ScrollHelper.qml
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Extracts normalized delta from wheel event scaled by a sensitivity factor.
    // A standard 120-unit wheel notch produces `1.0 * sensitivity`.
    // Default sensitivity is 0.02 (2% change per notch, ideal for 0.0–1.0 ranges like volume/mic).
    function getDelta(wheel, sensitivity = 0.02) {
        if (!wheel) return 0;
        let dy = 0;
        if (wheel.angleDelta && wheel.angleDelta.y !== 0) {
            dy = wheel.angleDelta.y;
        } else if (wheel.pixelDelta && wheel.pixelDelta.y !== 0) {
            dy = wheel.pixelDelta.y * 4;
        }
        if (dy === 0) return 0;

        return (dy / 120.0) * sensitivity;
    }

    // Alias for getDelta
    function delta(wheel, sensitivity = 0.02) {
        return getDelta(wheel, sensitivity);
    }

    // Returns discrete direction: +1 for scroll up, -1 for scroll down, 0 for none
    function getDirection(wheel) {
        let d = getDelta(wheel, 1.0);
        if (d > 0) return 1;
        if (d < 0) return -1;
        return 0;
    }
}
