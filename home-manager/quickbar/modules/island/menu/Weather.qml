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
    // 0. VARIANT CONFIGURATION & EXTENSIBLE STYLES REGISTRY
    // =========================================================================
    property string variant: "auto"
    // Customizable chips selection: pass an array of string names, e.g. ["wind", "humidity"]
    property var chips: null

    // Special rain chip (inches & chance of rain in separate container to the right of chips)
    property bool showRainChip: false
    property string rainInches: ""
    property string rainChance: ""

    readonly property bool isRainChipVisible: {
        if (showRainChip || Weather.showRainChip)
            return true;
        if (chips && Array.isArray(chips)) {
            for (let i = 0; i < chips.length; i++) {
                let c = chips[i].toString().toLowerCase().trim();
                if (c === "rain" || c === "rainchip" || c === "precip" || c === "precipitation")
                    return true;
            }
        }
        if (currentStyle && currentStyle.showRainChip === true)
            return true;
        return false;
    }

    readonly property string displayRainInches: {
        if (root.rainInches !== "")
            return root.rainInches;
        if (Weather.isOverridden) {
            return Weather.precipInches !== "" ? Weather.precipInches : "0";
        }
        if (Weather.precipInches && Weather.precipInches !== "0.0" && Weather.precipInches !== "0") {
            return Weather.precipInches;
        }
        return "5";
    }

    readonly property string displayRainChance: {
        if (root.rainChance !== "")
            return root.rainChance;
        if (Weather.isOverridden) {
            return Weather.chanceOfRain.toString();
        }
        if (Weather.chanceOfRain && Weather.chanceOfRain > 0) {
            return Weather.chanceOfRain.toString();
        }
        return "40";
    }

    readonly property var activeChips: {
        let list = null;
        if (chips !== null && chips !== undefined && Array.isArray(chips)) {
            list = chips;
        } else if (currentStyle && currentStyle.chips && Array.isArray(currentStyle.chips)) {
            list = currentStyle.chips;
        } else {
            list = showUv ? ["wind", "moon", "uv", "humidity"] : ["wind", "moon", "humidity"];
        }
        // Filter out rain from square chips row since it renders in its dedicated container
        let result = [];
        for (let i = 0; i < list.length; i++) {
            let item = list[i].toString().toLowerCase().trim();
            if (item !== "rain" && item !== "rainchip" && item !== "precip" && item !== "precipitation") {
                result.push(list[i]);
            }
        }
        return result;
    }

    onActiveChipsChanged: {
        if (chipsGradientBorder) {
            chipsGradientBorder.requestPaint();
        }
    }

    readonly property bool isNight: {
        if (!Weather.isLoaded || !Weather.sunrise || !Weather.sunset) {
            let hr = (new Date()).getHours();
            return hr < 6 || hr >= 20;
        }
        try {
            let parseTime = function (tStr) {
                let match = tStr.match(/(\d+):(\d+)\s*(AM|PM)/i);
                if (!match)
                    return 0;
                let h = parseInt(match[1]);
                let m = parseInt(match[2]);
                let ampm = match[3].toUpperCase();
                if (ampm === "PM" && h < 12)
                    h += 12;
                if (ampm === "AM" && h === 12)
                    h = 0;
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

    // Declarative style definitions. Add new weather variants here.
    readonly property var weatherStyles: ({
            "sunny": {
                title: "Sunny",
                dayIcon: Quickshell.shellDir + "/assets/icons/sun.json",
                nightIcon: Quickshell.shellDir + "/assets/icons/weather/clear-night.json",
                titleColor: "#fbb01b",
                textGradient: null,
                borderGradient: [
                    {
                        pos: 0.0,
                        color: "#fbb01b"
                    },
                    {
                        pos: 0.35,
                        color: "#d97706"
                    },
                    {
                        pos: 0.70,
                        color: "#92400e"
                    },
                    {
                        pos: 1.0,
                        color: "#5a2505"
                    }
                ],
                heroRightMargin: -60,
                heroYOffset: -75,
                heroScaleX: 1.0,
                showUv: true
            },
            "clear": {
                title: "Clear",
                dayIcon: Quickshell.shellDir + "/assets/icons/sun.json",
                nightIcon: Quickshell.shellDir + "/assets/icons/weather/clear-night.json",
                titleColor: "#79BDD7",
                textGradient: null,
                borderGradient: [
                    {
                        pos: 0.0,
                        color: "#FFFFFF"
                    },
                    {
                        pos: 1.0,
                        color: "#79BDD7"
                    }
                ],
                heroRightMargin: -20,
                heroYOffset: -30,
                heroScaleX: -1.0,
                showUv: false
            },
            "overcast": {
                title: "Cloudy",
                dayIcon: Quickshell.shellDir + "/assets/icons/weather/partly-cloudy-day.json",
                nightIcon: Quickshell.shellDir + "/assets/icons/weather/partly-cloudy-night.json",
                titleColor: "#FFFFFF",
                textGradient: [
                    {
                        pos: 0.0,
                        color: "#FFFFFF"
                    },
                    {
                        pos: 1.0,
                        color: "#A7B4C6"
                    }
                ],
                borderGradient: [
                    {
                        pos: 0.0,
                        color: "#FFFFFF"
                    },
                    {
                        pos: 1.0,
                        color: "#A7B4C6"
                    }
                ],
                heroRightMargin: -15,
                heroYOffset: -25,
                heroScaleX: 1.0,
                showUv: false
            },
            "rainy": {
                title: "Rainy",
                dayIcon: Quickshell.shellDir + "/assets/icons/weather/rain.json",
                nightIcon: Quickshell.shellDir + "/assets/icons/weather/rain.json",
                titleColor: "#0A5AD4",
                textGradient: [
                    {
                        pos: 0.0,
                        color: "#0A5AD4"
                    },
                    {
                        pos: 1.0,
                        color: "#10274B"
                    }
                ],
                borderGradient: [
                    {
                        pos: 0.0,
                        color: "#0A5AD4"
                    },
                    {
                        pos: 1.0,
                        color: "#10274B"
                    }
                ],
                heroRightMargin: -15,
                heroYOffset: -50,
                heroScaleX: .9,
                showUv: false,
                showRainChip: true,
                chips: ["wind", "humidity"]
            }
        })

    function normalizeVariantName(name) {
        if (!name)
            return "";
        let n = name.toLowerCase().trim();
        if (n === "cloudy")
            return "overcast";
        if (n === "clear_night")
            return "clear";
        if (n === "rain")
            return "rainy";
        return n;
    }

    readonly property string activeVariant: {
        if (Weather.isOverridden && Weather.forcedVariant && Weather.forcedVariant !== "") {
            let normalized = normalizeVariantName(Weather.forcedVariant);
            if (weatherStyles[normalized])
                return normalized;
        }

        if (variant !== "auto" && variant !== "") {
            let normalized = normalizeVariantName(variant);
            if (weatherStyles[normalized])
                return normalized;
            return normalized;
        }

        if (Weather.forcedVariant && Weather.forcedVariant !== "") {
            let normalized = normalizeVariantName(Weather.forcedVariant);
            if (weatherStyles[normalized])
                return normalized;
        }

        let cond = (Weather.condition || "").toLowerCase().trim();
        if (!cond || cond === "loading...") {
            return isNight ? "clear" : "sunny";
        }

        if (cond.includes("rain") || cond.includes("drizzle") || cond.includes("shower")) {
            return "rainy";
        }
        if (cond.includes("overcast") || cond.includes("cloudy") || cond.includes("partly cloudy")) {
            return "overcast";
        }
        if (cond.includes("clear") || (isNight && cond.includes("sunny"))) {
            return "clear";
        }
        if (cond.includes("sunny")) {
            return isNight ? "clear" : "sunny";
        }

        return isNight ? "clear" : "sunny";
    }

    readonly property var currentStyle: {
        let s = weatherStyles[activeVariant];
        if (s)
            return s;
        return weatherStyles[isNight ? "clear" : "sunny"];
    }

    // Dynamic properties driven cleanly by currentStyle
    readonly property bool isClearVariant: activeVariant === "clear"
    readonly property string defaultTitle: currentStyle.title || (isNight ? "Clear" : "Sunny")
    readonly property string titleText: {
        if (Weather.forcedTitle && Weather.forcedTitle !== "") {
            return Weather.forcedTitle;
        }
        if (Weather.isOverridden && Weather.condition && Weather.condition !== "" && Weather.condition !== "Loading...") {
            return Weather.condition;
        }
        return currentStyle.title || (Weather.condition ? Weather.condition : defaultTitle);
    }
    readonly property string titleColor: currentStyle.titleColor || "#ffffff"
    readonly property var textGradient: currentStyle.textGradient || null
    readonly property bool hasTextGradient: Boolean(textGradient && textGradient.length >= 2)
    readonly property string textGradientStart: hasTextGradient ? (textGradient[0].color || textGradient[0]) : "#ffffff"
    readonly property string textGradientEnd: hasTextGradient ? (textGradient[textGradient.length - 1].color || textGradient[1]) : "#ffffff"

    readonly property string heroSource: isNight ? (currentStyle.nightIcon ? currentStyle.nightIcon : currentStyle.dayIcon) : (currentStyle.dayIcon ? currentStyle.dayIcon : currentStyle.nightIcon)
    readonly property real heroRightMargin: currentStyle.heroRightMargin !== undefined ? currentStyle.heroRightMargin : -20
    readonly property real heroY: weatherTextBlock.y + (currentStyle.heroYOffset !== undefined ? currentStyle.heroYOffset : -30)
    readonly property real heroScaleX: currentStyle.heroScaleX !== undefined ? currentStyle.heroScaleX : 1.0
    readonly property bool showUv: currentStyle.showUv !== undefined ? currentStyle.showUv : !isNight

    onActiveVariantChanged: {
        if (chipsGradientBorder) {
            chipsGradientBorder.requestPaint();
        }
    }

    onIsNightChanged: {
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

    function getWindDirectionIcon(dir) {
        let code = "n";
        if (dir) {
            let d = dir.toUpperCase().trim();
            if (d === "N" || d === "NNW" || d === "NNE")
                code = "n";
            else if (d === "NE" || d === "ENE")
                code = "ne";
            else if (d === "E" || d === "ESE")
                code = "e";
            else if (d === "SE" || d === "SSE")
                code = "se";
            else if (d === "S" || d === "SSW")
                code = "s";
            else if (d === "SW" || d === "WSW")
                code = "sw";
            else if (d === "W" || d === "WNW")
                code = "w";
            else if (d === "NW")
                code = "nw";
        }
        return "https://cdn.meteocons.com/3.0.0-next.10/lottie/fill/wind-direction-" + code + ".json";
    }

    function getCompassIcon(dir) {
        return getWindDirectionIcon(dir);
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

        // Main Title (supports solid color or native-antialiased linear gradient)
        Item {
            id: conditionTitleContainer
            width: conditionTitleText.width
            height: conditionTitleText.height

            // Base Text element (displayed when no gradient is configured, provides layout metrics)
            Text {
                id: conditionTitleText
                text: root.titleText
                font.family: Theme.fontFamily
                font.pixelSize: 32
                font.weight: Font.Black
                color: root.titleColor
                visible: !root.hasTextGradient
            }

            // Vector Canvas text (native subpixel font antialiasing with gradient fill)
            Canvas {
                id: gradientTitleCanvas
                anchors.fill: parent
                visible: root.hasTextGradient
                antialiasing: true

                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();
                    let w = width;
                    let h = height;
                    if (w <= 0 || h <= 0)
                        return;

                    ctx.font = "900 " + conditionTitleText.font.pixelSize + "px " + (Theme.fontFamily || "sans-serif");
                    ctx.textBaseline = "alphabetic";

                    let grad = ctx.createLinearGradient(0, 0, w, 0);
                    let stops = root.textGradient;
                    if (stops && stops.length > 0) {
                        for (let i = 0; i < stops.length; i++) {
                            grad.addColorStop(stops[i].pos, stops[i].color);
                        }
                    } else {
                        grad.addColorStop(0.0, root.textGradientStart);
                        grad.addColorStop(1.0, root.textGradientEnd);
                    }

                    ctx.fillStyle = grad;
                    ctx.fillText(conditionTitleText.text, 0, conditionTitleText.baselineOffset);
                }

                Connections {
                    target: root
                    function onTitleTextChanged() {
                        gradientTitleCanvas.requestPaint();
                    }
                    function onActiveVariantChanged() {
                        gradientTitleCanvas.requestPaint();
                    }
                    function onHasTextGradientChanged() {
                        gradientTitleCanvas.requestPaint();
                    }
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }
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
                let stops = root.currentStyle && root.currentStyle.borderGradient ? root.currentStyle.borderGradient : [];
                if (stops.length > 0) {
                    for (let i = 0; i < stops.length; i++) {
                        grad.addColorStop(stops[i].pos, stops[i].color);
                    }
                } else {
                    grad.addColorStop(0.0, "#FFFFFF");
                    grad.addColorStop(1.0, "#A7B4C6");
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

        visible: root.activeChips.length > 0

        // =====================================================================
        // REUSABLE CHIP COMPONENTS
        // =====================================================================
        Component {
            id: windChipComponent
            Item {
                width: bottomChipsRow.chipSize
                height: bottomChipsRow.chipSize

                LottieIcon {
                    anchors.centerIn: parent
                    size: 54
                    source: root.getWindDirectionIcon(Weather.windDir)
                }
            }
        }

        Component {
            id: moonChipComponent
            Item {
                width: bottomChipsRow.chipSize
                height: bottomChipsRow.chipSize

                LottieIcon {
                    anchors.centerIn: parent
                    size: 74
                    source: root.getMoonIcon(Weather.moonPhase)
                }
            }
        }

        Component {
            id: uvChipComponent
            Item {
                width: bottomChipsRow.chipSize
                height: bottomChipsRow.chipSize

                LottieIcon {
                    anchors.centerIn: parent
                    size: 48
                    source: root.getUvIcon(Weather.uvIndex > 0 ? Weather.uvIndex : 8)
                }
            }
        }

        Component {
            id: humidityChipComponent
            Item {
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

        function getChipComponent(chipName) {
            if (!chipName)
                return null;
            let n = chipName.toString().toLowerCase().trim();
            if (n === "wind" || n === "winddir" || n === "winddirection" || n === "compass") {
                return windChipComponent;
            }
            if (n === "moon" || n === "moonphase") {
                return moonChipComponent;
            }
            if (n === "uv" || n === "uvindex") {
                return uvChipComponent;
            }
            if (n === "humidity" || n === "hum") {
                return humidityChipComponent;
            }
            return null;
        }

        Row {
            id: bottomChipsRow
            anchors.centerIn: parent
            spacing: 4

            readonly property real chipSize: 55

            Repeater {
                model: root.activeChips

                Loader {
                    width: bottomChipsRow.chipSize
                    height: bottomChipsRow.chipSize
                    sourceComponent: chipsContainer.getChipComponent(modelData)
                }
            }
        }
    }

    // =========================================================================
    // 3b. RAIN CHIP CONTAINER (Placed to the right of the other chips)
    // =========================================================================
    Rectangle {
        id: rainChipContainer
        anchors.left: chipsContainer.visible ? chipsContainer.right : parent.left
        anchors.leftMargin: chipsContainer.visible ? 6 : 14
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        height: chipsContainer.height
        width: rainChipRow.width + 16
        radius: 16
        color: "transparent"
        border.width: 0
        visible: root.isRainChipVisible
        z: 2

        // 45° Gradient Border on Rain Chip Container
        Canvas {
            id: rainGradientBorder
            anchors.fill: parent
            z: 10
            antialiasing: true

            onPaint: {
                let ctx = getContext("2d");
                ctx.reset();
                let w = width;
                let h = height;
                let r = rainChipContainer.radius;
                let strokeW = 1.2;
                let half = strokeW / 2;

                let grad = ctx.createLinearGradient(0, 0, w, h);
                let stops = root.currentStyle && root.currentStyle.borderGradient ? root.currentStyle.borderGradient : [];
                if (stops.length > 0) {
                    for (let i = 0; i < stops.length; i++) {
                        grad.addColorStop(stops[i].pos, stops[i].color);
                    }
                } else {
                    grad.addColorStop(0.0, "#FFFFFF");
                    grad.addColorStop(1.0, "#A7B4C6");
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

            Connections {
                target: root
                function onActiveVariantChanged() {
                    rainGradientBorder.requestPaint();
                }
                function onIsNightChanged() {
                    rainGradientBorder.requestPaint();
                }
            }
        }

        Row {
            id: rainChipRow
            anchors.centerIn: parent
            spacing: 6

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: -4

                Text {
                    text: root.displayRainInches + "\""
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: "#2563EB"
                }

                Text {
                    text: root.displayRainChance + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: "#084BB2"
                }
            }

            LottieIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 60
                source: Quickshell.shellDir + "/assets/icons/weather/raindrop-measure.json"
            }
        }
    }
}
