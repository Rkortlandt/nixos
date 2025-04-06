import style from "./style.scss"
import Bar from "./widget/Bar"
import { Gdk, Gtk, App } from "astal/gtk3"
import QuickSettings from "./widget/QuickSettings"
import { Variable, bind } from "astal"
import { calculate } from "./calculator/qalculate" 

App.start({
    icons: `${SRC}/assets`,
    css: style,
    main() {
        const bars = new Map<Gdk.Monitor, Gtk.Widget>()
        const quickSettings = new Map<Gdk.Monitor, Gtk.Widget>()

        console.log(calculate("2 + 2"))
        // initialize
        for (const gdkmonitor of App.get_monitors()) {
            bars.set(gdkmonitor, Bar(gdkmonitor))
            quickSettings.set(gdkmonitor, QuickSettings(gdkmonitor))
            App.toggle_window(`quicksettings-${gdkmonitor.get_model()}`)
        }

        App.connect("monitor-added", (_, gdkmonitor) => {
            bars.set(gdkmonitor, Bar(gdkmonitor))
            quickSettings.set(gdkmonitor, QuickSettings(gdkmonitor))
            App.toggle_window(`quicksettings-${gdkmonitor.get_model()}`)
        })

        App.connect("monitor-removed", (_, gdkmonitor) => {
            bars.get(gdkmonitor)?.destroy()
            bars.delete(gdkmonitor)
            quickSettings.get(gdkmonitor)?.destroy()
            quickSettings.delete(gdkmonitor)
        })
    },
})
