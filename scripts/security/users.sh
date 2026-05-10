#!/bin/bash
# Security module for monitoring system users and accounts

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/config.conf" 2>/dev/null

now=$(date '+%Y-%m-%d %H:%M:%S')

users=$(who | wc -l)

status="OK"
[ "$users" -ge 5 ]  && status="WARNING"
[ "$users" -ge 10 ] && status="CRITICAL"

echo "LOGGED_USERS|${users}|${status}|${now}"
