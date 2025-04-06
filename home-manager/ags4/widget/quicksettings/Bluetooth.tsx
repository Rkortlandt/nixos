import { Settings } from "./Info";
import { Variable, bind, execAsync } from "astal"
import AstalBluetooth from "gi://AstalBluetooth";
import GLib from "gi://GLib?version=2.0";
import Gtk from "gi://Gtk?version=3.0";

export function Bluetooth(props : { visibleSetting : Variable<Settings> }) {
    var bluetooth = AstalBluetooth.get_default();
    var spinner = Variable(0);

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 60, () => {
        var progress = spinner.get()
        progress += 0.03;
        
        if (progress > 1) {
            progress = 0;
        }

        spinner.set(progress);
        return true;
    })
    
    function formatBluetoothDevices(Devices : AstalBluetooth.Device[]) {
        return Devices
            .filter((dev) => (dev.get_name() != null) && (dev.get_paired() == true))
            .map((dev) => {
                return <button 
                    className={bind(dev, "connected").as((c) => c? 'bg-selected': '')} 
                    onClick={() => { 
                        if (dev.get_connected()) { 
                            dev.disconnect_device(() => {
                            }); 
                        } else {
                            dev.connect_device(() => {
                            });    
                        }
                    } 
                    }>
                    <box>
                        <label label={`${dev.get_name()}`}/>
                        <circularprogress visible={bind(dev, "connecting")} startAt={spinner()} endAt={spinner().as((v) => (v + (.3)))}/>
                    </box>
                </button>
            })
    }
    return <revealer
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN} 
        revealChild={props.visibleSetting().as((vs) => vs == Settings.BLUETOOTH)}>
        <box vertical={true}>
            {bind(bluetooth, "devices").as((devs) => formatBluetoothDevices(devs))}
        </box>
    </revealer>



} 
