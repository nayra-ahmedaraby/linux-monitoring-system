#!/bin/bash
# Security module for file integrity checking and baseline management
#
# IMPORTANT: This script does NOT auto-update the baseline when changes
# are detected. A real change should be reviewed by an admin. To accept
# changes after manual review, delete the baseline file and re-run.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/config.conf" 2>/dev/null

BASELINE_FILE="${BASELINE_DIR:-./baseline}/passwd.hash"
mkdir -p "$(dirname "$BASELINE_FILE")"

now=$(date "+%Y-%m-%d %H:%M:%S")
current_hash=$(md5sum /etc/passwd | awk '{print $1}')

if [ ! -f "$BASELINE_FILE" ]; then
    echo "$current_hash" > "$BASELINE_FILE"
    echo "FILE_INTEGRITY|baseline_created|OK|${now}"
else
    old_hash=$(cat "$BASELINE_FILE")
    if [ "$current_hash" = "$old_hash" ]; then
        echo "FILE_INTEGRITY|unchanged|OK|${now}"
    else
        # Baseline is intentionally NOT updated here - tampering must
        # remain visible until an admin explicitly resets it.
        echo "FILE_INTEGRITY|passwd_changed|CRITICAL|${now}"
    fi
fi
