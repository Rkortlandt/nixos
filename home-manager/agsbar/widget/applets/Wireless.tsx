import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import AstalBattery from "gi://AstalBattery"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import AstalWp from "gi://AstalWp"
import AstalNetwork from "gi://AstalNetwork"
import AstalTray from "gi://AstalTray"
import AstalMpris from "gi://AstalMpris"
import AstalApps from "gi://AstalApps"
import { For, With, createBinding, createComputed, createState, onCleanup } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import Wp from "gi://Wp?version=0.5"
import AstalBluetooth from "gi://AstalBluetooth?version=0.1"



export default function ConnectivityModule() {
  const network = AstalNetwork.get_default()
  const bluetooth = AstalBluetooth.get_default()

  // State for switching between 'wifi' and 'bluetooth'
  const [activeTab, setActiveTab] = createState<"wifi" | "bluetooth">("wifi");

  async function connect(ap: AstalNetwork.AccessPoint) {
    // connecting to ap is not yet supported
    // https://github.com/Aylur/astal/pull/13
    try {
      await execAsync(`nmcli d wifi connect ${ap.bssid}`)
    } catch (error) {
      // you can implement a popup asking for password here
      console.error(error)
    }
  }

  return (
    <menubutton class="connectivity-module">
      <box spacing={6} >
        <image
          iconName={createBinding(network.wifi, "iconName")}
          tooltipText={createBinding(network.wifi, "ssid")}
        />
        <image
          iconName={createBinding(bluetooth, "is_powered").as(p =>
            p ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
          )}
        />
      </box>

      <popover>
        <box orientation={Gtk.Orientation.VERTICAL} class="menu-container" widthRequest={300} spacing={4}>

          {/* --- TAB TOGGLE --- */}
          <box class="tab-toggle" hexpand={true} homogeneous={true} spacing={4}>
            <button
              class="big-btn"

              hexpand={true}
              onClicked={() => setActiveTab("wifi")}>
              <label label="Wi-Fi" />
            </button>
            <button
              class="big-btn"
              hexpand={true}
              onClicked={() => setActiveTab("bluetooth")}>
              <label label="Bluetooth" />
            </button>
          </box>

          {/* --- WIFI LIST --- */}
          <box visible={activeTab.as((tab) => tab == "wifi")}>
            <box heightRequest={300}>
              <box orientation={Gtk.Orientation.VERTICAL}>
                <For each={createBinding(network.wifi, "accessPoints")}>
                  {(ap: AstalNetwork.AccessPoint, index) => (
                    <button
                      visible={ap.ssid != null}
                      onClicked={() => connect(ap)}
                      hexpand={true}
                    >
                      <box spacing={8}>
                        <image iconName={ap.iconName} />
                        <label label={ap.ssid} />
                      </box>
                    </button>
                  )}
                </For>
              </box>
            </box>
          </box>
          <box visible={activeTab.as((tab) => tab === "bluetooth")}>
            <box heightRequest={300}>
              <box orientation={Gtk.Orientation.VERTICAL}>
                <For each={createBinding(bluetooth, "devices")}>
                  {(device: AstalBluetooth.Device) => {
                    const connecting = createBinding(device, "connecting");
                    const connected = createBinding(device, "connected");
                    const isFullyConnected = createComputed(() => {
                      return connected != connecting
                    });
                    return (
                      <button
                        onClicked={() => device.connected ? device.disconnect_device(() => { }) : device.connect_device(() => { })} class={createBinding(device, "connected").as((cntd) => cntd ? "primary-bg" : "")}
                        hexpand={true}
                      >
                        <box spacing={8}>
                          <image iconName={createBinding(device, "icon")} />
                          <label label={createBinding(device, "name")} />
                          <box hexpand={true} />
                          <label label={createBinding(device, "batteryPercentage").as((pcnt) => { return pcnt == -1 ? "" : `${Math.floor(pcnt * 100)}%` })} />
                          <image
                            iconName="object-select-symbolic"
                            visible={isFullyConnected}
                          />
                        </box>
                      </button>
                    );
                  }}
                </For>
              </box>
            </box>
          </box>
        </box>
      </popover>
    </menubutton>
  )
}
