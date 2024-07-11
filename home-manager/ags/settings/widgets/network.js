import { Menu, ArrowToggleButton } from "./togglebutton.js"
const { wifi } = await Service.import("network")

export const NetworkToggle = () => ArrowToggleButton({
    name: "network",
    icon: wifi.bind("icon_name"),
    label: wifi.bind("ssid").as(ssid => ssid || "Not Connected"),
    connection: [wifi, () => wifi.enabled],
    deactivate: () => wifi.enabled = false,
    activate: () => {
        wifi.enabled = true
        wifi.scan()
    },
})

export const WifiSelection = () => Menu({
    name: "network",
    icon: wifi.bind("icon_name"),
    title: "Wifi Selection",
    content: [
        Widget.Box({
            vertical: true,
            setup: self => self.hook(wifi, () => self.children =
                wifi.access_points
                    .sort((a, b) => b.strength - a.strength)
                    .slice(0, 10)
                    .filter((ap) => ap.ssid?.toLowerCase() != "unknown")
                    .map(ap => Widget.Button({
                        on_clicked: () => {
                            Utils.execAsync(`nmcli device wifi connect ${ap.bssid}`)
                        },
                        child: Widget.Box({
                            children: [
                                Widget.Icon(ap.iconName),
                                Widget.Label({label: ap.ssid || "", css: "font-size: 8px; padding: 0px"}),
                                Widget.Icon({
                                    hexpand: true,
                                    hpack: "end",
                                    setup: self => Utils.idle(() => {
                                        if (!self.is_destroyed)
                                            self.visible = ap.active
                                    }),
                                }),
                            ],
                        }),
                    })),
            ),
        }),
        Widget.Separator(),
    ],
})
