import { Gdk, Gtk } from "ags/gtk4";
import { createState } from "ags";
import { calculate } from "../../qualculate";

export const [showCalculator, setShowCalculator] = createState(false);

export function InlineCalculator() {
  return (
    <revealer revealChild={showCalculator} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
      <box class="black-bg">
        <label label="  " css="color: white; margin-right: 8px;" />

        <entry
          placeholderText="Calculate..."
          widthRequest={150}
          class="no-bg"
          css="color:white; border-radius: 15px; font-size: 10px; min-height: 10px"
          onActivate={(self) => {
            // Run the input through our new calculate function
            const math = calculate(self.text);

            if (math.error) {
              // Temporarily show the error, then clear it when the user types again
              self.text = math.error;
            } else {
              // Update the entry box with the clean, terse result
              self.text = math.terse;

              // Optional: move the cursor to the end of the text so the user can continue doing math
              self.set_position(-1);
            }
          }}

          $={(self) => {
            // Clear errors automatically if the user starts typing again
            self.connect("changed", () => {
              if (self.text === "Math Error" || self.text === "Syntax Error") {
                self.text = "";
              }
            });

            const keyCtrl = new Gtk.EventControllerKey();
            keyCtrl.connect("key-pressed", (_, keyval) => {
              if (keyval === Gdk.KEY_Escape) {
                setShowCalculator(false);
                return true; // Tells GTK we successfully handled this keystroke
              }
              return false;
            });
            self.add_controller(keyCtrl);

            // Handle focus/clearing when revealed/hidden
            showCalculator.subscribe(() => {
              if (showCalculator.get()) {
                self.grab_focus();
              } else {
                self.text = "";
              }
            });
          }}
        />
      </box>
    </revealer>
  );
}
