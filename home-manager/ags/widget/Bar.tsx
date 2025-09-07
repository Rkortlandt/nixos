import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Clock } from "./bar/Clock"
import { Workspaces } from "./bar/Hyprland"
import { BarBattery } from "./bar/Battery"
import { Mic, Speaker } from "./bar/Audio"
import { Brightness } from "./bar/Brightness"
import { NetworkIndicator } from "./bar/Network"
import { BarMprisPlayer } from "./quicksettings/Media"
import { Calculator } from "./bar/Calculator"
import { timers, formatDuration, removeTimer, updateTimers } from "./quicksettings/Timer"
import { interval, Variable } from "astal"

export default function Bar(gdkmonitor: Gdk.Monitor) {
    return <window
        keymode={Astal.Keymode.ON_DEMAND}
        gdkmonitor={gdkmonitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={Astal.WindowAnchor.TOP
            | Astal.WindowAnchor.LEFT
            | Astal.WindowAnchor.RIGHT}
        name="bar"
        application={App}>
        <box className="bar" spacing={4} canFocus={false}>
            <Workspaces />
            <Speaker />
            <Mic />
            <Calculator />
            <BarBattery />
            <box expand={true} />
            <box expand={true} />
            <BarMprisPlayer />
            {updateTimers().as((bla) => timers.get().filter((item) => { console.log(item); return item.pinned == true }).map((timer, index, array) => {

                let timeRemaining: Variable<number> = Variable(0);

                interval(1000, () => {
                    timeRemaining.set((timer.finishTime - Date.now()))
                })
                console.log(timer)
                return <button onClick={() => removeTimer(timer.id)}><box><label>{timeRemaining().as((ms) => formatDuration(ms))}</label><icon icon="Timer" css="font-size: 25px" /></box></button>
            }))}
            <NetworkIndicator />
            <Brightness />
            <Clock monitor={gdkmonitor.get_model()} />
        </box>
    </window>
}
