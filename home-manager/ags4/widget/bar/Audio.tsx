import Wp from "gi://AstalWp"
import { bind } from "astal";

export function getVolumeIcon(volume: number): string {
    if (volume > .8) {
        return "Speaker-High"
    } else if (volume > .5) {
        return "Speaker-Mid"
    }
    return "Speaker-Low"
}

export function Speaker() { 
    const speaker = Wp.get_default()?.audio.defaultSpeaker!
    


        //onClick={() => speaker.set_mute(!speaker.get_mute())} 
    return <button 
        onScroll={(self, scroll) => 
            speaker.volume = Math.max(0, Math.min(1, speaker.volume - (scroll.delta_y / 50)))
        }
        className="bg-black">
        <box>
            <label label={bind(speaker, "volume").as((v) => `${Math.floor(v * 100)}%`)}/>
            <icon icon={bind(speaker, "volume").as((v) => getVolumeIcon(v))} css="font-size: 23px; padding-left: 3px;"/>
        </box>
    </button>    
}

export function Mic() { 
    const mic = Wp.get_default()?.audio.default_microphone!
    


    return <button 
        onClick={() => mic.set_mute(!mic.get_mute())} 
        className="bg-black mic">
        <box>
            <icon icon={bind(mic, "mute").as((muted) => muted? "Mic-Muted" : "Mic")} css="font-size: 23px;"/>
        </box>
    </button>    
}
