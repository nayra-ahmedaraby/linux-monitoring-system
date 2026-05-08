#!/bin/bash
# CPU monitoring module

source "$(dirname "$0")/../../config.conf"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

cpu_usage=$(top -bn1 | awk '/Cpu\(s\)/ {print int(100 - $8)}')

status="OK"

if (( cpu_usage >= CPU_CRIT_THRESHOLD )); then
    status="CRITICAL"
elif (( cpu_usage >= CPU_WARN_THRESHOLD )); then
    status="WARNING"
fi

echo "CPU_USAGE|${cpu_usage}|${status}|${TIMESTAMP}"