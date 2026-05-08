#!/bin/bash
# Memory monitoring module

source "$(dirname "$0")/../../config.conf"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

memory_usage=$(free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}')

status="OK"

if (( memory_usage >= RAM_CRIT_THRESHOLD )); then
    status="CRITICAL"
elif (( memory_usage >= RAM_WARN_THRESHOLD )); then
    status="WARNING"
fi

echo "MEMORY_USAGE|${memory_usage}|${status}|${TIMESTAMP}"