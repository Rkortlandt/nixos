import { Brightness } from "./widgets/brightness.js"
import { NetworkToggle, WifiSelection } from "./widgets/network.js"
import { BluetoothToggle, BluetoothDevices } from "./widgets/bluetooth.js"
import { Info } from "./widgets/info.js"
import SettingsWindow from "../widgets/settingswindow.js"
import { CpuUsageSlider, HeatSlider, RamUsageSlider } from "./widgets/system.js"
import { Audio, Mic } from "./widgets/sound.js"
import { Media } from "./widgets/media.js"
const media = (await Service.import("mpris")).bind("players")

/** 
 * @param toggles {Array}
 * @param menus {Array}
 * */
const Row = (
    toggles,
    menus,
) => Widget.Box({
    vertical: true,
    children: [
        Widget.Box({
            class_name: " padding",
            homogeneous: true,
            children: toggles.map(w => w()),
        }),
        ...menus.map(w => w()),
    ],
    })

const TopLeft = () => Widget.Box({
    vertical: true,
    class_name: "bg padding",
    homogeneous: false,
    hexpand: false,
    vexpand: false,
    spacing: 8,
    children: [
        Widget.Box({
            class_name: " padding",
            vertical: true,
            children: [
                Audio(),
                Mic(),
                Media(),
            ],
        }),
    ],
})

const TopRight = () => Widget.Box({
    vertical: true,
    class_name: "bg padding",
    homogeneous: false,
    hexpand: false,
    vexpand: false,
    spacing: 8,
    children: [
        Info(),
        Widget.Box({
            class_name: " padding",
            vertical: true,
            children: [
                Brightness(),
            ],
        }),
        Row(
            [NetworkToggle, BluetoothToggle],
            [WifiSelection, BluetoothDevices],
        ),
    ],
})

const BottomLeft = () => Widget.Box({
    vertical: true,
    class_name: "bg padding",
    homogeneous: false,
    hexpand: false,
    vexpand: false,
    spacing: 8,
    children: [
        Widget.Box({
            class_name: " padding",
            vertical: true,
            children: [
                CpuUsageSlider(),
                HeatSlider(),
                RamUsageSlider(),
            ],
        }),
    ],
})

const BottomRight = () => Widget.Box({
    vertical: true,
    class_name: "bg padding",
    homogeneous: false,
    hexpand: false,
    vexpand: false,
    spacing: 8,
    children: [
        Widget.Box({
            class_name: " padding",
            vertical: true,
            children: [
                Widget.Calendar({
                    showDayNames: true,
                    showDetails: true,
                    showHeading: true,
                    class_name: "calender",
                    //detail: (self, y, m, d) => {
                    //    return `<span color="white">${y}. ${m}. ${d}.</span>`
                    //},
                    //onDaySelected: ({ date: [y, m, d] }) => {
                    //    print(`${y}. ${m}. ${d}.`)
                    //},
                })           
            ],
        }),
    ],
})
export function Settings (window = 0) {
    return SettingsWindow({
        name: `quicksettings-${window}`,
        monitor: window,
        exclusivity: "exclusive",
        transition: "slide_down",
        layout: "top-right",
        child1: TopLeft(),
        child2: BottomLeft(),
        child3: TopRight(),
        child4: BottomRight(),
    })
}
