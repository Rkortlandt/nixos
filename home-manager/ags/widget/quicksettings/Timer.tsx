import { Settings } from "./Info";
import { AstalIO, Variable, bind, execAsync, idle, interval } from "astal"
import AstalBluetooth from "gi://AstalBluetooth";
import GLib from "gi://GLib?version=2.0";
import Gtk from "gi://Gtk?version=3.0";
import { VarMap } from "./TimerObj";
import Mpris from "gi://AstalMpris?version=0.1"


interface Timer {
  name: string;
  establishedTime: number;
  finishTime: number;
  length: number;
  id: number;
  pinned: boolean;
}


export const timers: Variable<Timer[]> = Variable([]);

export function formatDuration(ms: number): string {
  if (ms < 0) {
    ms = 0; // Handle negative durations gracefully
  }

  const seconds = Math.floor(ms / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  const remainingHours = hours % 24;
  const remainingMinutes = minutes % 60;
  const remainingSeconds = seconds % 60;

  let parts: string[] = [];

  if (days > 0) {
    parts.push(`${days}d`);
  }
  if (remainingHours > 0) {
    parts.push(`${remainingHours}h`);
  }

  let timePart = "";
  if (days === 0 && remainingHours === 0 && remainingMinutes === 0 && remainingSeconds === 0) {
    timePart = "0:00";
  } else if (days === 0 && remainingHours === 0 && remainingMinutes === 0) {
    timePart = `${remainingSeconds}s`; // Or `0:${remainingSeconds.toString().padStart(2, '0')}` if preferred
  } else {
    timePart = `${remainingMinutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  }

  if (parts.length > 0) {
    return `${parts.join(' ')} ${timePart}`;
  } else {
    return timePart;
  }
}

export function removeTimer(timerId: number): void {
  timers.set(timers.get().filter((item) => item.id != timerId));
  updateTimers.set(updateTimers.get() + 1);
}

export const updateTimers = Variable<number>(0);

export function Timer(props: { visibleSetting: Variable<Settings> }) {
  let showInput: Variable<boolean> = Variable(false);
  let timeS: number = 0;
  let timeM: number = 0;
  let timeH: number = 0;
  return <revealer
    transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
    revealChild={props.visibleSetting().as((vs) => vs == Settings.TIMER)}>
    <box hexpand={true}>
      <box vertical={true} hexpand={true}>
        <box hexpand={true}>
          <revealer
            transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
            revealChild={showInput().as((input) => input)}>
            <box hexpand={true}>
              <label label="S:" />
              <entry
                widthChars={2}
                hexpand={false}
                onChanged={(self) => {
                  let val = parseInt(self.get_buffer().text);
                  isNaN(val) ? timeS = 0 : timeS = val * 1000;
                }}
                placeholderText=""
              />
              <label label="M:" />
              <entry
                widthChars={2}
                onChanged={(self) => {
                  let val = parseInt(self.get_buffer().text);
                  isNaN(val) ? timeM = 0 : timeM = val * 60000;
                }}
                placeholderText=""
              />
              <label label="H:" />
              <entry
                widthChars={2}
                onChanged={(self) => {
                  let val = parseInt(self.get_buffer().text);
                  isNaN(val) ? timeH = 0 : timeH = val * 3600000;
                }}
                placeholderText=""
              />
              <box hexpand={true} />
              <box hexpand={false} spacing={2}>
                <button className="bg-blue square-button" css="margin:0px 8px" onClick={() => {
                  showInput.set(false);
                }}>
                  <icon icon="Close" css="font-size: 23px;" />
                </button>
              </box>
            </box>
          </revealer>
          <button hexpand={false} className="bg-blue square-button" css="padding:0px 4px" onClick={() => {
            showInput.set(!showInput.get());
            let timeMS = timeM + timeH + timeS;
            if (showInput.get() == false && timeMS > 0) {
              timers.set(timers.get().concat({
                name: "New Timer",
                establishedTime: Date.now(),
                finishTime: Date.now() + timeMS,
                length: timeMS,
                id: Math.random(),
                pinned: false,
              }));
            }
            timeMS = 0;
          }}> + </button>
          <revealer
            transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
            revealChild={showInput().as((input) => !input)}>
            <box hexpand={true}>
              <button onClick={() => {
                timers.set(timers.get().concat({
                  name: "5min timer",
                  establishedTime: Date.now(),
                  finishTime: Date.now() + 5000,
                  length: 300000,
                  id: Math.random(),
                  pinned: false,
                }));
              }}>+5min</button>
              <button onClick={() => {
                timers.set(timers.get().concat({
                  name: "10min timer",
                  establishedTime: Date.now(),
                  finishTime: Date.now() + 600000,
                  length: 600000,
                  id: Math.random(),
                  pinned: false,
                }));
              }}>+10min</button>
              <button onClick={() => {
                timers.set(timers.get().concat({
                  name: "1min timer",
                  establishedTime: Date.now(),
                  finishTime: Date.now() + 1800000,
                  length: 1800000,
                  id: Math.random(),
                  pinned: false,
                }));
              }}>+30min</button>
            </box>
          </revealer>
        </box>
        {timers().as((timers) =>
          <box vertical={true}> {timers.map((timer, index, array) => {
            let timeRemaining: Variable<number> = Variable(0);
            let playing = false;
            let success = false;
            let pid: number | null = null;

            let intervalid = interval(1000, () => {
              timeRemaining.set((timer.finishTime - Date.now()))
            })

            timeRemaining.subscribe(() => {
              if (timeRemaining.get() < 0) {
                if (!playing) {
                  console.log("Ran");

                  Mpris.get_default().get_players().forEach((player) => {
                    player.pause();
                  });

                  [success, pid,] = GLib.spawn_async_with_pipes(
                    GLib.get_home_dir(), // Use parent's working directory
                    ['mpg123', './nixos/home-manager/ags/symphony_marimba.mp3'], // Command and arguments
                    null, // Use parent's environment
                    GLib.SpawnFlags.SEARCH_PATH | GLib.SpawnFlags.DO_NOT_REAP_CHILD, // Find 'mpv' in PATH, and let us monitor it
                    null // No special setup
                  );
                  playing = true;
                }
              }
            });

            return <box onDestroy={() => {
              intervalid.run_dispose();
              if (pid != null && playing) {
                console.log(`Terminating mpg123 process (PID: ${pid}) due to box destruction.`);
                // Send SIGTERM to the process
                execAsync(['kill', String(pid)])
                  .then(() => {
                    console.log(`Sent SIGTERM to ${pid}`);
                    // After sending the signal, the child watch should eventually fire
                    // and call GLib.spawn_close_pid.
                  })
                  .catch(error => {
                    console.error(`Failed to send SIGTERM to ${pid}: ${error.message}`);
                  });
              }
            }} className="margin" spacing={4}>
              <label>{timer.name}</label>
              <box hexpand={true}></box>
              <label>{timeRemaining().as((ms) => formatDuration(ms))}</label>
              <button className={`square-button ${timer.pinned ? "bg-blue" : ""}`} onClick={() => {
                timer.pinned = !timer.pinned;
                updateTimers.set(updateTimers.get() + 1);
                console.log(timer.pinned);
              }}>
                <icon icon="Pin" css="font-size: 23px;" />
              </button>
              <button className="square-button" onClick={() => {
                removeTimer(timer.id)
              }}>
                <icon icon="Close" css="font-size: 23px;" />
              </button>
            </box>
          })}</box>
        )}
      </box>
    </box >
  </revealer >



} 
