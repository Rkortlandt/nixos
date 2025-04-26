import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Clock } from "./bar/Clock"
import { Workspaces } from "./bar/Hyprland"
import { BarBattery } from "./bar/Battery"
import { Mic, Speaker } from "./bar/Audio"
import { Brightness } from "./bar/Brightness"
import { NetworkIndicator } from "./bar/Network"
import { Variable } from "../../../../.local/share/ags"
import { BarMprisPlayer } from "./quicksettings/Media"
import { Calculator } from "./bar/Calculator"


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
            <NetworkIndicator />
            <Brightness />
            <Clock monitor={gdkmonitor.get_model()} />
        </box>
    </window>
}
