import { monitorFile, readFile } from "ags/file";
import { execAsync } from "ags/process";
import GObject, { getter, ParamSpec, register, setter, signal } from "ags/gobject";

import Gio from "gi://Gio?version=2.0";
import GLib from "gi://GLib?version=2.0"; // <-- Added for timer


export namespace RefreshRate {
  let instance: _RefreshRate;

  export function getDefault(): _RefreshRate {
    if (!instance)
      instance = new _RefreshRate();

    return instance;
  }

  @register({ GTypeName: "RefreshRate" })
  class _RefreshRate extends GObject.Object {
    declare $signals: GObject.Object.SignalSignatures & {
      "refresh-rate-changed": (value: number) => void
    };

    #refreshRate: number;

    @signal(Number) brightnessChanged(_: number): void { };

    @getter(String)
    get refreshRate() { return this.#refreshRate; }

    @setter(Number)
    set refreshRate(hertz: number) {
      if (hertz != 60 && hertz != 120) {
        return
      }

      this.#refreshRate = hertz;
      this.notify("refresh-rate");
      this.emit("refresh-rate-changed", hertz);
    }

    @getter(Number)
    get avalibleRefreshRates() {
      // Get Main Display RefreshRates from eDP-1 from hyprlan
      const refreshRates: number[] = [];

      const output = execAsync(["hyprctl", "monitors"]).stdout;
      const lines = output.split("\n");
      for (const line of lines) {
        const match = line.match(/"name":\s*"(\w+)"/);

        return
      }


      constructor(name: string = "intel_backlight", deviceClass: DeviceClass = "backlight") {
        super();

        this.#name = name;
        this.#deviceClass = deviceClass;
        this.#type = deviceClass === "leds" || name.includes("kbd") ? "keyboard" : "screen";
        this.#path = `/sys/class/${deviceClass}/${name}`;

        if (!Gio.File.new_for_path(`${this.#path}/brightness`).query_exists(null))
          throw new Error(`Brightness: Couldn't find brightness for "${name}" in ${this.#path}`);

        this.#conn = getDefault().connect(
          this.#type === "keyboard" ? "notify::default-kbd" : "notify::default",
          () => this.notify("is-default")
        );

        this.notify("path");
        this.#maxBrightness = Number.parseInt(readFile(`${this.#path}/max_brightness`));
        this.notify("max-brightness");

        // Read initial brightness and set both internal and system values
        this.#systemBrightness = Number.parseInt(readFile(`${this.#path}/brightness`));
        this.#internalBrightness = this.#systemBrightness;


        this.#monitor = monitorFile(`${this.#path}/brightness`, () => {
          // System file changed (e.g., hardware keys)
          const newBrightness = this.readBrightness();

          // Only update if the value has actually changed
          if (this.#systemBrightness === newBrightness)
            return;

          // Cancel any pending UI-driven write
          if (this.#writeTimer > 0) {
            GLib.source_remove(this.#writeTimer);
            this.#writeTimer = 0;
          }

          // Sync both system and internal values
          this.#systemBrightness = newBrightness;
          this.#internalBrightness = newBrightness;
          this.notify("brightness");
          this.emit("brightness-changed", this.brightness);
        });
      }

    private readBrightness(): number {
      try {
        const brightness = Number.parseInt(readFile(`${this.#path}/brightness`));
        return brightness;
      } catch (e) {
        console.error(`Backlight: An error occurred while reading brightness from "${this.#name}"`);
      }

      // Fallback to the last known *system* brightness
      return this.#systemBrightness ?? this.#maxBrightness ?? 0;
    }

    private async writeBrightness(level: number): Promise<boolean> {
      this.#systemBrightness = level;

      // 1. Try brightnessctl first
      try {
        await execAsync(["brightnessctl", "-d", this.#name, "s", `${level}`]);
        return true;
      } catch (_) {
        // brightnessctl failed or had permission denied, fall back to login1
      }

      // 2. Fall back to systemd-logind via DBus (which has permissions to set brightness)
      try {
        const bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, null);
        const sessions = bus.call_sync(
          "org.freedesktop.login1",
          "/org/freedesktop/login1",
          "org.freedesktop.login1.Manager",
          "ListSessions",
          null,
          null,
          Gio.DBusCallFlags.NONE,
          -1,
          null
        );
        const arr = sessions.get_child_value(0);
        for (let i = 0; i < arr.n_children(); i++) {
          const item = arr.get_child_value(i);
          const spath = item.get_child_value(4).get_string()[0];
          try {
            bus.call_sync(
              "org.freedesktop.login1",
              spath,
              "org.freedesktop.login1.Session",
              "SetBrightness",
              new GLib.Variant("(ssu)", [this.#deviceClass, this.#name, level]),
              null,
              Gio.DBusCallFlags.NONE,
              -1,
              null
            );
            return true;
          } catch (_) {
            // continue searching for active session
          }
        }
      } catch (e) {
        console.error(`Backlight: Couldn't set brightness for "${this.#name}" via login1. Error: ${e}`);
      }

      return false;
    }

    public destroy(): void {
      this.#monitor?.cancel();
      if (this.#conn && instance) {
        instance.disconnect(this.#conn);
        this.#conn = 0;
      }

      // Ensure timer is cleaned up
      if (this.#writeTimer > 0) {
        GLib.source_remove(this.#writeTimer);
        this.#writeTimer = 0;
      }
    }
  }

  export const Backlights = _Backlights;
  export const Backlight = _Backlight;
  export type Backlight = InstanceType<typeof Backlight>;
  export type Backlights = InstanceType<typeof Backlights>;
}
