import { Gtk } from "ags/gtk4";
import { createBinding, createComputed, For, With } from "ags";
import { getSymbolicIcon, getAppIcon } from "../../utils";
import AstalHyprland from "gi://AstalHyprland";

export const Workspaces = () => {
  const hyprland = AstalHyprland.get_default();
  const workspaces = createBinding(hyprland, "workspaces");

  const defaultWorkspaces = workspaces.as(wss =>
    wss.filter(ws => ws.id > 0).sort((a, b) => a.id - b.id)
  );

  const specialWorkspaces = workspaces.as(wss =>
    wss.filter(ws => ws.id < 0).sort((a, b) => a.id - b.id)
  );

  const focusedWorkspace = createBinding(hyprland, "focusedWorkspace");

  return (
    <box class={"workspaces-row"}>
      <box class={"default-workspaces"} spacing={0}>
        <For each={defaultWorkspaces}>
          {(ws: AstalHyprland.Workspace, i) => {
            return (
              <Gtk.Button
                class={createComputed([
                  createBinding(hyprland, "focusedWorkspace"),
                  createBinding(hyprland, "workspaces"),
                ], (focusedWs, workspacesArray) => {
                  return `workspace 
                  ${focusedWs?.id === ws.id ? "focusedws" : ""} 
                  ${workspacesArray.length - specialWorkspaces.get().length === i.get() + 1 ? "lastws" : ""} 
                  ${workspacesArray.length === 1 ? "onlyws" : ""} ${0 === i.get() ? "firstws" : ""}
                  `
                })}
                tooltipText={createComputed([
                  createBinding(ws, "lastClient"),
                ], (lastClient) =>
                  `workspace ${ws.id}${lastClient ? ` - ${!lastClient.title.toLowerCase().includes(lastClient.class) ?
                    `${lastClient.get_class()}: `
                    : ""
                    } ${lastClient.title}` : ""}`
                )}
                onClicked={() => focusedWorkspace.get()?.id !== ws.id && ws.focus()}
              >
                <Gtk.Label label={createBinding(ws, "id").as(String)} />
              </Gtk.Button>
            )
          }}
        </For>
      </box>
    </box>
  );
}

export const SpecialWorkspaces = () => {
  const hyprland = AstalHyprland.get_default();
  const workspaces = createBinding(hyprland, "workspaces");

  const specialWorkspaces = workspaces.as(wss =>
    wss.filter(ws => ws.id < 0).sort((a, b) => a.id - b.id)
  );

  return (
    <box class={"special-workspaces"} spacing={0}>
      <For each={specialWorkspaces}>
        {(ws: AstalHyprland.Workspace, i) => (
          <Gtk.Button
            class={createComputed([
              createBinding(hyprland, "focusedWorkspace"),
              createBinding(hyprland, "workspaces"),
            ], (focusedWs, workspacesArray) => {
              // Fixed the null crash here by adding ?.id
              return `workspace ${focusedWs?.id === ws.id ? "focus" : ""} ${specialWorkspaces.get().length === i.get() + 1 ? "lastws" : ""} ${workspacesArray.length === 1 ? "onlyws" : ""} ${0 === i.get() ? "firstws" : ""}`
            })}
            tooltipText={createBinding(ws, "name").as(name => {
              name = name.replace(/^special\:/, "");
              return name.charAt(0).toUpperCase().concat(name.substring(1, name.length));
            })}
            onClicked={() => hyprland.dispatch(
              "togglespecialworkspace", ws.name.replace(/^special[:]/, "")
            )}
          >
            <With value={createBinding(ws, "lastClient")}>
              {(lastClient: AstalHyprland.Client | null) => lastClient &&
                <Gtk.Image class="last-client" iconName={
                  createBinding(lastClient, "initialClass").as(initialClass =>
                    getSymbolicIcon(initialClass) ?? getAppIcon(initialClass) ??
                    "application-x-executable-symbolic")}
                />
              }
            </With>
          </Gtk.Button>
        )}
      </For>
    </box>
  );
}
