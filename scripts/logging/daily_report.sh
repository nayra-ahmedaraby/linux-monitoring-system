#!/bin/bash
# =============================================================================
# daily_report.sh  –  Daily summary report from logs
# Reads alerts.log and system.log, generates a summary of the day's events.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/config.conf"
source "$PROJECT_ROOT/scripts/ui/colors.sh"

REPORT_DATE="${1:-$(date '+%Y-%m-%d')}"   # accepts a date arg, defaults to today
REPORT_FILE="$REPORT_DIR/report_${REPORT_DATE}.txt"

mkdir -p "$REPORT_DIR"

write_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] [DAILY_REPORT] $1" >> "$LOG_FILE"
}

# =============================================================================
# Grep helpers  –  all reads come from the log files
# =============================================================================

# lines from today in a given log file
today_lines() {
    local file="$1"
    [ -f "$file" ] && grep "^\[$REPORT_DATE" "$file" || true
}

count_level() {
    local file="$1" level="$2"
    local n
    n=$(today_lines "$file" | grep -c "\[$level\]" 2>/dev/null)
    echo "${n:-0}"
}

# =============================================================================
# Build the report
# =============================================================================

{
# ── Header ────────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║              DAILY SYSTEM REPORT                     ║"
printf "║  Host: %-19s  Date: %-19s║\n" "$(hostname)" "$REPORT_DATE"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Alert Summary ─────────────────────────────────────────────────────────────
echo -e "${BLUE}${BOLD}ALERT SUMMARY${NC}"

crit=$(count_level "$ALERT_LOG" "CRITICAL")
warn=$(count_level "$ALERT_LOG" "WARN")
info=$(count_level "$LOG_FILE"  "INFO")

echo -e "  ${RED}CRITICAL alerts : $crit${NC}"
echo -e "  ${YELLOW}WARNING  alerts : $warn${NC}"
echo -e "  ${GREEN}INFO     entries: $info${NC}"
echo ""

# ── Top Issues ────────────────────────────────────────────────────────────────
echo -e "${BLUE}${BOLD}TOP ISSUES${NC}"

# CPU criticals
cpu_crits=$(today_lines "$ALERT_LOG" | grep "\[CRITICAL\].*CPU" | wc -l)
if [ "$cpu_crits" -gt 0 ]; then
    cpu_times=$(today_lines "$ALERT_LOG" | grep "\[CRITICAL\].*CPU" | grep -oP '\d{2}:\d{2}:\d{2}' | tr '\n' ', ' | sed 's/,$//')
    echo -e "  ${RED}● CPU${NC}  $cpu_crits critical alert(s)  →  $cpu_times"
else
    echo -e "  ${GREEN}● CPU${NC}  No critical alerts"
fi

# RAM criticals / warnings
ram_crits=$(today_lines "$ALERT_LOG" | grep "\[CRITICAL\].*RAM" | wc -l)
ram_warns=$(today_lines "$ALERT_LOG" | grep "\[WARN\].*RAM"     | wc -l)
if [ "$ram_crits" -gt 0 ] || [ "$ram_warns" -gt 0 ]; then
    echo -e "  ${YELLOW}● RAM${NC}  $ram_crits critical, $ram_warns warning alert(s)"
else
    echo -e "  ${GREEN}● RAM${NC}  No alerts"
fi

# Disk criticals / warnings
disk_crits=$(today_lines "$ALERT_LOG" | grep "\[CRITICAL\].*DISK" | wc -l)
disk_warns=$(today_lines "$ALERT_LOG" | grep "\[WARN\].*DISK"     | wc -l)
if [ "$disk_crits" -gt 0 ] || [ "$disk_warns" -gt 0 ]; then
    echo -e "  ${YELLOW}● DISK${NC}  $disk_crits critical, $disk_warns warning alert(s)"
else
    echo -e "  ${GREEN}● DISK${NC}  No alerts"
fi

echo ""

# ── Service Events ────────────────────────────────────────────────────────────
echo -e "${BLUE}${BOLD}SERVICE EVENTS${NC}"

for svc in $MONITORED_SERVICES; do
    stopped=$(today_lines "$ALERT_LOG" | grep "\[CRITICAL\].*SERVICE.*$svc=STOPPED" | wc -l)
    if [ "$stopped" -gt 0 ]; then
        times=$(today_lines "$ALERT_LOG" | grep "\[CRITICAL\].*SERVICE.*$svc=STOPPED" | grep -oP '\d{2}:\d{2}:\d{2}' | tr '\n' ', ' | sed 's/,$//')
        echo -e "  ${RED}● $svc${NC}  went DOWN $stopped time(s)  →  $times"
    else
        echo -e "  ${GREEN}● $svc${NC}  stable all day"
    fi
done

echo ""

# ── Disk Timing ───────────────────────────────────────────────────────────────
echo -e "${BLUE}${BOLD}DISK ALERTS TIMING${NC}"
disk_events=$(today_lines "$ALERT_LOG" | grep "DISK")
if [ -n "$disk_events" ]; then
    echo "$disk_events" | while read -r line; do
        t=$(echo "$line" | grep -oP '\d{2}:\d{2}:\d{2}')
        mnt=$(echo "$line" | grep -oP 'Mount=\S+' | cut -d= -f2)
        lvl=$(echo "$line" | grep -oP '\[(CRITICAL|WARN)\]' | tr -d '[]')
        echo -e "  ● $t  ${mnt:-unknown}  → $lvl"
    done
else
    echo -e "  ${GREEN}● No disk alerts today${NC}"
fi
echo ""

# ── SSH Attempts (from system.log) ────────────────────────────────────────────
ssh_fails=$(today_lines "$LOG_FILE" | grep -i "ssh.*fail\|failed.*ssh\|ssh_attempts" | wc -l)
if [ "$ssh_fails" -gt 0 ]; then
    last_ssh=$(today_lines "$LOG_FILE" | grep -i "ssh.*fail\|failed.*ssh\|ssh_attempts" | tail -1 | grep -oP '\d{2}:\d{2}:\d{2}')
    echo -e "${BLUE}${BOLD}SSH ACTIVITY${NC}"
    echo -e "  ${RED}● Failed attempts : $ssh_fails${NC}  (last at ${last_ssh:-unknown})"
    echo ""
fi

# ── Footer ────────────────────────────────────────────────────────────────────
echo -e "${DIM}  Generated : $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "  From logs : $LOG_FILE"
echo -e "            : $ALERT_LOG${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"

} | tee "$REPORT_FILE"

write_log "Report saved to $REPORT_FILE"
