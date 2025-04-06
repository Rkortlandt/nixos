import AstalNetwork from "gi://AstalNetwork"
import { Settings } from "./Info";
import { Variable, bind, execAsync } from "astal"
import Gtk from "gi://Gtk?version=3.0";

export function Wifi(props : { visibleSetting : Variable<Settings> }) {
    var network = AstalNetwork.get_default();
    
    function formatWifiAps(Aps : AstalNetwork.AccessPoint[]) {
        return Aps
            .sort((a, b) => (a.get_strength() < b.get_strength())? 1 : 0)
            .sort((a, b) => (a.get_frequency() < b.get_frequency())? 1 : 0)
            .filter((ap) => ap.get_ssid() != null)
            .map((ap) => { 
                return ( 
                    <button
                        className={bind(network.wifi, 'ssid').as((ssid) => (ssid == ap.ssid)? 'bg-selected': '')}
                        onClick={() => execAsync(`nmcli device wifi connect ${ap.bssid}`).catch((err) => 
                            print(err))}
                    >
                        <box>
                            <label label={ap.get_ssid()?.toString() ?? "unknown"}/>
                            <box hexpand={true}/>
                            <label label={`${(Math.floor((ap.get_frequency() / 100)) / 10).toString()} `}/>
                            <icon icon={ap.get_icon_name()}/>
                        </box>
                    </button>
                );
            })
    }
    return <revealer 
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN} 
        revealChild={props.visibleSetting().as((vs) => vs == Settings.WIFI)}>
        <box vertical={true}>
            {bind(network.wifi, "accessPoints").as((aps) => formatWifiAps(aps))}
        </box>
    </revealer>

} 
