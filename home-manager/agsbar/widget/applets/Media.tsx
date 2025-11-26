import { Accessor, createBinding, createComputed, createState, For, jsx, Setter, State } from "gnim";
import AstalMpris from "gi://AstalMpris?version=0.1";
import Gtk from "gi://Gtk?version=4.0"

function lengthStr(length: number) {
  const min = Math.floor(length / 60)
  const sec = Math.floor(length % 60)
  const sec0 = sec < 10 ? "0" : ""
  return `${min}:${sec0}${sec}`
}


function MediaPlayer({ player }: { player: AstalMpris.Player }) {
  const { START, END } = Gtk.Align

  const title = createBinding(player, "title").as(t => {
    if (!t) return "Unknown Track";
    if (t.length > 28) return t.slice(0, 28).trim() + "...";
    return t;
  });

  const artist = createBinding(player, "artist").as(a => {
    if (!a) return "Unknown Artist";
    if (a.length > 28) return a.slice(0, 28).trim() + "...";
    return a;
  });

  const coverArtStyle = createBinding(player, "coverArt").as(c => {
    return `background-image: url('file://${c}');`
  })


  const position = createBinding(player, "position").as(p => player.length > 0
    ? p / player.length : 0)

  const playIcon = createBinding(player, "playbackStatus").as(s =>
    s === AstalMpris.PlaybackStatus.PLAYING
      ? "Pause"
      : "Play"
  )

  return <box
    class="media-player media-player-cover"
    css={coverArtStyle}
    visible={createBinding(player, "title").as((t) => t.length > 0)}
  >
    <box orientation={Gtk.Orientation.VERTICAL}>
      <box class="title">
        <label hexpand halign={START} label={title} />
      </box>
      <label hexpand halign={START} label={artist} />
      <slider
        visible={createBinding(player, "length").as(l => l > 0)}
        onChangeValue={(_, __, value) => { player.position = value * player.length }}
        value={position}
      />
      <box class="actions">
        <label
          hexpand
          class="position"
          halign={START}
          visible={createBinding(player, "length").as(l => l > 0)}
          label={createBinding(player, "position").as(lengthStr)}
        />
        <box>
          <button
            onClicked={() => player.previous()}
            visible={createBinding(player, "canGoPrevious")}
          >
            <image iconName="Skip-Backward" pixelSize={22} />
          </button>
          <button
            class="bg-blue round"
            onClicked={() => player.play_pause()}
            visible={createBinding(player, "canControl")}>
            <image iconName={playIcon} pixelSize={22} />
          </button>
          <button
            onClicked={() => player.next()}
            visible={createBinding(player, "canGoNext")}>
            <image iconName="Skip-Forward" pixelSize={22} />

          </button>
        </box>
        <label
          class="length"
          hexpand
          halign={END}
          visible={createBinding(player, "length").as(l => l > 0)}
          label={createBinding(player, "length").as(l => l > 0 ? lengthStr(l) : "0:00")}
        />
      </box>
    </box>
  </box>
}

function BarMediaPlayer(
  { player, onClick }: { player: AstalMpris.Player, onClick: () => void }) {

  const playIcon = createBinding(player, "playbackStatus").as(s =>
    s === AstalMpris.PlaybackStatus.PLAYING
      ? "Pause"
      : "Play"
  )

  const title = createBinding(player, "title").as(t =>
    (t.length > 28) ? t.slice(0, 28).trim() + "..." : t || "Unknown Track")

  var [showPlayIcons, setShowPlayIcons] = createState(false);

  return <Gtk.Box
    class="bar-media-player"
    hexpand={false}
    halign={Gtk.Align.END}
  >
    <Gtk.EventControllerMotion
      onEnter={() => {
        setShowPlayIcons(true);
      }}
      onLeave={() => {
        setShowPlayIcons(false);
      }}
    />
    <box>
      <image
        class="bar-music-icon"
        pixelSize={22}
        iconName="Music"
      />
      <revealer revealChild={showPlayIcons} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
        <box>
          <button
            class="square-button-no-rad no-bg"
            onClicked={() => player.previous()}
            visible={createBinding(player, "canGoPrevious")}>
            <image
              class="bar-control-icon"
              pixelSize={22}
              iconName="Skip-Backward"
            />
          </button>
          <button
            class="no-bg"
            onClicked={() => player.play_pause()}
            visible={createBinding(player, "canControl")}>
            <image
              class="bar-control-icon bar-play-icon"
              pixelSize={22}
              iconName={playIcon} />
          </button>
          <button
            class="square-button-no-rad no-bg"
            onClicked={() => player.next()}
            visible={createBinding(player, "canGoNext")}>
            <image
              class="bar-control-icon"
              pixelSize={22}
              iconName="Skip-Forward"
            />
          </button>
        </box>
      </revealer>
      <label class="bar-title-label" label={title}>
        <Gtk.GestureClick onBegin={() => onClick()} />
      </label>
    </box>
  </Gtk.Box>

}

export function BarMprisPlayer() {
  const mpris = AstalMpris.get_default()
  const players = createBinding(mpris, "players");
  const [shownPlayer, setShownPlayer] = createState(0);

  players.subscribe(() => {
    setShownPlayer(players.get().length - 1);

    players.get().forEach((player, index) => {
      var playerPaused = createBinding(player, "playbackStatus");

      playerPaused.subscribe(() => {
        if (playerPaused.get() == AstalMpris.PlaybackStatus.PLAYING) {
          setShownPlayer(index);

          players.get().forEach((player2, index2) => {
            if (index != index2) {
              player2.pause();
            }
          });
        }
      });
    });
  });

  return <box>
    <For each={players}>
      {(player, index) => {
        const onClick = () => {
          var numberOfPlayers = players.get().length;
          var newValue = ((shownPlayer.get() < numberOfPlayers - 1) && numberOfPlayers != 1) ? (shownPlayer.get() + 1) : 0;
          // console.log(newValue, numberOfPlayers, shownPlayer.get())
          setShownPlayer(newValue);
        }

        // console.log(player.bus_name, index);
        return <revealer revealChild={shownPlayer.as((number) => number == index.get())} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
          <BarMediaPlayer player={player} onClick={onClick} />
        </revealer>
      }
      }
    </For>
  </box>
}

export function MprisPlayers() {
  const mpris = AstalMpris.get_default()
  print("Players", mpris.players.length);
  return <box orientation={Gtk.Orientation.VERTICAL}>
    <For each={createBinding(mpris, "players")}>
      {(player: AstalMpris.Player) => {
        return <MediaPlayer player={player} />
      }}
    </For>
  </box>
}
