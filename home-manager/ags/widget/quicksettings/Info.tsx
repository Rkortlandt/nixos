import { Variable, bind, exec, execAsync } from "astal";
import AstalNetwork from "gi://AstalNetwork";
import AstalBluetooth from "gi://AstalBluetooth";
import Gtk from "gi://Gtk?version=3.0";
var network = AstalNetwork.get_default();
var bluetooth = AstalBluetooth.get_default();

enum Settings {
    NONE,
    WIFI,
    BLUETOOTH,
}

var VisibleSetting = Variable(Settings.NONE);

function getDaySuffix(day : string) {
    const num = parseInt(day, 10);
    if (num >= 11 && num <= 13) {
        return 'th';
    }
    switch (num % 10) {
        case 1: return 'st';
        case 2: return 'nd';
        case 3: return 'rd';
        default: return 'th';
    }
}

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

const date = Variable("").poll(10000, `date "+%B %e, %Y"`, (out) => {
    return `${out.slice(0, out.search(' '))} ${out.slice(out.search(' '), out.search(',')).trim()}${getDaySuffix(out.slice(out.search(' '), out.search(',').valueOf()))}${out.slice(out.search(','), out.length)}`;
});


const weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wendnesday', 'Thursday', 'Friday', 'Saturday']
const weekday = Variable("").poll(1000, `date "+%w"`, (out) => weekdays[parseInt(out)]);

export function Info() {
    return <box vertical={true} spacing={4} css="min-width: 250px">
        <box>
            <label className="padding title" label={bind(date)}/>
            <box hexpand={true}/>
            <label className="padding subtitle" label={bind(weekday)}/>
        </box>
        <box css="min-height: 10px;"/>
        <box>
            <box hexpand={true}/>
            <button onClick={() => exec("hyprctl dispatch exit") } className="square-button margin bg-blue">
                <icon icon="Logout" css="font-size: 23px;"/>
            </button> 
            <button onClick={() => exec("reboot") } className="square-button margin bg-blue">
                <icon icon="Reboot" css="font-size: 23px;"/>
            </button> 
            <button onClick={() => exec("shutdown") } className="square-button margin bg-blue">
                <icon icon="Shutdown" css="font-size: 23px;"/>
            </button>
        </box>
        <box homogeneous={true} spacing={4}>
            <box>
                <button className="thick-button-left bg-blue">
                    <label label="Wifi" hexpand={true} css="padding-left: 10px;" halign={Gtk.Align.START} />
                </button>
                <button className="thick-button-right bg-blue"
                    onClick={() => (VisibleSetting.get() == Settings.WIFI)? VisibleSetting.set(Settings.NONE) : VisibleSetting.set(Settings.WIFI)}
                >
                    <icon 
                        icon={VisibleSetting().as((vs) => vs == Settings.WIFI? "Arrow-Down" : "Arrow-Right")} 
                        css="font-size: 23px;"
                    />
                </button>
            </box>
            <box>
                <button className="thick-button-left bg-blue">
                    <label label="Bluetooth"hexpand={true} />
                </button>
                <button className="thick-button-right bg-blue"
                    onClick={() => (VisibleSetting.get() == Settings.BLUETOOTH)? VisibleSetting.set(Settings.NONE) : VisibleSetting.set(Settings.BLUETOOTH)}
                >
                    <icon 
                        icon={VisibleSetting().as((vs) => vs ==Settings.BLUETOOTH? "Arrow-Down" : "Arrow-Right")} 
                        css="font-size: 23px;"
                    />
                </button>
            </box>
        </box>
        <box vertical={true} visible={VisibleSetting().as((vs) => vs == Settings.WIFI)}>
            {bind(network.wifi, "accessPoints").as((aps) => formatWifiAps(aps))} 
        </box> 
        <box vertical={true} visible={VisibleSetting().as((vs) => vs == Settings.BLUETOOTH)}>
            {bind(bluetooth, "devices").as((devs) => devs.filter((dev) => (dev.get_name() != null) && (dev.get_paired() == true)).map((dev) => {
                return <button className={bind(dev, "connected").as((c) => c? 'bg-selected': '')} onClick={() => 
                    dev.get_connected()? 
                        dev.disconnect_device((dev) => {print(dev?.get_connected())}) 
                        : 
                        dev.connect_device((dev) => {print(dev?.get_connected())})
                }
                >{`${dev.get_name()}`}</button>
            }))}
        </box> 
    </box>
}
