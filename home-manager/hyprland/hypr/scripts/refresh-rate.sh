#!/usr/bin/env bash

# Adaptive Hyprland Refresh Rate Script
# Toggles or sets refresh rate on the main display dynamically (adaptively detecting resolution, scale, position, and available modes).
# Supports battery-aware auto switching and a background daemon.

set -euo pipefail

# Ensure HYPRLAND_INSTANCE_SIGNATURE is set and valid
find_hyprland_instance() {
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        if hyprctl monitors >/dev/null 2>&1; then
            return 0
        fi
    fi

    local hypr_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"
    if [ -d "$hypr_dir" ]; then
        for dir in $(ls -td "$hypr_dir"/* 2>/dev/null); do
            if [ -S "$dir/.socket.sock" ]; then
                export HYPRLAND_INSTANCE_SIGNATURE=$(basename "$dir")
                if hyprctl monitors >/dev/null 2>&1; then
                    return 0
                fi
            fi
        done
    fi
}

find_hyprland_instance || true

# Function to get monitor metadata in JSON
get_monitor_info() {
    local raw_json
    raw_json=$(hyprctl monitors -j 2>/dev/null || echo "[]")
    
    if [ -z "$raw_json" ] || [ "$raw_json" = "[]" ]; then
        return 1
    fi

    echo "$raw_json" | jq -c '
        if length == 0 then
            empty
        else
            (map(select(.name | startswith("eDP"))) + map(select(.focused == true)) + .)[0] as $m |
            {
                name: $m.name,
                width: $m.width,
                height: $m.height,
                refreshRate: ($m.refreshRate // 60),
                scale: ($m.scale // 1),
                x: ($m.x // 0),
                y: ($m.y // 0),
                vrr: ($m.vrr // false),
                availableRates: (
                    ($m.availableModes // [])
                    | map(capture("(?<w>[0-9]+)x(?<h>[0-9]+)@(?<hz>[0-9]+(\\.[0-9]+)?)Hz")
                    | select(.w == ($m.width|tostring) and .h == ($m.height|tostring))
                    | .hz | tonumber | round)
                    | unique
                    | sort
                )
            }
        end
    ' 2>/dev/null
}

# Check whether system is on battery power
is_on_battery() {
    # Check AC adapters in sysfs
    for ac in /sys/class/power_supply/AC* /sys/class/power_supply/ACAD* /sys/class/power_supply/ADP*; do
        if [ -f "$ac/online" ]; then
            if [ "$(cat "$ac/online")" -eq 1 ]; then
                return 1 # Plugged in (not on battery)
            fi
        fi
    done

    # Check battery discharging status
    for bat in /sys/class/power_supply/BAT*; do
        if [ -f "$bat/status" ]; then
            if [ "$(cat "$bat/status")" = "Discharging" ]; then
                return 0 # On battery
            fi
        fi
    done

    return 1
}

# Apply refresh rate to monitor
set_refresh_rate() {
    local target_hz="$1"
    local info
    info=$(get_monitor_info)
    
    if [ -z "$info" ]; then
        echo "Error: Could not retrieve monitor information from Hyprland" >&2
        return 1
    fi

    local name width height scale x y vrr
    name=$(echo "$info" | jq -r '.name')
    width=$(echo "$info" | jq -r '.width')
    height=$(echo "$info" | jq -r '.height')
    scale=$(echo "$info" | jq -r '.scale')
    x=$(echo "$info" | jq -r '.x')
    y=$(echo "$info" | jq -r '.y')
    vrr=$(echo "$info" | jq -r '.vrr')

    local mon_rule="${name},${width}x${height}@${target_hz},${x}x${y},${scale}"
    if [ "$vrr" = "true" ] || [ "$vrr" = "1" ]; then
        mon_rule="${mon_rule},vrr,1"
    fi

    hyprctl keyword monitor "$mon_rule" >/dev/null

    # Notify via hyprctl notify if available
    hyprctl notify 1 2000 "rgb(0EA16F)" "Display: ${name} set to ${target_hz}Hz" >/dev/null 2>&1 || true
    echo "Set ${name} to ${target_hz}Hz (${width}x${height} scale ${scale})"
}

# Toggle between lowest and highest available refresh rates
toggle_rate() {
    local info
    info=$(get_monitor_info)

    if [ -z "$info" ]; then
        echo "Error: Could not retrieve monitor information from Hyprland" >&2
        return 1
    fi

    local current_hz min_hz max_hz rates_count
    current_hz=$(echo "$info" | jq -r '.refreshRate | round')
    rates_count=$(echo "$info" | jq -r '.availableRates | length')

    if [ "$rates_count" -gt 1 ]; then
        min_hz=$(echo "$info" | jq -r '.availableRates[0]')
        max_hz=$(echo "$info" | jq -r '.availableRates[-1]')
    else
        min_hz=60
        max_hz=120
    fi

    local target_hz
    # If current rate is closer to max_hz, switch to min_hz, else switch to max_hz
    local threshold=$(( (min_hz + max_hz) / 2 ))
    if [ "$current_hz" -gt "$threshold" ]; then
        target_hz="$min_hz"
    else
        target_hz="$max_hz"
    fi

    set_refresh_rate "$target_hz"
}

# Auto mode: set rate based on power state (battery vs AC)
auto_rate() {
    local info
    info=$(get_monitor_info)

    if [ -z "$info" ]; then
        return 1
    fi

    local min_hz max_hz rates_count
    rates_count=$(echo "$info" | jq -r '.availableRates | length')

    if [ "$rates_count" -gt 1 ]; then
        min_hz=$(echo "$info" | jq -r '.availableRates[0]')
        max_hz=$(echo "$info" | jq -r '.availableRates[-1]')
    else
        min_hz=60
        max_hz=120
    fi

    if is_on_battery; then
        echo "System is on battery: setting ${min_hz}Hz"
        set_refresh_rate "$min_hz"
    else
        echo "System is on AC power: setting ${max_hz}Hz"
        set_refresh_rate "$max_hz"
    fi
}

# Get current refresh rate (rounded number)
get_current_rate() {
    local info
    info=$(get_monitor_info || echo "")
    if [ -n "$info" ]; then
        echo "$info" | jq -r '.refreshRate | round'
    else
        echo "60"
    fi
}

# Run background daemon monitoring power events
daemon_mode() {
    echo "Starting Hyprland Adaptive Refresh Rate Daemon..."
    # Apply on start
    auto_rate || true

    # Listen to power_supply udev events if udevadm exists
    if command -v udevadm >/dev/null 2>&1; then
        udevadm monitor --subsystem-match=power_supply --udev 2>/dev/null | while read -r line; do
            if echo "$line" | grep -q "change"; then
                # Debounce slight event bursts
                sleep 0.5
                auto_rate || true
            fi
        done
    fi
}

# Command dispatch
case "${1:-toggle}" in
    toggle)
        toggle_rate
        ;;
    auto)
        auto_rate
        ;;
    get)
        get_current_rate
        ;;
    get-json)
        get_monitor_info
        ;;
    daemon)
        daemon_mode
        ;;
    60|120|[0-9]*)
        set_refresh_rate "$1"
        ;;
    set)
        if [ -n "${2:-}" ]; then
            set_refresh_rate "$2"
        else
            echo "Usage: $0 set <hz>" >&2
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {toggle|auto|get|get-json|daemon|<hz>|set <hz>}" >&2
        exit 1
        ;;
esac
