// modules/island/LauncherView.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../core"

FocusScope {
    id: root
    anchors.fill: parent
    focus: LauncherService.isOpen

    Keys.onEscapePressed: event => {
        LauncherService.close();
        event.accepted = true;
    }

    // Catch clicks inside launcher card so they do not fall through to the dismissal backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    property int selectedIndex: 0
    property int appsVersion: 0

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.appsVersion++;
        }
    }

    Connections {
        target: DesktopEntries.applications ?? null
        ignoreUnknownSignals: true
        function onValuesChanged() {
            root.appsVersion++;
        }
    }

    readonly property var rawApps: {
        let dummy = root.appsVersion;
        return (DesktopEntries.applications && DesktopEntries.applications.values) ? DesktopEntries.applications.values : [];
    }

    readonly property var filteredApps: {
        let list = [];
        let q = (searchInput.text || "").toLowerCase().trim();
        for (let i = 0; i < rawApps.length; i++) {
            let app = rawApps[i];
            if (!app || app.noDisplay)
                continue;
            let name = (app.name || "").toLowerCase();
            let gen = (app.genericName || "").toLowerCase();
            let com = (app.comment || "").toLowerCase();
            if (q.length === 0 || name.includes(q) || gen.includes(q) || com.includes(q)) {
                list.push(app);
            }
        }
        list.sort((a, b) => (a.name || "").localeCompare(b.name || "", undefined, {
            sensitivity: 'base'
        }));
        return list;
    }

    onFilteredAppsChanged: {
        root.selectedIndex = 0;
    }

    function launchApp(app) {
        if (!app)
            return;
        LauncherService.close();
        app.execute();
    }

    function resetAndFocus() {
        searchInput.text = "";
        root.selectedIndex = 0;
        root.forceActiveFocus();
        focusTimer.restart();
    }

    Timer {
        id: focusTimer
        interval: 30
        repeat: false
        onTriggered: {
            root.forceActiveFocus();
            searchInput.forceActiveFocus();
        }
    }

    onActiveFocusChanged: {
        if (activeFocus && LauncherService.isOpen) {
            searchInput.forceActiveFocus();
        }
    }

    Connections {
        target: LauncherService
        function onIsOpenChanged() {
            if (LauncherService.isOpen) {
                root.resetAndFocus();
            }
        }
    }

    Component.onCompleted: {
        if (LauncherService.isOpen) {
            root.resetAndFocus();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // =====================================================================
        // 1. HEADER ROW: BACK BUTTON, SEARCH INPUT & CLOSE BUTTON
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Back button to Main Menu
            IconButton {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                customRadius: 6
                buttonStyle: Button.Style.Normal
                backgroundColor: Theme.cardBg
                hoverColor: Theme.cardHoverBg
                iconSize: 18
                source: Quickshell.shellDir + "/assets/icons/Back.svg"
                onClicked: {
                    MenuService.open();
                }
            }

            // Search Bar Container
            Rectangle {
                id: searchBarContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 12
                color: Theme.cardBg
                border.color: searchInput.activeFocus ? Theme.primaryBorder : Theme.cardBorder
                border.width: 1

                Behavior on border.color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 8

                    IconImage {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: Quickshell.shellDir + "/assets/icons/Apps.svg"
                        opacity: 0.6
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: Theme.normalText
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        selectByMouse: true
                        clip: true
                        focus: true

                        Text {
                            anchors.fill: parent
                            text: "Search applications..."
                            color: "#555555"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onDownPressed: event => {
                            let next = root.selectedIndex + 4;
                            if (next < root.filteredApps.length) {
                                root.selectedIndex = next;
                                gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            }
                            event.accepted = true;
                        }

                        Keys.onUpPressed: event => {
                            let prev = root.selectedIndex - 4;
                            if (prev >= 0) {
                                root.selectedIndex = prev;
                                gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            }
                            event.accepted = true;
                        }

                        Keys.onRightPressed: event => {
                            if (root.selectedIndex + 1 < root.filteredApps.length) {
                                root.selectedIndex++;
                                gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            }
                            event.accepted = true;
                        }

                        Keys.onLeftPressed: event => {
                            if (root.selectedIndex - 1 >= 0) {
                                root.selectedIndex--;
                                gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            }
                            event.accepted = true;
                        }

                        Keys.onReturnPressed: event => {
                            if (root.filteredApps.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredApps.length) {
                                root.launchApp(root.filteredApps[root.selectedIndex]);
                            }
                            event.accepted = true;
                        }

                        Keys.onEnterPressed: event => {
                            if (root.filteredApps.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredApps.length) {
                                root.launchApp(root.filteredApps[root.selectedIndex]);
                            }
                            event.accepted = true;
                        }

                        Keys.onEscapePressed: event => {
                            if (searchInput.text.length > 0) {
                                searchInput.text = "";
                            } else {
                                LauncherService.close();
                            }
                            event.accepted = true;
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_PageDown) {
                                let next = Math.min(root.filteredApps.length - 1, root.selectedIndex + 12);
                                root.selectedIndex = next;
                                gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageUp) {
                                let prev = Math.max(0, root.selectedIndex - 12);
                                root.selectedIndex = prev;
                                gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                                event.accepted = true;
                            }
                        }
                    }

                    // Clear search button
                    IconButton {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        customRadius: 11
                        buttonStyle: Button.Style.Normal
                        backgroundColor: "transparent"
                        hoverColor: "#333333"
                        iconSize: 12
                        source: Quickshell.shellDir + "/assets/icons/Close.svg"
                        visible: searchInput.text.length > 0
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
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
                backgroundColor: Theme.cardBg
                hoverColor: Theme.cardHoverBg
                iconSize: 22
                source: Quickshell.shellDir + "/assets/icons/Close.svg"
                onClicked: {
                    LauncherService.close();
                }
            }
        }

        // =====================================================================
        // 2. APPLICATIONS GRID VIEW
        // =====================================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state message
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: root.filteredApps.length === 0

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitSize: 36
                    source: Quickshell.shellDir + "/assets/icons/Apps.svg"
                    opacity: 0.35
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: searchInput.text.length > 0 ? "No applications found" : "Loading applications..."
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: "#666666"
                }
            }

            GridView {
                id: gridView
                anchors.fill: parent
                clip: true
                visible: root.filteredApps.length > 0

                cellWidth: Math.floor(width / 4)
                cellHeight: 92
                boundsBehavior: Flickable.StopAtBounds

                model: root.filteredApps

                WheelHandler {
                    orientation: Qt.Vertical
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        let scrollDelta = 0;
                        if (event.pixelDelta.y !== 0) {
                            // Touchpad: amplify so Hyprland's scroll_factor (0.2) scrolls briskly and smoothly
                            scrollDelta = event.pixelDelta.y * 4.5;
                        } else if (event.angleDelta.y !== 0) {
                            // Mouse wheel notch: ~1.5 rows per notch (140px)
                            scrollDelta = (event.angleDelta.y / 120.0) * 140;
                        }
                        let maxScroll = Math.max(0, gridView.contentHeight - gridView.height);
                        gridView.contentY = Math.max(0, Math.min(maxScroll, gridView.contentY - scrollDelta));
                    }
                }

                // Subtle scrollbar pill indicator
                Rectangle {
                    id: scrollIndicator
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    width: 3
                    radius: 1.5
                    color: "#44ffffff"
                    visible: gridView.contentHeight > gridView.height
                    height: Math.max(24, (gridView.height / Math.max(1, gridView.contentHeight)) * gridView.height)
                    y: (gridView.contentY / Math.max(1, gridView.contentHeight - gridView.height)) * (gridView.height - height)
                }

                delegate: Item {
                    id: appDelegate
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    readonly property var app: modelData
                    readonly property bool isSelected: index === root.selectedIndex

                    Rectangle {
                        id: cellCard
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 12
                        color: appDelegate.isSelected ? Theme.primaryBg : (cellMouse.containsMouse ? Theme.itemHoverBg : "transparent")
                        border.color: appDelegate.isSelected ? Theme.primaryBorder : (cellMouse.containsMouse ? Theme.itemBorder : "transparent")
                        border.width: 1

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 5
                            width: parent.width - 8

                            Item {
                                width: 40
                                height: 40
                                anchors.horizontalCenter: parent.horizontalCenter

                                Image {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: Quickshell.iconPath(app.icon || "", "application-x-executable")
                                    sourceSize.width: 80
                                    sourceSize.height: 80
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    asynchronous: true
                                }

                                IconImage {
                                    anchors.fill: parent
                                    visible: appIcon.status === Image.Error || !app.icon
                                    source: Quickshell.shellDir + "/assets/icons/Apps.svg"
                                    implicitSize: 32
                                }
                            }

                            Text {
                                text: app.name || "App"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.normalText
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                width: parent.width
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.launchApp(app);
                            }
                            onEntered: {
                                root.selectedIndex = index;
                            }
                        }
                    }
                }
            }
        }
    }
}
