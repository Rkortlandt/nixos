/** @param day {string} */
function getDaySuffix(day) {
    const num = parseInt(day, 10);
    if (num >= 11 && num <= 13) {
        return 'th';
    }
    switch (num % 10) {
        case 1: return 'st';
        case 2: return 'nd';
        case 3: return 'rd';
        default: return 'th';
    }
}

const date = Variable("", {
    poll: [1000, `date "+%B %e, %Y"`, (out) => {
        return `${out.slice(0, out.search(' '))} ${out.slice(out.search(' '), out.search(',')).trim()}${getDaySuffix(out.slice(out.search(' '), out.search(',').valueOf()))}${out.slice(out.search(','), out.length)}`;
    }], 
})

const weekdays = ['Sunday', 'Saturday', 'Monday', 'Tuesday', 'Wendnesday', 'Thursday', 'Friday']
const weekday = Variable("", {
    poll: [1000, `date "+%w"`, out => weekdays[out]]
})

export function Info() {
    return Widget.Box({
        class_name: "bg-black padding",
        vertical: true,
        children : [
            Widget.Box({
                children: [
                    Widget.Label({
                        class_name: "padding",
                        css: "font-size: 16px; font-weight: bold",
                        label: date.bind()
                    }),
                    Widget.Box({ hexpand: true }),
                    Widget.Label({
                        class_name: "padding",
                        css: "color: grey",
                        label: weekday.bind()
                    }),
                ],
            }),
            Widget.Box({ css: "min-height: 4px"}),
            Widget.Box({
                children: [
                    Widget.Box({ hexpand: true }),
                    Widget.Button({
                        onClicked: () => { Utils.exec("hyprctl dispatch exit") },
                        class_name: "square-button margin bg-blue",
                        child: Widget.Icon({ icon: "logout", css: "font-size: 25px" })
                    }),
                    Widget.Button({
                        onClicked: () => { Utils.exec("reboot") },
                        class_name: "square-button margin bg-blue",
                        child: Widget.Icon({ icon: "restart", css: "font-size: 25px" })
                    }),
                    Widget.Button({
                        onClicked: () => { Utils.exec("shutdown") },
                        class_name: "square-button margin bg-blue",
                        child: Widget.Icon({ icon: "power", css: "font-size: 25px" })
                    }),
                ],
            }),
        ]
    });
}
