import app from "ags/gtk4/app";
import Gtk from "gi://Gtk?version=4.0";
import GLib from "gi://GLib?version=2.0";
import Astal from "gi://Astal?version=4.0";
import { createBinding, createComputed, createState } from "ags";
import { createPoll } from "ags/time";
import { Backlights } from "../../modules/backlight";
import { RefreshRate } from "../../modules/refreshrate";
import AstalPowerProfiles from "gi://AstalPowerProfiles?version=0.1";

function RefreshRateToggle() {
  const refreshRate = RefreshRate.getDefault();
  const currentHz = createBinding(refreshRate, "refreshRate");

  const setSpecificRate = (hz: number) => {
    refreshRate.refreshRate = hz;
  };

  const headerBadgeClass = currentHz.as((hz) =>
    hz >= 100 ? "setting-card-badge performance" : "setting-card-badge saver"
  );

  const headerBadgeText = currentHz.as((hz) => (hz > 0 ? `${hz} HZ` : "MANUAL"));

  const ratesList = [60, 120];

  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="setting-card" spacing={8}>
      <box spacing={6}>
        <image iconName="video-display-symbolic" pixelSize={18} />
        <label label="DISPLAY REFRESH RATE" class="setting-card-title" hexpand={true} halign={Gtk.Align.START} />
        <label
          label={headerBadgeText}
          class={headerBadgeClass}
        />
      </box>

      <box class="squircle-pill-container" homogeneous={true} spacing={4}>
        {ratesList.map((hz) => (
          <button
            class={currentHz.as((cur) =>
              cur === hz
                ? `squircle-pill active ${hz >= 100 ? "high" : "low"}`
                : "squircle-pill"
            )}
            onClicked={() => setSpecificRate(hz)}
            tooltipText={`Force ${hz}Hz`}
          >
            <label label={`${hz} Hz`} />
          </button>
        ))}
      </box>
    </box>
  );
}

function KeyboardBrightnessSlider() {
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
    <box orientation={Gtk.Orientation.VERTICAL} class="setting-card" spacing={8} visible={isKbdAvailable}>
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

function PowerProfilesControl() {
  const powerprofiles = AstalPowerProfiles.get_default();
  const activeProfile = createBinding(powerprofiles, "activeProfile");

  const setProfile = (profile: string) => {
    try {
      powerprofiles.set_active_profile(profile);
    } catch (e) {
      console.error(`Failed to set power profile to ${profile}:`, e);
    }
  };

  const formatLabel = (profile: string) => {
    switch (profile) {
      case "power-saver":
        return "Power Saver";
      case "performance":
        return "Performance";
      case "balanced":
      default:
        return "Balanced";
    }
  };

  const formatShort = (profile: string) => {
    switch (profile) {
      case "power-saver":
        return "Saver";
      case "performance":
        return "Perf";
      case "balanced":
      default:
        return "Balanced";
    }
  };

  const badgeClass = activeProfile.as((profile) => {
    switch (profile) {
      case "power-saver":
        return "setting-card-badge saver";
      case "performance":
        return "setting-card-badge performance";
      case "balanced":
      default:
        return "setting-card-badge balanced";
    }
  });

  const squircleBadgeText = activeProfile.as((profile) => {
    switch (profile) {
      case "power-saver":
        return "SAVER";
      case "performance":
        return "PERF";
      case "balanced":
      default:
        return "BALANCED";
    }
  });

  const availableProfiles = (() => {
    try {
      const daemonProfiles = powerprofiles.get_profiles().map((p) => p.profile);
      if (daemonProfiles && daemonProfiles.length > 0) {
        return daemonProfiles;
      }
    } catch (e) {
      // Fall back to standard profiles
    }
    return ["power-saver", "balanced", "performance"];
  })();

  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="setting-card" spacing={8}>
      <box spacing={6}>
        <image iconName="Battery-High" pixelSize={18} />
        <label label="POWER PROFILE" class="setting-card-title" hexpand={true} halign={Gtk.Align.START} />
        <label
          label={activeProfile.as((p) => formatShort(p).toUpperCase())}
          class="setting-card-badge"
        />
      </box>

      {/* Segmented Selector Pills */}
      <box class="squircle-pill-container" homogeneous={true} spacing={4}>
        {availableProfiles.map((id) => (
          <button
            class={activeProfile.as((cur) =>
              cur === id
                ? `squircle-pill active ${id === "power-saver" ? "saver" : id === "performance" ? "performance" : "balanced"}`
                : "squircle-pill"
            )}
            onClicked={() => setProfile(id)}
            tooltipText={`Set ${formatLabel(id)} Profile`}
          >
            <label label={formatShort(id)} />
          </button>
        ))}
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
        <RefreshRateToggle />

        {/* Squircle Style Power Profiles Control */}
        <PowerProfilesControl />

        {/* Stepped Slider Keyboard Brightness with Stops */}
        <KeyboardBrightnessSlider />
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
