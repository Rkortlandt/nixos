import { Astal, Gtk } from "astal/gtk3"
import Mpris from "gi://AstalMpris"
import { bind } from "astal"

function lengthStr(length: number) {
    const min = Math.floor(length / 60)
    const sec = Math.floor(length % 60)
    const sec0 = sec < 10 ? "0" : ""
    return `${min}:${sec0}${sec}`
}


function MediaPlayer({ player }: { player: Mpris.Player }) {
    const { START, END } = Gtk.Align

    const title = bind(player, "title").as(t =>
        (t.length > 28)? t.slice(0, 28).trim() + "..." : t || "Unknown Track")

    const artist = bind(player, "artist").as(a =>
        (a.length > 28)? a.slice(0, 28).trim() + "..." : a || "Unknown Artist")

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

    return <box className="media-player" css={coverArt}>
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

export default function MprisPlayers() {
    const mpris = Mpris.get_default()
    print("Players", mpris.players.length);
    return <box>
        {bind(mpris, "players").as(arr => arr.map(player => {
            return <MediaPlayer player={player} />
        }))}
    </box>
}
