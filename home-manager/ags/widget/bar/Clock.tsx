import { App, Gdk, Gtk } from "astal/gtk3"
import GLib from "gi://GLib?version=2.0"
import { Variable, bind } from "astal"

export function Clock(props: { monitor: string | null, }) {
	const time = Variable("").poll(1000, 'date "+%I:%M"')
	// const date = Variable("").poll(100000, 'date "+%m/%e"')
	// const weather = Variable("").poll(600000, 'curl wttr.in/kalamazoo?format="%t"&u')

	return <box>
		<button className="bg-black" onClick={() => { App.toggle_window(`quicksettings-${props.monitor}`) }}>
			<box>
				<label label={time()} />
				<label label=" " />
			</box>
		</button >
	</box>
}
