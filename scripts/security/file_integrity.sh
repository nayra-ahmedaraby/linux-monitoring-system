#!/bin/bash
# Security module for file integrity checking and baseline management.
#
# Watches multiple security-critical files. Detects tampering by
# comparing MD5 hashes against a saved baseline.
#
# IMPORTANT: When a change is detected, this script does NOT auto-update
# the baseline. The CRITICAL alert keeps showing until an admin explicitly
# acknowledges the change. This is by design - if an attacker tampers
# with /etc/passwd, the alert must remain visible.
#
# Usage:
#   bash file_integrity.sh           # check (default)
#   bash file_integrity.sh --reset   # accept current state as new baseline
#   bash file_integrity.sh --status  # show baseline info
#   bash file_integrity.sh --help

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/config.conf" 2>/dev/null

# Files to watch (override by setting WATCHED_FILES in config.conf)
: "${WATCHED_FILES:=/etc/passwd /etc/shadow /etc/sudoers /etc/hosts /etc/ssh/sshd_config}"

BASELINE_FILE="${BASELINE_DIR:-./baseline}/file_hashes.txt"
mkdir -p "$(dirname "$BASELINE_FILE")"

now=$(date "+%Y-%m-%d %H:%M:%S")

# ---------- helpers ----------

build_current() {
    local f
    for f in $WATCHED_FILES; do
        [ -r "$f" ] && md5sum "$f" 2>/dev/null
    done
}

create_baseline() {
    build_current > "$BASELINE_FILE"
    local count; count=$(wc -l < "$BASELINE_FILE" 2>/dev/null || echo 0)
    echo "FILE_INTEGRITY|baseline_created_${count}_files|OK|${now}"
}

show_status() {
    if [ ! -f "$BASELINE_FILE" ]; then
        echo "No baseline exists. Run without arguments to create one."
        return
    fi
    echo "Baseline: $BASELINE_FILE"
    echo "Created : $(stat -c %y "$BASELINE_FILE" 2>/dev/null || echo unknown)"
    echo "Files watched:"
    awk '{print "  - " $2}' "$BASELINE_FILE"
}

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTION]

  (no arg)    Compare watched files against baseline. Creates baseline
              on first run.
  --reset     Accept current state as new baseline. Use this AFTER
              verifying that the changed files are intentional
              (e.g., you added a new user, edited sudoers, etc.)
  --status    Show what files are tracked and when the baseline was set
  --help, -h  Show this help

Output format: NAME|VALUE|STATUS|TIMESTAMP

Watched files (configurable via WATCHED_FILES in config.conf):
  $WATCHED_FILES
EOF
}

# ---------- dispatch ----------

case "${1:-}" in
    --reset)
        create_baseline
        exit 0
        ;;
    --status)
        show_status
        exit 0
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    "")
        # default - check
        ;;
    *)
        echo "Unknown option: $1" >&2
        show_help
        exit 1
        ;;
esac

# ---------- check (default action) ----------

# First run -> create baseline
if [ ! -f "$BASELINE_FILE" ]; then
    create_baseline
    exit 0
fi

# Subsequent runs -> compare each baseline entry against current hash
changed=0
missing=0
while read -r expected_hash file; do
    [ -z "$file" ] && continue
    if [ ! -r "$file" ]; then
        missing=$((missing + 1))
        continue
    fi
    actual_hash=$(md5sum "$file" 2>/dev/null | awk '{print $1}')
    if [ "$actual_hash" != "$expected_hash" ]; then
        changed=$((changed + 1))
    fi
done < "$BASELINE_FILE"

# Status:
#   OK       - everything matches
#   WARNING  - file(s) unreadable but no tampering detected
#   CRITICAL - any file content changed (tampering possibility)
if [ "$changed" -gt 0 ]; then
    echo "FILE_INTEGRITY|${changed}_changed_${missing}_missing|CRITICAL|${now}"
elif [ "$missing" -gt 0 ]; then
    echo "FILE_INTEGRITY|${missing}_missing|WARNING|${now}"
else
    echo "FILE_INTEGRITY|all_intact|OK|${now}"
fi
