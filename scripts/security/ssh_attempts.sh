#!/bin/bash
# Security module for monitoring SSH authentication attempts

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/config.conf" 2>/dev/null

now=$(date '+%Y-%m-%d %H:%M:%S')

# Debian/Kali uses auth.log, Red Hat uses secure
if [ -r /var/log/auth.log ]; then
    failed_ssh=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null)
elif [ -r /var/log/secure ]; then
    failed_ssh=$(grep -c "Failed password" /var/log/secure 2>/dev/null)
else
    failed_ssh=0
fi

status="OK"
[ "$failed_ssh" -ge 5 ]  && status="WARNING"
[ "$failed_ssh" -ge 20 ] && status="CRITICAL"

echo "FAILED_SSH|${failed_ssh}|${status}|${now}"
