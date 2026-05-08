import { Gdk, Gtk } from "ags/gtk4";
import { createState, For } from "ags";
import { calculate } from "../../qualculate";

export const [showCalculator, setShowCalculator] = createState(false);

type HistoryItem = { id: number; equation: string; result: string };

const [history, setHistory] = createState<HistoryItem[]>([]);
const [historyIndex, setHistoryIndex] = createState(-1);
const [visibleIds, setVisibleIds] = createState<number[]>([]);
let nextHistoryId = 0;

function updateHistoryState(newHistory: HistoryItem[], newIndex: number) {
  setHistory(newHistory);
  setHistoryIndex(newIndex);
  setVisibleIds(newHistory.slice(newIndex + 1, newIndex + 6).map(historyItem => historyItem.id));
}

// Helper function to extract distinct numerical answers from strings like "x = 2 or x = -2"
function parseAnswers(resultStr: string): { display: string, value: string }[] {
  if (!resultStr) return [];
  // Split the result by " or " or commas
  const parts = resultStr.split(/\s+or\s+|,/);
  return parts.map(part => {
    const display = part.trim();
    // Strip out variable assignments like "x = " or "y=" to leave just the number
    const value = part.replace(/^[a-zA-Z]+\s*=\s*/, '').trim();
    return { display, value };
  });
}

export function InlineCalculator() {
  let calcEntry: Gtk.Entry;

  return (
    <revealer revealChild={showCalculator} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
      <box spacing={4}>
        <box class="black-bg calc-container">
          <label label="  " class="calc-icon" />

          <entry
            placeholderText="Calculate..."
            widthRequest={150}
            class="no-bg highlight calc-entry"
            onActivate={(self) => {
              const math = calculate(self.text);

              if (math.error) {
                self.text = math.error;
              } else {
                const currentHistory = history.get();
                let updatedHistory = currentHistory;

                if (currentHistory[0]?.equation !== self.text) {
                  updatedHistory = [{ id: nextHistoryId++, equation: self.text, result: math.terse }, ...currentHistory].slice(0, 20);
                }

                updateHistoryState(updatedHistory, -1);

                self.text = "";
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

                if (keyval === Gdk.KEY_Up) {
                  const currentHistory = history.get();
                  const currentIndex = historyIndex.get();
                  if (currentIndex < currentHistory.length - 1) {
                    const targetIndex = currentIndex + 1;
                    self.text = currentHistory[targetIndex].result;
                    self.set_position(-1);
                    updateHistoryState(currentHistory, targetIndex);
                  }
                  return true;
                }

                if (keyval === Gdk.KEY_Down) {
                  const currentHistory = history.get();
                  const currentIndex = historyIndex.get();
                  if (currentIndex > 0) {
                    const targetIndex = currentIndex - 1;
                    self.text = currentHistory[targetIndex].result;
                    self.set_position(-1);
                    updateHistoryState(currentHistory, targetIndex);
                  } else if (currentIndex === 0) {
                    self.text = "";
                    self.set_position(-1);
                    updateHistoryState(currentHistory, -1);
                  } else if (currentIndex === -1 && self.text !== "") {
                    const math = calculate(self.text);
                    if (!math.error) {
                      let updatedHistory = currentHistory;
                      if (currentHistory[0]?.equation !== self.text) {
                        updatedHistory = [{ id: nextHistoryId++, equation: self.text, result: math.terse }, ...currentHistory].slice(0, 20);
                      }
                      self.text = "";
                      self.set_position(-1);
                      updateHistoryState(updatedHistory, -1);
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

          <For each={history}>
            {(item) => {
              const answers = parseAnswers(item.result);

              return (
                <revealer
                  revealChild={visibleIds.as(ids => ids.includes(item.id))}
                  transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
                >
                  <box class="black-bg calc-history-group" css="border: 1px solid #0F5880;" spacing={2}>
                    {/* The grouped container for multiple answers */}
                    <box spacing={0}>
                      {answers.map((ans, i) => (
                        <box spacing={0}>
                          <button
                            class="calc-history-sub-btn"
                            onClicked={() => {
                              const currentHistory = history.get();
                              const targetIndex = currentHistory.findIndex(historyItem => historyItem.id === item.id);
                              if (targetIndex !== -1) {
                                calcEntry.text = ans.value; // Only puts the specific clicked number in the box
                                calcEntry.grab_focus();
                                calcEntry.set_position(-1);
                                updateHistoryState(currentHistory, targetIndex);
                              }
                            }}
                          >
                            <label
                              label={ans.display} // Shows the full "x = 2" visually
                              class="calc-history-result"
                            />
                          </button>

                          {/* Inserts an "or" label between multiple results for grouping readability */}
                          <label
                            label="or"
                            class="calc-history-equation"
                            css="margin: 0 2px;"
                            visible={i < answers.length - 1}
                          />
                        </box>
                      ))}
                    </box>
                  </box>
                </revealer>
              )
            }}
          </For>
        </box>
      </box>
    </revealer>
  );
}
