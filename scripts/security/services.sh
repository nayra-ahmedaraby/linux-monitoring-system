#!/bin/bash

timestamp=$(date "+%Y-%m-%d %H:%M:%S")

ssh_status=$(systemctl is-active ssh 2>/dev/null)
cron_status=$(systemctl is-active cron 2>/dev/null)

if [ "$ssh_status" = "active" ]; then
    ssh_class="OK"
else
    ssh_class="CRITICAL"
fi

if [ "$cron_status" = "active" ]; then
    cron_class="OK"
else
    cron_class="CRITICAL"
fi

echo "SSHD_SERVICE|$ssh_status|$ssh_class|$timestamp"
echo "CRON_SERVICE|$cron_status|$cron_class|$timestamp"
