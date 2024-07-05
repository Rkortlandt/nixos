import { Brightness } from "./widgets/brightness.js"
import { NetworkToggle, WifiSelection } from "./widgets/network.js"
import { BluetoothToggle, BluetoothDevices } from "./widgets/bluetooth.js"
import { Info } from "./widgets/info.js"
import PopupWindow from "../widgets/popupwindow.js"
import { CpuUsageSlider, HeatSlider, RamUsageSlider } from "./widgets/system.js"
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
            class_name: "bg-black padding",
            homogeneous: true,
            children: toggles.map(w => w()),
        }),
        ...menus.map(w => w()),
    ],
    })

const Settings = () => Widget.Box({
    vertical: true,
    class_name: "bg padding",
    css: "min-width: 70px;",
    homogeneous: false,
    spacing: 8,
    children: [
        Info(),
        Widget.Box({
            class_name: "bg-black padding",
            vertical: true,
            children: [
                Brightness(),
            ],
        }),
        Row(
            [NetworkToggle, BluetoothToggle],
            [WifiSelection, BluetoothDevices],
        ),
        Widget.Box({
            class_name: "bg-black padding",
            vertical: true,
            children: [
                CpuUsageSlider(),
                HeatSlider(),
                RamUsageSlider(),
            ],
        }),
    ],
})

const QuickSettings = () => PopupWindow({
    name: "quicksettings",
    exclusivity: "exclusive",
    transition: "slide_down",
    layout: "top-right",
    child: Settings(),
})

export function setupQuickSettings() {
    App.addWindow(QuickSettings())
}
