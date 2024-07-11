import brightness from "../../bar/services/brightness.js"

const BrightnessSlider = () => Widget.Slider({
    draw_value: false,
    hexpand: true,
    value: brightness.bind("value"),
    on_change: ({ value }) => brightness.value = value,
})

export const Brightness = () => Widget.Box({
    children: [
        Widget.Button({
            vpack: "center",
            class_name: "bg-blue",
            child: Widget.Icon({icon: "brightness", css: "font-size: 17px"}),
            tooltip_text: brightness.bind("value").as(v =>
                `Screen Brightness: ${Math.floor(v * 100)}%`),
        }),
        BrightnessSlider(),
    ],
})
