#!/bin/bash

timestamp=$(date "+%Y-%m-%d %H:%M:%S")

zombies=$(ps aux | awk '{ if ($8=="Z") print }' | wc -l)

if [ $zombies -ge 5 ]; then
    status="CRITICAL"
elif [ $zombies -ge 1 ]; then
    status="WARNING"
else
    status="OK"
fi

echo "ZOMBIE_PROCESSES|$zombies|$status|$timestamp"
