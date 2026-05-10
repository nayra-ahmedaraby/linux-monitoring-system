#!/bin/bash
# Security module for monitoring and managing zombie processes

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/config.conf" 2>/dev/null

now=$(date '+%Y-%m-%d %H:%M:%S')

zombies=$(ps aux | awk '{ if ($8=="Z") print }' | wc -l)

status="OK"
[ "$zombies" -ge 1 ] && status="WARNING"
[ "$zombies" -ge 5 ] && status="CRITICAL"

echo "ZOMBIES|${zombies}|${status}|${now}"
