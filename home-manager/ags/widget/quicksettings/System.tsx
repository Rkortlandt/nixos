import { App } from "astal/gtk3";
import { Variable, exec, bind } from "astal";

var cpu = Variable(0).poll(2000, `${SRC}/scripts/system.sh --cpu-usage`, (c) => parseInt(c));
var ram = Variable(0).poll(10000, `${SRC}/scripts/system.sh --ram-usage`, (c) => (parseInt(c)))
var temp = Variable(0).poll(5000, `${SRC}/scripts/system.sh --cpu-temp`, (c) => (parseInt(c) * 9 / 5) + 32)

export function System() {
    return <box vertical={true} spacing={4} css="min-width: 250px">
        <box>
            <button className="bg-blue margin menu-btn"><icon css="font-size: 23px;" icon="Cpu" /></button>
            <label css="color: white; font-weight: bold;" label={bind(cpu).as((cpu) => (cpu.toString() + "%").padEnd(4))} />
            <slider
                hexpand
                value={bind(cpu)}
                max={100}
            />
        </box>
        <box>
            <button className="bg-blue margin menu-btn"><icon css="font-size: 23px;" icon="Ram" /></button>
            <label css="color: white; font-weight: bold;" label={bind(ram).as((ram) => (ram.toString() + "%").padEnd(4))} />
            <slider
                hexpand
                value={bind(ram)}
                max={100}
            />
        </box>
        <box>
            <button className="bg-blue margin menu-btn"><icon css="font-size: 23px;" icon="Temp" /></button>
            <label css="color: white; font-weight: bold;" label={bind(temp).as((temp) => (temp.toString() + "°F").padEnd(4))} />
            <slider
                hexpand
                value={bind(temp)}
                max={200}
            />
        </box>
    </box>
}
