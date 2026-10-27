// modules/island/WallpaperView.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../core"

FocusScope {
    id: root
    anchors.fill: parent
    focus: WallpaperService.isOpen

    Keys.onEscapePressed: event => {
        WallpaperService.close();
        event.accepted = true;
    }

    // Catch clicks inside wallpaper card so they do not fall through to the dismissal backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    property int selectedIndex: 0

    readonly property var filteredWallpapers: {
        let raw = WallpaperService.wallpapers || [];
        let q = (searchInput.text || "").toLowerCase().trim();
        if (q.length === 0)
            return raw;
        let list = [];
        for (let i = 0; i < raw.length; i++) {
            let wp = raw[i];
            if (!wp)
                continue;
            let name = (wp.name || "").toLowerCase();
            let file = (wp.fileName || "").toLowerCase();
            if (name.includes(q) || file.includes(q)) {
                list.push(wp);
            }
        }
        return list;
    }

    onFilteredWallpapersChanged: {
        let activeIdx = 0;
        let cur = WallpaperService.currentWallpaper;
        if (cur) {
            for (let i = 0; i < filteredWallpapers.length; i++) {
                if (filteredWallpapers[i].path === cur) {
                    activeIdx = i;
                    break;
                }
            }
        }
        root.selectedIndex = activeIdx;
    }

    function applyWallpaper(wp) {
        if (!wp || !wp.path)
            return;
        WallpaperService.setWallpaper(wp.path);
    }

    function resetAndFocus() {
        searchInput.text = "";
        let activeIdx = 0;
        let cur = WallpaperService.currentWallpaper;
        for (let i = 0; i < root.filteredWallpapers.length; i++) {
            if (root.filteredWallpapers[i].path === cur) {
                activeIdx = i;
                break;
            }
        }
        root.selectedIndex = activeIdx;
        if (gridView.count > 0) {
            gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
        }
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
        if (activeFocus && WallpaperService.isOpen) {
            searchInput.forceActiveFocus();
        }
    }

    Connections {
        target: WallpaperService
        function onIsOpenChanged() {
            if (WallpaperService.isOpen) {
                root.resetAndFocus();
            }
        }
    }

    Component.onCompleted: {
        if (WallpaperService.isOpen) {
            root.resetAndFocus();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // =====================================================================
        // 1. HEADER ROW: BACK BUTTON, SEARCH INPUT, RANDOM & CLOSE BUTTON
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
                        source: Quickshell.shellDir + "/assets/icons/Wallpaper.svg"
                        opacity: 0.7
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
                            text: "Search wallpapers..."
                            color: "#555555"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onDownPressed: event => {
                            let next = root.selectedIndex + 2;
                            if (next < root.filteredWallpapers.length) {
                                root.selectedIndex = next;
                                gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            }
                            event.accepted = true;
                        }

                        Keys.onUpPressed: event => {
                            let prev = root.selectedIndex - 2;
                            if (prev >= 0) {
                                root.selectedIndex = prev;
                                gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                            }
                            event.accepted = true;
                        }

                        Keys.onRightPressed: event => {
                            if (root.selectedIndex + 1 < root.filteredWallpapers.length) {
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
                            if (root.filteredWallpapers.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredWallpapers.length) {
                                root.applyWallpaper(root.filteredWallpapers[root.selectedIndex]);
                            }
                            event.accepted = true;
                        }

                        Keys.onEnterPressed: event => {
                            if (root.filteredWallpapers.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredWallpapers.length) {
                                root.applyWallpaper(root.filteredWallpapers[root.selectedIndex]);
                            }
                            event.accepted = true;
                        }

                        Keys.onEscapePressed: event => {
                            if (searchInput.text.length > 0) {
                                searchInput.text = "";
                            } else {
                                WallpaperService.close();
                            }
                            event.accepted = true;
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

            // Random Wallpaper Button
            TextButton {
                Layout.preferredHeight: 32
                customRadius: 8
                buttonStyle: Button.Style.Normal
                backgroundColor: Theme.cardBg
                hoverColor: Theme.cardHoverBg
                bordered: true
                borderColor: Theme.cardBorder
                text: "Random"
                textColor: "#cccccc"
                font.pixelSize: 11
                font.bold: true
                paddingHorizontal: 10
                onClicked: {
                    WallpaperService.setRandom();
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
                    WallpaperService.close();
                }
            }
        }

        // =====================================================================
        // 2. WALLPAPERS GRID VIEW
        // =====================================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state message
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: root.filteredWallpapers.length === 0

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitSize: 36
                    source: Quickshell.shellDir + "/assets/icons/Wallpaper.svg"
                    opacity: 0.35
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: searchInput.text.length > 0 ? "No wallpapers found" : "No wallpapers in directory"
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
                visible: root.filteredWallpapers.length > 0

                cellWidth: Math.floor(width / 2)
                cellHeight: 142
                boundsBehavior: Flickable.StopAtBounds

                model: root.filteredWallpapers

                WheelHandler {
                    orientation: Qt.Vertical
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        let scrollDelta = 0;
                        if (event.pixelDelta.y !== 0) {
                            scrollDelta = event.pixelDelta.y * 4.5;
                        } else if (event.angleDelta.y !== 0) {
                            scrollDelta = (event.angleDelta.y / 120.0) * 142;
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
                    id: wpDelegate
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    readonly property var wp: modelData
                    readonly property bool isActive: wp && wp.path === WallpaperService.currentWallpaper
                    readonly property bool isSelected: index === root.selectedIndex

                    Rectangle {
                        id: cardOuter
                        anchors.fill: parent
                        anchors.margins: 5
                        radius: 14
                        color: Theme.cardBg
                        border.color: wpDelegate.isActive ? Theme.accentBorder : (wpDelegate.isSelected ? Theme.primaryBorder : (cardMouse.containsMouse ? "#444444" : Theme.cardBorder))
                        border.width: (wpDelegate.isActive || wpDelegate.isSelected) ? 2 : 1

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 12
                            color: "#111111"

                            Image {
                                id: thumbImg
                                anchors.fill: parent
                                source: wpDelegate.wp ? wpDelegate.wp.url : ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 440
                                sourceSize.height: 280
                                asynchronous: true
                                cache: true
                                smooth: true
                            }

                            // Bottom label bar
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 28
                                color: "#cc0a0a0a"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    spacing: 6

                                    Text {
                                        Layout.fillWidth: true
                                        text: wpDelegate.wp ? wpDelegate.wp.name : ""
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.normalText
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        visible: wpDelegate.isActive
                                        Layout.preferredHeight: 16
                                        Layout.preferredWidth: activeLabel.implicitWidth + 10
                                        radius: 8
                                        color: Theme.accentBg
                                        border.color: Theme.accentBorder
                                        border.width: 1

                                        Text {
                                            id: activeLabel
                                            anchors.centerIn: parent
                                            text: "ACTIVE"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: "#ffffff"
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = index;
                                root.applyWallpaper(wpDelegate.wp);
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
