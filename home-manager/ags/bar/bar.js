import { Workspaces } from './widgets/hyprland.js';
import { Volume, Mic, Media } from './widgets/sound.js';
import { Battery } from './widgets/battery.js'
import { Network } from './widgets/network.js'
import { Brightness } from './widgets/brightness.js';
import { Clock } from './widgets/clock.js';
import { settingsVisible } from '../config.js';
//import { Calculator } from './widgets/calculator.js';
import { CpuUsage, Heat, RamUsage } from './widgets/system.js';

const visibleItems = Variable({
    Workspaces: true,
    Volume: true,
    Mic: true,
    Battery: true,
    Media: true,
    Calculator: false,
    Network: true,
    Brightness: true,
    Clock: true,
    CpuUsage: false,
    RamUsage: false,
    Heat: false,
});

const leftItems = ["Workspaces", "Volume", "Mic", "Battery"]
const rightItems = ["Media", "Network", "Brightness", "CpuUsage", "RamUsage", "Heat", "Clock"]
const barItems = { Workspaces, Volume, Mic, Battery, Media, Network, Brightness, Clock, CpuUsage, RamUsage, Heat};

export function Bar (window = 0) {
    return Widget.Window({
        class_name: settingsVisible.bind().as((o) => (o)? "bg-norad": ""),
        exclusivity: 'exclusive',
        name: `bar-${window}`,
        monitor: window,
        anchor: ['top', 'left', 'right'],
        child: Widget.Box({
            className: '',
            child: Widget.Box({
                className: 'margin',
                spacing: 4,
                homogeneous: false,
                vertical: false,
                children: visibleItems.bind().as(visible => [
                    ...leftItems.filter(item => visible[item]).map(item => barItems[item]()),
                    Widget.Box({ hexpand: true }),
                    ...rightItems.filter(item => visible[item]).map(item => barItems[item]())
                ])
            }), 
        }), 
    });
}




export function toggleBarItemVisibility(itemName) {
    visibleItems.value = {
        ...visibleItems.value,
        [itemName]: !visibleItems.value[itemName]
    };
}
