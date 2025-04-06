import AstalBattery from "gi://AstalBattery?version=0.1"
import { Gdk, Gtk } from "astal/gtk3"
import { Variable, bind } from "astal"
import { calculate } from "../../calculator/qalculate";

var battery = AstalBattery.get_default();
var upower = new AstalBattery.UPower;
var device = upower.get_devices()[1];
function getBatteryIcon(percent: number): string {
    if (battery.charging) {
        return 'Battery-Charging';
    } else if (percent >= .70) {
        return 'Battery-Full';
    } else if (percent >= .10) {
        return 'Battery-Mid';
    } else {
        return 'Battery-Critical';
    }
}

function getColorState(percent: number): string {
    if (battery.charging) {
        return '#127CF0';
    } else if (percent >= .70) {
        return '#239A20';
    } else if (percent >= .10) {
        return '#6FAB40';
    } else {
        return '#BD3030';
    }
}

export function BarBattery() {
    return <button css={bind(battery, "percentage").as((p) => `background-color:${getColorState(p)};`)}>
        <box>
            <label label={bind(battery, "percentage").as((p) => `${Math.floor(p * 100)}%`)} />
            <icon
                icon={bind(battery, "percentage").as((p) => getBatteryIcon(p))}
                css="font-size: 25px; padding-left: 3px;" />
        </box>
    </button>

}

export function Battery() {
    return <box vertical={true}>
        <box css="padding-right: 8px">
            <icon
                css="font-size: 25px"
                icon={bind(battery, "charging").as((charging) => charging ?
                    "Charging-Arrow-Up" :
                    "Charging-Arrow-Down")} />
            <label css="color: white" label={bind(battery, "energyRate").as((rate) => `${rate.toFixed(2)}W `)} />
            <label label={bind(device, "voltage").as((rate) => `${rate.toFixed(1)}V`)} />
            <box hexpand={true} />
            <label label={bind(battery, "energy").as((rate) => `${rate.toFixed(1)} / ${battery.energyFull.toFixed(1)}Wh`)} />
        </box>
        <box css="padding-left: 8px; padding-bottom: 6px">
            <label
                css="color: white"
                label={bind(battery, "percentage").as((percent) => `${(percent * 100).toFixed(0)}%  `)} />
            {bind(battery, "charging").as((charging) => charging ?
                <label
                    label={bind(battery, "timeToFull").as((rate) =>
                        "Full in ⋅ " + (rate / 3600).toFixed(1).toString() + "h")} /> :
                <label
                    label={bind(battery, "timeToEmpty").as((rate) =>
                        "Empty in ⋅ " + (rate / 3600).toFixed(1).toString() + "h")} />
            )}
        </box>
        <box css="padding-left: 8px;">
            <label label={bind(device, "capacity").as((rate) => `Health ${(rate * 100).toFixed(2).toString()}% ⋅ `)} />
            <label label={bind(device, "charge_cycles").as((rate) => rate.toString() +  "cycles")} />
        </box>
    </box>
}

