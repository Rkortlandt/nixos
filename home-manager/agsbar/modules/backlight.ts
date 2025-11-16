import { monitorFile, readFile } from "ags/file";
import { exec } from "ags/process";
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
    #default: Backlight | null = null;
    #available: boolean = false;


    @getter(Array as unknown as ParamSpec<Array<Backlight>>)
    get backlights() { return this.#backlights; }

    @getter(BacklightParamSpec)
    get default() { return this.#default!; }

    /** true if there are any backlights available */
    @getter(Boolean)
    get available() { return this.#available; }

    public scan(): Array<Backlight> {
      const dir = Gio.File.new_for_path(`/sys/class/backlight`),
        backlights: Array<Backlight> = [];

      let fileEnum: Gio.FileEnumerator;

      try {
        fileEnum = dir.enumerate_children("standard::*", Gio.FileQueryInfoFlags.NONE, null);
        for (const backlight of fileEnum) {
          try {
            backlights.push(new Backlight(backlight.get_name()));
          } catch (_) { }
        }
      } catch (_) {
        return [];
      }

      if (backlights.length < 1) {
        if (this.#available) {
          this.#available = false;
          this.notify("available");
        }

        this.#default = null;
        this.notify("default");
      }

      if (backlights.length > 0) {
        if (this.#backlights.length < 1) {
          this.#available = true;
          this.notify("available");
        }

        if (!this.#default || !backlights.filter(bk => bk.path === this.#default?.path)[0]) {
          this.#default = backlights[0];
          this.notify("default");
        }
      }

      this.#backlights = backlights;
      this.notify("backlights");

      return backlights;
    }

    public setDefault(bk: Backlight): void {
      this.#default = bk;
      this.notify("default");
    }

    constructor(scan: boolean = true) {
      super();
      scan && this.scan();
    }
  }

  @register({ GTypeName: "Backlight" })
  class _Backlight extends GObject.Object {

    declare $signals: GObject.Object.SignalSignatures & {
      "brightness-changed": (value: number) => void
    };

    readonly #name: string;
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

    @getter(Boolean)
    get isDefault() { return this.path === getDefault().default?.path; }

    /**
     * The "internal" brightness value, which updates instantly.
     * Changes are debounced before being written to the system.
     */
    @getter(Number)
    get brightness() { return this.#internalBrightness; };
    @setter(Number)
    set brightness(level: number) {
      // Don't do anything if the value is already set
      if (level === this.#internalBrightness)
        return;

      // Update internal value and notify UI instantly
      this.#internalBrightness = level;
      this.notify("brightness");
      this.emit("brightness-changed", level);

      // Cancel any pending write operation
      if (this.#writeTimer > 0)
        GLib.source_remove(this.#writeTimer);

      // Schedule a new write operation
      this.#writeTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
        this.writeBrightness(this.#internalBrightness);
        this.#writeTimer = 0; // Clear the timer ID
        return GLib.SOURCE_REMOVE; // Stop timer from repeating
      });
    }

    @getter(Number)
    get maxBrightness() { return this.#maxBrightness; };


    constructor(name: string = "intel_backlight") {
      super();

      if (!Gio.File.new_for_path(`/sys/class/backlight/${name}/brightness`).query_exists(null))
        throw new Error(`Brightness: Couldn't find brightness for "${name}"`);

      this.#conn = getDefault().connect("notify::default", () =>
        this.notify("is-default"));

      this.#name = name;
      this.#path = `/sys/class/backlight/${name}`;
      this.notify("path");
      this.#maxBrightness = Number.parseInt(readFile(`${this.#path}/max_brightness`));
      this.notify("max-brightness");

      // Read initial brightness and set both internal and system values
      this.#systemBrightness = Number.parseInt(readFile(`${this.#path}/brightness`));
      this.#internalBrightness = this.#systemBrightness;


      this.#monitor = monitorFile(`/sys/class/backlight/${name}/brightness`, () => {
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

    private writeBrightness(level: number): boolean {
      try {
        // Update system brightness optimistically
        // The file monitor will correct this if it fails
        this.#systemBrightness = level;
        exec(`brightnessctl -d ${this.#name} s ${level}`);
        return true;
      } catch (e) {
        console.error(`Backlight: Couldn't set brightness for "${this.#name}". Stderr: ${e}`);
      }

      return false;
    }

    vfunc_dispose(): void {
      this.#monitor.cancel();
      getDefault().disconnect(this.#conn);

      // Ensure timer is cleaned up
      if (this.#writeTimer > 0)
        GLib.source_remove(this.#writeTimer);
    }

    public emit<Signal extends keyof typeof this.$signals>(
      signal: Signal,
      ...args: Parameters<(typeof this.$signals)[Signal]>
    ): void {
      super.emit(signal, ...args);
    }

    public connect<Signal extends keyof typeof this.$signals>(
      signal: Signal,
      callback: (self: typeof this, ...args: Parameters<(typeof this.$signals)[Signal]>) => ReturnType<(typeof this.$signals)[Signal]>
    ): number {
      return super.connect(signal, callback);
    }
  }

  export const Backlights = _Backlights;
  export const Backlight = _Backlight;
  export type Backlight = InstanceType<typeof Backlight>;
  export type Backlights = InstanceType<typeof Backlights>;
}
