#!/usr/bin/env bash

# Power Profile Management Script
# Supports:
# 1. power-profiles-daemon (powerprofilesctl)
# 2. asusctl (ASUS ROG / TUF / ProArt profiles)
# 3. Linux kernel /sys/firmware/acpi/platform_profile
# 4. AMD / Intel P-State energy_performance_preference
# 5. Persistent user state fallback

set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_FILE="$CACHE_DIR/power-profile"
mkdir -p "$CACHE_DIR"

# Normalize profile names: power-saver | balanced | performance
normalize_profile() {
    local raw="$1"
    case "$raw" in
        *power-saver*|*powersave*|*saver*|*quiet*|*low-power*|*battery*)
            echo "power-saver"
            ;;
        *performance*|*perf*|*boost*)
            echo "performance"
            ;;
        *balanced*|*balance*|*default*)
            echo "balanced"
            ;;
        *)
            echo "balanced"
            ;;
    esac
}

get_profile() {
    # 1. Try powerprofilesctl if available and responsive
    if command -v powerprofilesctl >/dev/null 2>&1; then
        local p
        if p=$(powerprofilesctl get 2>/dev/null); then
            if [ -n "$p" ]; then
                normalize_profile "$p"
                return 0
            fi
        fi
    fi

    # 2. Try asusctl if available
    if command -v asusctl >/dev/null 2>&1; then
        local asus_out
        if asus_out=$(asusctl profile -p 2>/dev/null); then
            local active
            active=$(echo "$asus_out" | grep -i "Active profile" | awk -F': ' '{print $2}' | tr -d ' ' || echo "")
            if [ -n "$active" ]; then
                normalize_profile "$active"
                return 0
            fi
        fi
    fi

    # 3. Check persistent state file
    if [ -f "$STATE_FILE" ]; then
        local saved
        saved=$(cat "$STATE_FILE" 2>/dev/null || echo "")
        if [ -n "$saved" ]; then
            normalize_profile "$saved"
            return 0
        fi
    fi

    # 4. Try ACPI platform_profile in sysfs
    if [ -f /sys/firmware/acpi/platform_profile ]; then
        local acpi_p
        acpi_p=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo "")
        if [ -n "$acpi_p" ]; then
            normalize_profile "$acpi_p"
            return 0
        fi
    fi

    # Default fallback
    echo "balanced"
}

set_profile() {
    local target
    target=$(normalize_profile "$1")

    # 1. Try powerprofilesctl
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set "$target" 2>/dev/null || true
    fi

    # 2. Try asusctl
    if command -v asusctl >/dev/null 2>&1; then
        local asus_target="Balanced"
        if [ "$target" = "power-saver" ]; then
            asus_target="Quiet"
        elif [ "$target" = "performance" ]; then
            asus_target="Performance"
        fi
        asusctl profile -P "$asus_target" 2>/dev/null || true
    fi

    # 3. Try ACPI platform_profile if writable
    if [ -w /sys/firmware/acpi/platform_profile ]; then
        local acpi_choice="balanced"
        local supported
        supported=$(cat /sys/firmware/acpi/platform_profile_choices 2>/dev/null || echo "")
        if [ "$target" = "power-saver" ]; then
            if echo "$supported" | grep -q "quiet"; then
                acpi_choice="quiet"
            elif echo "$supported" | grep -q "low-power"; then
                acpi_choice="low-power"
            fi
        elif [ "$target" = "performance" ]; then
            if echo "$supported" | grep -q "performance"; then
                acpi_choice="performance"
            fi
        fi
        echo "$acpi_choice" > /sys/firmware/acpi/platform_profile 2>/dev/null || true
    fi

    # 4. Try AMD/Intel energy_performance_preference if writable
    local epp="balance_performance"
    if [ "$target" = "power-saver" ]; then
        epp="power"
    elif [ "$target" = "performance" ]; then
        epp="performance"
    fi

    for f in /sys/devices/system/cpu/cpu*/power/energy_performance_preference; do
        if [ -w "$f" ]; then
            echo "$epp" > "$f" 2>/dev/null || true
        fi
    done

    # 5. Save state to file
    echo "$target" > "$STATE_FILE"

    # 6. Send notification
    local label="Balanced"
    local color="rgb(15,88,128)"
    if [ "$target" = "power-saver" ]; then
        label="Power Saver"
        color="rgb(14,161,111)"
    elif [ "$target" = "performance" ]; then
        label="Performance"
        color="rgb(229,83,75)"
    fi

    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl notify 1 2000 "$color" "Power Profile: ${label}" >/dev/null 2>&1 || true
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send "Power Profile" "Switched to ${label}" -i battery >/dev/null 2>&1 || true
    fi

    echo "Set power profile to $target"
}

toggle_profile() {
    local current
    current=$(get_profile)
    case "$current" in
        power-saver)
            set_profile "balanced"
            ;;
        balanced)
            set_profile "performance"
            ;;
        performance)
            set_profile "power-saver"
            ;;
        *)
            set_profile "balanced"
            ;;
    esac
}

case "${1:-get}" in
    get)
        get_profile
        ;;
    set)
        if [ -n "${2:-}" ]; then
            set_profile "$2"
        else
            echo "Usage: $0 set <power-saver|balanced|performance>" >&2
            exit 1
        fi
        ;;
    toggle|cycle)
        toggle_profile
        ;;
    power-saver|balanced|performance)
        set_profile "$1"
        ;;
    *)
        echo "Usage: $0 {get|set <profile>|toggle}" >&2
        exit 1
        ;;
esac
