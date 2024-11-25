App.addIcons(`${App.configDir}/assets`);
import { Bar } from './bar/bar.js';
import { Settings } from './settings/settings.js';
import { NotificationPopups } from './notifications/popups.js';
import Gdk from "gi://Gdk"
export const settingsVisible = Variable(false);

App.config({
    windows: [
        ...forMonitors(Bar),
        ...forMonitors(Settings),
        NotificationPopups(),
        // this is where window definitions will go
    ],
    style: './style.css',
})

function Test (window = 0) {
    return Widget.Window({
        exclusivity: "ignore",
        layer: "overlay",
        name: `test-${window}`,
        monitor: window,
        child: Widget.Box({
            className: '',
            child: Widget.Label({
                label: "hello"
            })       
        }), 
    });
}

export function forMonitors(widget) {
    const n = Gdk.Display.get_default()?.get_n_monitors() || 1
    return range(n, 0).flatMap(widget)
}

function range(length, start = 1) {
    return Array.from({ length }, (_, i) => i + start)
}

export {}
