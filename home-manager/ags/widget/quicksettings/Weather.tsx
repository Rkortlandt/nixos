import { App, Gdk, Gtk } from "astal/gtk3"
import GLib from "gi://GLib?version=2.0"
import { Variable, bind } from "astal"

interface ValueObject {
    value: string;
}

interface HourlyWeather {
    DewPointC: string;
    DewPointF: string;
    FeelsLikeC: string;
    FeelsLikeF: string;
    HeatIndexC: string;
    HeatIndexF: string;
    WindChillC: string;
    WindChillF: string;
    WindGustKmph: string;
    WindGustMiles: string;
    chanceoffog: string;
    chanceoffrost: string;
    chanceofhightemp: string;
    chanceofovercast: string;
    chanceofrain: string;
    chanceofremdry: string;
    chanceofsnow: string;
    chanceofsunshine: string;
    chanceofthunder: string;
    chanceofwindy: string;
    cloudcover: string;
    diffRad: string;
    humidity: string;
    precipInches: string;
    precipMM: string;
    pressure: string;
    pressureInches: string;
    shortRad: string;
    tempC: string;
    tempF: string;
    time: string;
    uvIndex: string;
    visibility: string;
    visibilityMiles: string;
    weatherCode: string;
    weatherDesc: ValueObject[];
    weatherIconUrl: ValueObject[];
    winddir16Point: string;
    winddirDegree: string;
    windspeedKmph: string;
    windspeedMiles: string;
}

interface Astronomy {
    moon_illumination: string;
    moon_phase: string;
    moonrise: string;
    moonset: string;
    sunrise: string;
    sunset: string;
}

interface DailyWeather {
    astronomy: Astronomy[];
    avgtempC: string;
    avgtempF: string;
    date: string;
    hourly: HourlyWeather[];
    maxtempC: string;
    maxtempF: string;
    mintempC: string;
    mintempF: string;
    sunHour: string;
    totalSnow_cm: string;
    uvIndex: string;
}

interface CurrentCondition {
    FeelsLikeC: string;
    FeelsLikeF: string;
    cloudcover: string;
    humidity: string;
    localObsDateTime: string;
    observation_time: string;
    precipInches: string;
    precipMM: string;
    pressure: string;
    pressureInches: string;
    temp_C: string;
    temp_F: string;
    uvIndex: string;
    visibility: string;
    visibilityMiles: string;
    weatherCode: string;
    weatherDesc: ValueObject[];
    weatherIconUrl: ValueObject[];
    winddir16Point: string;
    winddirDegree: string;
    windspeedKmph: string;
    windspeedMiles: string;
}

interface NearestArea {
    areaName: ValueObject[];
    country: ValueObject[];
    latitude: string;
    longitude: string;
    population: string;
    region: ValueObject[];
    weatherUrl: ValueObject[];
}

interface Request {
    query: string;
    type: string;
}

interface WeatherData {
    current_condition: CurrentCondition[];
    nearest_area: NearestArea[];
    request: Request[];
    weather: DailyWeather[];
}

export function Weather(props: { monitor: string | null, }) {
    const time = Variable("").poll(1000, 'date "+%H:%M"')
    const date = Variable("").poll(100000, 'date "+%e %B (%m)"')
    const weather = Variable<WeatherData | null>(null).poll(600000, 'curl wttr.in/kalamazoo?format=j1', (out) => JSON.parse(out))

    return <box className="bg-black">
        {/*  {weather().as((w) => w?.current_condition[0].temp_F)} */}
        <box>
            {weather().as((w) => w?.weather[0].hourly.map((hour) => {
                let parsed = hour.time
                console.log(hour.time, hour.tempF);

                if (parsed == "0") {
                    parsed = "12pm"
                }

                if (parsed != "0" && (parseInt(hour.time) / 100) < 12) {
                    parsed = parseInt(hour.time) / 100 + "am"
                }

                return <label>{parsed}
                </label>
            }
            ))}
        </box>
    </box>
}
