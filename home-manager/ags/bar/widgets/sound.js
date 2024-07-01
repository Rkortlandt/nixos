const audio = await Service.import('audio')
const mpris = await Service.import('mpris')

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

export function Media() {
    return Widget.Box({
        children: mpris.bind('players').as(p => p.map(Player))
    })
}

export const Volume = () => {
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

export const Mic = () => Widget.Button({
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
