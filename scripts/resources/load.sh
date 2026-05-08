#!/bin/bash
# Load monitoring module

source "$(dirname "$0")/../../config.conf"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)

status="OK"

load_int=${load_avg%.*}

if (( load_int >= LOAD_CRIT_THRESHOLD )); then
    status="CRITICAL"
elif (( load_int >= LOAD_WARN_THRESHOLD )); then
    status="WARNING"
fi

echo "LOAD_AVG_1M|${load_avg}|${status}|${TIMESTAMP}"