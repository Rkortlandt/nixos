import Hyprland from "gi://AstalHyprland"
import { Variable, bind } from "astal"

export function Workspaces() {
    const hyprland = Hyprland.get_default();
    const focusedWorkspace = bind(hyprland, "focusedWorkspace");
    
    const startCss = "border-top-left-radius: 15px; border-top-right-radius: 0px; border-bottom-left-radius: 15px; border-bottom-right-radius: 0px;";
    const endCss = "border-top-left-radius: 0px; border-top-right-radius: 15px; border-bottom-left-radius: 0px; border-bottom-right-radius: 15px;";
    const startandendCss = "border-top-left-radius: 15px; border-top-right-radius: 15px; border-bottom-left-radius: 15px; border-bottom-right-radius: 15px;";

    function getBorderRadius(index: number, totalWorkspaces: number) {
	if (totalWorkspaces === 1) {
	    return startandendCss;
	} else if (index === 0) {
	    return startCss;
	} else if (index === totalWorkspaces - 1) {
	    return endCss;
	}
	return '';
    }

    function getColor(index: number, workspaces: Hyprland.Workspace[]) {
	if (focusedWorkspace.get() == null) return "color: #0F5880;"
	if (workspaces[index].get_id() == focusedWorkspace.get().get_id()) {
	    return "color: #0EA16F;";
	} else if (workspaces[index].get_monitor().name != 'eDP-1') {
	    return "color: #172A7D;";
	} else {
	    return "color: #0F5880;";
	}
    }

    return <box className="Workspaces">
        {bind(hyprland, "workspaces").as(wss => wss
	    .filter((a) => a.get_id() > 0)
            .sort((a, b) => a.get_id() - b.get_id())
            .map((ws, index, workspaces) => (
                <button
                    className="workspace-button"
		    css={bind(hyprland, "focusedWorkspace").as(() => `${getColor(index, workspaces)} ${getBorderRadius(index, workspaces.length)}`)}
                    onClicked={() => ws.focus()}>
                    {ws.get_id()}
                </button>
            ))
        )}
    </box>

}
