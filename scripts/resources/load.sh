#!/bin/bash
# Load monitoring module

source "$(dirname "$0")/../../config.conf"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)

status=$(awk -v v="$load_avg" \
             -v w="$LOAD_WARN_THRESHOLD" \
             -v c="$LOAD_CRIT_THRESHOLD" \
    'BEGIN {
        if (v+0 >= c) print "CRITICAL"
        else if (v+0 >= w) print "WARNING"
        else print "OK"
    }')

echo "LOAD_AVG_1M|${load_avg}|${status}|${TIMESTAMP}"