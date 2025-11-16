import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import AstalBattery from "gi://AstalBattery"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import AstalWp from "gi://AstalWp"
import AstalNetwork from "gi://AstalNetwork"
import AstalTray from "gi://AstalTray"
import AstalMpris from "gi://AstalMpris"
import AstalApps from "gi://AstalApps"
import { For, With, createBinding, onCleanup } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import { SpecialWorkspaces, Workspaces } from "./applets/Workspaces"
import { Backlights } from "../modules/backlight";
import Wp from "gi://Wp?version=0.5"
import { BarMprisPlayer } from "./applets/Media"

function Mpris() {
  const mpris = AstalMpris.get_default()
  const apps = new AstalApps.Apps()
  const players = createBinding(mpris, "players")

  return (
    <menubutton>
      <box>
        <For each={players}>
          {(player) => {
            const [app] = apps.exact_query(player.entry)
            return <image visible={!!app.iconName} iconName={app?.iconName} />
          }}
        </For>
      </box>
      <popover>
        <box spacing={4} orientation={Gtk.Orientation.VERTICAL}>
          <For each={players}>
            {(player) => (
              <box spacing={4} widthRequest={200}>
                <box overflow={Gtk.Overflow.HIDDEN} css="border-radius: 8px;">
                  <image
                    pixelSize={64}
                    file={createBinding(player, "coverArt")}
                  />
                </box>
                <box
                  valign={Gtk.Align.CENTER}
                  orientation={Gtk.Orientation.VERTICAL}
                >
                  <label xalign={0} label={createBinding(player, "title")} />
                  <label xalign={0} label={createBinding(player, "artist")} />
                </box>
                <box hexpand halign={Gtk.Align.END}>
                  <button
                    onClicked={() => player.previous()}
                    visible={createBinding(player, "canGoPrevious")}
                  >
                    <image iconName="media-seek-backward-symbolic" />
                  </button>
                  <button
                    onClicked={() => player.play_pause()}
                    visible={createBinding(player, "canControl")}
                  >
                    <box>
                      <image
                        iconName="media-playback-start-symbolic"
                        visible={createBinding(
                          player,
                          "playbackStatus",
                        )((s) => s === AstalMpris.PlaybackStatus.PLAYING)}
                      />
                      <image
                        iconName="media-playback-pause-symbolic"
                        visible={createBinding(
                          player,
                          "playbackStatus",
                        )((s) => s !== AstalMpris.PlaybackStatus.PLAYING)}
                      />
                    </box>
                  </button>
                  <button
                    onClicked={() => player.next()}
                    visible={createBinding(player, "canGoNext")}
                  >
                    <image iconName="media-seek-forward-symbolic" />
                  </button>
                </box>
              </box>
            )}
          </For>
        </box>
      </popover>
    </menubutton>
  )
}

function Tray() {
  const tray = AstalTray.get_default()
  const items = createBinding(tray, "items")

  const init = (btn: Gtk.MenuButton, item: AstalTray.TrayItem) => {
    btn.menuModel = item.menuModel
    btn.insert_action_group("dbusmenu", item.actionGroup)
    item.connect("notify::action-group", () => {
      btn.insert_action_group("dbusmenu", item.actionGroup)
    })
  }

  return (
    <box>
      <For each={items}>
        {(item) => (
          <menubutton $={(self) => init(self, item)}>
            <image gicon={createBinding(item, "gicon")} />
          </menubutton>
        )}
      </For>
    </box>
  )
}

function Wireless() {
  const network = AstalNetwork.get_default()
  const wifi = createBinding(network, "wifi")

  const sorted = (arr: Array<AstalNetwork.AccessPoint>) => {
    return arr.filter((ap) => !!ap.ssid).sort((a, b) => b.strength - a.strength)
  }

  async function connect(ap: AstalNetwork.AccessPoint) {
    // connecting to ap is not yet supported
    // https://github.com/Aylur/astal/pull/13
    try {
      await execAsync(`nmcli d wifi connect ${ap.bssid}`)
    } catch (error) {
      // you can implement a popup asking for password here
      console.error(error)
    }
  }

  return (
    <box visible={wifi(Boolean)}>
      <With value={wifi}>
        {(wifi) =>
          wifi && (
            <menubutton>
              <image iconName={createBinding(wifi, "iconName")} />
              <popover>
                <box orientation={Gtk.Orientation.VERTICAL}>
                  <For each={createBinding(wifi, "accessPoints")(sorted)}>
                    {(ap: AstalNetwork.AccessPoint) => (
                      <button onClicked={() => connect(ap)}>
                        <box spacing={4}>
                          <image iconName={createBinding(ap, "iconName")} />
                          <label label={createBinding(ap, "ssid")} />
                          <image
                            iconName="object-select-symbolic"
                            visible={createBinding(
                              wifi,
                              "activeAccessPoint",
                            )((active) => active === ap)}
                          />
                        </box>
                      </button>
                    )}
                  </For>
                </box>
              </popover>
            </menubutton>
          )
        }
      </With>
    </box>
  )
}

function AudioOutput() {
  const { defaultSpeaker: speaker } = AstalWp.get_default()!
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
    <button >
      <box>
        <Gtk.EventControllerScroll $={(self) => self.set_flags(Gtk.EventControllerScrollFlags.VERTICAL)}
          onScroll={(_, __, dy) => {
            speaker.volume = Math.max(0, Math.min(1, speaker.volume - (dy / 200)))

            return true;
          }}
        />
        <label label={createBinding(speaker, "volume").as((volume) => (Math.floor(volume * 100)).toString() + "%")} />
        <image
          iconName={createBinding(speaker, "volumeIcon").as(() => getVolumeIcon())}
          pixelSize={22}
          css="padding-left: 3px"
        />
      </box>
    </button>
  )
}

export function Mic() {
  const mic = AstalWp.get_default()?.audio.default_microphone!

  return <button
    class="mic"
    onClicked={() => mic.set_mute(!mic.get_mute())}
  >
    <box>
      <image
        iconName={createBinding(mic, "mute").as((muted) => muted ? "Mic-Muted" : "Mic")}
        pixelSize={22}
      />
    </box>
  </button >
}


function Battery() {

  function getBatteryIcon(percent: number): string {
    if (battery.charging) {
      return 'Battery-Charging';
    } else if (percent >= .70) {
      return 'Battery-Full';
    } else if (percent >= .20) {
      return 'Battery-Mid';
    } else if (percent >= .10) {
      return 'Battery-Low'
    } else {
      return 'Battery-Critical';
    }
  }

  const battery = AstalBattery.get_default();

  return (
    <button css="background: transparent">
      <box>
        <label label={createBinding(battery, "percentage").as((p) => `${Math.floor(p * 100)}%`)} />
        <image
          iconName={createBinding(battery, "batteryIconName").as(() => getBatteryIcon(battery.percentage))}
          pixelSize={27}
          css="padding-left: 3px"
        />
      </box>
    </button>
  )
}

function Clock({ format = "%l:%M %p" }) {
  const time = createPoll("", 1000, () => {
    return GLib.DateTime.new_now_local().format(format)?.trimStart()!
  })

  return (
    <button>
      <label label={time} />
    </button>
  )
}

function Backlight() {
  return <With value={createBinding(Backlights.getDefault(), "default")}>
    {(bklight: Backlights.Backlight | null) => bklight &&
      <Gtk.Button onClicked={() => {
        bklight.brightness = bklight.maxBrightness
      }}
        class={"backlight"}>
        <box>
          <image
            iconName={"Brightness"}
            pixelSize={22}
            css=""
          />
          <label label={createBinding(bklight, "brightness").as(() => {
            var brightness = Math.ceil((bklight.brightness / bklight.maxBrightness) * 100).toString() + "%";
            return brightness;
          })} />
          <Gtk.EventControllerScroll $={(self) => self.set_flags(Gtk.EventControllerScrollFlags.VERTICAL)}
            onScroll={(_, __, dy) => {
              var newBrightness = (Math.max(.01, Math.min(1, (bklight.brightness / bklight.maxBrightness) - (dy / 200)))) * bklight.maxBrightness
              bklight.brightness = Math.floor(newBrightness);
              return true;
            }}
          />
        </box>
      </Gtk.Button>
    }
  </With>
}

export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  let win: Astal.Window
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  onCleanup(() => {
    // Root components (windows) are not automatically destroyed.
    // When the monitor is disconnected from the system, this callback
    // is run from the parent <For> which allows us to destroy the window
    win.destroy()
  })

  return (
    <window
      $={(self) => (win = self)}
      visible
      namespace="my-bar"
      cssClasses={["bar"]}
      name={`bar-${gdkmonitor.connector}`}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox>
        <box $type="start" spacing={4}>
          <Workspaces />
          <AudioOutput />
          <Mic />
          <SpecialWorkspaces />
          <Battery />
        </box>
        <box $type="end" spacing={4}>
          <BarMprisPlayer />
          <Wireless />
          <Backlight />
          <Clock />
        </box>
      </centerbox>
    </window>
  )
}
