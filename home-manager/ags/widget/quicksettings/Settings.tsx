import { SpeakerSlider, MicSlider, Output} from "./Audio"
import { Info } from "./Info"
import MprisPlayers from "./Media"
import AstalTray from "gi://AstalTray?version=0.1"
import { System } from "./System"
import Gtk from "gi://Gtk?version=3.0"
import Calendar from "./Calendar"
import { Battery } from "../bar/Battery"
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
	<Battery/>
	<box hexpand={true} css="min-height: 1px; background-color: rgba(160,160,160,.15); margin: 6px"/>
	<System/>
    </box>
}

export function BottomRight () {

    return <box className="bg-black menu" >
	<Calendar className={'calendar-menu-widget'} hexpand={true} showHeading showDayNames/>	
    </box>
}	
