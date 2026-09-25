// modules/DynamicIsland.qml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import "../core"
import "island"
import "island/osd"
import "island/menu"

PanelWindow {
    id: root

    // Force Overlay layer so it renders above fullscreen windows
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (ConnectivityService.isOpen || MenuService.isOpen) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    margins {
        top: 4
    }
    exclusionMode: ExclusionMode.Ignore

    property bool isScreenFocused: true
    visible: root.isScreenFocused

    // Hyprland fullscreen tracking: check workspace and active toplevel window
    readonly property bool isWorkspaceFullscreen: (Hyprland.focusedWorkspace?.hasFullscreen ?? false) || (Hyprland.activeToplevel?.wayland?.fullscreen ?? false)

    // Listen to Hyprland raw IPC events to guarantee instantaneous refresh on fullscreen transitions
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event)
                return;
            if (event.name === "fullscreen" || event.name === "changefloatingmode" || event.name === "workspace") {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
            }
        }
    }

    color: "transparent"

    // Wayland input mask:
    // When closed, ONLY the visible island pill captures mouse clicks.
    // When open, the island pill AND the backdrop below the top bar capture clicks (leaving the bar row clickable).
    mask: Region {
        Region {
            item: (ConnectivityService.isOpen || MenuService.isOpen) ? backdropArea : islandPill
        }
        Region {
            item: islandPill
        }
    }

    // Dismissal backdrop covering everything below the top bar height
    MouseArea {
        id: backdropArea
        z: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        anchors.topMargin: Theme.defaultHeight + 4
        enabled: ConnectivityService.isOpen || MenuService.isOpen
        focus: ConnectivityService.isOpen || MenuService.isOpen
        Keys.onEscapePressed: event => {
            ConnectivityService.close();
            MenuService.close();
            event.accepted = true;
        }
        onClicked: {
            ConnectivityService.close();
            MenuService.close();
        }
    }

    // =========================================================================
    // OSD STATE MANAGEMENT & EVENT DISPATCHER
    // =========================================================================
    // 0: Idle (DateView / MediaView)
    // 1: Volume
    // 2: Screen Brightness
    // 3: Keyboard Backlight
    // 4: Wi-Fi
    // 5: Bluetooth
    property int activeOsdMode: 0
    readonly property bool isOsdActive: activeOsdMode !== 0

    // -------------------------------------------------------------------------
    // MPRIS Active Media Player Tracking (via MediaService)
    // -------------------------------------------------------------------------
    readonly property var activePlayer: MediaService.activePlayer
    readonly property bool hasActiveTrack: MediaService.hasActiveTrack

    property bool isMediaExpanded: false
    property bool isIslandHovered: false

    function triggerOsd(mode, duration = 1800) {
        isMediaExpanded = false;
        activeOsdMode = mode;
        osdDismissTimer.interval = duration;
        osdDismissTimer.restart();
    }

    Timer {
        id: osdDismissTimer
        interval: 1800
        onTriggered: root.activeOsdMode = 0
    }

    // -------------------------------------------------------------------------
    // 1. Audio Sink (Volume) Tracking
    // -------------------------------------------------------------------------
    readonly property var audioSink: Pipewire.defaultAudioSink
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null
        ignoreUnknownSignals: true
        function onVolumeChanged() {
            root.triggerOsd(1);
        }
        function onMutedChanged() {
            root.triggerOsd(1);
        }
    }

    // -------------------------------------------------------------------------
    // 2. Main Screen & Keyboard Backlight Tracking (via fast BacklightService)
    // -------------------------------------------------------------------------
    Connections {
        target: BacklightService
        function onScreenAdjusted() {
            root.triggerOsd(2);
        }
        function onKbdAdjusted() {
            root.triggerOsd(3);
        }
    }

    // -------------------------------------------------------------------------
    // 4. Wi-Fi Tracking & Change Detection (Event-driven via ConnectivityService)
    // -------------------------------------------------------------------------
    readonly property string wifiSsid: ConnectivityService.wifiActiveSsid
    readonly property int wifiSignal: ConnectivityService.wifiActiveSignal
    property string lastWifiSsid: ""
    property bool wifiInitialized: false

    Connections {
        target: ConnectivityService
        function onWifiActiveSsidChanged() {
            let ssid = ConnectivityService.wifiActiveSsid;
            if (!root.wifiInitialized) {
                root.lastWifiSsid = ssid;
                root.wifiInitialized = true;
                return;
            }
            if (root.lastWifiSsid !== ssid) {
                root.lastWifiSsid = ssid;
                if (!ConnectivityService.isOpen) {
                    root.triggerOsd(4, 2500);
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // 5. Bluetooth Connection / Disconnection Events
    // -------------------------------------------------------------------------
    property string btDeviceName: ""
    property bool btDeviceConnected: false

    Repeater {
        model: (ConnectivityService.btAdapter && ConnectivityService.btAdapter.devices) ? ConnectivityService.btAdapter.devices.values : []
        Item {
            readonly property var dev: modelData
            Connections {
                target: dev ?? null
                ignoreUnknownSignals: true
                function onConnectedChanged() {
                    if (!dev)
                        return;
                    root.btDeviceName = dev.alias || dev.deviceName || dev.name || dev.address || "Device";
                    root.btDeviceConnected = dev.connected;
                    root.triggerOsd(5, 2500);
                }
            }
        }
    }

    // =========================================================================
    // MORPHING CAPSULE (GPU rendered, sub-pixel smooth)
    // =========================================================================
    Rectangle {
        id: islandPill
        z: 2
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property bool effectiveMediaExpanded: root.hasActiveTrack && !root.isOsdActive && !ConnectivityService.isOpen && !MenuService.isOpen && (root.isIslandHovered || root.isMediaExpanded)
        readonly property bool shouldShowIsland: root.isScreenFocused && (MenuService.isOpen || ConnectivityService.isOpen || root.isOsdActive || effectiveMediaExpanded || !root.isWorkspaceFullscreen)

        readonly property real currentContentWidth: {
            if (MenuService.isOpen) {
                return 500;
            }
            if (ConnectivityService.isOpen) {
                return 420;
            }
            if (root.isOsdActive) {
                switch (root.activeOsdMode) {
                case 1:
                    return volumeItem.implicitWidth;
                case 2:
                    return brightnessItem.implicitWidth;
                case 3:
                    return kbdItem.implicitWidth;
                case 4:
                    return wifiItem.implicitWidth;
                case 5:
                    return btItem.implicitWidth;
                }
            }
            if (root.hasActiveTrack) {
                return effectiveMediaExpanded ? 420 : mediaItem.implicitWidth;
            }
            return dateItem.implicitWidth;
        }

        readonly property real targetWidth: MenuService.isOpen ? 500 : (ConnectivityService.isOpen ? 420 : (!shouldShowIsland ? 0 : (effectiveMediaExpanded ? 420 : (currentContentWidth + 24))))
        readonly property real targetHeight: MenuService.isOpen ? 520 : (ConnectivityService.isOpen ? 320 : (!shouldShowIsland ? 0 : (root.isOsdActive ? 36 : (effectiveMediaExpanded ? 124 : Theme.defaultHeight))))
        readonly property real targetRadius: MenuService.isOpen ? 24 : ((ConnectivityService.isOpen || effectiveMediaExpanded) ? 16 : (targetHeight / 2))

        width: targetWidth
        height: targetHeight
        y: 0
        radius: targetRadius

        color: Theme.normalBg

        Behavior on width {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutBack
                easing.overshoot: 1.08
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.05
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: pillHoverHandler
            onHoveredChanged: {
                root.isIslandHovered = hovered;
                if (!hovered && !ConnectivityService.isOpen && !MenuService.isOpen) {
                    root.isMediaExpanded = false;
                }
            }
        }

        clip: true

        // -------------------------------------------------------------
        // ITEM 0A: Idle Date View (when no track is playing)
        // -------------------------------------------------------------
        DateView {
            id: dateItem
            anchors.centerIn: parent
            opacity: (!MenuService.isOpen && !ConnectivityService.isOpen && !root.isOsdActive && !root.hasActiveTrack && !root.isWorkspaceFullscreen) ? 1.0 : 0.0
            scale: opacity > 0 ? 1.0 : 0.90
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: (!root.isOsdActive && !root.hasActiveTrack) ? 250 : 100
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }
        }

        // -------------------------------------------------------------
        // ITEM 0B: Default Media View (when song is active)
        // -------------------------------------------------------------
        MediaView {
            id: mediaItem
            anchors.fill: parent
            player: root.activePlayer
            isExpanded: islandPill.effectiveMediaExpanded
            opacity: (!MenuService.isOpen && !ConnectivityService.isOpen && !root.isOsdActive && root.hasActiveTrack && (!root.isWorkspaceFullscreen || islandPill.effectiveMediaExpanded)) ? 1.0 : 0.0
            scale: opacity > 0 ? 1.0 : 0.90
            visible: opacity > 0.01
            onToggleExpand: root.isMediaExpanded = !root.isMediaExpanded

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }
        }

        // -------------------------------------------------------------
        // ITEM 1: Volume OSD View
        // -------------------------------------------------------------
        VolumeOsd {
            id: volumeItem
            anchors.centerIn: parent
            opacity: (!MenuService.isOpen && !ConnectivityService.isOpen && root.activeOsdMode === 1) ? 1.0 : 0.0
            scale: opacity > 0 ? 1.0 : 0.90
            visible: opacity > 0.01
            onInteraction: root.triggerOsd(1)

            Behavior on opacity {
                NumberAnimation {
                    duration: root.activeOsdMode === 1 ? 250 : 100
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }
        }

        // -------------------------------------------------------------
        // ITEM 2: Screen Brightness OSD View
        // -------------------------------------------------------------
        BrightnessOsd {
            id: brightnessItem
            anchors.centerIn: parent
            brightnessPercent: BacklightService.screenPercent
            opacity: (!MenuService.isOpen && !ConnectivityService.isOpen && root.activeOsdMode === 2) ? 1.0 : 0.0
            scale: opacity > 0 ? 1.0 : 0.90
            visible: opacity > 0.01
            onInteraction: root.triggerOsd(2)

            Behavior on opacity {
                NumberAnimation {
                    duration: root.activeOsdMode === 2 ? 250 : 100
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }
        }

        // -------------------------------------------------------------
        // ITEM 3: Keyboard Backlight OSD View
        // -------------------------------------------------------------
        KbdBacklightOsd {
            id: kbdItem
            anchors.centerIn: parent
            kbdBrightness: BacklightService.kbdBrightness
            kbdMaxBrightness: BacklightService.kbdMaxBrightness
            kbdIsOn: BacklightService.kbdBrightness > 0
            opacity: (!MenuService.isOpen && !ConnectivityService.isOpen && root.activeOsdMode === 3) ? 1.0 : 0.0
            scale: opacity > 0 ? 1.0 : 0.90
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: root.activeOsdMode === 3 ? 250 : 100
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }
        }

        // -------------------------------------------------------------
        // ITEM 4: Wi-Fi OSD View
        // -------------------------------------------------------------
        WifiOsd {
            id: wifiItem
            anchors.centerIn: parent
            ssid: root.wifiSsid
            signalStrength: root.wifiSignal
            opacity: (!MenuService.isOpen && !ConnectivityService.isOpen && root.activeOsdMode === 4) ? 1.0 : 0.0
            scale: opacity > 0 ? 1.0 : 0.90
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: root.activeOsdMode === 4 ? 250 : 100
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }
        }

        // -------------------------------------------------------------
        // ITEM 5: Bluetooth OSD View
        // -------------------------------------------------------------
        BluetoothOsd {
            id: btItem
            anchors.centerIn: parent
            deviceName: root.btDeviceName
            connected: root.btDeviceConnected
            opacity: (!MenuService.isOpen && !ConnectivityService.isOpen && root.activeOsdMode === 5) ? 1.0 : 0.0
            scale: opacity > 0 ? 1.0 : 0.90
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: root.activeOsdMode === 5 ? 250 : 100
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }
        }

        // -------------------------------------------------------------
        // ITEM 6: Connectivity (Wi-Fi & Bluetooth) Management Page
        // -------------------------------------------------------------
        Loader {
            id: connectivityLoader
            anchors.fill: parent
            focus: ConnectivityService.isOpen
            active: ConnectivityService.isOpen || opacity > 0.01
            sourceComponent: Component {
                ConnectivityView {
                    id: connectivityItem
                }
            }
            opacity: (!MenuService.isOpen && ConnectivityService.isOpen) ? 1.0 : 0.0
            scale: opacity > 0 ? 1.0 : 0.90
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }
        }

        // -------------------------------------------------------------
        // ITEM 7: Main Menu / Dashboard Page
        // -------------------------------------------------------------
        Loader {
            id: mainMenuLoader
            anchors.fill: parent
            focus: MenuService.isOpen
            active: MenuService.isOpen || opacity > 0.01
            sourceComponent: Component {
                MainMenuView {
                    id: mainMenuItem
                }
            }
            opacity: MenuService.isOpen ? 1.0 : 0.0
            scale: opacity > 0 ? 1.0 : 0.90
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }
        }
    }
}
