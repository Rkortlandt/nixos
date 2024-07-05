async function SystemInfo() {
    const cpu_usage = await Utils.execAsync(`${App.configDir}/scripts/system.sh --cpu-usage`)
        .then(str => String(str))
        .catch(err => {
            print(err)
            return "0"
        });
    const ram_usage = await Utils.execAsync(`${App.configDir}/scripts/system.sh --ram-usage`)
        .then(str => String(str))
        .catch(err => {
            print(err)
            return "0"
        });
    const swap_usage = await Utils.execAsync(`${App.configDir}/scripts/system.sh --swap-usage`)
        .then(str => String(str))
        .catch(err => {
            print(err)
            return "0"
        });
    const cpu_temp = await Utils.execAsync(`${App.configDir}/scripts/system.sh --cpu-temp`)
        .then(str => String(str))
        .catch(err => {
            print(err)
            return "0"
        });
    return {
        cpu: cpu_usage,
        ram: ram_usage,
        swap: swap_usage,
        cpu_temp: cpu_temp
    }
}

const usage = Variable(0, {poll: [2000, `${App.configDir}/scripts/system.sh --cpu-usage`]});
const ram = Variable(0, {poll: [10000, `${App.configDir}/scripts/system.sh --ram-usage`]});
const temp = Variable(0, {poll: [5000, `${App.configDir}/scripts/system.sh --cpu-temp`, (c) => (parseFloat(c) * 9/5) + 32]});

export function CpuUsageSlider () {
    return Widget.Box({
        children: [
            Widget.Button({ label: usage.bind().as((u) => `Cpu: ${u}%`), css: "padding: 0px 3px; margin-right: 5px;", class_name: "square-button"}),
            Widget.ProgressBar({
                vpack: 'center',
                hexpand: true,
                value: usage.bind().as((u) => u / 100),
            }),
        ],
    })
}


export function RamUsageSlider () {
    return Widget.Box({
        children: [
            Widget.Button({ label: ram.bind().as((u) => `Ram: ${u}%`), css: "padding: 0px 3px; margin-right: 5px;", class_name: "square-button"}),
            Widget.ProgressBar({
                vpack: 'center',
                hexpand: true,
                value: ram.bind().as((u) => u / 100),
            }),
        ],
    })
}

export function HeatSlider () {
    return Widget.Box({
        children: [
            Widget.Button({ label: temp.bind().as((u) => `Temp: ${Math.round(u * 10) / 10}f`), css: "padding: 0px 3px; margin-right: 5px;", class_name: "square-button"}),
            Widget.ProgressBar({
                vpack: 'center',
                hexpand: true,
                value: temp.bind().as((u) => Math.min(1, u / 200)),
            }),
        ],
    })
}

