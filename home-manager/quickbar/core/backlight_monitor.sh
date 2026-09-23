#!/usr/bin/env bash

# core/backlight_monitor.sh - High-speed sysfs backlight monitor with udev event integration

s_b=$(ls /sys/class/backlight/*/brightness 2>/dev/null | head -n 1)
s_m=$(ls /sys/class/backlight/*/max_brightness 2>/dev/null | head -n 1)
k_b=$(ls /sys/class/leds/*kbd_backlight*/brightness 2>/dev/null | head -n 1)
k_m=$(ls /sys/class/leds/*kbd_backlight*/max_brightness 2>/dev/null | head -n 1)

s_max=100
k_max=1
s_cur=100
k_cur=0

[ -n "$s_m" ] && [ -f "$s_m" ] && read -r s_max < "$s_m"
[ -n "$k_m" ] && [ -f "$k_m" ] && read -r k_max < "$k_m"

echo "MAX_SCREEN $s_max"
echo "MAX_KBD $k_max"

[ -n "$s_b" ] && [ -f "$s_b" ] && read -r s_cur < "$s_b"
[ -n "$k_b" ] && [ -f "$k_b" ] && read -r k_cur < "$k_b"

echo "SCREEN $s_cur"
echo "KBD $k_cur"

PIDFILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickbar-backlight-monitor.pid"

if [ -f "$PIDFILE" ]; then
    old_pid=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$old_pid" ] && [ "$old_pid" != "$$" ] && kill -0 "$old_pid" 2>/dev/null; then
        kill "$old_pid" 2>/dev/null
        sleep 0.05
    fi
fi
echo "$$" > "$PIDFILE"

parent_pid="$PPID"

cleanup() {
    trap - EXIT INT TERM HUP PIPE
    [ -f "$PIDFILE" ] && [ "$(cat "$PIDFILE" 2>/dev/null)" = "$$" ] && rm -f "$PIDFILE" 2>/dev/null
    kill $(jobs -p) 2>/dev/null
    exit 0
}
trap cleanup EXIT INT TERM HUP PIPE

# Event-driven screen brightness monitor via udev (near-instant 0ms response)
if [ -n "$s_b" ]; then
    (
        udevadm monitor --subsystem-match=backlight --udev 2>/dev/null | while read -r line; do
            if [[ "$line" == *"change"* && "$line" == *"backlight"* ]]; then
                if [ -f "$s_b" ]; then
                    read -r val < "$s_b"
                    echo "SCREEN $val"
                fi
            fi
        done
    ) &
fi

# Fast 80ms loop for keyboard backlight & screen fallback (pure bash builtins, zero process forks)
(
    last_k="$k_cur"
    last_s="$s_cur"
    while true; do
        if [ -n "$k_b" ] && [ -f "$k_b" ]; then
            read -r val < "$k_b"
            if [ "$val" != "$last_k" ]; then
                last_k="$val"
                echo "KBD $val"
            fi
        fi
        if [ -n "$s_b" ] && [ -f "$s_b" ]; then
            read -r val < "$s_b"
            if [ "$val" != "$last_s" ]; then
                last_s="$val"
                echo "SCREEN $val"
            fi
        fi
        sleep 0.08
    done
) &

# Monitor parent process and stdin to prevent orphaned processes on reload/exit
while kill -0 "$parent_pid" 2>/dev/null; do
    if read -t 1 -r _; then
        :
    else
        code=$?
        # Code 1 indicates EOF on stdin; code > 128 indicates timeout
        if [ "$code" -eq 1 ]; then
            break
        fi
    fi
done

cleanup
