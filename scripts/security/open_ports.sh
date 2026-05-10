#!/bin/bash
# Security module for monitoring open network ports
# Note: M1's network.sh emits a generic OPEN_PORTS list. This script
# focuses on the security angle - flagging suspicious ports from config.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/config.conf" 2>/dev/null

now=$(date '+%Y-%m-%d %H:%M:%S')

ports=$(ss -tuln | awk 'NR>1 {print $5}' | cut -d':' -f2 | sort -u | tr '\n' ',' | sed 's/,$//')

# Flag suspicious ports defined in config.conf
suspicious=""
for sp in $SUSPICIOUS_PORTS; do
    echo "$ports" | tr ',' '\n' | grep -qx "$sp" && suspicious="${suspicious}${sp},"
done
suspicious=${suspicious%,}

if [ -n "$suspicious" ]; then
    echo "SUSPICIOUS_PORTS|${suspicious}|CRITICAL|${now}"
else
    echo "SUSPICIOUS_PORTS|none|OK|${now}"
fi
