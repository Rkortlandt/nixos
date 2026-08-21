import { monitorFile, readFile } from "ags/file";
import { execAsync } from "ags/process";
import GObject, { getter, ParamSpec, register, setter, signal } from "ags/gobject";

import Gio from "gi://Gio?version=2.0";
import GLib from "gi://GLib?version=2.0"; // <-- Added for timer


export namespace Backlights {

  const BacklightParamSpec = (name: string, flags: GObject.ParamFlags) =>
    GObject.ParamSpec.jsobject(name, null, null, flags) as ParamSpec<Backlight>;

  let instance: Backlights;

  export function getDefault(): Backlights {
    if (!instance)
      instance = new Backlights();

    return instance;
  }

  @register({ GTypeName: "Backlights" })
  class _Backlights extends GObject.Object {

    #backlights: Array<Backlight> = [];
    #kbdBacklights: Array<Backlight> = [];
    #default: Backlight | null = null;
    #defaultKbd: Backlight | null = null;
    #available: boolean = false;
    #kbdAvailable: boolean = false;

    @getter(Array as unknown as ParamSpec<Array<Backlight>>)
    get backlights() { return this.#backlights; }

    @getter(Array as unknown as ParamSpec<Array<Backlight>>)
    get kbdBacklights() { return this.#kbdBacklights; }

    @getter(BacklightParamSpec)
    get default() { return this.#default!; }

    @getter(BacklightParamSpec)
    get defaultKbd() { return this.#defaultKbd!; }

    /** true if there are any screen backlights available */
    @getter(Boolean)
    get available() { return this.#available; }

    /** true if there are any keyboard backlights available */
    @getter(Boolean)
    get kbdAvailable() { return this.#kbdAvailable; }

    public scan(): void {
      for (const bk of this.#backlights) {
        bk.destroy();
      }
      for (const bk of this.#kbdBacklights) {
        bk.destroy();
      }

      // 1. Scan Screen Backlights (/sys/class/backlight)
      const screenDir = Gio.File.new_for_path(`/sys/class/backlight`);
      const screenBacklights: Array<Backlight> = [];

      try {
        const fileEnum = screenDir.enumerate_children("standard::*", Gio.FileQueryInfoFlags.NONE, null);
        for (const backlight of fileEnum) {
          try {
            screenBacklights.push(new Backlight(backlight.get_name(), "backlight"));
          } catch (_) { }
        }
      } catch (_) { }

      const screenAvailable = screenBacklights.length > 0;
      if (this.#available !== screenAvailable) {
        this.#available = screenAvailable;
        this.notify("available");
      }

      this.#default = screenAvailable ? screenBacklights[0] : null;
      this.notify("default");

      this.#backlights = screenBacklights;
      this.notify("backlights");

      // 2. Scan Keyboard Backlights (/sys/class/leds)
      const ledsDir = Gio.File.new_for_path(`/sys/class/leds`);
      const kbdList: Array<Backlight> = [];

      try {
        const fileEnum = ledsDir.enumerate_children("standard::*", Gio.FileQueryInfoFlags.NONE, null);
        for (const led of fileEnum) {
          const name = led.get_name();
          if (name.includes("kbd_backlight") || name.includes("kbd") || name.includes("keyboard")) {
            try {
              kbdList.push(new Backlight(name, "leds"));
            } catch (_) { }
          }
        }
      } catch (_) { }

      const kbdAvailable = kbdList.length > 0;
      if (this.#kbdAvailable !== kbdAvailable) {
        this.#kbdAvailable = kbdAvailable;
        this.notify("kbd-available");
      }

      this.#defaultKbd = kbdAvailable ? kbdList[0] : null;
      this.notify("default-kbd");

      this.#kbdBacklights = kbdList;
      this.notify("kbd-backlights");
    }

    public setDefault(bk: Backlight): void {
      if (bk.type === "keyboard") {
        this.#defaultKbd = bk;
        this.notify("default-kbd");
      } else {
        this.#default = bk;
        this.notify("default");
      }
    }

    constructor(scan: boolean = true) {
      super();
      instance = this;
      scan && this.scan();
    }
  }

  export type DeviceClass = "backlight" | "leds";
  export type DeviceType = "screen" | "keyboard";

  @register({ GTypeName: "Backlight" })
  class _Backlight extends GObject.Object {

    declare $signals: GObject.Object.SignalSignatures & {
      "brightness-changed": (value: number) => void
    };

    readonly #name: string;
    readonly #deviceClass: DeviceClass;
    readonly #type: DeviceType;
    #path: string;
    #maxBrightness: number;
    #monitor: Gio.FileMonitor;
    #conn: number;

    // --- New/Modified Fields ---
    /** The "snappy" brightness value for the UI */
    #internalBrightness: number;
    /** The "actual" brightness value from the system */
    #systemBrightness: number;
    /** Debounce timer for writing to system */
    #writeTimer: number = 0;
    // ---

    @signal(Number) brightnessChanged(_: number): void { };

    @getter(String)
    get name() { return this.#name; }

    @getter(String)
    get path() { return this.#path; }

    @getter(String)
    get deviceClass() { return this.#deviceClass; }

    @getter(String)
    get type() { return this.#type; }

    @getter(Boolean)
    get isDefault() {
      return this.#type === "keyboard"
        ? this.path === getDefault().defaultKbd?.path
        : this.path === getDefault().default?.path;
    }

    /**
     * The "internal" brightness value, which updates instantly.
     * Changes are debounced before being written to the system.
     */
    @getter(Number)
    get brightness() { return this.#internalBrightness; }
    @setter(Number)
    set brightness(level: number) {
      const clamped = Math.max(0, Math.min(this.#maxBrightness, Math.round(level)));
      // Don't do anything if the value is already set
      if (clamped === this.#internalBrightness)
        return;

      // Update internal value and notify UI instantly
      this.#internalBrightness = clamped;
      this.notify("brightness");
      this.emit("brightness-changed", clamped);

      // Cancel any pending write operation
      if (this.#writeTimer > 0) {
        GLib.source_remove(this.#writeTimer);
        this.#writeTimer = 0;
      }

      // If discrete/keyboard (low maxBrightness), write immediately
      // If screen backlight, debounce with short 25ms delay
      if (this.#maxBrightness <= 10) {
        this.writeBrightness(this.#internalBrightness);
      } else {
        this.#writeTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 25, () => {
          this.writeBrightness(this.#internalBrightness);
          this.#writeTimer = 0;
          return GLib.SOURCE_REMOVE;
        });
      }
    }

    @getter(Number)
    get maxBrightness() { return this.#maxBrightness; }


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
