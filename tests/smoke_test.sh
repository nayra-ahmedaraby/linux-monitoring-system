#!/bin/bash
# smoke_test.sh
#
# Verifies each monitoring module produces output in the canonical
# format (NAME|VALUE|STATUS|TIMESTAMP). Reports pass/fail per script
# and exits non-zero if any module fails. Use before integration.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# colors (graceful fallback if ui/colors.sh is missing)
if [ -f "$PROJECT_ROOT/scripts/ui/colors.sh" ]; then
    source "$PROJECT_ROOT/scripts/ui/colors.sh"
else
    GREEN=''; YELLOW=''; RED=''; CYAN=''; BOLD=''; NC=''
fi

# Canonical line format:
#   NAME|VALUE|STATUS|TIMESTAMP
#   - NAME: uppercase identifier
#   - VALUE: any non-pipe text
#   - STATUS: OK, WARNING, or CRITICAL
#   - TIMESTAMP: YYYY-MM-DD HH:MM:SS
LINE_RE='^[A-Z][A-Z0-9_]*\|[^|]+\|(OK|WARNING|CRITICAL)\|[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'

PASS=0
FAIL=0
SKIP=0

pass() { printf '  %b[PASS]%b %-30s %s\n' "$GREEN" "$NC" "$1" "$2"; PASS=$((PASS+1)); }
fail() { printf '  %b[FAIL]%b %-30s %s\n' "$RED"   "$NC" "$1" "$2"; FAIL=$((FAIL+1)); }
skip() { printf '  %b[SKIP]%b %-30s %s\n' "$YELLOW" "$NC" "$1" "$2"; SKIP=$((SKIP+1)); }

# check_format SCRIPT LABEL
# Runs SCRIPT, validates every non-empty line against LINE_RE.
check_format() {
    local script="$1"
    local label="$2"

    if [ ! -f "$script" ]; then
        skip "$label" "(file not found)"
        return
    fi

    local output
    output=$(bash "$script" 2>&1)

    if [ -z "$output" ]; then
        fail "$label" "no output"
        return
    fi

    local valid=0 invalid=0 line first_bad=""
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        if [[ "$line" =~ $LINE_RE ]]; then
            valid=$((valid+1))
        else
            invalid=$((invalid+1))
            [ -z "$first_bad" ] && first_bad="$line"
        fi
    done <<< "$output"

    if [ "$invalid" -eq 0 ] && [ "$valid" -gt 0 ]; then
        pass "$label" "$valid valid line(s)"
    else
        fail "$label" "$valid valid, $invalid invalid"
        [ -n "$first_bad" ] && printf '          first bad line: %s\n' "$first_bad"
    fi
}

# check_runs SCRIPT LABEL [args...]
# Runs SCRIPT with optional args, checks exit code is 0.
check_runs() {
    local script="$1"; shift
    local label="$1"; shift

    if [ ! -f "$script" ]; then
        skip "$label" "(file not found)"
        return
    fi

    if bash "$script" "$@" >/dev/null 2>&1; then
        pass "$label" "exit 0"
    else
        fail "$label" "exit $?"
    fi
}

echo
printf '%b%s%b\n' "$CYAN$BOLD" "===========================================" "$NC"
printf '%b%s%b\n' "$CYAN$BOLD" "  Linux Monitoring System - Smoke Test"     "$NC"
printf '%b%s%b\n' "$CYAN$BOLD" "===========================================" "$NC"
echo

# -------------------- M1 (Resources) --------------------
printf '%b-- M1 Resources (format check) --%b\n' "$BOLD" "$NC"
check_format "$PROJECT_ROOT/scripts/resources/cpu.sh"     "cpu.sh"
check_format "$PROJECT_ROOT/scripts/resources/memory.sh"  "memory.sh"
check_format "$PROJECT_ROOT/scripts/resources/disk.sh"    "disk.sh"
check_format "$PROJECT_ROOT/scripts/resources/load.sh"    "load.sh"
check_format "$PROJECT_ROOT/scripts/resources/network.sh" "network.sh"
echo

# -------------------- M2 (Security) --------------------
printf '%b-- M2 Security (format check) --%b\n' "$BOLD" "$NC"
check_format "$PROJECT_ROOT/scripts/security/services.sh"       "services.sh"
check_format "$PROJECT_ROOT/scripts/security/ssh_attempts.sh"   "ssh_attempts.sh"
check_format "$PROJECT_ROOT/scripts/security/open_ports.sh"     "open_ports.sh"
check_format "$PROJECT_ROOT/scripts/security/users.sh"          "users.sh"
check_format "$PROJECT_ROOT/scripts/security/zombies.sh"        "zombies.sh"
check_format "$PROJECT_ROOT/scripts/security/file_integrity.sh" "file_integrity.sh"
echo

# -------------------- M4 (Logging) --------------------
printf '%b-- M4 Logging (run check) --%b\n' "$BOLD" "$NC"
check_runs "$PROJECT_ROOT/scripts/logging/log_writer.sh"  "log_writer.sh"  --help
check_runs "$PROJECT_ROOT/scripts/logging/log_rotate.sh"  "log_rotate.sh"  --status
check_runs "$PROJECT_ROOT/scripts/logging/alerts.sh"      "alerts.sh"
check_runs "$PROJECT_ROOT/scripts/logging/daily_report.sh" "daily_report.sh"
echo

# -------------------- M3 (UI / controller) --------------------
printf '%b-- M3 UI / controller (run check) --%b\n' "$BOLD" "$NC"
check_runs "$PROJECT_ROOT/monitor.sh" "monitor.sh --help" --help
check_runs "$PROJECT_ROOT/monitor.sh" "monitor.sh --once" --once
echo

# -------------------- Summary --------------------
printf '%b-------------------------------------------%b\n' "$BOLD" "$NC"
printf '  %bPASS: %d%b   %bFAIL: %d%b   %bSKIP: %d%b\n' \
    "$GREEN"  "$PASS" "$NC" \
    "$RED"    "$FAIL" "$NC" \
    "$YELLOW" "$SKIP" "$NC"
printf '%b-------------------------------------------%b\n' "$BOLD" "$NC"

if [ "$FAIL" -eq 0 ]; then
    printf '%bAll modules conform to the contract.%b\n' "$GREEN$BOLD" "$NC"
    exit 0
else
    printf '%b%d module(s) need fixing before integration.%b\n' \
        "$RED$BOLD" "$FAIL" "$NC"
    exit 1
fi
