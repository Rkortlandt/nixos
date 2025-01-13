import AstalBattery from "gi://AstalBattery?version=0.1"
import { Gdk, Gtk } from "astal/gtk3"
import { Variable, bind } from "astal"

var battery = AstalBattery.get_default();

function getBatteryIcon(percent : number): string {
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

function getColorState(percent : number): string {
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

export function Battery() {
    return <button css={bind(battery, "percentage").as((p) => `background-color:${getColorState(p)};`)}>
	<box>
	    <label label={bind(battery, "percentage").as((p) => `${Math.floor(p * 100)}%`)}/>
	    <icon 
		icon={bind(battery, "percentage").as((p) => getBatteryIcon(p))} 
		css="font-size: 25px; padding-left: 3px;"/> 
	</box>
    </button>

}
