import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import AstalWp from "gi://AstalWp"
import AstalTray from "gi://AstalTray"
import { For, With, createBinding, createState, onCleanup } from "ags"
import { createPoll } from "ags/time"
import { SpecialWorkspaces, Workspaces } from "./applets/Workspaces"
import { Backlights } from "../modules/backlight";
import { BarMprisPlayer } from "./applets/Media"
import { SystemInfo } from "./applets/SystemInfo"
import ConnectivityModule from "./applets/Wireless"
import { AudioOutput } from "./applets/Audio"

// Import the calculator and its global state
import { showCalculator, InlineCalculator } from "./applets/Calculator"

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

export function Mic() {
  const mic = AstalWp.get_default()?.audio.default_microphone!

  const [showSlider, setShowSlider] = createState(false);

  return <box>
    <Gtk.EventControllerMotion
      onEnter={() => {
        setShowSlider(true);
      }}
      onLeave={() => {
        setShowSlider(false);
      }}
    />


    <box cssClasses={["black-bg"]} css={"border-radius: 13px;"}>
      <button
        class="mic"
        onClicked={() => mic.set_mute(!mic.get_mute())}
      >
        <image
          iconName={createBinding(mic, "mute").as((muted) => muted ? "Mic-Muted" : "Mic")}
          pixelSize={22}
        />
      </button>
      <revealer revealChild={showSlider} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
        <slider class="mic" widthRequest={100} value={createBinding(mic, "volume")} onChangeValue={(slider) => mic.set_volume(slider.value)} />
      </revealer>
    </box>
  </box >
}

function Clock({ format = "%l:%M" }) {
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

      // Keep our Wayland keyboard focus trick active here!
      keymode={showCalculator.as(show =>
        show ? Astal.Keymode.EXCLUSIVE : Astal.Keymode.NONE
      )}
    >
      <centerbox>
        {/* === LEFT SIDE === */}
        <box $type="start" spacing={4}>

          {/* 1. Place the Calculator as the absolute leftmost element */}
          <InlineCalculator />

          {/* 2. Bind the visibility of everything else to hide when the Calculator shows */}
          <revealer
            revealChild={showCalculator.as(show => !show)}
            transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
          >
            <box spacing={4}>
              <Workspaces />
              <AudioOutput />
              <Mic />
              <SpecialWorkspaces />
              <SystemInfo />
            </box>
          </revealer>

        </box>

        {/* === CENTER === */}
        <box $type="center" spacing={4}>
          {/* Currently empty, but reserves space in the middle if needed */}
        </box>

        {/* === RIGHT SIDE === */}
        <box $type="end" spacing={4}>
          <BarMprisPlayer />
          <ConnectivityModule />
          <Backlight />
          <Clock />
        </box>
      </centerbox>
    </window>
  )
}
