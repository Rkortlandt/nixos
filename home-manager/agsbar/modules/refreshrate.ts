import { execAsync } from "ags/process";
import GObject, { getter, register, setter } from "ags/gobject";
import AstalHyprland from "gi://AstalHyprland?version=0.1";
import GLib from "gi://GLib?version=2.0";

export interface HyprlandWorkspace {
  id: number;
  name: string;
}

export interface HyprlandMonitor {
  id: number;
  name: string;
  description: string;
  make: string;
  model: string;
  serial: string;
  width: number;
  height: number;
  physicalWidth: number;
  physicalHeight: number;
  refreshRate: number;
  x: number;
  y: number;
  activeWorkspace: HyprlandWorkspace;
  specialWorkspace: HyprlandWorkspace;
  reserved: [number, number, number, number];
  scale: number;
  transform: number;
  focused: boolean;
  dpmsStatus: boolean;
  vrr: boolean;
  solitary: string;
  solitaryBlockedBy: string[];
  activelyTearing: boolean;
  tearingBlockedBy: string[];
  directScanoutTo: string;
  directScanoutBlockedBy: string[];
  disabled: boolean;
  currentFormat: string;
  mirrorOf: string;
  availableModes: string[];
  colorManagementPreset: string;
  sdrBrightness: number;
  sdrSaturation: number;
  sdrMinLuminance: number;
  sdrMaxLuminance: number;
  hardwareCursorsInUse: boolean;
}

export namespace RefreshRate {
  let instance: _RefreshRate;

  export function getDefault(): _RefreshRate {
    if (!instance)
      instance = new _RefreshRate();

    return instance;
  }

  @register({ GTypeName: "RefreshRate" })
  class _RefreshRate extends GObject.Object {
    #refreshRate: number = -1;
    #availableRefreshRates: number[] = [];
    #hyprlandSignalId: number = 0;
    #pollTimer: number = 0;
    #applyChain: Promise<void> = Promise.resolve();

    constructor() {
      super();

      const hyprland = AstalHyprland.get_default();
      this.#hyprlandSignalId = hyprland.connect("event", (_self, event: string) => {
        if (
          event.startsWith("monitoradded") ||
          event.startsWith("monitorremoved") ||
          event.startsWith("focusedmon") ||
          event.startsWith("configreloaded")
        ) {
          this.handleExternalEvent();
        }
      });

      this.updateCurrentRefreshRate();
      this.updateRefreshRates();

      // Poll periodically to catch external keyword changes that emit no socket2 events
      this.#pollTimer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 2, () => {
        this.updateCurrentRefreshRate();
        return GLib.SOURCE_CONTINUE;
      });
    }

    private async handleExternalEvent(): Promise<void> {
      // Re-sync both the current rate AND the list of available rates off a
      // single hyprctl call, since a hotplug/reconfig can change either.
      try {
        const monitors = await this.fetchMonitors();

        this.#availableRefreshRates = this.parseAvailableRefreshRates(monitors);
        this.notify("available-refresh-rates");

        const hyprlandRefreshRate = this.parseCurrentRefreshRate(monitors);
        if (hyprlandRefreshRate !== this.#refreshRate) {
          this.#refreshRate = hyprlandRefreshRate;
          this.notify("refresh-rate");
        }
      } catch {
        this.#availableRefreshRates = [];
        this.notify("available-refresh-rates");
        this.#refreshRate = -1;
        this.notify("refresh-rate");
      }
    }

    @setter(Number)
    set refreshRate(hertz: number) {
      if (!this.#availableRefreshRates.includes(hertz)) {
        console.error("Unapplicable refresh rate");
        return;
      }

      this.#applyChain = this.#applyChain
        .then(() => this.applyRefreshRate(hertz))
        .catch((error) => console.error("Could not sync refresh rate state", error));
    }

    @getter(Number)
    get refreshRate() {
      return this.#refreshRate;
    }

    @getter(Array)
    get availableRefreshRates() {
      return this.#availableRefreshRates;
    }

    private async fetchMonitors(): Promise<HyprlandMonitor[]> {
      const output = await execAsync(["hyprctl", "monitors", "-j"]);
      return JSON.parse(output) as HyprlandMonitor[];
    }

    async updateRefreshRates(): Promise<void> {
      try {
        const monitors = await this.fetchMonitors();
        this.#availableRefreshRates = this.parseAvailableRefreshRates(monitors);
      } catch {
        this.#availableRefreshRates = [];
      }

      this.notify("available-refresh-rates");
    }

    parseAvailableRefreshRates(hyprctlOut: HyprlandMonitor[]): number[] {
      const eDP1 = this.findPrimaryDisplay(hyprctlOut);
      if (eDP1 == null) {
        return [];
      }
      const resolution = eDP1.width + "x" + eDP1.height;

      const rates = eDP1.availableModes
        .filter((mode) => mode.includes(resolution))
        .map((mode) => Math.round(parseFloat(mode.split("@")[1])));

      return [...new Set(rates)].sort((a, b) => a - b);
    }

    async updateCurrentRefreshRate(): Promise<void> {
      try {
        const monitors = await this.fetchMonitors();
        const hyprlandRefreshRate = this.parseCurrentRefreshRate(monitors);

        if (hyprlandRefreshRate === this.#refreshRate) {
          return;
        }

        this.#refreshRate = hyprlandRefreshRate;
        this.notify("refresh-rate");
      } catch {
        this.#refreshRate = -1;
        this.notify("refresh-rate");
      }
    }

    parseCurrentRefreshRate(hyprctlOut: HyprlandMonitor[]): number {
      const primaryDisplay = this.findPrimaryDisplay(hyprctlOut);
      return primaryDisplay ? Math.round(primaryDisplay.refreshRate) : -1;
    }

    private findPrimaryDisplay(monitors: HyprlandMonitor[]) {
      const eDP1 = monitors.find((monitor) => { return monitor.name === "eDP-1" });

      if (eDP1 === undefined || eDP1 == null) {
        return null;
      }

      return eDP1;
    }

    private async applyRefreshRate(hertz: number): Promise<void> {
      const monitors = await this.fetchMonitors();
      await this.syncRefreshRateState(monitors, hertz);

      this.#refreshRate = hertz;
      this.notify("refresh-rate");
    }

    private async syncRefreshRateState(hyprctlMonitors: HyprlandMonitor[], hertz: number): Promise<void> {
      const hyprctlMonitor = this.findPrimaryDisplay(hyprctlMonitors);

      if (!hyprctlMonitor) {
        throw new Error("eDP-1 was not found");
      }
      if (!this.#availableRefreshRates.includes(hertz)) {
        throw new Error("Unapplicable refreshRate");
      }

      const monitorArgs = [
        "eDP-1",
        `${hyprctlMonitor.width}x${hyprctlMonitor.height}@${hertz}`,
        `${hyprctlMonitor.x}x${hyprctlMonitor.y}`,
        `${hyprctlMonitor.scale}`,
      ];

      await execAsync(["hyprctl", "keyword", "monitor", monitorArgs.join(",")]);
    }

    public destroy(): void {
      if (this.#pollTimer) {
        GLib.source_remove(this.#pollTimer);
        this.#pollTimer = 0;
      }
      if (this.#hyprlandSignalId) {
        AstalHyprland.get_default().disconnect(this.#hyprlandSignalId);
      }
      this.run_dispose();
    }
  }

  export const RefreshRate = _RefreshRate;
  export type RefreshRate = InstanceType<typeof RefreshRate>;
}
