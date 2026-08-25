import app from "ags/gtk4/app";
import Gtk from "gi://Gtk?version=4.0";
import GLib from "gi://GLib?version=2.0";
import Astal from "gi://Astal?version=4.0";
import { createBinding, createComputed, createState } from "ags";
import { createPoll } from "ags/time";
import { Backlights } from "../../modules/backlight";
import { RefreshRate } from "../../modules/refreshrate";
import AstalPowerProfiles from "gi://AstalPowerProfiles?version=0.1";
import AstalBattery from "gi://AstalBattery?version=0.1";

function RefreshRateToggle() {
  const refreshRate = RefreshRate.getDefault();
  const currentHz = createBinding(refreshRate, "refreshRate");

  const setSpecificRate = (hz: number) => {
    refreshRate.refreshRate = hz;
  };

  const ratesList = [60, 120];

  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="setting-card" spacing={8}>
      <box spacing={6}>
        <image iconName="video-display-symbolic" pixelSize={18} />
        <label label="DISPLAY REFRESH RATE" class="setting-card-title" hexpand={true} halign={Gtk.Align.START} />
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
        <image iconName="Cpu" pixelSize={18} />
        <label label="POWER PROFILE" class="setting-card-title" hexpand={true} halign={Gtk.Align.START} />
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

function readBatterySysfs() {
  try {
    let basePath = "/sys/class/power_supply/BAT1";
    if (!GLib.file_test(basePath, GLib.FileTest.EXISTS)) {
      basePath = "/sys/class/power_supply/BAT0";
    }
    if (!GLib.file_test(basePath, GLib.FileTest.EXISTS)) {
      return { voltage: 0, health: 100, cycles: 0, rate: 0, energy: 0, energyFull: 0, timeHours: 0 };
    }

    const readNum = (file: string) => {
      try {
        const [ok, content] = GLib.file_get_contents(`${basePath}/${file}`);
        if (ok && content) {
          const str = new TextDecoder().decode(content).trim();
          const n = parseFloat(str);
          return isNaN(n) ? 0 : n;
        }
      } catch (_) { }
      return 0;
    };

    const voltageNow = readNum("voltage_now");
    const voltageMinDesign = readNum("voltage_min_design") || voltageNow;
    const currentNow = readNum("current_now");
    const powerNow = readNum("power_now");

    const chargeNow = readNum("charge_now");
    const chargeFull = readNum("charge_full");
    const chargeFullDesign = readNum("charge_full_design");

    const energyNow = readNum("energy_now");
    const energyFull = readNum("energy_full");
    const energyFullDesign = readNum("energy_full_design");

    const cycles = readNum("cycle_count");

    // Voltage (V)
    const voltage = voltageNow > 0 ? voltageNow / 1e6 : (voltageMinDesign > 0 ? voltageMinDesign / 1e6 : 0);

    // Rate (W)
    let rate = 0;
    if (powerNow > 0) {
      rate = powerNow / 1e6;
    } else if (currentNow > 0 && voltage > 0) {
      rate = (currentNow / 1e6) * voltage;
    }

    // Energy (Wh)
    const vRef = (voltageMinDesign > 0 ? voltageMinDesign : voltageNow) / 1e6;
    let energy = 0;
    let eFull = 0;
    let eDesign = 0;

    if (energyNow > 0 || energyFull > 0) {
      energy = energyNow / 1e6;
      eFull = energyFull / 1e6;
      eDesign = energyFullDesign > 0 ? energyFullDesign / 1e6 : eFull;
    } else if (chargeNow > 0 || chargeFull > 0) {
      energy = (chargeNow / 1e6) * vRef;
      eFull = (chargeFull / 1e6) * vRef;
      eDesign = chargeFullDesign > 0 ? (chargeFullDesign / 1e6) * vRef : eFull;
    }

    // Health (%)
    let health = 100;
    if (eDesign > 0 && eFull > 0) {
      health = (eFull / eDesign) * 100;
    } else if (chargeFullDesign > 0 && chargeFull > 0) {
      health = (chargeFull / chargeFullDesign) * 100;
    }

    // Time (hours)
    let timeHours = 0;
    if (currentNow > 0 && chargeNow > 0) {
      timeHours = chargeNow / currentNow;
    } else if (rate > 0 && energy > 0) {
      timeHours = energy / rate;
    }

    return { voltage, health, cycles, rate, energy, energyFull: eFull, timeHours };
  } catch (_) {
    return { voltage: 0, health: 100, cycles: 0, rate: 0, energy: 0, energyFull: 0, timeHours: 0 };
  }
}

function BatteryStatusCard() {
  const battery = AstalBattery.get_default();
  if (!battery) return null;

  const isPresent = createBinding(battery, "isPresent");
  const percentage = createBinding(battery, "percentage");
  const charging = createBinding(battery, "charging");
  const energy = createBinding(battery, "energy");
  const energyFull = createBinding(battery, "energyFull");
  const energyRate = createBinding(battery, "energyRate");
  const state = createBinding(battery, "state");
  const timeToFull = createBinding(battery, "timeToFull");
  const timeToEmpty = createBinding(battery, "timeToEmpty");

  const sysfsData = createPoll(readBatterySysfs(), 5000, readBatterySysfs);

  const batteryHeaderIcon = createComputed([percentage, charging], (pct, chg) => {
    if (chg) return "Battery-Charging";
    if (pct > 0.8) return "Battery-Full";
    if (pct > 0.4) return "Battery-Mid";
    if (pct > 0.1) return "Battery-Low";
    return "Battery-Critical";
  });

  // Top line: Arrow + Rate (white) + Voltage (grey) on left, Energy Wh (grey) on right
  const arrowIcon = createComputed([state], (st) => {
    if (st === AstalBattery.State.CHARGING) return "Charging-Arrow-Up";
    if (st === AstalBattery.State.DISCHARGING) return "Charging-Arrow-Down";
    return "";
  });

  const wattageText = createComputed([energyRate, sysfsData], (rate, sys) => {
    const w = Math.abs(rate || 0) > 0 ? Math.abs(rate) : (sys?.rate || 0);
    return `${w.toFixed(2)}W`;
  });

  const voltageText = sysfsData.as((sys) => `${(sys?.voltage || 0).toFixed(1)}V`);

  const energyWhText = createComputed([energy, energyFull, sysfsData], (cur, full, sys) => {
    const c = (cur && cur > 0) ? cur : (sys?.energy || 0);
    const f = (full && full > 0) ? full : (sys?.energyFull || 0);
    return `${c.toFixed(1)} / ${f.toFixed(1)}Wh`;
  });

  // Middle line: Percentage (white) + Status / Time (grey)
  const percentText = percentage.as((p) => `${Math.round((p || 0) * 100)}%`);

  const statusTimeText = createComputed(
    [state, timeToFull, timeToEmpty, percentage, sysfsData],
    (st, tFull, tEmpty, pct, sys) => {
      if (st === AstalBattery.State.CHARGING) {
        const hours = (tFull && Number(tFull) > 0) ? Number(tFull) / 3600 : (sys?.timeHours || 0);
        return hours > 0 ? `Full in · ${hours.toFixed(1)}h` : "Charging";
      }
      if (st === AstalBattery.State.DISCHARGING) {
        const hours = (tEmpty && Number(tEmpty) > 0) ? Number(tEmpty) / 3600 : (sys?.timeHours || 0);
        return hours > 0 ? `Empty in · ${hours.toFixed(1)}h` : "Discharging";
      }
      if (st === AstalBattery.State.FULLY_CHARGED || (pct && pct >= 0.99)) {
        return "Fully Charged";
      }
      return "Plugged In";
    }
  );

  // Bottom line: Health (grey)
  const healthCyclesText = sysfsData.as((sys) => {
    const health = sys?.health || 100;
    return `Health ${health.toFixed(2)}%`;
  });

  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="setting-card battery-status-card" spacing={8} visible={isPresent}>
      {/* Header */}
      <box spacing={6}>
        <image iconName={batteryHeaderIcon} pixelSize={18} />
        <label label="BATTERY" class="setting-card-title" hexpand={true} halign={Gtk.Align.START} />
      </box>

      {/* Metrics container */}
      <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        {/* Top Row: [Arrow] Wattage (white), Voltage (grey) on left, Energy Wh (grey) on right */}
        <box spacing={6}>
          <box spacing={4} hexpand={true} halign={Gtk.Align.START} valign={Gtk.Align.CENTER}>
            <image
              iconName={arrowIcon}
              pixelSize={18}
              visible={arrowIcon.as((ic) => !!ic)}
            />
            <label label={wattageText} class="battery-text-white" />
            <label label={voltageText} class="battery-text-grey" />
          </box>
          <label label={energyWhText} class="battery-text-grey" halign={Gtk.Align.END} valign={Gtk.Align.CENTER} />
        </box>

        {/* Middle Row: Percentage (white) + Status / Time (grey) */}
        <box spacing={6} valign={Gtk.Align.CENTER}>
          <label label={percentText} class="battery-text-white" halign={Gtk.Align.START} />
          <label label={statusTimeText} class="battery-text-grey" halign={Gtk.Align.START} />
        </box>

        {/* Bottom Row: Health & Cycles (grey) */}
        <box spacing={6}>
          <label label={healthCyclesText} class="battery-text-grey" halign={Gtk.Align.START} />
        </box>
      </box>
    </box>
  );
}

export function SettingsMenu() {
  const time = createPoll("", 30000, () => {
    return GLib.DateTime.new_now_local().format("%l:%M")?.trimStart()!;
  });

  const fullDate = createPoll("", 60000, () => {
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

        <box class="settings-separator" />

        {/* Battery Status Section */}
        <BatteryStatusCard />
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
