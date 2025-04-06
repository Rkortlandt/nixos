import Network from "gi://AstalNetwork"
import { bind, GLib, Variable } from "astal"
import { Gdk, Gtk } from "astal/gtk3";
import { calculate } from "../../calculator/qalculate";
import { Box, Popover, Stack } from "astal/gtk4/widget";


enum CalculatorState {
    None,
    ShowAnswer,
    Input
}

export function Calculator() {

    var calculateShown = Variable(CalculatorState.None);
    var recentCalculation = Variable("");

    calculateShown.subscribe((value) => {
        if (value == CalculatorState.ShowAnswer) {
            GLib.timeout_add(GLib.PRIORITY_LOW, 10000, () => {
                if (calculateShown.get() == CalculatorState.ShowAnswer) {
                    calculateShown.set(CalculatorState.None);
                }
                return false;
            })
        }
    })

    return <>
        <box className="bg-black" css="border-radius: 12px;">
            <button
                className="bg-black calc"
                visible={calculateShown().as((state) =>
                    state === CalculatorState.None ||
                    state === CalculatorState.ShowAnswer
                )}
                onClick={() => calculateShown.set(CalculatorState.Input)}>
                <icon
                    css="font-size: 25px"
                    icon={"Calculator"}
                />
            </button>
            <revealer
                revealChild={calculateShown().as((state) => state === CalculatorState.Input)}
                transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
            >

                <entry
                    visible={calculateShown().as((state) => state == CalculatorState.Input)}
                    setup={(self) => { self.connect("map", () => { self.grab_focus(); }) }}
                    placeholderText="Enter Text"
                    onKeyPressEvent={(self, event) => {
                        if (event.get_keyval()[1] === 65293) {
                            let calculated = calculate(self.get_buffer().text).result
                            recentCalculation.set(calculated);
                            self.get_buffer().set_text("", 0)
                            calculateShown.set(CalculatorState.ShowAnswer)
                        }
                        if (event.get_keyval()[1] === 65307) {
                            self.get_buffer().set_text("", 0)
                            calculateShown.set(CalculatorState.None)
                        }
                    }}
                />
            </revealer>
            <revealer
                revealChild={calculateShown().as((state) => state === CalculatorState.ShowAnswer)}
                transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}
            >
                <label
                    className="bg-black calculator-label"
                    label={recentCalculation()}
                />
            </revealer>
        </box>
    </>
}


