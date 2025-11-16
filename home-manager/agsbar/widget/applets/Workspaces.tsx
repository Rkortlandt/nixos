/* import Astal from "gi://Astal?version=3.0";
import AstalHyprland from "gi://AstalHyprland?version=0.1";
import bind from "gi://Astal";
import Variable from "gi://Astal";
import { createBinding, createComputed, For } from "gnim";

export function Workspaces() {
  const hyprland = AstalHyprland.get_default();



  function getBorderRadius(workspaceId: number, totalWorkspaces: number, workspaces: AstalHyprland.Workspace[]) {
    if (totalWorkspaces === 1) {
      return startAndEndCss;
    }
    const index = workspaces.findIndex((ws) => ws.get_id() === workspaceId);
    if (index === 0) {
      return startCss;
    } else if (index === totalWorkspaces - 1) {
      return endCss;
    }
    return '';
  }

  function getColor(workspaceId: number, workspace: AstalHyprland.Workspace, focusedWs: AstalHyprland.Workspace | null) {
    if (focusedWs == null) {
      return "color: #0F5880;";
    }
    if (workspaceId === focusedWs.get_id()) {
      return "color: #0EA16F;";
    } else if (workspace.get_monitor().name !== 'eDP-1') {
      return "color: #172A7D;";
    } else {
      return "color: #0F5880;";
    }
  }

  const workspaceList = createBinding(hyprland, "workspaces").as((wss) =>
    wss
      .filter((a) => a.get_id() > 0)
      .sort((a, b) => a.get_id() - b.get_id())
  );

  const focusedWorkspace = createBinding(hyprland, "focusedWorkspace");

  // Create one computed value that holds a Map of all styles.
  // This reacts to BOTH workspaceList and focusedWorkspace changes.
  const styleMap = Variable.derive(
    [bind(hyprland, "focusedWorkspace"), bind(hyprland, "clients")],
    (focusedWs: AstalHyprland.Workspace, workspaces: AstalHyprland.Workspace[]) => {
      const map = new Map<number, string>();

      for (const ws of workspaces) {
        const id = ws.get_id();
        const color = getColor(id, ws, focusedWs);
        const border = getBorderRadius(id, workspaces.length, workspaces);
        map.set(id, `${color} ${border}`);
      }
      return map;
    };

  return (
    <box cssClasses={["Workspaces"]}>
      <For each={workspaceList}>
        {(workspaceButton) => (
          <button
            cssClasses={["workspace-button"]}
            // Each button's CSS is now a simple lookup from the reactive map.
            css={}
            onClicked={() => workspaceButton.focus()}
          >
            {workspaceButton.get_id()}
          </button>
        )}
      </For>
    </box>
  );
} */


import { Gtk } from "ags/gtk4";
import { createBinding, createComputed, createState, For, With } from "ags";
import { variableToBoolean, getSymbolicIcon, getAppIcon } from "../../utils";

import AstalHyprland from "gi://AstalHyprland";

export const Workspaces = () => {
  const workspaces = createBinding(AstalHyprland.get_default(), "workspaces"),
    defaultWorkspaces = workspaces.as(wss =>
      wss.filter(ws => ws.id > 0).sort((a, b) => a.id - b.id)),
    specialWorkspaces = workspaces.as(wss =>
      wss.filter(ws => ws.id < 0).sort((a, b) => a.id - b.id)),
    focusedWorkspace = createBinding(AstalHyprland.get_default(), "focusedWorkspace");


  return <box class={"workspaces-row"}>
    <box class={"default-workspaces"} spacing={0}>
      <For each={defaultWorkspaces}>
        {(ws: AstalHyprland.Workspace, i) => {
          return <Gtk.Button class={createComputed([
            createBinding(AstalHyprland.get_default(), "focusedWorkspace"),
            createBinding(AstalHyprland.get_default(), "workspaces"),
          ], (focusedWs, workspaces) => {
            return `workspace 
            ${focusedWs.id === ws.id ? "focusedws" : ""} 
            ${workspaces.length - specialWorkspaces.get().length === i.get() + 1 ? "lastws" : ""} 
            ${workspaces.length === 1 ? "onlyws" : ""} ${0 === i.get() ? "firstws" : ""}
            `
          }
          )} tooltipText={createComputed([
            createBinding(ws, "lastClient"),
          ], (lastClient) =>
            `workspace ${ws.id}${lastClient ? ` - ${!lastClient.title.toLowerCase().includes(lastClient.class) ?
              `${lastClient.get_class()}: `
              : ""
              } ${lastClient.title}` : ""}`
          )} onClicked={() => focusedWorkspace.get()?.id !== ws.id && ws.focus()}>
            <Gtk.Label label={createBinding(ws, "id").as(String)}
            />
          </Gtk.Button>
        }}
      </For>
    </box>

  </box>
}

export const SpecialWorkspaces = () => {
  const workspaces = createBinding(AstalHyprland.get_default(), "workspaces"),
    specialWorkspaces = workspaces.as(wss => wss.filter(ws => ws.id < 0).sort((a, b) => a.id - b.id))
  return <box class={"special-workspaces"} spacing={0}>
    <For each={specialWorkspaces}>
      {(ws: AstalHyprland.Workspace, i) =>
        <Gtk.Button class={createComputed([
          createBinding(AstalHyprland.get_default(), "focusedWorkspace"),
          createBinding(AstalHyprland.get_default(), "workspaces"),
        ], (focusedWs, workspaces) => {
          return `workspace ${focusedWs.id === ws.id ? "focus" : ""} ${specialWorkspaces.get().length === i.get() + 1 ? "lastws" : ""} ${workspaces.length === 1 ? "onlyws" : ""} ${0 === i.get() ? "firstws" : ""}`
        }
        )}
          tooltipText={createBinding(ws, "name").as(name => {
            name = name.replace(/^special\:/, "");
            return name.charAt(0).toUpperCase().concat(name.substring(1, name.length));
          })} onClicked={() => AstalHyprland.get_default().dispatch(
            "togglespecialworkspace", ws.name.replace(/^special[:]/, "")
          )}>

          {<With value={createBinding(ws, "lastClient")}>
            {(lastClient: AstalHyprland.Client | null) => lastClient &&
              <Gtk.Image class="last-client" iconName={
                createBinding(lastClient, "initialClass").as(initialClass =>
                  getSymbolicIcon(initialClass) ?? getAppIcon(initialClass) ??
                  "application-x-executable-symbolic")}
              />
            }
          </With>}
        </Gtk.Button>
      }
    </For>
  </box>

}
