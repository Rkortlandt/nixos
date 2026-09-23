#!/usr/bin/env bash

# CPU Usage from /proc/stat
STATE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickbar_cpu_stat"
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
curr_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
curr_idle=$((idle + iowait))

cpu=0
if [ -f "$STATE_FILE" ]; then
    read -r last_total last_idle < "$STATE_FILE"
    diff_total=$((curr_total - last_total))
    diff_idle=$((curr_idle - last_idle))
    if [ "$diff_total" -gt 0 ]; then
        cpu=$((( (diff_total - diff_idle) * 100 ) / diff_total))
    fi
fi
echo "$curr_total $curr_idle" > "$STATE_FILE"

# RAM Usage from /proc/meminfo
total=1
avail=1
while read -r key val _; do
    case "$key" in
        MemTotal:) total="$val" ;;
        MemAvailable:) avail="$val" ;;
    esac
    [ "$avail" -gt 1 ] && [ "$total" -gt 1 ] && break
done < /proc/meminfo
ram=$((( (total - avail) * 100 ) / total))

# CPU Temp from sysfs thermal
temp=0
for t in /sys/class/thermal/thermal_zone*/temp; do
    if [ -f "$t" ]; then
        read -r raw < "$t"
        if [ -n "$raw" ] && [ "$raw" -gt 0 ]; then
            temp=$((raw / 1000))
            break
        fi
    fi
done

echo "$cpu $ram $temp"
