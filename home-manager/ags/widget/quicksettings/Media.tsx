import { Astal, Gtk } from "astal/gtk3"
import Mpris from "gi://AstalMpris"
import { Variable, bind } from "astal"
import { Revealer, Stack } from "astal/gtk3/widget"

function lengthStr(length: number) {
    const min = Math.floor(length / 60)
    const sec = Math.floor(length % 60)
    const sec0 = sec < 10 ? "0" : ""
    return `${min}:${sec0}${sec}`
}


function MediaPlayer({ player }: { player: Mpris.Player }) {
    const { START, END } = Gtk.Align

    const title = bind(player, "title").as(t => {
        if (!t) return "Unknown Track";
        if (t.length > 28) return t.slice(0, 28).trim() + "...";
        return t;
    });

    const artist = bind(player, "artist").as(a => {
        if (!a) return "Unknown Artist";
        if (a.length > 28) return a.slice(0, 28).trim() + "...";
        return a;
    });

    const coverArt = bind(player, "coverArt").as(c =>
        `background: linear-gradient(to bottom, rgba(0, 0, 0, 0.5), rgba(10, 77, 100, 0.5)), url('${c}');
background-repeat: no-repeat;
background-size: cover;`)


    const position = bind(player, "position").as(p => player.length > 0
        ? p / player.length : 0)

    const playIcon = bind(player, "playbackStatus").as(s =>
        s === Mpris.PlaybackStatus.PLAYING
            ? "Pause"
            : "Play"
    )
    return <box className="media-player" css={coverArt} visible={bind(player, "title").as((t) => t.length > 0)}>
        <box vertical>
            <box className="title">
                <label truncate hexpand halign={START} label={title} />
            </box>
                <label truncate hexpand halign={START} label={artist} />
            <slider
                visible={bind(player, "length").as(l => l > 0)}
                onDragged={({ value }) => player.position = value * player.length}
                value={position}
            />
            <centerbox className="actions">
                <label
                    hexpand
                    className="position"
                    css="color:white"
                    halign={START}
                    visible={bind(player, "length").as(l => l > 0)}
                    label={bind(player, "position").as(lengthStr)}
                />
                <box>
                    <button
                        onClicked={() => player.previous()}
                        visible={bind(player, "canGoPrevious")}>
                        <icon icon="Skip-Backward" css="font-size: 23px" />
                    </button>
                    <button
                        className="bg-blue round"
                        onClicked={() => player.play_pause()}
                        visible={bind(player, "canControl")}>
                        <icon icon={playIcon} css="font-size: 24px" />
                    </button>
                    <button
                        onClicked={() => player.next()}
                        visible={bind(player, "canGoNext")}>
                        <icon icon="Skip-Forward" css="font-size: 23px" />
                    </button>
                </box>
                <label
                    className="length"
                    hexpand
                    css="color:white"
                    halign={END}
                    visible={bind(player, "length").as(l => l > 0)}
                    label={bind(player, "length").as(l => l > 0 ? lengthStr(l) : "0:00")}
                />
            </centerbox>
        </box>
    </box>
}


function BarMediaPlayer({ player, name, shown, length }: { player: Mpris.Player, name: number, shown: Variable<string>, length: number }) {
    
    const playIcon = bind(player, "playbackStatus").as(s =>
        s === Mpris.PlaybackStatus.PLAYING
            ? "Pause"
            : "Play"
    )
    
    const title = bind(player, "title").as(t =>
        (t.length > 28)? t.slice(0, 28).trim() + "..." : t || "Unknown Track")

    var showPlayIcons = Variable(false);

    return <eventbox
        name={name.toString()}
        hexpand={false}
        halign={Gtk.Align.END}
        css="background: linear-gradient(45deg, #0F5880, #0EA16F);"
        onClick={() => {(name >= (length - 1))? shown.set("0"): shown.set(`${name + 1}`);
            print(length);
            print(player.bus_name, name); }}
        onHover={() => showPlayIcons.set(true)} 
        onHoverLost={() => showPlayIcons.set(false)}
    >
        <box>
            <icon icon="Music" css="margin-left: 8px; font-size: 23px"/>
            <revealer revealChild={showPlayIcons()} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
                <box>
                    <button
                        className="square-button-no-rad"
                        onClicked={() => player.previous()}
                        visible={bind(player, "canGoPrevious")}>
                        <icon icon="Skip-Backward" css="font-size: 23px" />
                    </button>
                    <button
                        onClicked={() => player.play_pause()}
                        visible={bind(player, "canControl")}>
                        <icon icon={playIcon} css="font-size: 24px" />
                    </button>
                    <button
                        className="square-button-no-rad"
                        onClicked={() => player.next()}
                        visible={bind(player, "canGoNext")}>
                        <icon icon="Skip-Forward" css="font-size: 23px" />
                    </button>
                </box>
            </revealer>
            <label label={title} css="margin-left: 2px; margin-right: 8px;"/> 
        </box>
    </eventbox>
}

export function BarMprisPlayer() {
    const mpris = Mpris.get_default()
    const shown = Variable("0"); 
    return <Stack shown={shown()} transitionType={Gtk.StackTransitionType.SLIDE_UP}>
        {bind(mpris, "players").as((players) => players.map((player, index, arr) => {
            shown.set("0");
            print("changed")
            return <BarMediaPlayer name={index} player={player} shown={shown} length={arr.length}/>
        }))}
    </Stack>
}

export default function MprisPlayers() {
    const mpris = Mpris.get_default()
    print("Players", mpris.players.length);
    return <box vertical={true}>
        {bind(mpris, "players").as(arr => arr.map(player => {
            return <MediaPlayer player={player} />
        }))}
    </box>
}
