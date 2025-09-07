import Wp from "gi://AstalWp";
import { bind } from "astal";

const wireplumber = Wp.get_default()

export function SpeakerSlider() {
    const speaker = Wp.get_default()?.audio.defaultSpeaker!
    function getVolumeIcon(): string {
        let volume = speaker.get_volume();
        if (speaker.get_mute()) {
            return "Speaker-Muted"
        }
        if (volume > .8) {
            return "Speaker-High"
        } else if (volume > .5) {
            return "Speaker-Mid"
        } else if (volume > 0) {
            return "Speaker-Low"
        }
        return "Speaker-Zero"
    }


    return <box css="min-width: 250px">
        <button className="bg-blue margin menu-btn"><icon css="font-size: 23px;" icon={bind(speaker, "volume").as((v) => getVolumeIcon())} /></button>
        <slider
            hexpand
            onDragged={({ value }) => speaker.volume = value}
            value={bind(speaker, "volume")}
        />
    </box>
}

export function MicSlider() {
    const mic = Wp.get_default()?.audio.default_microphone!

    return <box css="min-width: 250px">
        <button className="bg-blue margin menu-btn"><icon css="font-size: 23px;" icon="Mic" /></button>
        <slider
            hexpand
            onDragged={({ value }) => mic.volume = value}
            value={bind(mic, "volume")}
        />
    </box>
}


export function Output() {
    const audio = Wp.get_default()?.audio
    if (audio == undefined) return null;



    function setOutputDevice(id: number) {
        audio?.get_endpoint(id)?.set_is_default(true);
    }
    return <box>
        {(audio != undefined) && bind(audio, "speakers").as((spks) => spks.map((spk) =>
            <button
                className={bind(spk, "is_default").as((isDef) => isDef ? "bg-selected menu-btn margin" : "menu-btn margin")}
                onClick={() => setOutputDevice(spk.get_id())}>
                {(spk.get_name() != null) ? spk.get_name() : "Built-in Audio"}
            </button>))}
    </box>
}
