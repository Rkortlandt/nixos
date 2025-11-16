import Gdk from "gi://Gdk?version=4.0";
import Astal from "gi://Astal?version=4.0";
import { onCleanup } from "ags";
import app from "ags/gtk4/app";
import { Gtk } from "ags/gtk4";
import { Accessor, createState, removeChild, Setter, State } from "gnim"
import { MprisPlayers } from "./applets/Media";

export function SideBar({ gdkmonitor, setSideBarVisible, sideBarVisible }: { gdkmonitor: Gdk.Monitor, setSideBarVisible: Setter<boolean>, sideBarVisible: Accessor<boolean> }) {
  let win: Astal.Window
  const { TOP, LEFT, BOTTOM } = Astal.WindowAnchor;

  onCleanup(() => {
    // Root components (windows) are not automatically destroyed.
    // When the monitor is disconnected from the system, this callback
    // is run from the parent <For> which allows us to destroy the window
    win.destroy()
  })

  return <window
    $={(self) => (win = self)}
    namespace="sideBar"
    cssClasses={["sidebar"]}
    name={`sidebar-${gdkmonitor.connector}`}
    gdkmonitor={gdkmonitor}
    exclusivity={Astal.Exclusivity.IGNORE}
    anchor={LEFT | TOP | BOTTOM}
    application={app}
  >
    <Gtk.EventControllerMotion onLeave={() => setSideBarVisible(false)} />
    <box>
      <box vexpand={true}>
        <MprisPlayers />
      </box>
    </box>
  </window>
}

export function SideBarTrigger({ gdkmonitor, setSideBarVisible }: { gdkmonitor: Gdk.Monitor, setSideBarVisible: Setter<boolean> }) {
  let win: Astal.Window
  const { TOP, LEFT, BOTTOM } = Astal.WindowAnchor;

  onCleanup(() => {
    // Root components (windows) are not automatically destroyed.
    // When the monitor is disconnected from the system, this callback
    // is run from the parent <For> which allows us to destroy the window
    win.destroy()
  })

  return <window
    visible
    $={(self) => (win = self)}
    namespace="sideBar"
    cssClasses={["side-trigger"]}
    name={`sidebartrigger-${gdkmonitor.connector}`}
    gdkmonitor={gdkmonitor}
    exclusivity={Astal.Exclusivity.IGNORE}
    anchor={LEFT | TOP | BOTTOM}
    application={app}
  >
    <box>
      <Gtk.EventControllerMotion onEnter={() => setSideBarVisible(true)} />
    </box>
  </window>
}
