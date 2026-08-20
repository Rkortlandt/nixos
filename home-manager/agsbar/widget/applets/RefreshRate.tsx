import Gtk from "gi://Gtk?version=4.0";
import { createComputed, createState } from "ags";
import { createPoll } from "ags/time";
import { execAsync } from "ags/process";

const SCRIPT_PATH = "/home/ss-pro/nixos/home-manager/hyprland/hypr/scripts/refresh-rate.sh";

export function RefreshRate() {
  // Fast poll to reflect current refresh rate seamlessly
  const currentHz = createPoll(120, 2000, `${SCRIPT_PATH} get`, (out) => {
    const num = parseInt(out.trim());
    return isNaN(num) ? 60 : num;
  });

  const [loading, setLoading] = createState(false);

  const toggleRate = async () => {
    if (loading.get()) return;
    setLoading(true);
    try {
      await execAsync([SCRIPT_PATH, "toggle"]);
      const out = await execAsync([SCRIPT_PATH, "get"]);
      const num = parseInt(out.trim());
      if (!isNaN(num)) {
        currentHz.set(num);
      }
    } catch (e) {
      console.error("RefreshRate toggle error:", e);
    } finally {
      setLoading(false);
    }
  };

  const setAutoMode = async () => {
    if (loading.get()) return;
    setLoading(true);
    try {
      await execAsync([SCRIPT_PATH, "auto"]);
      const out = await execAsync([SCRIPT_PATH, "get"]);
      const num = parseInt(out.trim());
      if (!isNaN(num)) {
        currentHz.set(num);
      }
    } catch (e) {
      console.error("RefreshRate auto error:", e);
    } finally {
      setLoading(false);
    }
  };

  const labelText = currentHz.as((hz) => `${hz}Hz`);
  const tooltip = currentHz.as((hz) =>
    `Display Refresh Rate: ${hz}Hz\n• Left Click: Toggle 60Hz / 120Hz\n• Right Click: Auto Mode (AC/Battery)`
  );

  return (
    <button
      class="refresh-rate"
      onClicked={toggleRate}
      tooltipText={tooltip}
    >
      <box spacing={4}>
        <Gtk.GestureClick
          button={3}
          onPressed={() => setAutoMode()}
        />
        <image iconName="video-display-symbolic" pixelSize={18} />
        <label label={labelText} />
      </box>
    </button>
  );
}
