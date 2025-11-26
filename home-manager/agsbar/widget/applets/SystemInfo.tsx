import { Gtk } from "ags/gtk4";
import { createPoll } from "ags/time";
import AstalBattery from "gi://AstalBattery?version=0.1";
import { createBinding, } from "gnim";

export function SystemInfo() {

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
    <menubutton css="background: transparent">
      <box>
        <label label={createBinding(battery, "percentage").as((p) => `${Math.floor(p * 100)}%`)} />
        <image
          iconName={createBinding(battery, "batteryIconName").as(() => getBatteryIcon(battery.percentage))}
          pixelSize={27}
          css="padding-left: 3px"
        />
      </box>
      <popover hasArrow={false}>
        <box orientation={Gtk.Orientation.VERTICAL} spacing={4} css="min-width: 250px">
          <box>
            <button class="primary-bg margin menu-btn"><image pixelSize={27} iconName="Cpu" /></button>
            <label css="color: white; font-weight: bold;" label={cpu.as((cpu) => ` ${cpu}%`)} />
            <slider
              hexpand
              value={cpu}
              max={100}
            />
          </box>
          <box>
            <button class="primary-bg margin menu-btn"><image pixelSize={27} iconName="Ram" /></button>
            <label css="color: white; font-weight: bold;" label={ram.as((ram) => ` ${ram}%`)} />
            <slider
              hexpand
              value={ram}
              max={100}
            />
          </box>
          <box>
            <button class="primary-bg margin menu-btn"><image pixelSize={27} iconName="Temp" /></button>
            <label css="color: white; font-weight: bold;" label={temp.as((temp) => ` ${temp}%`)} />
            <slider
              hexpand
              value={temp}
              max={200}
            />
          </box>
        </box>
      </popover>
    </menubutton>
  )
}
