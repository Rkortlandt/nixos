import { Gtk } from "ags/gtk4";
import { createPoll } from "ags/time";
import AstalBattery from "gi://AstalBattery?version=0.1";
import { createBinding, createComputed, createState, } from "gnim";

export function SystemInfo() {
  type states = "closed" | "temp" | "cpumem"

  var [state, setState] = createState("closed");
  var tempActive = createComputed(() => state() == "temp")
  var cpumemActive = createComputed(() => state() == "cpumem")

  function getBatteryIcon(percent: number): string {
    if (battery.charging) {
      return 'Battery-Charging';
    } else if (percent >= .70) {
      return 'Battery-Full';
    } else if (percent >= .20) {
      return 'Battery-Mid';
    } else if (percent >= .10) {
      return 'Battery-Low'
    } else {
      return 'Battery-Critical';
    }
  }

  const battery = AstalBattery.get_default();
  const cpu = createPoll(0, 2000, `${SRC}/scripts/system.sh --cpu-usage`,
    (out) => parseInt(out)
  );

  const ram = createPoll(0, 10000, `${SRC}/scripts/system.sh --ram-usage`,
    (out) => parseInt(out)
  );

  const temp = createPoll(0, 5000, `${SRC}/scripts/system.sh --cpu-temp`,
    (out) => {
      const tempC = parseInt(out) || 0;
      const tempF = Math.round((tempC * 9 / 5) + 32); // Rounding to nearest degree
      return tempF;
    }
  );

  return (
    <button css="background: transparent" onClicked={() => {
      if (state() == "closed") {
        setState("cpumem")
      } else if (state() == "cpumem") {
        setState("temp")
      } else if (state() == "temp") {
        setState("closed")
      }
    }}>
      <box>
        <box>
          <label label={createBinding(battery, "percentage").as((p) => `${Math.floor(p * 100)}%`)} />
          <image
            iconName={createBinding(battery, "batteryIconName").as(() => getBatteryIcon(battery.percentage))}
            pixelSize={27}
            css="padding-left: 3px"
          />
        </box>
        <revealer revealChild={tempActive} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
          <box>
            <box>
              <label css="color: white; font-weight: bold;" label={cpu.as((cpu) => ` ${cpu}%`)} />
              <button class="margin menu-btn"><image pixelSize={27} iconName="Cpu" /></button>
            </box>
            <box>
              <label css="color: white; font-weight: bold;" label={ram.as((ram) => ` ${ram}%`)} />
              <button class=" margin menu-btn"><image pixelSize={27} iconName="Ram" /></button>
            </box>
          </box>
        </revealer>
        <revealer revealChild={cpumemActive} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
          <box>
            <label css="color: white; font-weight: bold;" label={temp.as((temp) => ` ${temp}%`)} />
            <button class=" margin menu-btn"><image pixelSize={27} iconName="Temp" /></button>
            { /* <slider
              hexpand
              value={temp}
              max={200}
            /> */}
          </box>
        </revealer>
      </box>
    </button>
  )
}
