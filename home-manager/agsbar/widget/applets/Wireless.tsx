import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import AstalNetwork from "gi://AstalNetwork"
import AstalBluetooth from "gi://AstalBluetooth?version=0.1"
import { For, With, createBinding, createComputed, createState } from "ags"
import { execAsync } from "ags/process"

function getApSignalIcon(strength: number, isHotspot: boolean = false): string {
  const prefix = isHotspot ? "Wifi-Hotspot-" : "Wifi-";
  if (strength >= 75) return `${prefix}High`;
  if (strength >= 50) return `${prefix}Mid`;
  if (strength >= 25) return `${prefix}Low`;
  return `${prefix}Zero`;
}

function getNetworkStatusIcon(network: AstalNetwork.Network): string {
  if (
    network.primary === AstalNetwork.Primary.WIRED ||
    (network.wired && network.wired.state === AstalNetwork.DeviceState.ACTIVATED)
  ) {
    return "Ethernet";
  }

  const wifi = network.wifi;
  if (!wifi || !wifi.enabled) {
    return "Wifi-Disabled";
  }

  if (
    wifi.state === AstalNetwork.DeviceState.PREPARE ||
    wifi.state === AstalNetwork.DeviceState.CONFIG ||
    wifi.state === AstalNetwork.DeviceState.NEED_AUTH ||
    wifi.state === AstalNetwork.DeviceState.IP_CONFIG ||
    wifi.state === AstalNetwork.DeviceState.IP_CHECK
  ) {
    return "Wifi-Acquiring";
  }

  const ap = wifi.active_access_point;
  if (!ap && wifi.state !== AstalNetwork.DeviceState.ACTIVATED) {
    return "Wifi-Disabled";
  }

  if (wifi.internet === AstalNetwork.Internet.DISCONNECTED) {
    return "Wifi-None";
  }

  const strength = ap ? ap.strength : wifi.strength;
  const isHotspot = Boolean(
    wifi.is_hotspot ||
    (wifi.device && (wifi.device.metered === 1 || wifi.device.metered === 3))
  );
  return getApSignalIcon(strength, isHotspot);
}

export default function ConnectivityModule() {
  const network = AstalNetwork.get_default();
  const bluetooth = AstalBluetooth.get_default();
  const wifi = network.wifi;
  const wired = network.wired;
  const [activeTab, setActiveTab] = createState<"wifi" | "bluetooth">("wifi");

  const menuPopover = (
    <popover hasArrow={false}>
      <box orientation={Gtk.Orientation.VERTICAL} class="menu-container" widthRequest={300} spacing={8}>
        {/* Tab Switcher */}
        <box class="tab-toggle" homogeneous={true} spacing={4}>
          <button
            class={activeTab.as(t => t === "wifi" ? "primary-bg big-btn" : "big-btn")}
            onClicked={() => setActiveTab("wifi")}
          >
            <label label="Wi-Fi" />
          </button>
          <button
            class={activeTab.as(t => t === "bluetooth" ? "primary-bg big-btn" : "big-btn")}
            onClicked={() => setActiveTab("bluetooth")}
          >
            <label label="Bluetooth" />
          </button>
        </box>

        {/* Content Boxes - Replaced Stack */}
        <box orientation={Gtk.Orientation.VERTICAL}>
          <WifiList network={network} visible={activeTab.as(t => t === "wifi")} />
          <BluetoothList bluetooth={bluetooth} visible={activeTab.as(t => t === "bluetooth")} />
        </box>
      </box>
    </popover>
  );

  const wifiDeps = wifi ? [
    createBinding(wifi, "state"),
    createBinding(wifi, "strength"),
    createBinding(wifi, "active_access_point"),
    createBinding(wifi, "enabled"),
    createBinding(wifi, "internet"),
    createBinding(wifi, "is_hotspot"),
    ...(wifi.device ? [createBinding(wifi.device, "metered")] : []),
  ] : [];

  const wiredDeps = wired ? [
    createBinding(wired, "state"),
  ] : [];

  const networkIcon = createComputed([
    createBinding(network, "primary"),
    createBinding(network, "wifi"),
    createBinding(network, "wired"),
    ...wifiDeps,
    ...wiredDeps,
  ], () => getNetworkStatusIcon(network));

  return (
    <menubutton class="connectivity-module menu-btn" popover={menuPopover as any}>
      <box spacing={6} css="padding: 0 4px; background: transparent">
        <image iconName={networkIcon} pixelSize={22} />
        <image iconName={createBinding(bluetooth, "is_powered").as(p => p ? "Bluetooth" : "Bluetooth-Disabled")} pixelSize={22} />
      </box>
    </menubutton>
  );
}

function WifiList({ network, visible }: { network: AstalNetwork.Network, visible?: any }) {
  const [connectingTo, setConnectingTo] = createState<string | null>(null);
  const [passwordPrompt, setPasswordPrompt] = createState<string | null>(null);
  const [manualScanning, setManualScanning] = createState(false);

  const wifi = network.wifi;

  if (!wifi) {
    return (
      <box visible={visible} orientation={Gtk.Orientation.VERTICAL} spacing={10} halign={Gtk.Align.CENTER} css="padding: 24px 0;">
        <image iconName="Wifi-Disabled" pixelSize={32} css="opacity: 0.5;" />
        <label label="Wi-Fi Unavailable" css="opacity: 0.7;" />
      </box>
    );
  }

  const isEnabled = createBinding(wifi, "enabled");
  const isScanning = createComputed([
    createBinding(wifi, "scanning"),
    manualScanning
  ], (s, m) => Boolean(s || m));

  async function toggleWifi() {
    if (wifi == null) {
      return
    }

    const newState = !wifi.enabled;
    wifi.enabled = newState;
    try {
      await execAsync(["nmcli", "radio", "wifi", newState ? "on" : "off"]);
    } catch (_) { }
  }

  async function scanWifi() {
    setManualScanning(true);
    try {
      if (wifi == null) {
        return;
      }
      wifi.scan();
      await execAsync(["nmcli", "device", "wifi", "rescan"]);
    } catch (e) {
      console.error("Wi-Fi scan error:", e);
    } finally {
      setTimeout(() => {
        setManualScanning(false);
      }, 1500);
    }
  }

  async function connect(ap: AstalNetwork.AccessPoint, password?: string) {
    if (ap.ssid == null) {
      return;
    }

    setConnectingTo(ap.ssid);
    try {
      if (password) {
        try { await execAsync(["nmcli", "connection", "delete", ap.ssid]); } catch (_) { }
        await execAsync(["nmcli", "device", "wifi", "connect", ap.ssid, "password", password]);
      } else {
        await execAsync(["nmcli", "device", "wifi", "connect", ap.ssid]);
      }
    } catch (error) {
      if (!password) setPasswordPrompt(ap.ssid);
    } finally {
      setConnectingTo(null);
    }
  }

  const getAPs = (wifi: AstalNetwork.Wifi) => createBinding(wifi, "accessPoints").as(aps => {
    const uniqueAps = new Map<string, AstalNetwork.AccessPoint>();
    aps.forEach(ap => {
      if (!ap.ssid) return;
      const existing = uniqueAps.get(ap.ssid);
      if (!existing || ap.strength > existing.strength) uniqueAps.set(ap.ssid, ap);
    });
    return Array.from(uniqueAps.values()).sort((a, b) =>
      a.ssid === wifi.ssid ? -1 : b.ssid === wifi.ssid ? 1 : b.strength - a.strength
    );
  });

  const handleAPclick = (ap: AstalNetwork.AccessPoint) => {
    if (wifi.ssid === ap.ssid && wifi.activeConnection != null) {
      execAsync(["nmcli", "device", "disconnect", wifi.device?.interface ?? "wlan0"]);
    } else {
      connect(ap);
    }
  };

  return (
    <box
      visible={visible}
      orientation={Gtk.Orientation.VERTICAL}
      spacing={8}
    >
      {/* When Wi-Fi is Enabled */}
      <box
        visible={isEnabled}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={8}
      >
        {/* Header controls: Power toggle & Scan button */}
        <box spacing={6}>
          <button
            class={isEnabled.as(e => e ? "primary-bg big-btn" : "big-btn")}
            onClicked={toggleWifi}
            tooltipText="Toggle Wi-Fi Power"
          >
            <box spacing={4} css="padding: 0 8px;">
              <image iconName={isEnabled.as(e => e ? "Wifi-High" : "Wifi-Disabled")} pixelSize={22} />
              <label label="On" />
            </box>
          </button>

          <button
            hexpand={true}
            class={isScanning.as(s => s ? "primary-bg big-btn" : "big-btn")}
            onClicked={scanWifi}
          >
            <box spacing={6} halign={Gtk.Align.CENTER} css="padding: 0 8px;">
              <image iconName="view-refresh-symbolic" pixelSize={20} />
              <label label={isScanning.as(s => s ? "Scanning..." : "Scan for Networks")} />
            </box>
          </button>
        </box>

        {/* Scrollable Networks List */}
        <Gtk.ScrolledWindow
          heightRequest={240}
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
            <For each={getAPs(wifi)}>
              {(ap: AstalNetwork.AccessPoint) => {
                if (ap.ssid == null) {
                  return <box><label label="Hidden Network" /></box>;
                }
                return (
                  <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                    <button
                      onClicked={() => handleAPclick(ap)}
                      class={createBinding(wifi, "active_access_point").as(active => active != null && active.ssid === ap.ssid ? "primary-bg" : "")}
                    >
                      <box spacing={8} css="padding: 4px 8px;">
                        <image iconName={createBinding(ap, "strength").as(s => getApSignalIcon(s))} pixelSize={22} />
                        <label label={ap.ssid} />
                        <image
                          iconName="Locked"
                          visible={createBinding(ap, "requires_password")}
                          pixelSize={18}
                          css="opacity: 0.8;"
                        />
                        <box hexpand={true} />
                        <label label="Connecting..." visible={connectingTo.as(s => s === ap.ssid)} css="opacity: 0.6; font-size: 0.9em;" />
                        <image iconName="object-select-symbolic" visible={createBinding(wifi, "active_access_point").as(active => active != null && active.ssid === ap.ssid)} pixelSize={18} />
                      </box>
                    </button>
                    <revealer revealChild={passwordPrompt.as(s => s === ap.ssid)} transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}>
                      <entry
                        placeholderText="Password..." visibility={false}
                        onActivate={(self) => { connect(ap, self.text); self.text = ""; setPasswordPrompt(null); }}
                      />
                    </revealer>
                  </box>
                );
              }}
            </For>
          </box>
        </Gtk.ScrolledWindow>
      </box>

      {/* When Wi-Fi is Disabled */}
      <box
        visible={isEnabled.as(e => !e)}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={10}
        halign={Gtk.Align.CENTER}
        css="padding: 24px 0;"
      >
        <image iconName="Wifi-Disabled" pixelSize={32} css="opacity: 0.5;" />
        <label label="Wi-Fi is Disabled" css="opacity: 0.7;" />
        <button class="primary-bg big-btn" css="padding: 6px 16px;" onClicked={toggleWifi}>
          <label label="Turn On Wi-Fi" />
        </button>
      </box>
    </box>
  );
}

function BluetoothList({ bluetooth, visible }: { bluetooth: AstalBluetooth.Bluetooth, visible?: any }) {
  const [connectingTo, setConnectingTo] = createState<string | null>(null);
  const [pairingTo, setPairingTo] = createState<string | null>(null);

  const isPowered = createBinding(bluetooth, "is_powered");
  const devices = createBinding(bluetooth, "devices");

  const pairedDevices = devices.as(devs => devs.filter(d => d.paired));
  const availableDevices = devices.as(devs => devs.filter(d => !d.paired && Boolean(d.name || d.alias)));

  async function toggleConnect(device: AstalBluetooth.Device) {
    const addr = device.address;
    if (device.connected) {
      try {
        await execAsync(["bluetoothctl", "disconnect", addr]);
      } catch (_) {
        try {
          await device.disconnect_device();
        } catch (_) { }
      }
    } else {
      setConnectingTo(addr);
      try {
        await execAsync(["bluetoothctl", "connect", addr]);
      } catch (e) {
        console.error(`Connection failed for ${addr}:`, e);
        try {
          await device.connect_device();
        } catch (e2) {
          console.error(`Fallback connect failed for ${addr}:`, e2);
        }
      } finally {
        setConnectingTo(null);
      }
    }
  }

  async function pairDevice(device: AstalBluetooth.Device) {
    const addr = device.address;
    setPairingTo(addr);
    try {
      if (bluetooth.adapter) {
        bluetooth.adapter.pairable = true;
      }
      await execAsync(["bluetoothctl", "pair", addr]);
      await execAsync(["bluetoothctl", "trust", addr]);
      await execAsync(["bluetoothctl", "connect", addr]);
    } catch (e) {
      console.error(`Pairing failed for ${addr}:`, e);
      try {
        device.pair();
        device.trusted = true;
        await device.connect_device();
      } catch (e2) {
        console.error(`Fallback pair failed for ${addr}:`, e2);
      }
    } finally {
      setPairingTo(null);
    }
  }

  async function unpairDevice(device: AstalBluetooth.Device) {
    const addr = device.address;
    try {
      await execAsync(["bluetoothctl", "remove", addr]);
    } catch (e) {
      console.error(`Unpair failed for ${addr}:`, e);
      try {
        bluetooth.adapter?.remove_device(device);
      } catch (_) { }
    }
  }

  const adapter = bluetooth.adapter;
  const isDiscovering = adapter ? createBinding(adapter, "discovering") : createState(false)[0];

  function toggleDiscovery() {
    if (!bluetooth.adapter) return;
    if (bluetooth.adapter.discovering) {
      bluetooth.adapter.stop_discovery();
    } else {
      bluetooth.adapter.pairable = true;
      bluetooth.adapter.start_discovery();
    }
  }

  return (
    <box
      visible={visible}
      orientation={Gtk.Orientation.VERTICAL}
      spacing={8}
    >
      {/* When Bluetooth is Powered ON */}
      <box
        visible={isPowered}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={8}
      >
        {/* Header controls: Power toggle & Scan button */}
        <box spacing={6}>
          <button
            class={isPowered.as(p => p ? "primary-bg big-btn" : "big-btn")}
            onClicked={() => bluetooth.toggle()}
            tooltipText="Toggle Bluetooth Power"
          >
            <box spacing={4} css="padding: 0 8px;">
              <image iconName={isPowered.as(p => p ? "Bluetooth" : "Bluetooth-Disabled")} pixelSize={22} />
              <label label="On" />
            </box>
          </button>

          <button
            hexpand={true}
            class={isDiscovering.as(d => d ? "primary-bg big-btn" : "big-btn")}
            onClicked={toggleDiscovery}
          >
            <box spacing={6} halign={Gtk.Align.CENTER} css="padding: 0 8px;">
              <image iconName="view-refresh-symbolic" pixelSize={20} />
              <label label={isDiscovering.as(d => d ? "Scanning..." : "Scan for Devices")} />
            </box>
          </button>
        </box>

        {/* Scrollable Device Lists */}
        <Gtk.ScrolledWindow heightRequest={240} hscrollbarPolicy={Gtk.PolicyType.NEVER}>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
            {/* --- PAIRED DEVICES --- */}
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
              <box visible={pairedDevices.as(devs => devs.length > 0)}>
                <label label="PAIRED DEVICES" class="subtitle" css="font-size: 10px; padding: 2px 4px;" />
              </box>

              <For each={pairedDevices}>
                {(device: AstalBluetooth.Device) => (
                  <box spacing={4}>
                    <button
                      hexpand={true}
                      onClicked={() => toggleConnect(device)}
                      class={createBinding(device, "connected").as(c => c ? "primary-bg" : "")}
                    >
                      <box spacing={8} css="padding: 4px 8px;">
                        <image iconName={createBinding(device, "icon").as(i => i || "bluetooth-symbolic")} pixelSize={22} />
                        <label label={createBinding(device, "alias").as(a => a || device.name || device.address)} />
                        <box hexpand={true} />
                        <label
                          label="Connecting..."
                          visible={connectingTo.as(s => s === device.address)}
                          css="opacity: 0.6; font-size: 0.9em;"
                        />
                        <label
                          label={createBinding(device, "batteryPercentage").as(p => p > -1 ? `${Math.floor(p * 100)}%` : "")}
                          css="opacity: 0.7; font-size: 0.9em;"
                        />
                        <image iconName="object-select-symbolic" visible={createBinding(device, "connected")} pixelSize={18} />
                      </box>
                    </button>
                    <button
                      tooltipText="Forget Device"
                      class="no-bg"
                      css="padding: 0 6px;"
                      onClicked={() => unpairDevice(device)}
                    >
                      <image iconName="edit-delete-symbolic" pixelSize={18} />
                    </button>
                  </box>
                )}
              </For>
            </box>

            {/* --- AVAILABLE / UNPAIRED DEVICES (PAIRING) --- */}
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
              <box visible={availableDevices.as(devs => devs.length > 0)}>
                <label label="AVAILABLE DEVICES" class="subtitle" css="font-size: 10px; padding: 4px 4px 2px 4px;" />
              </box>

              <For each={availableDevices}>
                {(device: AstalBluetooth.Device) => (
                  <button
                    onClicked={() => pairDevice(device)}
                    css="padding: 4px 8px;"
                  >
                    <box spacing={8}>
                      <image iconName={createBinding(device, "icon").as(i => i || "bluetooth-symbolic")} pixelSize={22} />
                      <label label={createBinding(device, "alias").as(a => a || device.name || device.address)} />
                      <box hexpand={true} />
                      <label
                        label="Pairing..."
                        visible={pairingTo.as(s => s === device.address)}
                        css="opacity: 0.7; font-size: 0.9em;"
                      />
                      <label
                        label="Pair"
                        visible={pairingTo.as(s => s !== device.address)}
                        css="opacity: 0.6; font-size: 0.9em;"
                      />
                    </box>
                  </button>
                )}
              </For>

              {/* Empty state when discovering and no available devices found */}
              <box
                visible={createComputed([
                  isDiscovering,
                  availableDevices
                ], (d, devs) => Boolean(d && devs.length === 0))}
                halign={Gtk.Align.CENTER}
                css="padding: 12px 0;"
              >
                <label label="Searching for nearby devices..." css="opacity: 0.6; font-size: 0.9em;" />
              </box>
            </box>
          </box>
        </Gtk.ScrolledWindow>
      </box>

      {/* When Bluetooth is Powered OFF */}
      <box
        visible={isPowered.as(p => !p)}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={10}
        halign={Gtk.Align.CENTER}
        css="padding: 24px 0;"
      >
        <image iconName="Bluetooth-Disabled" pixelSize={32} css="opacity: 0.5;" />
        <label label="Bluetooth is Disabled" css="opacity: 0.7;" />
        <button class="primary-bg big-btn" css="padding: 6px 16px;" onClicked={() => bluetooth.toggle()}>
          <label label="Turn On Bluetooth" />
        </button>
      </box>
    </box>
  );
}
