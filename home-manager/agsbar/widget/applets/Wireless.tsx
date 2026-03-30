import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import AstalNetwork from "gi://AstalNetwork"
import AstalBluetooth from "gi://AstalBluetooth?version=0.1"
import { For, With, createBinding, createState } from "ags"
import { execAsync } from "ags/process"

export default function ConnectivityModule() {
  const network = AstalNetwork.get_default();
  const bluetooth = AstalBluetooth.get_default();
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

  return (
    <menubutton class="connectivity-module" popover={menuPopover}>
      <box spacing={6}>
        <With value={createBinding(network, "wifi")}>
          {(wifi: AstalNetwork.Wifi | null) => (
            <image iconName={wifi ? createBinding(wifi, "iconName") : "network-wireless-offline-symbolic"} />
          )}
        </With>
        <image iconName={createBinding(bluetooth, "is_powered").as(p => p ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic")} />
      </box>
    </menubutton>
  );
}

function WifiList({ network, visible }: { network: AstalNetwork.Network, visible?: any }) {
  const [connectingTo, setConnectingTo] = createState<string | null>(null);
  const [passwordPrompt, setPasswordPrompt] = createState<string | null>(null);

  async function connect(ap: AstalNetwork.AccessPoint, password?: string) {
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

  return (
    <box visible={visible} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <With value={createBinding(network, "wifi")}>
        {(wifi: AstalNetwork.Wifi | null) => wifi ? (
          <Gtk.ScrolledWindow heightRequest={220} hscrollbarPolicy={Gtk.PolicyType.NEVER}>
            <box orientation={Gtk.Orientation.VERTICAL}>
              <For each={createBinding(wifi, "accessPoints").as(aps => {
                const uniqueAps = new Map<string, AstalNetwork.AccessPoint>();
                aps.forEach(ap => {
                  if (!ap.ssid) return;
                  const existing = uniqueAps.get(ap.ssid);
                  if (!existing || ap.strength > existing.strength) uniqueAps.set(ap.ssid, ap);
                });
                return Array.from(uniqueAps.values()).sort((a, b) =>
                  a.ssid === wifi.ssid ? -1 : b.ssid === wifi.ssid ? 1 : b.strength - a.strength
                );
              })}>
                {(ap: AstalNetwork.AccessPoint) => (
                  <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                    <button
                      onClicked={() => wifi.ssid === ap.ssid ? execAsync(["nmcli", "device", "disconnect", wifi.device?.interface ?? "wlan0"]) : connect(ap)}
                      class={createBinding(wifi, "ssid").as(ssid => ssid === ap.ssid ? "primary-bg" : "")}
                    >
                      <box spacing={8}>
                        <image iconName={ap.iconName} />
                        <label label={ap.ssid} />
                        <box hexpand={true} />
                        <label label="Connecting..." visible={connectingTo.as(s => s === ap.ssid)} css="opacity: 0.6; font-size: 0.9em;" />
                        <image iconName="object-select-symbolic" visible={createBinding(wifi, "ssid").as(s => s === ap.ssid)} />
                      </box>
                    </button>
                    <revealer revealChild={passwordPrompt.as(s => s === ap.ssid)} transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}>
                      <entry
                        placeholderText="Password..." visibility={false}
                        onActivate={(self) => { connect(ap, self.text); self.text = ""; setPasswordPrompt(null); }}
                      />
                    </revealer>
                  </box>
                )}
              </For>
            </box>
          </Gtk.ScrolledWindow>
        ) : (
          <label label="Wi-Fi Unavailable" halign={Gtk.Align.CENTER} />
        )}
      </With>
    </box>
  );
}

function BluetoothList({ bluetooth, visible }: { bluetooth: AstalBluetooth.Bluetooth, visible?: any }) {
  return (
    <box visible={visible} orientation={Gtk.Orientation.VERTICAL}>
      <Gtk.ScrolledWindow heightRequest={220} hscrollbarPolicy={Gtk.PolicyType.NEVER}>
        <box orientation={Gtk.Orientation.VERTICAL}>
          <For each={createBinding(bluetooth, "devices")}>
            {(device: AstalBluetooth.Device) => (
              <button
                onClicked={() => device.connected ? device.disconnect_device(() => { }) : device.connect_device(() => { })}
                class={createBinding(device, "connected").as(c => c ? "primary-bg" : "")}
              >
                <box spacing={8}>
                  <image iconName={createBinding(device, "icon")} />
                  <label label={createBinding(device, "name")} />
                  <box hexpand={true} />
                  <label label={createBinding(device, "batteryPercentage").as(p => p == -1 ? "" : `${Math.floor(p * 100)}%`)} />
                  <image iconName="object-select-symbolic" visible={createBinding(device, "connected")} />
                </box>
              </button>
            )}
          </For>
        </box>
      </Gtk.ScrolledWindow>
    </box>
  );
}
