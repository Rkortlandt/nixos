import Network from "gi://AstalNetwork"
import { bind } from "astal"


export function NetworkIndicator() {
    const network = Network.get_default()
    

    return <Wifi />
}

function Wifi() {
    const { wifi } = Network.get_default()

    return <button className="bg-black">
        <icon
            tooltipText={bind(wifi, "ssid").as(String)}
            className="Wifi"
            css="font-size: 15px"
            icon={bind(wifi, "iconName")}
        />
    </button>
}

