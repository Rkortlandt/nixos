import Gtk from "gi://Gtk?version=4.0"
import AstalWp from "gi://AstalWp"
import { For, With, createBinding, createState, onCleanup } from "ags"

export function AudioOutput() {
  const [showAux, setShowAux] = createState(false);
  const [showSinks, setShowSinks] = createState(false);
  const { defaultSpeaker: speaker, audio: audio } = AstalWp.get_default()!
  const speakerList = createBinding(audio, "speakers");
  function getVolumeIcon(): string {
    let volume = speaker.get_volume();
    if (speaker.get_mute()) {
      return "Speaker-Muted"
    }
    if (volume > .8) {
      return "Speaker-High"
    } else if (volume > .5) {
      return "Speaker-Mid"
    } else if (volume > 0) {
      return "Speaker-Low"
    }
    return "Speaker-Zero"
  }

  return (
    <box css="background: rgba(0, 0, 0, .7);">
      <Gtk.EventControllerScroll $={(self) => self.set_flags(Gtk.EventControllerScrollFlags.VERTICAL)}
        onScroll={(_, __, dy) => {
          speaker.volume = Math.max(0, Math.min(1, speaker.volume - (dy / 200)))

          return true;
        }}
      />
      <Gtk.EventControllerMotion
        onEnter={() => {
          setShowAux(true);
        }}
        onLeave={() => {
          setShowAux(false);
        }}
      />

      <button onClicked={() => setShowSinks((s) => !s)}>
        <box>
          <label label={createBinding(speaker, "volume").as((volume) => (Math.floor(volume * 100)).toString() + "%")} />
          <image
            iconName={createBinding(speaker, "volumeIcon").as(() => getVolumeIcon())}
            pixelSize={22}
            css="padding-left: 3px;"
          />
        </box>
      </button>
      <revealer revealChild={showAux} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
        <box css="padding-left: 4px;">
          <revealer revealChild={showSinks.as((v) => !v)} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
            <button class={"mic"} onClicked={() => { speaker.set_mute(!speaker.get_mute()) }}>
              <image
                iconName={"Speaker-Muted"}
                pixelSize={22}
                css="padding-left: 3px;"
              />
            </button>
          </revealer>
          <revealer revealChild={showSinks} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT} >
            <box spacing={4}>
              <For each={speakerList}>
                {(device) => (
                  <button
                    onClicked={() => {
                      device.is_default = true
                      console.log(`Switched to: ${device.description}`)
                    }}

                    class={createBinding(speaker, "name").as((name) => name == device.name ? "primary-bg" : "")}
                  >
                    <label label={device.name ? device.name : "Default"} />
                  </button>
                )}
              </For>
            </box>
          </revealer>
        </box >
      </revealer >
    </box >
  )
}

