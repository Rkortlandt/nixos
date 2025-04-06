import { Settings } from "./Info";
import { Variable, bind, execAsync } from "astal"
import AstalBluetooth from "gi://AstalBluetooth";
import GLib from "gi://GLib?version=2.0";
import Gtk from "gi://Gtk?version=3.0";
import { VarMap } from "./TimerObj";

export const timers: VarMap = new VarMap();

export function Timer(props : { visibleSetting : Variable<Settings> }) {
    //GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
    //    timers.get().forEach(({name, establishedTime, finishTime, length}) => {
    //        if((Date.now() - 5000) >= finishTime) {
    //            print(`Timer: ${name} has elapsed`)
    //            timers.get().delete(name);
    //            return true;
    //        }
    //        print(`Timer: ${name} has ${Math.floor((finishTime - Date.now()) / 1000)} seconds left`);
    //    }) 
    //   return true; 
    //})
    return <revealer
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN} 
        revealChild={props.visibleSetting().as((vs) => vs == Settings.TIMER)}>
        <box vertical={true}>
            <box>
                <button onClick={() => {
                    timers.set("test", {
                        name: "test",
                        establishedTime: Date.now(),
                        finishTime: Date.now() + 10000,
                        length: 10000,
                    })
                    print(timers);
                }}>+5min</button>
            </box>
            {bind(timers).as((timers) => timers)}
            {/*    
                const remainingTime = Variable(length);
                GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
                    if((Date.now() - 5000) >= finishTime) {
                        print(`Timer: ${name} has elapsed`)
                        timers.delete(name);
                        return false;
                    }
                    remainingTime.set(Math.floor((finishTime - Date.now()) / 1000))
                    return true;
                });

                return <box>
                    <label label={name}/>
                    <label label={bind(remainingTime).toString()}/>
                </box>
            })*/}
        </box>
    </revealer>



} 
