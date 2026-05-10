#!/bin/bash

timestamp=$(date "+%Y-%m-%d %H:%M:%S")

failed=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)

if [ $failed -ge 10 ]; then
    status="CRITICAL"
elif [ $failed -ge 5 ]; then
    status="WARNING"
else
    status="OK"
fi

echo "FAILED_SSH|$failed|$status|$timestamp"
