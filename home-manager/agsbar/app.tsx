import { createBinding, createState, For, This } from "ags"
import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import { SideBar, SideBarTrigger } from "./widget/SideBar";

app.start({
  css: style,
  // It's usually best to go with the default Adwaita theme
  // and built off of it, instead of allowing the system theme
  // to potentially mess something up when it is changed.
  // Note: `* { all:unset }` in css is not recommended.
  gtkTheme: "Adwaita",
  icons: `${SRC}/icons`,
  main() {
    const monitors = createBinding(app, "monitors")


    return (
      <For each={monitors}>
        {(monitor) => {
          const [sideBarVisible, setSideBarVisible] = createState(false);

          sideBarVisible.subscribe(() => {
            console.log("changed");
            app.toggle_window(`sidebar-${monitor.connector}`)
          });
          return (
            <This this={app}>
              <Bar gdkmonitor={monitor} />
              <SideBarTrigger gdkmonitor={monitor} setSideBarVisible={setSideBarVisible} />
              <SideBar gdkmonitor={monitor} sideBarVisible={sideBarVisible} setSideBarVisible={setSideBarVisible} />
            </This>
          )
        }}
      </For>
    )
  },
});
