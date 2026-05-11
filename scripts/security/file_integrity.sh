#!/bin/bash
# Security module for file integrity checking.
# Detects tampering of critical system files by comparing MD5 hashes.
#
# To accept legitimate changes after manual review:
#     rm baseline/file_hashes.txt
#     bash scripts/security/file_integrity.sh    # creates new baseline

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/config.conf" 2>/dev/null

# Files to watch
WATCHED_FILES="/etc/passwd /etc/shadow /etc/sudoers /etc/hosts /etc/ssh/sshd_config"

BASELINE_FILE="${BASELINE_DIR:-./baseline}/file_hashes.txt"
mkdir -p "$(dirname "$BASELINE_FILE")"

now=$(date "+%Y-%m-%d %H:%M:%S")

# Build current hashes for files that are readable
build_current() {
    local f
    for f in $WATCHED_FILES; do
        [ -r "$f" ] && md5sum "$f" 2>/dev/null
    done
}

# First run -> create baseline
if [ ! -f "$BASELINE_FILE" ]; then
    build_current > "$BASELINE_FILE"
    count=$(wc -l < "$BASELINE_FILE" 2>/dev/null || echo 0)
    echo "FILE_INTEGRITY|baseline_created_${count}_files|OK|${now}"
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

# Status logic:
#   OK       - everything matches
#   WARNING  - file(s) became unreadable but no tampering detected
#   CRITICAL - any file content changed (tampering possibility)
if [ "$changed" -gt 0 ]; then
    echo "FILE_INTEGRITY|${changed}_changed_${missing}_missing|CRITICAL|${now}"
elif [ "$missing" -gt 0 ]; then
    echo "FILE_INTEGRITY|${missing}_missing|WARNING|${now}"
else
    echo "FILE_INTEGRITY|all_intact|OK|${now}"
fi
