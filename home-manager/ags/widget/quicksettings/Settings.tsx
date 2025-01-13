import { SpeakerSlider, MicSlider, Output} from "./Audio"
import { Info } from "./Info"
import MprisPlayers from "./Media"
import AstalTray from "gi://AstalTray?version=0.1"
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

    return <box>

	<label label="bottomleft"/>	
    </box>
}

export function BottomRight () {

    return <box>
		
	<label label="bottomRight"/>	
    </box>
}	
