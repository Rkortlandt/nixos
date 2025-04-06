import { SpeakerSlider, MicSlider, Output} from "./Audio"
import { Info } from "./Info"
import MprisPlayers from "./Media"
import AstalTray from "gi://AstalTray?version=0.1"
import { System } from "./System"
import Gtk from "gi://Gtk?version=3.0"
import Calendar from "./Calendar"
export function TopLeft () {
    const tray = AstalTray.get_default()
    for (const item of tray.get_items()) {
	print(item.title)
    }
    return <box className="bg-black menu" vertical={true}>
	<SpeakerSlider />
	<MicSlider />
	<Output />
	<MprisPlayers/>
    </box>
}

export function TopRight () {

    return <box className="bg-black menu" vertical={true}>
	<Info />
    </box>
}

export function BottomLeft () {

    return <box className="bg-black menu" vertical={true}>
	<System/>
    </box>
}

export function BottomRight () {

    return <box className="bg-black menu" >
	<Calendar className="calendar" hexpand={true}/>	
    </box>
}	
