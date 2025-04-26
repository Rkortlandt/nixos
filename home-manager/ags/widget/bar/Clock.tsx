import { App, Gdk, Gtk } from "astal/gtk3"
import GLib from "gi://GLib?version=2.0"
import { Variable, bind } from "astal"

export function Clock(props: { monitor: string | null, }) {
	const time = Variable("").poll(1000, 'date "+%H:%M"')
	const date = Variable("").poll(100000, 'date "+%e %B (%m)"')
	const weather = Variable("").poll(600000, 'curl wttr.in/@42.2917,-85.5872?format="%t"&u')

	return <button className="bg-black" onClick={() => { App.toggle_window(`quicksettings-${props.monitor}`) }}>
		<box>
			<label label={time()} />
			<label label="  |  " />
			<label label={weather((w) => w)} />
			<label label=" " />
		</box>
	</button>

}
