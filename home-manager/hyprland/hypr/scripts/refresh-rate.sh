#!/usr/bin/env bash

# Adaptive Hyprland Refresh Rate Script
# Toggles or sets refresh rate on the main display dynamically (adaptively detecting resolution, scale, position, and available modes).
# Supports battery-aware auto switching and udev rule integration.

set -euo pipefail

# Ensure standard user/system paths are available (especially when run via udev/runuser)
export PATH="${HOME:-/home/$(id -un)}/.nix-profile/bin:/etc/profiles/per-user/$(id -un)/bin:/run/current-system/sw/bin:${PATH:-/bin:/usr/bin}"

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
    # 1. Check any Mains / AC / USB power supply for online status
    for ps in /sys/class/power_supply/*; do
        if [ -f "$ps/type" ] && [ -f "$ps/online" ]; then
            local type
            type=$(cat "$ps/type" 2>/dev/null || echo "")
            if [ "$type" = "Mains" ] || [ "$type" = "USB" ]; then
                if [ "$(cat "$ps/online" 2>/dev/null || echo 0)" -eq 1 ]; then
                    return 1 # AC / USB-PD connected (not on battery)
                fi
            fi
        fi
    done

    # 2. Check AC adapters by name in sysfs
    for ac in /sys/class/power_supply/AC* /sys/class/power_supply/ACAD* /sys/class/power_supply/ADP*; do
        if [ -f "$ac/online" ]; then
            if [ "$(cat "$ac/online" 2>/dev/null || echo 0)" -eq 1 ]; then
                return 1 # Plugged in (not on battery)
            fi
        fi
    done

    # 3. Check battery discharging status
    for bat in /sys/class/power_supply/BAT*; do
        if [ -f "$bat/status" ]; then
            local status
            status=$(cat "$bat/status" 2>/dev/null || echo "")
            if [ "$status" = "Discharging" ]; then
                return 0 # On battery
            fi
        fi
    done

    # Default to battery if no AC is online
    return 0
}

# Apply refresh rate to monitor
set_refresh_rate() {
    local target_hz="$1"
    local force="${2:-false}"
    local info
    info=$(get_monitor_info || echo "")
    
    if [ -z "$info" ]; then
        echo "Error: Could not retrieve monitor information from Hyprland" >&2
        return 1
    fi

    local name width height scale x y vrr current_hz
    name=$(echo "$info" | jq -r '.name')
    width=$(echo "$info" | jq -r '.width')
    height=$(echo "$info" | jq -r '.height')
    scale=$(echo "$info" | jq -r '.scale')
    x=$(echo "$info" | jq -r '.x')
    y=$(echo "$info" | jq -r '.y')
    vrr=$(echo "$info" | jq -r '.vrr')
    current_hz=$(echo "$info" | jq -r '.refreshRate | round')

    # Avoid redundant rate switches and notification spam
    if [ "$force" != "true" ] && [ "$current_hz" -eq "$target_hz" ]; then
        echo "Display ${name} is already at ${target_hz}Hz"
        return 0
    fi

    local mon_rule="${name},${width}x${height}@${target_hz},${x}x${y},${scale}"
    if [ "$vrr" = "true" ] || [ "$vrr" = "1" ]; then
        mon_rule="${mon_rule},vrr,1"
    fi

    hyprctl keyword monitor "$mon_rule" >/dev/null

    # Notify via hyprctl notify if available
    hyprctl notify 1 2000 "rgb(0EA16F)" "Display: ${name} set to ${target_hz}Hz" >/dev/null 2>&1 || true
    echo "Set ${name} from ${current_hz}Hz to ${target_hz}Hz (${width}x${height} scale ${scale})"
}

# Toggle between lowest and highest available refresh rates
toggle_rate() {
    local info
    info=$(get_monitor_info || echo "")

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

    set_refresh_rate "$target_hz" "true"
}

# Auto mode: set rate based on power state (battery vs AC)
auto_rate() {
    local info
    info=$(get_monitor_info || echo "")

    if [ -z "$info" ]; then
        return 1
    fi

    local min_hz max_hz rates_count current_hz
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
    if is_on_battery; then
        target_hz="$min_hz"
        echo "System is on battery: target ${target_hz}Hz (current: ${current_hz}Hz)"
    else
        target_hz="$max_hz"
        echo "System is on AC power: target ${target_hz}Hz (current: ${current_hz}Hz)"
    fi

    if [ "$current_hz" -ne "$target_hz" ]; then
        set_refresh_rate "$target_hz" "false"
    else
        echo "Refresh rate already optimal (${current_hz}Hz)"
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

# Handler when invoked via udev rule (can be called as root or user)
udev_handler() {
    if [ "$(id -u)" -eq 0 ]; then
        # Running as root from udev rule: find all user Hyprland sessions
        for user_dir in /run/user/*; do
            [ -d "$user_dir" ] || continue
            local uid
            uid=$(basename "$user_dir")
            case "$uid" in
                ''|*[!0-9]*) continue ;;
            esac

            local user_name
            user_name=$(id -nu "$uid" 2>/dev/null || true)
            [ -n "$user_name" ] || continue

            local user_hypr="$user_dir/hypr"
            if [ -d "$user_hypr" ]; then
                for inst in "$user_hypr"/*; do
                    if [ -S "$inst/.socket.sock" ]; then
                        local inst_sig
                        inst_sig=$(basename "$inst")
                        su -s /bin/sh "$user_name" -c "
                            export XDG_RUNTIME_DIR='$user_dir'
                            export HYPRLAND_INSTANCE_SIGNATURE='$inst_sig'
                            \"$0\" auto
                        " </dev/null >/dev/null 2>&1 || true
                    fi
                done
            fi
        done
    else
        auto_rate
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
    udev|udev-trigger)
        udev_handler
        ;;
    60|120|[0-9]*)
        set_refresh_rate "$1" "true"
        ;;
    set)
        if [ -n "${2:-}" ]; then
            set_refresh_rate "$2" "true"
        else
            echo "Usage: $0 set <hz>" >&2
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {toggle|auto|get|get-json|udev|<hz>|set <hz>}" >&2
        exit 1
        ;;
esac
