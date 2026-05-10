#!/bin/bash
# Security module for monitoring system services status

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/config.conf" 2>/dev/null

now=$(date '+%Y-%m-%d %H:%M:%S')

# Try both ssh/sshd and cron/crond for cross-distro support
ssh_status=$(systemctl is-active ssh 2>/dev/null \
          || systemctl is-active sshd 2>/dev/null)
cron_status=$(systemctl is-active cron 2>/dev/null \
           || systemctl is-active crond 2>/dev/null)

[ "$ssh_status"  = "active" ] && ssh_st="OK"  || ssh_st="CRITICAL"
[ "$cron_status" = "active" ] && cron_st="OK" || cron_st="CRITICAL"

echo "SSHD_SERVICE|${ssh_status:-inactive}|${ssh_st}|${now}"
echo "CRON_SERVICE|${cron_status:-inactive}|${cron_st}|${now}"
