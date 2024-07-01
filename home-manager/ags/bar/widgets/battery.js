const battery = await Service.import('battery')

export function Battery () {
    return Widget.Button({
        setup: self => {
            let batteryLabel;
            let batteryIcon;

            self.child = Widget.Box({
                children: [
                    batteryLabel = Widget.Label({
                        label: `${battery.percent}%`,
                    }),
                    batteryIcon = Widget.Icon({
                        icon: getBatteryIcon(battery),
                        css: "font-size: 25px; padding: 0px 4px;"
                    }),
                ],
            });

            self.hook(battery, () => {
                batteryLabel.label = `${battery.percent}%`;
                batteryIcon.icon = getBatteryIcon(battery);
                self.css = `background-color: ${getColorState(battery)}`;
            });
        },
    });
}    

/** @param battery {import('types/service/battery').Battery} */
function getBatteryIcon(battery) {
    if (battery.charging) {
        return 'batt-charging';
    } else if (battery.percent >= 90) {
        return 'batt-full';
    } else if (battery.percent >= 50) {
        return 'batt-mid';
    } else if (battery.percent >= 20) {
        return 'batt-warn';
    } else {
        return 'batt-crit';
    }
}

/** @param battery {import('types/service/battery').Battery} */
function getColorState(battery) {
    if (battery.charging) {
        return '#127CF0';
    } else if (battery.percent >= 90) {
        return '#239A20';
    } else if (battery.percent >= 50) {
        return '#6FAB40';
    } else if (battery.percent >= 20) {
        return '#BB712C';
    } else {
        return '#BD3030';
    }
}
