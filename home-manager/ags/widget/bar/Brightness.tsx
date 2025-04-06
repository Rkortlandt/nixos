import { readFile, monitorFile } from "astal/file";
import { Variable, exec } from "astal";

const device = exec("sh -c 'ls -w1 /sys/class/backlight | head -1'");
const path = `/sys/class/backlight/${device}/brightness`;

const currentBrightness = Variable(parseInt(readFile(path)) / 96000)
var bufferedBrightness = Variable(currentBrightness.get());



monitorFile(path, () => (currentBrightness.set(parseInt(readFile(path)) / 96000)));

function handleScroll(scrolly: number): void {
    bufferedBrightness.set(Math.max(.01, Math.min(1, bufferedBrightness.get() - scrolly / 25)));
    let difference = Math.abs(currentBrightness.get() - bufferedBrightness.get());
    if (difference > .05) {
        exec(`brightnessctl set ${Math.floor(bufferedBrightness.get() * 100)}% -q`)
    }
}

export function Brightness () {
    return <button className="bg-black" onScroll={(self, scroll) => handleScroll(scroll.delta_y)}>
        <box>
            <icon icon="Brightness" css="font-size: 23px;"/>
            <label label={bufferedBrightness().as((b) => `${Math.floor(b * 100)}%`)}/>
        </box>
    </button>
}
