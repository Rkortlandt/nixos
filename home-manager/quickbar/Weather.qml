// Weather.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // =========================================================================
    // 1. CURRENT CONDITIONS (Imperial Units Only)
    // =========================================================================
    property string location: ""
    property string region: ""
    property string condition: "Loading..."
    property string weatherCode: ""
    property int temp: 0
    property int feelsLike: 0
    property int tempMax: 0
    property int tempMin: 0
    property int humidity: 0
    property int windSpeed: 0
    property string windDir: ""
    property string sunrise: ""
    property string sunset: ""
    property string lastUpdated: ""
    property bool isLoaded: false
    property bool isLoading: false

    // =========================================================================
    // 2. FORECAST DATA (3-Hour Slots & 3-Day Daily Summaries)
    // =========================================================================
    // Array of { time, timeRaw, temp, feelsLike, condition, weatherCode, chanceOfRain, chanceOfSnow, windSpeed, windDir, humidity }
    property var hourlyForecast: []

    // Array of { date, dayName, tempMax, tempMin, condition, weatherCode, sunrise, sunset }
    property var dailyForecast: []

    // =========================================================================
    // 3. BACKGROUND FETCH PROCESS & 2-HOUR TIMER
    // =========================================================================
    Process {
        id: weatherProc
        command: ["curl", "-s", "--connect-timeout", "10", "--max-time", "15", "wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoading = false;
                try {
                    let data = JSON.parse(this.text);
                    root.parseWeather(data);
                } catch (e) {
                    console.log("[Weather] Error parsing JSON from wttr.in:", e);
                }
            }
        }
        onExited: (code, status) => {
            root.isLoading = false;
        }
    }

    // Refresh every 2 hours (2 * 60 * 60 * 1000 = 7,200,000 ms)
    Timer {
        id: updateTimer
        interval: 7200000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    function refresh() {
        if (root.isLoading)
            return;
        root.isLoading = true;
        weatherProc.running = true;
    }

    // =========================================================================
    // 4. DATA SANITIZATION & PARSING
    // =========================================================================
    function formatHourlyTime(rawTime) {
        let t = parseInt(rawTime) || 0;
        let hours = Math.floor(t / 100);
        let ampm = hours >= 12 ? "PM" : "AM";
        let h12 = hours % 12;
        if (h12 === 0) h12 = 12;
        return h12 + " " + ampm;
    }

    function getDayName(dateString, index) {
        if (index === 0) return "Today";
        if (index === 1) return "Tomorrow";
        try {
            let parts = dateString.split("-");
            if (parts.length === 3) {
                let d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
                let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                return days[d.getDay()] || dateString;
            }
        } catch (e) {}
        return dateString;
    }

    function parseWeather(data) {
        if (!data)
            return;

        // --- Current conditions ---
        if (data.current_condition && data.current_condition.length > 0) {
            let cur = data.current_condition[0];
            root.temp = parseInt(cur.temp_F) || 0;
            root.feelsLike = parseInt(cur.FeelsLikeF) || 0;
            root.humidity = parseInt(cur.humidity) || 0;
            root.windSpeed = parseInt(cur.windspeedMiles) || 0;
            root.windDir = cur.winddir16Point || "";
            root.weatherCode = cur.weatherCode || "";
            if (cur.weatherDesc && cur.weatherDesc.length > 0) {
                root.condition = cur.weatherDesc[0].value.trim();
            }
        }

        // --- Nearest area metadata ---
        if (data.nearest_area && data.nearest_area.length > 0) {
            let area = data.nearest_area[0];
            if (area.areaName && area.areaName.length > 0) {
                root.location = area.areaName[0].value;
            }
            if (area.region && area.region.length > 0) {
                root.region = area.region[0].value;
            }
        }

        // --- Forecast processing (3-Day Daily & 3-Hour Hourly) ---
        if (data.weather && data.weather.length > 0) {
            let daysList = [];
            let hoursList = [];

            for (let i = 0; i < data.weather.length; i++) {
                let w = data.weather[i];
                let ast = (w.astronomy && w.astronomy.length > 0) ? w.astronomy[0] : null;

                // Daily overview
                let midCond = "";
                let midCode = "";
                if (w.hourly && w.hourly.length > 4 && w.hourly[4].weatherDesc && w.hourly[4].weatherDesc.length > 0) {
                    midCond = w.hourly[4].weatherDesc[0].value.trim();
                    midCode = w.hourly[4].weatherCode || "";
                } else if (w.hourly && w.hourly.length > 0 && w.hourly[0].weatherDesc && w.hourly[0].weatherDesc.length > 0) {
                    midCond = w.hourly[0].weatherDesc[0].value.trim();
                    midCode = w.hourly[0].weatherCode || "";
                }

                daysList.push({
                    date: w.date || "",
                    dayName: root.getDayName(w.date, i),
                    tempMax: parseInt(w.maxtempF) || 0,
                    tempMin: parseInt(w.mintempF) || 0,
                    condition: midCond,
                    weatherCode: midCode,
                    sunrise: ast ? (ast.sunrise || "") : "",
                    sunset: ast ? (ast.sunset || "") : ""
                });

                // Extract 3-hour slots for today (day 0)
                if (i === 0 && w.hourly) {
                    for (let h = 0; h < w.hourly.length; h++) {
                        let slot = w.hourly[h];
                        let cond = (slot.weatherDesc && slot.weatherDesc.length > 0) ? slot.weatherDesc[0].value.trim() : "";
                        hoursList.push({
                            time: root.formatHourlyTime(slot.time),
                            timeRaw: slot.time || "0",
                            temp: parseInt(slot.tempF) || 0,
                            feelsLike: parseInt(slot.FeelsLikeF) || 0,
                            condition: cond,
                            weatherCode: slot.weatherCode || "",
                            chanceOfRain: parseInt(slot.chanceofrain) || 0,
                            chanceOfSnow: parseInt(slot.chanceofsnow) || 0,
                            windSpeed: parseInt(slot.windspeedMiles) || 0,
                            windDir: slot.winddir16Point || "",
                            humidity: parseInt(slot.humidity) || 0
                        });
                    }
                }
            }

            root.dailyForecast = daysList;
            root.hourlyForecast = hoursList;

            // Today's summary props
            if (daysList.length > 0) {
                root.tempMax = daysList[0].tempMax;
                root.tempMin = daysList[0].tempMin;
                root.sunrise = daysList[0].sunrise;
                root.sunset = daysList[0].sunset;
            }
        }

        let now = new Date();
        root.lastUpdated = Qt.formatTime(now, "h:mm ap");
        root.isLoaded = true;
    }
}
