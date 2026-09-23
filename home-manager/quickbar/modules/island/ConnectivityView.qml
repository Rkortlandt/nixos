// modules/island/ConnectivityView.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../core"

FocusScope {
    id: root

    focus: ConnectivityService.isOpen

    Keys.onEscapePressed: event => {
        ConnectivityService.close();
        event.accepted = true;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // =====================================================================
        // HEADER ROW: TABS & CLOSE BUTTON
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Tab Switcher Container with sliding pill indicator
            Rectangle {
                id: tabContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 16
                color: "#161616"
                border.color: "#282828"
                border.width: 1

                readonly property real tabWidth: (width - 4) / 2

                // Smooth Sliding Active Pill
                Rectangle {
                    id: selectionPill
                    y: 2
                    height: parent.height - 4
                    width: tabContainer.tabWidth
                    radius: 14
                    color: Theme.primaryBg

                    x: ConnectivityService.activeTab === "wifi" ? 2 : (parent.width - width - 2)

                    Behavior on x {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 0

                    // Wi-Fi Tab Button Touch Target
                    Item {
                        width: tabContainer.tabWidth
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: tabWifiMouse.containsMouse && ConnectivityService.activeTab !== "wifi" ? "#18ffffff" : "transparent"
                        }

                        MouseArea {
                            id: tabWifiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ConnectivityService.open("wifi")
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            IconImage {
                                implicitSize: 20
                                source: Qt.resolvedUrl("../../assets/icons/Wifi-High.svg")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Wi-Fi"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                                color: Theme.normalText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Bluetooth Tab Button Touch Target
                    Item {
                        width: tabContainer.tabWidth
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: tabBtMouse.containsMouse && ConnectivityService.activeTab !== "bluetooth" ? "#18ffffff" : "transparent"
                        }

                        MouseArea {
                            id: tabBtMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ConnectivityService.open("bluetooth")
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            IconImage {
                                implicitSize: 20
                                source: Qt.resolvedUrl("../../assets/icons/Bluetooth.svg")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Bluetooth"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                                color: Theme.normalText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // Square Close Button
            IconButton {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                customRadius: 6
                buttonStyle: Button.Style.Normal
                backgroundColor: "#161616"
                hoverColor: "#282828"
                iconSize: 22
                source: Qt.resolvedUrl("../../assets/icons/Close.svg")
                onClicked: ConnectivityService.close()
            }
        }

        // =====================================================================
        // CONTENT AREA (WI-FI vs BLUETOOTH)
        // =====================================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Loader {
                id: tabContentLoader
                anchors.fill: parent
                sourceComponent: ConnectivityService.activeTab === "wifi" ? wifiComponent : btComponent
            }

            // -----------------------------------------------------------------
            // 1. WI-FI VIEW COMPONENT
            // -----------------------------------------------------------------
            Component {
                id: wifiComponent

                Item {
                    id: wifiView
                    anchors.fill: parent

                // --- Disabled State ---
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: !ConnectivityService.wifiEnabled

                    IconImage {
                        implicitSize: 48
                        source: Qt.resolvedUrl("../../assets/icons/Wifi-Disabled.svg")
                        opacity: 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Wi-Fi is Disabled"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.normalText
                        opacity: 0.7
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Button {
                        buttonStyle: Button.Style.Primary
                        paddingHorizontal: 16
                        implicitHeight: 32
                        customRadius: 16
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: ConnectivityService.toggleWifi()

                        Text {
                            anchors.centerIn: parent
                            text: "Turn On Wi-Fi"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            color: Theme.primaryText
                        }
                    }
                }

                // --- Enabled State ---
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8
                    visible: ConnectivityService.wifiEnabled

                    // Controls Row (Power Toggle + Dead Space + Square Refresh Button on the right)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Rounded Pill Power Toggle
                        Rectangle {
                            Layout.preferredWidth: 104
                            Layout.preferredHeight: 28
                            radius: 14
                            color: ConnectivityService.wifiEnabled ? Theme.primaryBg : (pwrMouse.containsMouse ? "#222222" : "#141414")
                            border.color: ConnectivityService.wifiEnabled ? Theme.primaryBorder : "#2a2a2a"
                            border.width: 1

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            MouseArea {
                                id: pwrMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ConnectivityService.toggleWifi()
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                IconImage {
                                    implicitSize: 18
                                    source: ConnectivityService.wifiEnabled ? Qt.resolvedUrl("../../assets/icons/Wifi-High.svg") : Qt.resolvedUrl("../../assets/icons/Wifi-Disabled.svg")
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: ConnectivityService.wifiEnabled ? "Wi-Fi On" : "Wi-Fi Off"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.bold: true
                                    color: Theme.normalText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        // Square Scan/Refresh Icon Button
                        IconButton {
                            id: wifiScanBtn
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            customRadius: 6
                            buttonStyle: ConnectivityService.wifiScanning ? Button.Style.Accent : Button.Style.Normal
                            backgroundColor: ConnectivityService.wifiScanning ? Theme.accentBg : "#1c1c1c"
                            hoverColor: ConnectivityService.wifiScanning ? Theme.accentHoverBg : "#282828"
                            iconSize: 14
                            source: Qt.resolvedUrl("../../assets/icons/Loading.svg")
                            onClicked: ConnectivityService.scanWifi()

                            RotationAnimation {
                                target: wifiScanBtn.icon
                                property: "rotation"
                                running: ConnectivityService.wifiScanning
                                from: 0
                                to: 360
                                loops: Animation.Infinite
                                duration: 800
                            }
                        }
                    }

                    // Scrollable Networks List
                    ListView {
                        id: wifiListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: ConnectivityService.wifiList
                        boundsBehavior: Flickable.StopAtBounds
                        flickDeceleration: 5000
                        maximumFlickVelocity: 4000
                        pixelAligned: true

                        WheelHandler {
                            orientation: Qt.Vertical
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                let delta = event.angleDelta.y;
                                let scrollDelta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : delta * 0.8;
                                let maxScroll = Math.max(0, wifiListView.contentHeight - wifiListView.height);
                                wifiListView.contentY = Math.max(0, Math.min(maxScroll, wifiListView.contentY - scrollDelta));
                            }
                        }

                        delegate: Item {
                            id: apDelegate
                            width: wifiListView.width
                            height: colLayout.implicitHeight

                            readonly property var apData: modelData
                            readonly property bool isConnecting: ConnectivityService.connectingSsid === apData.ssid
                            readonly property bool isPrompting: ConnectivityService.passwordPromptSsid === apData.ssid

                            function getSignalIcon(sig) {
                                if (sig >= 75)
                                    return Qt.resolvedUrl("../../assets/icons/Wifi-High.svg");
                                if (sig >= 50)
                                    return Qt.resolvedUrl("../../assets/icons/Wifi-Mid.svg");
                                if (sig >= 25)
                                    return Qt.resolvedUrl("../../assets/icons/Wifi-Low.svg");
                                return Qt.resolvedUrl("../../assets/icons/Wifi-Zero.svg");
                            }

                            Column {
                                id: colLayout
                                width: parent.width
                                spacing: 4

                                // Main Network Item (Left-to-Right aligned)
                                Rectangle {
                                    width: parent.width
                                    height: 36
                                    radius: 8
                                    color: apData.inUse ? Theme.primaryBg : (apMouse.containsMouse ? "#222222" : "#141414")
                                    border.color: apData.inUse ? Theme.primaryBorder : "transparent"
                                    border.width: apData.inUse ? 1 : 0

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    MouseArea {
                                        id: apMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (apData.inUse) {
                                                ConnectivityService.disconnectWifi(apData.ssid);
                                            } else {
                                                ConnectivityService.connectWifi(apData.ssid, "", apData.requiresPassword);
                                            }
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        IconImage {
                                            implicitSize: 16
                                            source: apDelegate.getSignalIcon(apData.signal)
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: apData.ssid
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize
                                            font.bold: apData.inUse
                                            color: Theme.normalText
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignLeft
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        IconImage {
                                            implicitSize: 11
                                            source: Qt.resolvedUrl("../../assets/icons/Locked.svg")
                                            iconSize: 16
                                            visible: apData.requiresPassword
                                            opacity: 0.6
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: "Connecting..."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            color: Theme.accentText
                                            visible: apDelegate.isConnecting
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }
                                }

                                // Password Prompt Dropdown
                                Rectangle {
                                    width: parent.width
                                    height: apDelegate.isPrompting ? 36 : 0
                                    visible: apDelegate.isPrompting
                                    clip: true
                                    radius: 8
                                    color: "#1e1e1e"
                                    border.color: "#333333"
                                    border.width: 1

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        spacing: 6

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            TextInput {
                                                id: passInput
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                verticalAlignment: TextInput.AlignVCenter
                                                echoMode: TextInput.Password
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 12
                                                color: Theme.normalText
                                                clip: true
                                                focus: apDelegate.isPrompting

                                                onAccepted: {
                                                    ConnectivityService.connectWifi(apData.ssid, text);
                                                    text = "";
                                                    ConnectivityService.passwordPromptSsid = "";
                                                }

                                                Text {
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: "Enter password..."
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 12
                                                    color: "#666666"
                                                    visible: !passInput.text && !passInput.activeFocus
                                                }
                                            }
                                        }

                                        Button {
                                            Layout.preferredWidth: 56
                                            Layout.fillHeight: true
                                            customRadius: 6
                                            buttonStyle: Button.Style.Accent
                                            onClicked: {
                                                ConnectivityService.connectWifi(apData.ssid, passInput.text);
                                                passInput.text = "";
                                                ConnectivityService.passwordPromptSsid = "";
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Join"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: Theme.accentText
                                            }
                                        }

                                        IconButton {
                                            Layout.preferredWidth: 28
                                            Layout.fillHeight: true
                                            customRadius: 6
                                            buttonStyle: Button.Style.Normal
                                            backgroundColor: "transparent"
                                            hoverColor: "#333333"
                                            iconSize: 18
                                            source: Qt.resolvedUrl("../../assets/icons/Close.svg")
                                            onClicked: ConnectivityService.passwordPromptSsid = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

            // -----------------------------------------------------------------
            // 2. BLUETOOTH VIEW COMPONENT
            // -----------------------------------------------------------------
            Component {
                id: btComponent

                Item {
                    id: btView
                    anchors.fill: parent

                // --- Disabled State ---
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: !ConnectivityService.btPowered

                    IconImage {
                        implicitSize: 48
                        source: Qt.resolvedUrl("../../assets/icons/Bluetooth-Disabled.svg")
                        opacity: 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Bluetooth is Disabled"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.normalText
                        opacity: 0.7
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Button {
                        buttonStyle: Button.Style.Primary
                        paddingHorizontal: 16
                        implicitHeight: 32
                        customRadius: 16
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: ConnectivityService.toggleBt()

                        Text {
                            anchors.centerIn: parent
                            text: "Turn On Bluetooth"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            color: Theme.primaryText
                        }
                    }
                }

                // --- Enabled State ---
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8
                    visible: ConnectivityService.btPowered

                    // Controls Row (Power Toggle + Dead Space)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Rounded Pill Power Toggle
                        Rectangle {
                            Layout.preferredWidth: 124
                            Layout.preferredHeight: 28
                            radius: 14
                            color: ConnectivityService.btPowered ? Theme.primaryBg : (btPwrMouse.containsMouse ? "#222222" : "#141414")
                            border.color: ConnectivityService.btPowered ? Theme.primaryBorder : "#2a2a2a"
                            border.width: 1

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            MouseArea {
                                id: btPwrMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ConnectivityService.toggleBt()
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                IconImage {
                                    implicitSize: 18
                                    source: ConnectivityService.btPowered ? Qt.resolvedUrl("../../assets/icons/Bluetooth.svg") : Qt.resolvedUrl("../../assets/icons/Bluetooth-Disabled.svg")
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: ConnectivityService.btPowered ? "Bluetooth On" : "Bluetooth Off"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.bold: true
                                    color: Theme.normalText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        // Square Scan for Devices Icon Button
                        IconButton {
                            id: btScanBtn
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            customRadius: 6
                            buttonStyle: ConnectivityService.btScanning ? Button.Style.Accent : Button.Style.Normal
                            backgroundColor: ConnectivityService.btScanning ? Theme.accentBg : "#1c1c1c"
                            hoverColor: ConnectivityService.btScanning ? Theme.accentHoverBg : "#282828"
                            iconSize: 14
                            source: Qt.resolvedUrl("../../assets/icons/Loading.svg")
                            onClicked: ConnectivityService.toggleBtDiscovery()

                            RotationAnimation {
                                target: btScanBtn.icon
                                property: "rotation"
                                running: ConnectivityService.btScanning
                                from: 0
                                to: 360
                                loops: Animation.Infinite
                                duration: 800
                            }
                        }
                    }

                    // Devices Scroll Area
                    Flickable {
                        id: btFlickable
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: btCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        flickDeceleration: 5000
                        maximumFlickVelocity: 4000
                        pixelAligned: true

                        WheelHandler {
                            orientation: Qt.Vertical
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                let delta = event.angleDelta.y;
                                let scrollDelta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : delta * 0.8;
                                let maxScroll = Math.max(0, btFlickable.contentHeight - btFlickable.height);
                                btFlickable.contentY = Math.max(0, Math.min(maxScroll, btFlickable.contentY - scrollDelta));
                            }
                        }

                        ColumnLayout {
                            id: btCol
                            width: parent.width
                            spacing: 8

                            function isRealName(dev) {
                                if (!dev)
                                    return false;
                                let n = (dev.name || "").trim();
                                let a = (dev.alias || "").trim();
                                let isMac = /^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/;
                                if (a.length > 0 && !isMac.test(a))
                                    return true;
                                if (n.length > 0 && !isMac.test(n))
                                    return true;
                                return false;
                            }

                            function getDeviceLabel(dev) {
                                if (!dev)
                                    return "";
                                let n = (dev.name || "").trim();
                                let a = (dev.alias || "").trim();
                                let isMac = /^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/;
                                if (a.length > 0 && !isMac.test(a))
                                    return a;
                                if (n.length > 0 && !isMac.test(n))
                                    return n;
                                return dev.address || a || n || "";
                            }

                            readonly property var allDevices: (ConnectivityService.btAdapter && ConnectivityService.btAdapter.devices) ? ConnectivityService.btAdapter.devices.values : []
                            readonly property var pairedList: {
                                let paired = allDevices.filter(d => d.paired);
                                return paired.slice().sort((a, b) => {
                                    if (a.connected && !b.connected)
                                        return -1;
                                    if (!a.connected && b.connected)
                                        return 1;

                                    let hasNameA = btCol.isRealName(a);
                                    let hasNameB = btCol.isRealName(b);

                                    if (hasNameA && !hasNameB)
                                        return -1;
                                    if (!hasNameA && hasNameB)
                                        return 1;

                                    let labelA = btCol.getDeviceLabel(a);
                                    let labelB = btCol.getDeviceLabel(b);
                                    return labelA.localeCompare(labelB, undefined, {
                                        sensitivity: 'base'
                                    });
                                });
                            }
                            readonly property var availableList: {
                                let unpair = allDevices.filter(d => !d.paired);
                                return unpair.slice().sort((a, b) => {
                                    let hasNameA = btCol.isRealName(a);
                                    let hasNameB = btCol.isRealName(b);

                                    if (hasNameA && !hasNameB)
                                        return -1;
                                    if (!hasNameA && hasNameB)
                                        return 1;

                                    let labelA = btCol.getDeviceLabel(a);
                                    let labelB = btCol.getDeviceLabel(b);
                                    return labelA.localeCompare(labelB, undefined, {
                                        sensitivity: 'base'
                                    });
                                });
                            }

                            // --- PAIRED DEVICES SECTION ---
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                visible: btCol.pairedList.length > 0

                                Text {
                                    text: "PAIRED DEVICES"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#888888"
                                    horizontalAlignment: Text.AlignLeft
                                    Layout.leftMargin: 4
                                }

                                Repeater {
                                    model: btCol.pairedList

                                    Item {
                                        id: pairedDelegate
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36

                                        readonly property var dev: modelData
                                        readonly property bool isDevConnecting: ConnectivityService.btConnectingAddr === dev.address

                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 4

                                            // Main Clickable Device Row
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 8
                                                color: dev.connected ? Theme.primaryBg : (devMouse.containsMouse ? "#222222" : "#141414")
                                                border.color: dev.connected ? Theme.primaryBorder : "transparent"
                                                border.width: dev.connected ? 1 : 0

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }

                                                MouseArea {
                                                    id: devMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (dev.connected) {
                                                            ConnectivityService.disconnectBt(dev.address);
                                                        } else {
                                                            ConnectivityService.connectBt(dev.address);
                                                        }
                                                    }
                                                }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 10
                                                    spacing: 10

                                                    IconImage {
                                                        implicitSize: 18
                                                        source: Qt.resolvedUrl("../../assets/icons/Bluetooth.svg")
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }

                                                    Text {
                                                        text: btCol.getDeviceLabel(dev)
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: Theme.fontSize
                                                        font.bold: dev.connected
                                                        color: Theme.normalText
                                                        elide: Text.ElideRight
                                                        horizontalAlignment: Text.AlignLeft
                                                        Layout.fillWidth: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }

                                                    Text {
                                                        text: dev.batteryPercentage !== undefined && dev.batteryPercentage > -1 ? Math.floor(dev.batteryPercentage * 100) + "%" : (dev.battery !== undefined && dev.battery > -1 ? Math.floor(dev.battery) + "%" : "")
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 11
                                                        color: "#aaaaaa"
                                                        visible: text.length > 0
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }

                                                    Text {
                                                        text: "Connecting..."
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 11
                                                        color: Theme.accentText
                                                        visible: pairedDelegate.isDevConnecting
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }
                                                }
                                            }

                                            // Square Forget/Unpair Button
                                            IconButton {
                                                Layout.preferredWidth: 36
                                                Layout.preferredHeight: 36
                                                customRadius: 6
                                                buttonStyle: Button.Style.Normal
                                                backgroundColor: "transparent"
                                                hoverColor: "#2a2a2a"
                                                iconSize: 18
                                                source: Qt.resolvedUrl("../../assets/icons/Close.svg")
                                                onClicked: ConnectivityService.unpairBt(dev.address)
                                            }
                                        }
                                    }
                                }
                            }

                            // --- AVAILABLE DEVICES SECTION ---
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                visible: btCol.availableList.length > 0

                                Text {
                                    text: "AVAILABLE DEVICES"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#888888"
                                    horizontalAlignment: Text.AlignLeft
                                    Layout.leftMargin: 4
                                    Layout.topMargin: 4
                                }

                                Repeater {
                                    model: btCol.availableList

                                    Item {
                                        id: availDelegate
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36

                                        readonly property var dev: modelData
                                        readonly property bool isPairing: ConnectivityService.btPairingAddr === dev.address

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 8
                                            color: availMouse.containsMouse ? "#222222" : "#141414"

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                }
                                            }

                                            MouseArea {
                                                id: availMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: ConnectivityService.pairBt(dev.address)
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 10

                                                IconImage {
                                                    implicitSize: 12
                                                    source: Qt.resolvedUrl("../../assets/icons/Bluetooth.svg")
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                Text {
                                                    text: btCol.getDeviceLabel(dev)
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSize
                                                    color: Theme.normalText
                                                    elide: Text.ElideRight
                                                    horizontalAlignment: Text.AlignLeft
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                Text {
                                                    text: availDelegate.isPairing ? "Pairing..." : "Pair"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: Theme.accentText
                                                    Layout.alignment: Qt.AlignVCenter
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Empty search state
                            Text {
                                text: "Searching for nearby devices..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: "#888888"
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 12
                                visible: ConnectivityService.btScanning && btCol.availableList.length === 0
                            }
                        }
                    }
                }
            }
        }
    }
}
}

