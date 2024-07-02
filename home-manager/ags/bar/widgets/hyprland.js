const hyprland = await Service.import('hyprland');

const dispatch = ws => hyprland.messageAsync(`dispatch workspace ${ws}`);

const startCss = "border-top-left-radius: 15px; border-top-right-radius: 0px; border-bottom-left-radius: 15px; border-bottom-right-radius: 0px;";
const endCss = "border-top-left-radius: 0px; border-top-right-radius: 15px; border-bottom-left-radius: 0px; border-bottom-right-radius: 15px;";
const startandendCss = "border-top-left-radius: 15px; border-top-right-radius: 15px; border-bottom-left-radius: 15px; border-bottom-right-radius: 15px;";

export function Workspaces() {
    return Widget.EventBox({
        child: Widget.Box({
            children: Array.from({ length: 10 }, (_, i) => i + 1).map(i => Widget.Button({
                className: 'workspace-button',
                attribute: i,
                label: `${i}`,
                onClicked: () => dispatch(i),
            })),

            setup: self => {
                self.hook(hyprland.active.workspace, () => self.children.forEach(btn => {
                    btn.visible = hyprland.workspaces.some(ws => ws.id === btn.attribute);
                    let color = getColor(btn);
                    
                    if (hyprland.workspaces[0].id === hyprland.workspaces[hyprland.workspaces.length - 1].id) btn.css = startandendCss + color;
                    else if (hyprland.workspaces[0].id === btn.attribute) btn.css = startCss + color;
                    else if (hyprland.workspaces[hyprland.workspaces.length - 1].id === btn.attribute) btn.css = endCss + color; 
                    else btn.css = color;
                }));
            },
        }),
    })
}


function getColor(btn) {
    if (btn.attribute == hyprland.active.workspace.id) {
        return "color: #0EA16F";
    } else if (hyprland.workspaces.find(({ id }) => id == btn.attribute)?.monitor != 'eDP-1') {
        return "color: #172A7D";
    } else {
        return "color: #0F5880";
    }
}
