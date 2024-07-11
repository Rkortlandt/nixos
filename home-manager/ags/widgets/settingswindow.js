import { settingsVisible } from "../config.js"

export default ({
    name,
    child1,
    child2,
    child3,
    child4,
    layout = "center",
    transition,
    ...props
}) => Widget.Window({
    name,
    class_name: "bg-light",
    setup: w => w.keybind("Escape", () => settingsVisible.value = !settingsVisible.value),
    visible: settingsVisible.bind(),    
    keymode: "on-demand",
    layer: "top",
    anchor: ["top", "bottom", "right", "left"],
    child: Widget.Box({
            class_name: "padding",
            children: [
                Widget.Box({ vexpand: true, hexpand: false, vertical: true, css: "min-width: 250px", children: [
                    child1, 
                    Widget.Button({ vexpand: true, hexpand: true, className: "invis-btn", on_clicked : () => settingsVisible.value = !settingsVisible.value}),
                    child2,
                ]}),
                Widget.Button({ vexpand: true, hexpand: true, className: "invis-btn", on_clicked : () => settingsVisible.value = !settingsVisible.value}),
                Widget.Box({ vexpand: true, hexpand: false, vertical: true, css: "min-width: 300px", children: [
                    child3, 
                    Widget.Button({ vexpand: true, hexpand: true, className: "invis-btn", on_clicked : () => settingsVisible.value = !settingsVisible.value}),
                    child4,
                ]}),

            ],
        }),
    ...props,
})
