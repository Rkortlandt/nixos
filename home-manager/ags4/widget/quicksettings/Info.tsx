import { Variable, bind, exec, execAsync } from "astal";
import AstalNetwork from "gi://AstalNetwork";
import AstalBluetooth from "gi://AstalBluetooth";
import Gtk from "gi://Gtk?version=3.0";
import { Wifi } from "./Wifi";
import { Bluetooth } from "./Bluetooth";
import { Timer } from "./Timer";
var bluetooth = AstalBluetooth.get_default();

export enum Settings {
    NONE,
    WIFI,
    BLUETOOTH,
    TIMER,
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
            <button onClick={() => exec("shutdown 0") } className="square-button margin bg-blue">
                <icon icon="Shutdown" css="font-size: 23px;"/>
            </button>
        </box>
        {/*<icon icon="clear-day" css="font-size: 23px;"/>*/}
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
        <Wifi visibleSetting={VisibleSetting} />
        <Bluetooth visibleSetting={VisibleSetting} /> 
        {/*
        <box>
            <button className="thick-button-left bg-blue">
                <label label="Timer"hexpand={true} />
            </button>
            <button className="thick-button-right bg-blue"
                onClick={() => (VisibleSetting.get() == Settings.TIMER)? VisibleSetting.set(Settings.NONE) : VisibleSetting.set(Settings.TIMER)}
            >
                <icon 
                    icon={VisibleSetting().as((vs) => vs == Settings.TIMER? "Arrow-Down" : "Arrow-Right")} 
                    css="font-size: 23px;"
                />
            </button>
        </box>
        <Timer visibleSetting={VisibleSetting}/>
        */}
    </box>
}
