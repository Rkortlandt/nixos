const usage = Variable(0, {poll: [2000, `${App.configDir}/scripts/system.sh --cpu-usage`]});
const ram = Variable(0, {poll: [10000, `${App.configDir}/scripts/system.sh --ram-usage`]});
const temp = Variable(0, {poll: [5000, `${App.configDir}/scripts/system.sh --cpu-temp`, (c) => (parseFloat(c) * 9/5) + 32]});

export function CpuUsage () {
    return Widget.Button({ label: usage.bind().as((u) => `Cpu: ${u}%`), class_name: "bg-black"});
}

export function RamUsage () {
    return Widget.Button({ label: ram.bind().as((u) => `Ram: ${u}%`), class_name: "bg-black"});
}

export function Heat () {
    return Widget.Button({ label: temp.bind().as((u) => `Temp: ${Math.round(u * 10) / 10}f`), class_name: "bg-black"});
}
