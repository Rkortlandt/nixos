const hyprland = await Service.import('hyprland');

const dispatch = ws => hyprland.messageAsync(`dispatch workspace ${ws}`);

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
                    if (hyprland.workspaces[0].id === btn.attribute) btn.class_name = 'workspace-button-start';
                    if (hyprland.workspaces[hyprland.workspaces.length - 1].id === btn.attribute) btn.class_name = 'workspace-button-end';

                    if (btn.attribute == hyprland.active.workspace.id) {
                        btn.css = "color: #0EA16F";
                    } else if (hyprland.workspaces.find(({ id }) => id == btn.attribute)?.monitor != 'eDP-1') {
                        btn.css = "color: #172A7D";
                    } else {
                        btn.css = "color: #0F5880";
                    }
                }));
            },
        }),
    })
}


