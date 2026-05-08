#!/bin/bash
# Disk monitoring module

source "$(dirname "$0")/../../config.conf"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

disk_usage=$(df / | awk 'NR==2 {
    gsub("%","",$5)
    print $5
}')

status="OK"

if (( disk_usage >= DISK_CRIT_THRESHOLD )); then
    status="CRITICAL"
elif (( disk_usage >= DISK_WARN_THRESHOLD )); then
    status="WARNING"
fi

echo "DISK_ROOT|${disk_usage}|${status}|${TIMESTAMP}"