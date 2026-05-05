import { createBinding, createState, For, This } from "ags"
import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import { setShowCalculator, showCalculator } from "./widget/applets/Calculator"

app.start({
  css: style,
  gtkTheme: "Adwaita",
  icons: `${SRC}/icons`,

  requestHandler(request: string[], res: (response: any) => void) {
    if (request[0] === "toggle-calc") {
      setShowCalculator(!showCalculator.get());
      res("Calculator toggled");
    } else {
      res("Unknown command");
    }
  },

  main() {
    const monitors = createBinding(app, "monitors")

    return (
      <For each={monitors}>
        {(monitor) => {
          return (
            <This this={app}>
              <Bar gdkmonitor={monitor} />
            </This>
          )
        }}
      </For>
    )
  },
});
