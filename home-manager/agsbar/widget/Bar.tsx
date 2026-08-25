import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import AstalWp from "gi://AstalWp"
import AstalTray from "gi://AstalTray"
import { For, With, createBinding, createComputed, createState, onCleanup } from "ags"
import { SpecialWorkspaces, Workspaces } from "./applets/Workspaces"
import { Backlights } from "../modules/backlight";
import { BarMprisPlayer } from "./applets/Media"
import { SystemInfo } from "./applets/SystemInfo"
import ConnectivityModule from "./applets/Wireless"
import { AudioOutput } from "./applets/Audio"
import { SettingsMenu } from "./applets/SettingsMenu"

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

function ScreenBrightness() {
  const backlights = Backlights.getDefault();
  const screenBk = backlights.default;

  const handleScroll = (dy: number) => {
    const target = backlights.default;
    if (!target) return true;

    // Screen brightness: gentle dy / 400 (~0.25% per delta unit) for smooth, controlled adjustments
    const currentPct = target.brightness / target.maxBrightness;
    const newPct = Math.max(0.01, Math.min(1.0, currentPct - (dy / 400)));
    target.brightness = Math.round(newPct * target.maxBrightness);
    return true;
  };

  const screenBrightness = screenBk ? createBinding(screenBk, "brightness") : createState(0)[0];

  const labelText = createComputed(
    [
      screenBrightness,
      createBinding(backlights, "default"),
    ],
    () => {
      const target = backlights.default;
      if (!target || target.maxBrightness <= 0) return "";
      const pct = Math.ceil((target.brightness / target.maxBrightness) * 100);
      return `${pct}%`;
    }
  );

  const isVisible = createBinding(backlights, "available");

  return (
    <button
      class="backlight"
      visible={isVisible}
      tooltipText={labelText.as((pct) => `Screen Brightness: ${pct} (Scroll to adjust)`)}
    >
      <box spacing={4}>
        <image iconName="Brightness" pixelSize={22} />
        <label label={labelText} />
        <Gtk.EventControllerScroll
          $={(self) => self.set_flags(Gtk.EventControllerScrollFlags.VERTICAL)}
          onScroll={(_, __, dy) => handleScroll(dy)}
        />
      </box>
    </button>
  );
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
          <ScreenBrightness />
          <SettingsMenu />
        </box>
      </centerbox>
    </window>
  )
}
