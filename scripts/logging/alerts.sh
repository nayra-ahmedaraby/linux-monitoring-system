#!/bin/bash
# Alert engine - state-based.
#
# Logs to alerts.log ONLY when a metric's state changes (OK→WARN, WARN→CRIT,
# CRIT→OK, etc.) instead of every run. This avoids inflating the daily report
# with hundreds of duplicate entries when a condition persists.
#
# Always prints current state to screen so the user gets immediate feedback.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/config.conf"
source "$PROJECT_ROOT/scripts/ui/colors.sh"

mkdir -p "$LOG_DIR"

# State file: tracks previous state per metric so we can detect transitions
STATE_FILE="$LOG_DIR/state.txt"
touch "$STATE_FILE" 2>/dev/null

# Live counters - reflect current state (not log entries)
ALERT_COUNT=0
WARN_COUNT=0
OK_COUNT=0
CHANGES_COUNT=0

# ---------- core helpers ----------

get_timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

write_alert_log() {
    local level="$1" component="$2" message="$3"
    local timestamp; timestamp=$(get_timestamp)
    echo "[$timestamp] [$level] [$component] $message" >> "$ALERT_LOG"
    echo "[$timestamp] [$level] [$component] $message" >> "$LOG_FILE"
}

# ---------- state tracking ----------

# prev_state KEY -> previous state for KEY (empty if never seen)
prev_state() {
    grep "^$1=" "$STATE_FILE" 2>/dev/null | tail -1 | cut -d= -f2-
}

# set_state KEY VALUE
set_state() {
    local key="$1" value="$2"
    if grep -q "^${key}=" "$STATE_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$STATE_FILE"
    else
        echo "${key}=${value}" >> "$STATE_FILE"
    fi
}

# ---------- printing ----------

print_alert() {
    local level="$1" component="$2" message="$3" value="$4" threshold="$5"
    case "$level" in
        CRITICAL)
            echo -e "${RED_BG}${BOLD} ⚠ CRITICAL ${NC} ${RED}[$component]${NC} $message"
            [ -n "$value" ] && echo -e "   ${RED}Current: $value | Threshold: $threshold${NC}"
            ALERT_COUNT=$((ALERT_COUNT + 1)) ;;
        WARN)
            echo -e "${YELLOW}${BOLD} ⚡ WARNING ${NC} ${YELLOW}[$component]${NC} $message"
            [ -n "$value" ] && echo -e "   ${YELLOW}Current: $value | Threshold: $threshold${NC}"
            WARN_COUNT=$((WARN_COUNT + 1)) ;;
        OK)
            echo -e "${GREEN} ✓ OK ${NC} ${GREEN}[$component]${NC} $message"
            OK_COUNT=$((OK_COUNT + 1)) ;;
    esac
}

# ---------- the workhorse ----------
#
# evaluate KEY NEW_STATE COMPONENT VALUE THRESHOLD MESSAGE
#   - Always prints current state to screen
#   - Logs to alerts.log ONLY on state change
#
evaluate() {
    local key="$1" new_state="$2" component="$3" value="$4" threshold="$5" message="$6"
    local old_state; old_state=$(prev_state "$key")

    # Always show on screen
    case "$new_state" in
        CRITICAL) print_alert "CRITICAL" "$component" "$message" "$value" "$threshold" ;;
        WARN)     print_alert "WARN"     "$component" "$message" "$value" "$threshold" ;;
        OK)       print_alert "OK"       "$component" "$message" ;;
    esac

    # Log only on state change
    if [ "$old_state" != "$new_state" ]; then
        CHANGES_COUNT=$((CHANGES_COUNT + 1))
        local from="${old_state:-NONE}"
        write_alert_log "$new_state" "$component" \
            "STATE_CHANGE ${from}→${new_state} ${key}=${value:-$message}"
        set_state "$key" "$new_state"
    fi
}

# ---------- checks ----------

check_cpu() {
    echo -e "\n${CYAN}${BOLD}── CPU ──${NC}"
    local l1 l2
    l1=$(awk '/^cpu /{print $2,$3,$4,$5}' /proc/stat); sleep 0.5
    l2=$(awk '/^cpu /{print $2,$3,$4,$5}' /proc/stat)
    local u1 n1 s1 i1 u2 n2 s2 i2
    read -r u1 n1 s1 i1 <<< "$l1"; read -r u2 n2 s2 i2 <<< "$l2"
    local tdiff=$(( (u2+n2+s2+i2)-(u1+n1+s1+i1) ))
    local idiff=$(( i2-i1 ))
    local cpu_pct=0; [ "$tdiff" -gt 0 ] && cpu_pct=$(( (tdiff-idiff)*100/tdiff ))

    local state msg threshold
    if [ "$cpu_pct" -ge "$CPU_CRIT_THRESHOLD" ]; then
        state="CRITICAL"; msg="CPU critically high!"; threshold="${CPU_CRIT_THRESHOLD}%"
    elif [ "$cpu_pct" -ge "$CPU_WARN_THRESHOLD" ]; then
        state="WARN"; msg="CPU usage high"; threshold="${CPU_WARN_THRESHOLD}%"
    else
        state="OK"; msg="CPU normal - ${cpu_pct}%"; threshold=""
    fi
    evaluate "CPU" "$state" "CPU" "${cpu_pct}%" "$threshold" "$msg"
}

check_ram() {
    echo -e "\n${CYAN}${BOLD}── RAM ──${NC}"
    local total used pct
    total=$(free -m | awk '/^Mem/{print $2}')
    used=$(free -m | awk '/^Mem/{print $3}')
    pct=$(( used*100/total ))

    local state msg threshold
    if [ "$pct" -ge "$RAM_CRIT_THRESHOLD" ]; then
        state="CRITICAL"; msg="Memory critically high!"; threshold="${RAM_CRIT_THRESHOLD}%"
    elif [ "$pct" -ge "$RAM_WARN_THRESHOLD" ]; then
        state="WARN"; msg="Memory usage high"; threshold="${RAM_WARN_THRESHOLD}%"
    else
        state="OK"; msg="Memory normal - ${pct}%"; threshold=""
    fi
    evaluate "RAM" "$state" "RAM" "${pct}%" "$threshold" "$msg"
}

check_disk() {
    echo -e "\n${CYAN}${BOLD}── DISK ──${NC}"
    while read -r pct mnt; do
        pct=${pct%%%}
        local state msg threshold
        if [ "$pct" -ge "$DISK_CRIT_THRESHOLD" ]; then
            state="CRITICAL"; msg="Disk almost full: $mnt"; threshold="${DISK_CRIT_THRESHOLD}%"
        elif [ "$pct" -ge "$DISK_WARN_THRESHOLD" ]; then
            state="WARN"; msg="Disk high: $mnt"; threshold="${DISK_WARN_THRESHOLD}%"
        else
            state="OK"; msg="$mnt - ${pct}% used"; threshold=""
        fi
        # Per-mount key so each filesystem has its own state
        evaluate "DISK_$mnt" "$state" "DISK" "${pct}% on $mnt" "$threshold" "$msg"
    done < <(df -h --output=pcent,target | grep -vE "^(Use|tmpfs|devtmpfs)")
}

check_services() {
    echo -e "\n${CYAN}${BOLD}── SERVICES ──${NC}"
    for svc in $MONITORED_SERVICES; do
        local alt=""
        case "$svc" in
            cron)  alt="crond" ;;
            crond) alt="cron"  ;;
            ssh)   alt="sshd"  ;;
            sshd)  alt="ssh"   ;;
        esac

        local state msg
        if systemctl is-active --quiet "$svc" 2>/dev/null \
           || systemctl is-active --quiet "$alt" 2>/dev/null \
           || pgrep -x "$svc" >/dev/null 2>&1 \
           || pgrep -x "$alt" >/dev/null 2>&1; then
            state="OK"; msg="$svc is running"
        else
            state="CRITICAL"; msg="$svc is NOT running!"
        fi
        evaluate "SVC_$svc" "$state" "SVC" "$svc" "" "$msg"
    done
}

# ---------- main ----------

echo -e "${CYAN}${BOLD}"
echo "**********************************************"
echo "       SYSTEM HEALTH ALERT ENGINE            "
echo "        $(date '+%Y-%m-%d %H:%M:%S')         "
echo "**********************************************"
echo -e "${NC}"

# Heartbeat - always logged to system.log so daily_report can confirm checks ran.
# This is the ONLY routine entry; everything else only logs on state change.
echo "[$(get_timestamp)] [INFO] [ALERTS] Check started" >> "$LOG_FILE"

check_cpu
check_ram
check_disk
check_services

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
echo -e " Current state: ${RED}CRITICAL: $ALERT_COUNT${NC} | ${YELLOW}WARN: $WARN_COUNT${NC} | ${GREEN}OK: $OK_COUNT${NC}"
echo -e " ${CYAN}State changes this run: $CHANGES_COUNT${NC}  (only changes are logged)"
echo -e "${BOLD}══════════════════════════════════════════════════${NC}"

if [ "$CHANGES_COUNT" -eq 0 ]; then
    echo "[$(get_timestamp)] [INFO] [ALERTS] No state changes (all metrics stable)" >> "$LOG_FILE"
fi
