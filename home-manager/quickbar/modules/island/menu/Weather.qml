import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../../../core"
import "../../.."

Rectangle {
    id: root

    radius: 24
    color: "#000000"
    border.color: Theme.cardBorder
    border.width: 1
    clip: true

    // =========================================================================
    // 0. VARIANT CONFIGURATION ("auto", "sunny", "clear", etc.)
    // =========================================================================
    property string variant: "auto"

    readonly property bool isNight: {
        if (!Weather.isLoaded || !Weather.sunrise || !Weather.sunset) {
            let hr = (new Date()).getHours();
            return hr < 6 || hr >= 20;
        }
        try {
            let parseTime = function(tStr) {
                let match = tStr.match(/(\d+):(\d+)\s*(AM|PM)/i);
                if (!match) return 0;
                let h = parseInt(match[1]);
                let m = parseInt(match[2]);
                let ampm = match[3].toUpperCase();
                if (ampm === "PM" && h < 12) h += 12;
                if (ampm === "AM" && h === 12) h = 0;
                return h * 60 + m;
            };
            let now = new Date();
            let nowMins = now.getHours() * 60 + now.getMinutes();
            let rise = parseTime(Weather.sunrise);
            let set = parseTime(Weather.sunset);
            if (rise > 0 && set > 0) {
                return nowMins < rise || nowMins >= set;
            }
        } catch (e) {}
        let hr = (new Date()).getHours();
        return hr < 6 || hr >= 20;
    }

    readonly property string activeVariant: {
        if (variant !== "auto" && variant !== "")
            return variant.toLowerCase();

        let cond = (Weather.condition || "").toLowerCase();
        if (cond === "clear" || (isNight && cond === "sunny")) {
            return "clear";
        }
        if (cond === "sunny" || (!isNight && (cond === "" || cond === "loading..."))) {
            return "sunny";
        }
        if (isNight) {
            return "clear";
        }
        return "sunny";
    }

    // Dynamic properties driven by activeVariant
    readonly property bool isClearVariant: activeVariant === "clear" || activeVariant === "clear_night"
    readonly property string titleColor: isClearVariant ? "#79BDD7" : "#fbb01b"
    readonly property string defaultTitle: isClearVariant ? "Clear" : "Sunny"
    readonly property string heroSource: isClearVariant
        ? (Quickshell.shellDir + "/assets/icons/weather/clear-night.json")
        : (Quickshell.shellDir + "/assets/icons/sun.json")
    readonly property real heroRightMargin: isClearVariant ? -20 : -60
    readonly property real heroY: isClearVariant ? (weatherTextBlock.y - 30) : (weatherTextBlock.y - (weatherHero.size / 2))
    readonly property real heroScaleX: isClearVariant ? -1.0 : 1.0
    readonly property bool showUv: !isClearVariant

    onActiveVariantChanged: {
        if (chipsGradientBorder) {
            chipsGradientBorder.requestPaint();
        }
    }

    function getWindDegree(dir) {
        let map = {
            "N": 0,
            "NNE": 22.5,
            "NE": 45,
            "ENE": 67.5,
            "E": 90,
            "ESE": 112.5,
            "SE": 135,
            "SSE": 157.5,
            "S": 180,
            "SSW": 202.5,
            "SW": 225,
            "WSW": 247.5,
            "W": 270,
            "WNW": 292.5,
            "NW": 315,
            "NNW": 337.5
        };
        return map[dir] !== undefined ? map[dir] : 0;
    }

    function getCompassIcon(dir) {
        if (!dir)
            return Quickshell.shellDir + "/assets/icons/weather/compass.json";
        let d = dir.toUpperCase();
        if (d === "NE" || d === "NNE" || d === "ENE")
            return Quickshell.shellDir + "/assets/icons/weather/compass-ne.json";
        if (d === "SE" || d === "ESE" || d === "SSE")
            return Quickshell.shellDir + "/assets/icons/weather/compass-se.json";
        if (d === "SW" || d === "WSW" || d === "SSW")
            return Quickshell.shellDir + "/assets/icons/weather/compass-sw.json";
        if (d === "NW" || d === "WNW" || d === "NNW")
            return Quickshell.shellDir + "/assets/icons/weather/compass-nw.json";
        if (d === "N")
            return Quickshell.shellDir + "/assets/icons/weather/compass-n.json";
        if (d === "S")
            return Quickshell.shellDir + "/assets/icons/weather/compass-s.json";
        if (d === "E")
            return Quickshell.shellDir + "/assets/icons/weather/compass-e.json";
        if (d === "W")
            return Quickshell.shellDir + "/assets/icons/weather/compass-w.json";
        return Quickshell.shellDir + "/assets/icons/weather/compass.json";
    }

    function getMoonIcon(phase) {
        if (!phase)
            return Quickshell.shellDir + "/assets/icons/weather/moon-waxing-gibbous.json";
        let p = phase.toLowerCase();
        if (p.indexOf("new") !== -1)
            return Quickshell.shellDir + "/assets/icons/weather/moon-new.json";
        if (p.indexOf("waxing crescent") !== -1)
            return Quickshell.shellDir + "/assets/icons/weather/moon-waxing-crescent.json";
        if (p.indexOf("first quarter") !== -1)
            return Quickshell.shellDir + "/assets/icons/weather/moon-first-quarter.json";
        if (p.indexOf("waxing gibbous") !== -1)
            return Quickshell.shellDir + "/assets/icons/weather/moon-waxing-gibbous.json";
        if (p.indexOf("full") !== -1)
            return Quickshell.shellDir + "/assets/icons/weather/moon-full.json";
        if (p.indexOf("waning gibbous") !== -1)
            return Quickshell.shellDir + "/assets/icons/weather/moon-waning-gibbous.json";
        if (p.indexOf("last quarter") !== -1 || p.indexOf("third quarter") !== -1)
            return Quickshell.shellDir + "/assets/icons/weather/moon-last-quarter.json";
        if (p.indexOf("waning crescent") !== -1)
            return Quickshell.shellDir + "/assets/icons/weather/moon-waning-crescent.json";
        return Quickshell.shellDir + "/assets/icons/weather/moon-waxing-gibbous.json";
    }

    function getUvIcon(uv) {
        let val = parseInt(uv) || 0;
        if (val <= 0)
            return Quickshell.shellDir + "/assets/icons/weather/uv-index.json";
        if (val >= 12)
            return Quickshell.shellDir + "/assets/icons/weather/uv-index-11-plus.json";
        return Quickshell.shellDir + "/assets/icons/weather/uv-index-" + val + ".json";
    }

    // =========================================================================
    // 1. CURRENT WEATHER TEXT BLOCK (Left Aligned with Inline Time)
    // =========================================================================
    Column {
        id: weatherTextBlock
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 20
        spacing: -5
        z: 2

        // Location & Time Header Row
        Row {
            spacing: 4

            Text {
                text: (Weather.location ? Weather.location : "Houghton") + (Weather.region ? (" " + Weather.region.substring(0, 2).toUpperCase() + ",") : " MI,")
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Black
                color: "#ffffff"
            }

            Text {
                text: Weather.lastUpdated ? Weather.lastUpdated : (Time.time ? Time.time : "9:02AM")
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Black
                color: "#7e8694"
            }
        }

        // Main Title
        Text {
            id: conditionTitle
            text: Weather.condition ? Weather.condition : root.defaultTitle
            font.family: Theme.fontFamily
            font.pixelSize: 32
            font.weight: Font.Black
            color: root.titleColor
        }

        // Temperature Row ("45° 42-55°")
        Item {
            width: parent.width
            height: mainTempText.height

            Text {
                id: mainTempText
                text: (Weather.isLoaded ? Weather.temp : 45) + "°"
                font.family: Theme.fontFamily
                font.pixelSize: 26
                font.weight: Font.Black
                color: "#ffffff"
                anchors.left: parent.left
                anchors.bottom: parent.bottom
            }

            Text {
                id: rangeTempText
                text: (Weather.isLoaded ? (Weather.tempMin + "-" + Weather.tempMax) : "42-55") + "°"
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.weight: Font.Black
                color: "#6b7280"
                anchors.left: mainTempText.right
                anchors.leftMargin: 6
                anchors.baseline: mainTempText.baseline
            }
        }
    }

    // =========================================================================
    // 2. HERO ANIMATED ICON (Right Side, Clipped to Root Radius with MultiEffect)
    // =========================================================================
    Item {
        id: heroClipper
        anchors.fill: parent
        z: 1
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: roundedMask
        }

        LottieIcon {
            id: weatherHero
            anchors.right: parent.right
            anchors.rightMargin: root.heroRightMargin
            y: root.heroY
            size: 150
            transform: Scale {
                origin.x: weatherHero.width / 2
                origin.y: weatherHero.height / 2
                xScale: root.heroScaleX
            }
            source: root.heroSource
        }
    }

    Item {
        id: roundedMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "#ffffff"
        }
    }

    // =========================================================================
    // 3. BOTTOM LEFT-ALIGNED SQUARE CHIPS (Unified Gradient Border Container)
    // =========================================================================
    Rectangle {
        id: chipsContainer
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 14
        anchors.bottomMargin: 10
        width: bottomChipsRow.width + 8
        height: bottomChipsRow.height + 8
        radius: 16
        color: "transparent"
        border.width: 0
        z: 2

        // 45° Gradient Border on Chips Container
        Canvas {
            id: chipsGradientBorder
            anchors.fill: parent
            z: 10
            antialiasing: true

            onPaint: {
                let ctx = getContext("2d");
                ctx.reset();
                let w = width;
                let h = height;
                let r = chipsContainer.radius;
                let strokeW = 1.2;
                let half = strokeW / 2;

                let grad = ctx.createLinearGradient(0, 0, w, h);
                if (root.isClearVariant) {
                    // Clear night: FFFFFF to 79BDD7
                    grad.addColorStop(0.0, "#FFFFFF");
                    grad.addColorStop(1.0, "#79BDD7");
                } else {
                    // Sunny: Sun gold to deep amber
                    grad.addColorStop(0.0, "#fbb01b");
                    grad.addColorStop(0.35, "#d97706");
                    grad.addColorStop(0.70, "#92400e");
                    grad.addColorStop(1.0, "#5a2505");
                }

                ctx.strokeStyle = grad;
                ctx.lineWidth = strokeW;

                ctx.beginPath();
                ctx.moveTo(r + half, half);
                ctx.lineTo(w - r - half, half);
                ctx.arcTo(w - half, half, w - half, r + half, r);
                ctx.lineTo(w - half, h - r - half);
                ctx.arcTo(w - half, h - half, w - r - half, h - half, r);
                ctx.lineTo(r + half, h - half);
                ctx.arcTo(half, h - half, half, h - r - half, r);
                ctx.lineTo(half, r + half);
                ctx.arcTo(half, half, r + half, half, r);
                ctx.closePath();
                ctx.stroke();
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        Row {
            id: bottomChipsRow
            anchors.centerIn: parent
            spacing: 4

            readonly property real chipSize: 55

            // --- CHIP 1: WIND COMPASS ---
            Item {
                width: bottomChipsRow.chipSize
                height: bottomChipsRow.chipSize

                LottieIcon {
                    anchors.centerIn: parent
                    size: 54
                    source: root.getCompassIcon(Weather.windDir)
                }
            }

            // --- CHIP 2: MOON PHASE ---
            Item {
                width: bottomChipsRow.chipSize
                height: bottomChipsRow.chipSize

                LottieIcon {
                    anchors.centerIn: parent
                    size: 74
                    source: root.getMoonIcon(Weather.moonPhase)
                }
            }

            // --- CHIP 3: UV INDEX (Visible only on sunny/day variants) ---
            Item {
                id: uvChip
                visible: root.showUv
                width: visible ? bottomChipsRow.chipSize : 0
                height: bottomChipsRow.chipSize

                LottieIcon {
                    anchors.centerIn: parent
                    size: 48
                    source: root.getUvIcon(Weather.uvIndex > 0 ? Weather.uvIndex : 8)
                }
            }

            // --- CHIP 4: HUMIDITY ---
            Item {
                id: humChip
                width: bottomChipsRow.chipSize
                height: bottomChipsRow.chipSize

                Item {
                    id: humContainer
                    anchors.centerIn: parent
                    width: humText.width + Math.round(humIcon.width * 0.38)
                    height: humIcon.height

                    Text {
                        id: humText
                        text: (Weather.isLoaded ? Weather.humidity : 50)
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Black
                        color: "#ffffff"
                        anchors.left: parent.left
                        anchors.verticalCenter: humIcon.top
                        anchors.verticalCenterOffset: Math.round(humIcon.height * (73.5 / 128.0))
                    }

                    LottieIcon {
                        id: humIcon
                        anchors.left: humText.right
                        anchors.leftMargin: -Math.round(size * 0.32)
                        anchors.verticalCenter: parent.verticalCenter
                        size: 50
                        source: Quickshell.shellDir + "/assets/icons/weather/humidity.json"
                    }
                }
            }
        }
    }
}
