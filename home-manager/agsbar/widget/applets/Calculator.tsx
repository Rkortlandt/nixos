import { Gdk, Gtk } from "ags/gtk4";
import { createState, For } from "ags";
import { calculate } from "../../qualculate"; // Kept your refactored import!

export const [showCalculator, setShowCalculator] = createState(false);

// We now store both the equation and the result in the history object
type HistoryItem = { id: number; equation: string; result: string };

const [history, setHistory] = createState<HistoryItem[]>([]);
const [historyIndex, setHistoryIndex] = createState(-1);
const [visibleIds, setVisibleIds] = createState<number[]>([]);
let nextHistoryId = 0;

// Helper function to keep our history, the index, and the visible UI buttons perfectly in sync
function updateHistoryState(newHistory: HistoryItem[], newIndex: number) {
  setHistory(newHistory);
  setHistoryIndex(newIndex);
  // Only show a maximum of 5 buttons that are "older" than our current index
  setVisibleIds(newHistory.slice(newIndex + 1, newIndex + 6).map(x => x.id));
}

export function InlineCalculator() {
  let calcEntry: Gtk.Entry;

  return (
    <revealer revealChild={showCalculator} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
      <box spacing={4}>
        <box class="black-bg" css="border-radius: 15px;">
          <label label="  " css="color: white; margin-right: 8px;" />

          <entry
            placeholderText="Calculate..."
            widthRequest={150}
            class="no-bg highlight"
            css="color:white; font-size: 10px; min-height: 10px; border-radius: 15px;"
            onActivate={(self) => {
              const math = calculate(self.text);

              if (math.error) {
                self.text = math.error;
              } else {
                const h = history.get();
                let newHistory = h;

                // Add to history stack (max 20 items), avoid duplicate if it's already the most recent equation
                if (h[0]?.equation !== self.text) {
                  newHistory = [{ id: nextHistoryId++, equation: self.text, result: math.terse }, ...h].slice(0, 20);
                }

                // Reset index so all recent buttons show up again
                updateHistoryState(newHistory, -1);

                self.text = ""
                self.set_position(-1);
              }
            }}

            $={(self) => {
              calcEntry = self;

              self.connect("changed", () => {
                if (self.text === "Math Error" || self.text === "Syntax Error") {
                  self.text = "";
                }
              });

              const keyCtrl = new Gtk.EventControllerKey();
              keyCtrl.connect("key-pressed", (_, keyval) => {
                if (keyval === Gdk.KEY_Escape) {
                  setShowCalculator(false);
                  return true;
                }

                // HISTORY UP: Go back in time. Hides the newest button and puts equation in entry.
                if (keyval === Gdk.KEY_Up) {
                  const h = history.get();
                  const idx = historyIndex.get();
                  if (idx < h.length - 1) {
                    const newIdx = idx + 1;
                    self.text = h[newIdx].equation; // Put the EQUATION back into the box
                    self.set_position(-1);
                    updateHistoryState(h, newIdx);
                  }
                  return true;
                }

                // HISTORY DOWN: Go forward in time. Restores hidden buttons.
                if (keyval === Gdk.KEY_Down) {
                  const h = history.get();
                  const idx = historyIndex.get();
                  if (idx > 0) {
                    const newIdx = idx - 1;
                    self.text = h[newIdx].equation;
                    self.set_position(-1);
                    updateHistoryState(h, newIdx);
                  } else if (idx === 0) {
                    self.text = ""; // We are back to the present! Clear the box.
                    self.set_position(-1);
                    updateHistoryState(h, -1);
                  } else if (idx === -1 && self.text !== "") {
                    // Calculate current text, push into UI as button, and clear entry box
                    const math = calculate(self.text);
                    if (!math.error) {
                      let newHistory = h;
                      if (h[0]?.equation !== self.text) {
                        newHistory = [{ id: nextHistoryId++, equation: self.text, result: math.terse }, ...h].slice(0, 20);
                      }
                      self.text = "";
                      self.set_position(-1);
                      updateHistoryState(newHistory, -1);
                    }
                  }
                  return true;
                }

                return false;
              });
              self.add_controller(keyCtrl);

              showCalculator.subscribe(() => {
                if (showCalculator.get()) {
                  self.grab_focus();
                } else {
                  self.text = "";
                  updateHistoryState(history.get(), -1);
                }
              });
            }}
          />

          {/* History Buttons Pop-out with Smooth Reveal Animation */}
          <For each={history}>
            {(item) => {
              // Create a local hover state for each individual button
              const [isHovered, setIsHovered] = createState(false);

              return (
                <revealer
                  revealChild={visibleIds.as(ids => ids.includes(item.id))}
                  transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
                >
                  <button
                    class="black-bg"
                    css="border-radius: 15px; padding: 0 8px; min-height: 10px;"
                    onClicked={() => {
                      const h = history.get();
                      const targetIndex = h.findIndex(x => x.id === item.id);
                      if (targetIndex !== -1) {
                        calcEntry.text = item.result;
                        calcEntry.grab_focus();
                        calcEntry.set_position(-1);
                        updateHistoryState(h, targetIndex);
                      }
                    }}
                  >
                    <Gtk.EventControllerMotion
                      onEnter={() => setIsHovered(true)}
                      onLeave={() => setIsHovered(false)}
                    />

                    {/* Dynamically swap between the result and the equation based on hover state */}
                    <label
                      label={isHovered.as(hovered => hovered ? item.equation + "=" + item.result : item.result)}
                      css="color: white; font-size: 10px;"
                    />
                  </button>
                </revealer>
              )
            }}
          </For>
        </box>
      </box>
    </revealer>
  );
}
