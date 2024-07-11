const audio = await Service.import('audio')
const mpris = await Service.import('mpris')

const AudioSlider = () => Widget.Slider({
    draw_value: false,
    hexpand: true,
    value: audio.speaker.bind("volume"),
    on_change: ({ value }) => audio.speaker.volume = value,
})

const MicSlider = () => Widget.Slider({
    draw_value: false,
    hexpand: true,
    value: audio.microphone.bind("volume"),
    on_change: ({ value }) => audio.microphone.volume = value,
})


export const Audio = () => Widget.Box({
    children: [
        Widget.Button({
            vpack: "center",
            class_name: "bg-blue",
            child: Widget.Icon({icon: "speaker", css: "font-size: 17px"}),
            tooltip_text: audio.speaker.bind("volume").as(v =>
                `Volume: ${Math.floor(v * 100)}%`),
        }),
        AudioSlider(),
    ],
})

export const Mic = () => Widget.Box({
    children: [
        Widget.Button({
            vpack: "center",
            class_name: "bg-blue",
            child: Widget.Icon({icon: "mic-unmuted", css: "font-size: 17px"}),
            tooltip_text: audio.microphone.bind("volume").as(v =>
                `Mic: ${Math.floor(v * 100)}%`),
        }),
        MicSlider(),
    ],
})
