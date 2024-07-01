App.addIcons(`${App.configDir}/assets`);
const hyprland = await Service.import('hyprland');
const audio = await Service.import('audio')
const battery = await Service.import('battery')
const mpris = await Service.import('mpris')
const network = await Service.import('network')
import { setupBar } from './bar/bar.js';
import { setupQuickSettings } from './quicksettings/quicksettings.js';


function Clock() {
    const time = Variable("", {
        poll: [1000, 'date "+%H:%M"'],
    })

    const date = Variable("", {
        poll: [1000, 'date "+%e %B (%m)"'],
    })

    return Widget.Button({
        on_clicked: () => App.toggleWindow("quicksettings"),
        label: time.bind(),
       
    })

}

const wifiIndicator = () => {
    /** @param strength {number} */
    let getColorByStrength = (strength) => {
        switch (true) {
            case strength >= 75:
                return '#127CF0'; // Strong signal: Blue
            case strength >= 50:
                return '#2AA028'; // Good signal: Green
            case strength >= 25:
                return '#6EBD30'; // Fair signal: YGreen
            default:
                return '#D17C2E'; // Weak signal: Orange
        }
    } 

    return Widget.Button({
        className: "wifi",
        child: Widget.Icon({
            icon: network.wifi.bind('state').as(
                state => {
                    if (state === "disconnected") {
                        return "no-wifi"
                    } else {
                        return "wifi"
                    }
                }
            ),
            css: "font-size: 15px; padding: 0px 3px;",
            setup: (self) => {
                self.hook(network.wifi, () => {
                    self.icon = (network.wifi.state === "disconnected")? 
                        "no-wifi": "wifi";
                })
            }
        }),
        css: network.bind('wifi').as(wifi => 
            `background-color: ${getColorByStrength(wifi.strength)};`
        ),
        setup: (self) => {
            self.hook(network.wifi, () => {
                self.css = `background-color: ${(network.wifi.state === "disconnected")? "#BD3030" : getColorByStrength(network.wifi.strength)}`;
            })
        }
    })
}


const wiredIndicator = () => Widget.Icon({
    icon: network.wired.bind('icon_name'),
})

const networkIndicator = () => Widget.Stack({
    children: {
        wifi: wifiIndicator(),
        wired: wiredIndicator(),
    },
    shown: network.bind('primary').as(p => p || 'wifi'),
})

/** @param {import('types/service/mpris').MprisPlayer} player */
const Player = (player) => Widget.Box({
    children: [
        Widget.Label().hook(player, label => {
            const { track_artists, track_title } = player;
            label.label = `${track_artists[0] } - ${track_title}`.slice(0, 25).concat('...');
        }),
        Widget.Button({ 
            onClicked: () => player.playPause(),
            child: Widget.Icon({
                icon: "pause",
                css: "font-size: 15px; "
            })
        }),
        Widget.Button({ 
            onClicked: () => player.next(),
            child: Widget.Icon({
                icon: "skip-forward",
                css: "font-size: 15px; "
            })
        }),
    ] 
});

const players = Widget.Box({
    children: mpris.bind('players').as(p => p.map(Player))
})

const batteryIndicator = Widget.Button({
    setup: self => {
        let batteryLabel;
        let batteryIcon;

        self.child = Widget.Box({
            children: [
                batteryLabel = Widget.Label({
                    label: `${battery.percent}%`,
                }),
                batteryIcon = Widget.Icon({
                    icon: getBatteryIcon(battery),
                    css: "font-size: 25px; padding: 0px 4px;"
                }),
            ],
        });

        self.hook(battery, () => {
            batteryLabel.label = `${battery.percent}%`;
            batteryIcon.icon = getBatteryIcon(battery);
            self.css = `background-color: ${getColorState(battery)}`;
        });
    },
});


/** @param battery {import('types/service/battery').Battery} */
function getBatteryIcon(battery) {
    if (battery.charging) {
        return 'batt-charging';
    } else if (battery.percent >= 90) {
        return 'batt-full';
    } else if (battery.percent >= 50) {
        return 'batt-mid';
    } else if (battery.percent >= 20) {
        return 'batt-warn';
    } else {
        return 'batt-crit';
    }
}

/** @param battery {import('types/service/battery').Battery} */
function getColorState(battery) {
    if (battery.charging) {
        return '#127CF0';
    } else if (battery.percent >= 90) {
        return '#239A20';
    } else if (battery.percent >= 50) {
        return '#6FAB40';
    } else if (battery.percent >= 20) {
        return '#BB712C';
    } else {
        return '#BD3030';
    }
}

const volumeIndicator = () => {
    audio.maxStreamVolume = 1;
    return Widget.Button({
        on_scroll_up: () => audio.speaker.volume += .01,
        on_scroll_down: () => audio.speaker.volume -= .01,
        setup: self => {
            let volumeLabel;
            let icon;
        

            self.child = Widget.Box({ 
                children: [
                    volumeLabel = Widget.Label({
                        label: `${Math.floor(audio.speaker.volume * 100)}`,
                    }),
                    icon = Widget.Icon({
                        icon: 'speaker',
                        css: "font-size: 15px; padding: 0px 3px;"
                    }),
                ],
            });

            self.hook(audio.speaker, () => {
                volumeLabel.label = `${Math.floor(audio.speaker.volume * 100)}%`;
            });
        },
    })
};

const mic = () => Widget.Button({
    on_clicked: () => audio.microphone.is_muted = !audio.microphone.is_muted,
    className: 'mic',
    setup: self => {
        let icon;
        self.child = Widget.Box({
            children: [ icon = Widget.Icon({icon: 'mic-unmuted', css: "font-size: 17px; padding: 0px 0px;"})]
        }),

        self.hook(audio.microphone, () => { 
           icon.icon = (audio.microphone.is_muted)? 'mic-muted': 'mic-unmuted',
            self.css = (audio.microphone.is_muted)? 'background-color: #BD3030': 'background-color: transparent'
        });
    }
});

const dispatch = ws => hyprland.messageAsync(`dispatch workspace ${ws}`);
const Workspaces = () => Widget.EventBox({
    child: Widget.Box({
        children: Array.from({ length: 10 }, (_, i) => i + 1).map(i => Widget.Button({
            className: 'workspace-button',
            attribute: i,
            label: `${i}`,
            onClicked: () => dispatch(i),
        })),

        setup: self => {
            self.hook(hyprland.active.workspace, () => self.children.forEach(btn => {
                btn.visible = hyprland.workspaces.some(ws => ws.id === btn.attribute);
                if (hyprland.workspaces[0].id === btn.attribute) btn.class_name = 'workspace-button-start';
                if (hyprland.workspaces[hyprland.workspaces.length - 1].id === btn.attribute) btn.class_name = 'workspace-button-end';

                if (btn.attribute == hyprland.active.workspace.id) {
                    btn.css = "color: #0EA16F";
                } else if (hyprland.workspaces.find(({ id }) => id == btn.attribute)?.monitor != 'eDP-1') {
                    btn.css = "color: #172A7D";
                } else {
                    btn.css = "color: #0F5880";
                }
            }));
        },
    }),
})

/*
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
                    volumeIndicator(),
                    mic(),
                    batteryIndicator,
                    Widget.Box({ hexpand: true }),
                    players,
                    networkIndicator(),
                    brightnessLabel(),
                    Clock(),
                ]
            }), 
        }), 
    });
}
*/

setupQuickSettings();
setupBar();
App.config({
    windows: [
        // this is where window definitions will go
    ],
    style: './style.css',
})

export {}
