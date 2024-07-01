import { Workspaces } from './widgets/hyprland.js';
import { Volume, Mic, Media } from './widgets/sound.js';
import { Battery } from './widgets/battery.js'
import { Network } from './widgets/network.js'
import { Brightness } from './widgets/brightness.js';
import { Clock } from './widgets/clock.js';

function Bar (window = 0) {
    return Widget.Window({
        exclusivity: 'exclusive',
        name: `bar-${window}`,
        monitor: window,
        anchor: ['top', 'left', 'right'],
        child: Widget.Box({
            className: 'bg',
            child: Widget.Box({
                className: 'bar',
                spacing: 4,
                homogeneous: false,
                vertical: false,
                children: [
                    Workspaces(),
                    Volume(),
                    Mic(),
                    Battery(),
                    Widget.Box({ hexpand: true }),
                    Media(),
                    Network(),
                    Brightness(),
                    Clock(),
                ]
            }), 
        }), 
    });
}

export function setupBar() {
    App.addWindow(Bar())
}
