// core/ConnectivityService.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Singleton {
    id: root

    // =========================================================================
    // MODAL / VIEW STATE
    // =========================================================================
    property bool isOpen: false
    property string activeTab: "wifi" // "wifi" | "bluetooth"

    function open(tab = "wifi") {
        activeTab = tab;
        isOpen = true;
        if (tab === "wifi") {
            refreshWifi();
        }
    }

    function toggle(tab = "wifi") {
        if (isOpen && activeTab === tab) {
            close();
        } else {
            open(tab);
        }
    }

    function close() {
        isOpen = false;
        passwordPromptSsid = "";
    }

    // =========================================================================
    // WI-FI STATE & LOGIC
    // =========================================================================
    property bool wifiEnabled: true
    property bool wifiScanning: false
    property string wifiActiveSsid: ""
    property int wifiActiveSignal: 0
    property var wifiList: []
    property string connectingSsid: ""
    property string passwordPromptSsid: ""
    property string wifiErrorMessage: ""

    // Wi-Fi Power Poller
    Process {
        id: wifiPowerProc
        command: ["sh", "-c", "nmcli radio wifi 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let status = this.text.trim();
                root.wifiEnabled = (status === "enabled");
            }
        }
    }

    // Wi-Fi Access Points Poller
    Process {
        id: wifiListProc
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan no 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                let apMap = {};
                let activeSsid = "";
                let activeSig = 0;

                for (let i = 0; i < lines.length; i++) {
                    let raw = lines[i].trim();
                    if (!raw) continue;
                    let inUse = raw.startsWith("*");
                    let text = raw.startsWith("*:") ? raw.slice(2) : (raw.startsWith(":") ? raw.slice(1) : (raw.startsWith(" :") ? raw.slice(2) : raw));
                    let parts = text.split(":");
                    if (parts.length < 3) continue;

                    let signal = parseInt(parts[0]) || 0;
                    let security = (parts[1] || "").replace(/\\:/g, ":").trim();
                    let ssid = parts.slice(2).join(":").replace(/\\:/g, ":").trim();

                    if (!ssid || ssid === "--") continue;

                    let requiresPassword = security.length > 0
                        && security !== "--"
                        && security.toLowerCase() !== "(none)"
                        && !security.includes("802.1X");

                    if (inUse) {
                        activeSsid = ssid;
                        activeSig = signal;
                    }

                    if (!apMap[ssid] || signal > apMap[ssid].signal || inUse) {
                        apMap[ssid] = {
                            ssid: ssid,
                            signal: signal,
                            security: security,
                            inUse: inUse,
                            requiresPassword: requiresPassword
                        };
                    }
                }

                root.wifiActiveSsid = activeSsid;
                root.wifiActiveSignal = activeSig;

                let apArray = Object.values(apMap);
                apArray.sort((a, b) => {
                    if (a.inUse) return -1;
                    if (b.inUse) return 1;
                    return b.signal - a.signal;
                });

                root.wifiList = apArray;
            }
        }
    }

    function refreshWifi() {
        if (!wifiListProc.running) wifiListProc.running = true;
        if (!wifiPowerProc.running) wifiPowerProc.running = true;
    }

    // Wi-Fi Action Execution Process
    Process {
        id: wifiExecProc
        property var onCompleteCallback: null
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            root.connectingSsid = "";
            root.refreshWifi();
            if (onCompleteCallback) {
                onCompleteCallback(exitCode);
                onCompleteCallback = null;
            }
        }
    }

    function toggleWifi() {
        let cmd = root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on";
        root.wifiEnabled = !root.wifiEnabled;
        wifiExecProc.command = ["sh", "-c", cmd];
        wifiExecProc.running = true;
    }

    function scanWifi() {
        root.wifiScanning = true;
        wifiExecProc.command = ["sh", "-c", "nmcli dev wifi rescan 2>/dev/null || true"];
        wifiExecProc.onCompleteCallback = function(exitCode) {
            wifiScanDelayTimer.start();
        };
        wifiExecProc.running = true;
    }

    Timer {
        id: wifiScanDelayTimer
        interval: 1200
        repeat: false
        onTriggered: {
            root.wifiScanning = false;
            root.refreshWifi();
        }
    }

    function connectWifi(ssid, password = "", requiresPassword = true) {
        root.connectingSsid = ssid;
        root.wifiErrorMessage = "";
        let cmd = "";
        if (password && password.length > 0) {
            let escapedPass = password.replace(/"/g, '\\"').replace(/\$/g, '\\$');
            let escapedSsid = ssid.replace(/"/g, '\\"').replace(/\$/g, '\\$');
            cmd = `nmcli connection delete "${escapedSsid}" 2>/dev/null || true; nmcli device wifi connect "${escapedSsid}" password "${escapedPass}"`;
        } else {
            let escapedSsid = ssid.replace(/"/g, '\\"').replace(/\$/g, '\\$');
            cmd = `nmcli device wifi connect "${escapedSsid}"`;
        }

        wifiExecProc.command = ["sh", "-c", cmd];
        wifiExecProc.onCompleteCallback = function(exitCode) {
            if (exitCode !== 0 && !password && requiresPassword) {
                root.passwordPromptSsid = ssid;
            } else {
                root.passwordPromptSsid = "";
            }
        };
        wifiExecProc.running = true;
    }

    function disconnectWifi(ssid = "") {
        let cmd = ssid
            ? `nmcli connection down id "${ssid.replace(/"/g, '\\"')}" 2>/dev/null || nmcli device disconnect $(nmcli -t -f DEVICE,TYPE dev | grep ':wifi$' | cut -d: -f1 | head -n1)`
            : `nmcli device disconnect $(nmcli -t -f DEVICE,TYPE dev | grep ':wifi$' | cut -d: -f1 | head -n1)`;
        wifiExecProc.command = ["sh", "-c", cmd];
        wifiExecProc.running = true;
    }

    // =========================================================================
    // BLUETOOTH STATE & LOGIC
    // =========================================================================
    readonly property var btAdapter: Bluetooth.defaultAdapter ?? null
    readonly property bool btPowered: (btAdapter !== null && btAdapter.enabled) || false
    readonly property bool btScanning: (btAdapter !== null && btAdapter.discovering) || false
    property string btConnectingAddr: ""
    property string btPairingAddr: ""

    Process {
        id: btExecProc
        property var onCompleteCallback: null
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            root.btConnectingAddr = "";
            root.btPairingAddr = "";
            if (onCompleteCallback) {
                onCompleteCallback(exitCode);
                onCompleteCallback = null;
            }
        }
    }

    function toggleBt() {
        if (btAdapter) {
            btAdapter.enabled = !btAdapter.enabled;
        } else {
            let cmd = root.btPowered ? "bluetoothctl power off" : "bluetoothctl power on";
            btExecProc.command = ["sh", "-c", cmd];
            btExecProc.running = true;
        }
    }

    function toggleBtDiscovery() {
        if (btAdapter) {
            btAdapter.discovering = !btAdapter.discovering;
        } else {
            let cmd = root.btScanning ? "bluetoothctl scan off" : "bluetoothctl --timeout 20 scan on";
            btExecProc.command = ["sh", "-c", cmd];
            btExecProc.running = true;
        }
    }

    function connectBt(address) {
        root.btConnectingAddr = address;
        let cmd = `bluetoothctl connect ${address}`;
        btExecProc.command = ["sh", "-c", cmd];
        btExecProc.running = true;
    }

    function disconnectBt(address) {
        root.btConnectingAddr = address;
        let cmd = `bluetoothctl disconnect ${address}`;
        btExecProc.command = ["sh", "-c", cmd];
        btExecProc.running = true;
    }

    function pairBt(address) {
        root.btPairingAddr = address;
        let cmd = `bluetoothctl pairable on; bluetoothctl pair ${address}; bluetoothctl trust ${address}; bluetoothctl connect ${address}`;
        btExecProc.command = ["sh", "-c", cmd];
        btExecProc.running = true;
    }

    function unpairBt(address) {
        let cmd = `bluetoothctl remove ${address}`;
        btExecProc.command = ["sh", "-c", cmd];
        btExecProc.running = true;
    }

    Component.onCompleted: {
        root.refreshWifi();
    }

    // =========================================================================
    // PERIODIC POLLING TIMER (Active only when Island / ConnectivityView is Open)
    // =========================================================================
    Timer {
        interval: 4000
        running: root.isOpen
        repeat: true
        onTriggered: {
            if (root.activeTab === "wifi") {
                root.refreshWifi();
            }
        }
    }
}
