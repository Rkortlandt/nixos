const network = await Service.import('network');

const wifiIndicator = () => {
    /** @param strength {number} */
    let getColorByStrength = (strength) => {
        switch (true) {
            case strength >= 75:
                return '#127CF0'; // Strong signal: Blue
            case strength >= 50:
                return '#2AA028'; // Good signal: Green
            case strength >= 25:
                return '#6EBD30'; // Fair signal: YGreen
            default:
                return '#D17C2E'; // Weak signal: Orange
        }
    } 

    return Widget.Button({
        className: "wifi",
        child: Widget.Icon({
            icon: network.wifi.bind('state').as(
                state => {
                    if (state === "disconnected") {
                        return "no-wifi"
                    } else {
                        return "wifi"
                    }
                }
            ),
            css: "font-size: 15px; padding: 0px 3px;",
            setup: (self) => {
                self.hook(network.wifi, () => {
                    self.icon = (network.wifi.state === "disconnected")? 
                        "no-wifi": "wifi";
                })
            }
        }),
        css: network.bind('wifi').as(wifi => 
            `background-color: ${getColorByStrength(wifi.strength)};`
        ),
        setup: (self) => {
            self.hook(network.wifi, () => {
                self.css = `background-color: ${(network.wifi.state === "disconnected")? "#BD3030" : getColorByStrength(network.wifi.strength)}`;
            })
        }
    })
}

const wiredIndicator = () => Widget.Icon({
    icon: network.wired.bind('icon_name'),
})

export function Network() {
    return Widget.Stack({
        children: {
            wifi: wifiIndicator(),
            wired: wiredIndicator(),
        },
        shown: network.bind('primary').as(p => p || 'wifi'),
    })
}

