import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { TopLeft, TopRight, BottomLeft, BottomRight } from "./quicksettings/Settings"
import { Variable } from "../../../../.local/share/ags";



export default function QuickSettings(gdkmonitor: Gdk.Monitor) {
    function toggleSettings() {
        App.toggle_window(`quicksettings-${gdkmonitor.get_model()}`); 
    }

    return <window
        name={`quicksettings-${gdkmonitor.get_model()}`}
        gdkmonitor={gdkmonitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={Astal.WindowAnchor.TOP
            | Astal.WindowAnchor.LEFT
            | Astal.WindowAnchor.RIGHT
            | Astal.WindowAnchor.BOTTOM }
        application={App}>
        <box className="bg-light">
            <box vertical={true} hexpand={false}>
                <TopLeft/>
                <button className="invis-btn" vexpand={true} hexpand={true} onClick={() => toggleSettings()}/>
                <BottomLeft/>
            </box>
            <button className="invis-btn" vexpand={true} hexpand={true} onClick={() => toggleSettings()}/>
            <box vertical={true} hexpand={false}>
                <TopRight/>
                <button className="invis-btn" vexpand={true} hexpand={true} onClick={() => toggleSettings()}/>
                <BottomRight/>
            </box>
        </box>
    </window>
}
