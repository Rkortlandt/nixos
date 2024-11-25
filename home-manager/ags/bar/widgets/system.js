const usage = Variable(0, {poll: [2000, `${App.configDir}/scripts/system.sh --cpu-usage`]});
const ram = Variable(0, {poll: [10000, `${App.configDir}/scripts/system.sh --ram-usage`]});
const temp = Variable(0, {poll: [5000, `${App.configDir}/scripts/system.sh --cpu-temp`, (c) => (parseFloat(c) * 9/5) + 32]});

export function CpuUsage () {
    return Widget.Button({ 
        class_name: "bg-black",
        child: Widget.Box({ children :[
            Widget.Icon({ icon:'cpu', css:'font-size:17px'}),
            Widget.Label({ label: usage.bind().as((u) => `${u}%`)}),
        ]
        })
    })
}

export function RamUsage () {
    return Widget.Button({
        class_name: "bg-black",
        child: Widget.Box({ children :[
            Widget.Icon({ icon:'ram', css:'font-size:17px'}),
            Widget.Label({ label: ram.bind().as((u) => `${u}%`)})
            ]
        })
    })
}

export function Heat () {
    return Widget.Button({ 
        class_name: "bg-black",
        child: Widget.Box({ children :[
            Widget.Icon({ icon:'heat', css:'font-size:17px'}),
            Widget.Label({ label: temp.bind().as((u) => `${Math.round(u)}°`)}),
            ]
        })
    })
}
