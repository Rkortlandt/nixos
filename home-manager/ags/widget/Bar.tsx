import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Clock } from "./bar/Clock"
import { Workspaces } from "./bar/Hyprland"
import { Battery } from "./bar/Battery"
import { Mic, Speaker } from "./bar/Audio"
import { Brightness } from "./bar/Brightness"
import { NetworkIndicator } from "./bar/Network"
import { Variable } from "../../../../.local/share/ags"
import { BarMediaPlayer, BarMprisPlayer } from "./quicksettings/Media"


export default function Bar(gdkmonitor: Gdk.Monitor) {
    return <window
        gdkmonitor={gdkmonitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={Astal.WindowAnchor.TOP
            | Astal.WindowAnchor.LEFT
            | Astal.WindowAnchor.RIGHT}
        name="bar"
        application={App}>
        <box className="bar" spacing={4}>
            <Workspaces />
            <Speaker />
            <Mic />
            <Battery />
            <box expand={true}/>
            <BarMprisPlayer/>
            <NetworkIndicator />
            <Brightness />
            <Clock monitor={gdkmonitor.get_model()}/>
        </box>
    </window>
}
