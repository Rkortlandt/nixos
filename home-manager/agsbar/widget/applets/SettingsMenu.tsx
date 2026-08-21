import app from "ags/gtk4/app";
import Gtk from "gi://Gtk?version=4.0";
import GLib from "gi://GLib?version=2.0";
import Astal from "gi://Astal?version=4.0";
import { createBinding, createComputed, createState } from "ags";
import { createPoll } from "ags/time";
import { execAsync } from "ags/process";
import { Backlights } from "../../modules/backlight";

const SCRIPT_PATH = "/home/ss-pro/nixos/home-manager/hyprland/hypr/scripts/refresh-rate.sh";

function RefreshRateSquircleToggle() {
  const currentHz = createPoll(120, 2000, `${SCRIPT_PATH} get`, (out) => {
    const num = parseInt(out.trim());
    return isNaN(num) ? 60 : num;
  });

  const [loading, setLoading] = createState(false);
  const [isAuto, setIsAuto] = createState(false);

  const toggleRate = async () => {
    if (loading.get()) return;
    setLoading(true);
    try {
      await execAsync([SCRIPT_PATH, "toggle"]);
      const out = await execAsync([SCRIPT_PATH, "get"]);
      const num = parseInt(out.trim());
      if (!isNaN(num)) {
        currentHz.set(num);
      }
      setIsAuto(false);
    } catch (e) {
      console.error("RefreshRate toggle error:", e);
    } finally {
      setLoading(false);
    }
  };

  const setSpecificRate = async (hz: number) => {
    if (loading.get()) return;
    setLoading(true);
    try {
      await execAsync([SCRIPT_PATH, `${hz}`]);
      const out = await execAsync([SCRIPT_PATH, "get"]);
      const num = parseInt(out.trim());
      if (!isNaN(num)) {
        currentHz.set(num);
      }
      setIsAuto(false);
    } catch (e) {
      console.error(`RefreshRate set ${hz}Hz error:`, e);
    } finally {
      setLoading(false);
    }
  };

  const setAutoMode = async () => {
    if (loading.get()) return;
    setLoading(true);
    try {
      await execAsync([SCRIPT_PATH, "auto"]);
      const out = await execAsync([SCRIPT_PATH, "get"]);
      const num = parseInt(out.trim());
      if (!isNaN(num)) {
        currentHz.set(num);
      }
      setIsAuto(true);
    } catch (e) {
      console.error("RefreshRate auto error:", e);
    } finally {
      setLoading(false);
    }
  };

  const cardClass = createComputed(
    [currentHz, isAuto],
    (hz, auto) => {
      if (auto) return "squircle-toggle active-auto";
      return hz >= 100 ? "squircle-toggle active-high" : "squircle-toggle active-low";
    }
  );

  const subtitleText = createComputed(
    [currentHz, isAuto],
    (hz, auto) => {
      if (auto) return `${hz} Hz • Automatic (Battery / AC)`;
      return hz >= 100 ? `${hz} Hz • Ultra Smooth` : `${hz} Hz • Power Saver`;
    }
  );

  const badgeClass = createComputed(
    [currentHz, isAuto],
    (hz, auto) => {
      if (auto) return "squircle-badge auto";
      return hz >= 100 ? "squircle-badge high" : "squircle-badge low";
    }
  );

  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="setting-card" spacing={10}>
      <box spacing={6}>
        <label label="DISPLAY REFRESH RATE" class="setting-card-title" hexpand={true} halign={Gtk.Align.START} />
        <label
          label={isAuto.as((auto) => (auto ? "AUTO" : "MANUAL"))}
          class="setting-card-badge"
        />
      </box>

      {/* Main Squircle Toggle Button */}
      <button
        class={cardClass}
        onClicked={toggleRate}
        tooltipText="Click to toggle between 60Hz and 120Hz"
      >
        <box spacing={12} css="padding: 2px 4px;">
          <box class="squircle-icon-container" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
            <image iconName="video-display-symbolic" pixelSize={22} />
          </box>
          <box orientation={Gtk.Orientation.VERTICAL} hexpand={true} valign={Gtk.Align.CENTER} spacing={2}>
            <label label="Refresh Rate" halign={Gtk.Align.START} css="font-size: 13px; font-weight: bold;" />
            <label label={subtitleText} halign={Gtk.Align.START} css="font-size: 11px; opacity: 0.75;" />
          </box>
          <box valign={Gtk.Align.CENTER}>
            <label
              label={currentHz.as((hz) => `${hz} Hz`)}
              class={badgeClass}
            />
          </box>
        </box>
      </button>

      {/* Squircle Segmented Selector Pills */}
      <box class="squircle-pill-container" homogeneous={true} spacing={4}>
        <button
          class={createComputed(
            [currentHz, isAuto],
            (hz, auto) => (!auto && hz === 60 ? "squircle-pill active" : "squircle-pill")
          )}
          onClicked={() => setSpecificRate(60)}
          tooltipText="Force 60Hz"
        >
          <label label="60 Hz" />
        </button>
        <button
          class={createComputed(
            [currentHz, isAuto],
            (hz, auto) => (!auto && hz === 120 ? "squircle-pill active" : "squircle-pill")
          )}
          onClicked={() => setSpecificRate(120)}
          tooltipText="Force 120Hz"
        >
          <label label="120 Hz" />
        </button>
        <button
          class={isAuto.as((auto) => (auto ? "squircle-pill active" : "squircle-pill"))}
          onClicked={setAutoMode}
          tooltipText="Auto mode switches refresh rate based on power state"
        >
          <label label="Auto" />
        </button>
      </box>
    </box>
  );
}

function KeyboardBrightnessStopsSlider() {
  const backlights = Backlights.getDefault();
  const kbdBk = backlights.defaultKbd;
  const isKbdAvailable = createBinding(backlights, "kbdAvailable");

  if (!kbdBk) {
    return (
      <box orientation={Gtk.Orientation.VERTICAL} class="setting-card" spacing={8}>
        <box spacing={6}>
          <image iconName="Keyboard-Brightness" pixelSize={18} />
          <label label="KEYBOARD BACKLIGHT" class="setting-card-title" />
        </box>
        <label label="No keyboard backlight detected" class="subtitle" css="font-size: 11px; padding: 8px 0;" />
      </box>
    );
  }

  const max = kbdBk.maxBrightness > 0 ? kbdBk.maxBrightness : 3;
  const kbdBrightness = createBinding(kbdBk, "brightness");

  // Format label for stop value
  const getStopLabel = (val: number) => {
    if (val === 0) return "Off";
    if (max === 3) {
      if (val === 1) return "Low";
      if (val === 2) return "Med";
      if (val === 3) return "High";
    }
    if (val === max) return "Max";
    return `${val}`;
  };

  const statusLabel = kbdBrightness.as((b) => {
    if (b === 0) return "Off";
    return `${getStopLabel(b)} (${b}/${max})`;
  });

  const handleScroll = (dy: number) => {
    const current = kbdBk.brightness;
    const next = dy > 0 ? Math.max(0, current - 1) : Math.min(max, current + 1);
    if (next !== current) {
      kbdBk.brightness = next;
    }
    return true;
  };

  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="setting-card" spacing={10} visible={isKbdAvailable}>
      <Gtk.EventControllerScroll
        $={(self) => self.set_flags(Gtk.EventControllerScrollFlags.VERTICAL)}
        onScroll={(_, __, dy) => handleScroll(dy)}
      />

      {/* Header */}
      <box spacing={6}>
        <image iconName="Keyboard-Brightness" pixelSize={18} />
        <label label="KEYBOARD BACKLIGHT" class="setting-card-title" hexpand={true} halign={Gtk.Align.START} />
        <label label={statusLabel} class="setting-card-badge" />
      </box>

      {/* Slider with Discrete Stops */}
      <box orientation={Gtk.Orientation.VERTICAL} spacing={4} css="padding: 0 4px;">
        <slider
          class="stepped-slider"
          hexpand={true}
          min={0}
          max={max}
          step={1}
          page={1}
          value={kbdBrightness}
          onChangeValue={({ value }) => {
            const rounded = Math.max(0, Math.min(max, Math.round(value)));
            if (kbdBk.brightness !== rounded) {
              kbdBk.brightness = rounded;
            }
          }}
          $={(self) => {
            self.set_round_digits(0);
            self.set_draw_value(false);
            self.set_has_origin(true);
            for (let i = 0; i <= max; i++) {
              self.add_mark(i, Gtk.PositionType.BOTTOM, getStopLabel(i));
            }
          }}
        />
      </box>
    </box>
  );
}

export function SettingsMenu() {
  const time = createPoll("", 1000, () => {
    return GLib.DateTime.new_now_local().format("%l:%M")?.trimStart()!;
  });

  const fullDate = createPoll("", 10000, () => {
    return GLib.DateTime.new_now_local().format("%A, %B %e")?.trim()!;
  });

  const settingsPopover = (
    <popover hasArrow={false} class="settings-popover">
      <box orientation={Gtk.Orientation.VERTICAL} class="settings-menu menu-container" widthRequest={320} spacing={12}>
        {/* Header with Date & Title */}
        <box orientation={Gtk.Orientation.VERTICAL} class="settings-header" spacing={2}>
          <box spacing={6}>
            <label label="Quick Settings" class="settings-date" hexpand={true} halign={Gtk.Align.START} />
            <label label={time} css="font-size: 14px; font-weight: bold; color: #0EA16F;" />
          </box>
          <label label={fullDate} class="settings-subdate" halign={Gtk.Align.START} />
        </box>

        <box class="settings-separator" />

        {/* Squircle Style Refresh Rate Toggle */}
        <RefreshRateSquircleToggle />

        {/* Stepped Slider Keyboard Brightness with Stops */}
        <KeyboardBrightnessStopsSlider />
      </box>
    </popover>
  );

  return (
    <menubutton class="settings-menu-btn menu-btn" popover={settingsPopover as any}>
      <box spacing={4} css="padding: 0 4px; background: transparent">
        <label label={time} css="font-weight: bold;" />
      </box>
    </menubutton>
  );
}

export default SettingsMenu;
