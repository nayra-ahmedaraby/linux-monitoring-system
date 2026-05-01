#!/bin/bash
LOG_DIR="/var/log/sysmonitor"
LOG_FILE="$LOG_DIR/system.log"
ALERT_LOG="$LOG_DIR/alerts.log"
CPU_WARN_THRESHOLD=70
CPU_CRIT_THRESHOLD=90
RAM_WARN_THRESHOLD=75
RAM_CRIT_THRESHOLD=90
DISK_WARN_THRESHOLD=80
DISK_CRIT_THRESHOLD=95
MONITORED_SERVICES="sshd cron"
RED='\033[0;31m'
RED_BG='\033[41m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
ALERT_COUNT=0
WARN_COUNT=0
OK_COUNT=0
mkdir -p "$LOG_DIR"
get_timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
write_alert_log() {
    local level="$1" component="$2" message="$3"
    local timestamp; timestamp=$(get_timestamp)
    echo "[$timestamp] [$level] [$component] $message" >> "$ALERT_LOG"
    echo "[$timestamp] [$level] [$component] $message" >> "$LOG_FILE"
}
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
    if [ "$cpu_pct" -ge "$CPU_CRIT_THRESHOLD" ]; then
        print_alert "CRITICAL" "CPU" "CPU critically high!" "${cpu_pct}%" "${CPU_CRIT_THRESHOLD}%"
        write_alert_log "CRITICAL" "CPU" "CPU=${cpu_pct}%"
    elif [ "$cpu_pct" -ge "$CPU_WARN_THRESHOLD" ]; then
        print_alert "WARN" "CPU" "CPU usage high" "${cpu_pct}%" "${CPU_WARN_THRESHOLD}%"
        write_alert_log "WARN" "CPU" "CPU=${cpu_pct}%"
    else
        print_alert "OK" "CPU" "CPU normal - ${cpu_pct}%"
        write_alert_log "INFO" "CPU" "CPU=${cpu_pct}% OK"
    fi
}
check_ram() {
    echo -e "\n${CYAN}${BOLD}── RAM ──${NC}"
    local total used pct
    total=$(free -m | awk '/^Mem/{print $2}')
    used=$(free -m | awk '/^Mem/{print $3}')
    pct=$(( used*100/total ))
    if [ "$pct" -ge "$RAM_CRIT_THRESHOLD" ]; then
        print_alert "CRITICAL" "RAM" "Memory critically high!" "${pct}%" "${RAM_CRIT_THRESHOLD}%"
        write_alert_log "CRITICAL" "RAM" "RAM=${pct}%"
    elif [ "$pct" -ge "$RAM_WARN_THRESHOLD" ]; then
        print_alert "WARN" "RAM" "Memory usage high" "${pct}%" "${RAM_WARN_THRESHOLD}%"
        write_alert_log "WARN" "RAM" "RAM=${pct}%"
    else
        print_alert "OK" "RAM" "Memory normal - ${pct}%"
        write_alert_log "INFO" "RAM" "RAM=${pct}% OK"
    fi
}
check_disk() {
    echo -e "\n${CYAN}${BOLD}── DISK ──${NC}"
    df -h --output=pcent,target | grep -vE "^(Use|tmpfs|devtmpfs)" | while read -r pct mnt; do
        pct=${pct%%%}
        if [ "$pct" -ge "$DISK_CRIT_THRESHOLD" ]; then
            print_alert "CRITICAL" "DISK" "Disk almost full: $mnt" "${pct}%" "${DISK_CRIT_THRESHOLD}%"
            write_alert_log "CRITICAL" "DISK" "Mount=$mnt Usage=${pct}%"
        elif [ "$pct" -ge "$DISK_WARN_THRESHOLD" ]; then
            print_alert "WARN" "DISK" "Disk high: $mnt" "${pct}%" "${DISK_WARN_THRESHOLD}%"
            write_alert_log "WARN" "DISK" "Mount=$mnt Usage=${pct}%"
        else
            print_alert "OK" "DISK" "$mnt - ${pct}% used"
            write_alert_log "INFO" "DISK" "Mount=$mnt Usage=${pct}% OK"
        fi
    done
}
check_services() {
    echo -e "\n${CYAN}${BOLD}── SERVICES ──${NC}"
    for svc in $MONITORED_SERVICES; do
        if systemctl is-active --quiet "$svc" 2>/dev/null || pgrep -x "$svc" > /dev/null 2>&1; then
            print_alert "OK" "SVC" "$svc is running"
            write_alert_log "INFO" "SERVICE" "$svc=RUNNING"
        else
            print_alert "CRITICAL" "SVC" "$svc is NOT running!"
            write_alert_log "CRITICAL" "SERVICE" "$svc=STOPPED"
        fi
    done
}
echo -e "${CYAN}${BOLD}"
echo "**********************************************"
echo "       SYSTEM HEALTH ALERT ENGINE            "
echo "        $(date '+%Y-%m-%d %H:%M:%S')         "
echo "**********************************************"
echo -e "${NC}"
write_alert_log "INFO" "ALERTS" "=== Check started ==="
check_cpu
check_ram
check_disk
check_services
echo ""
echo -e "${BOLD}══════════════════════════════════════${NC}"
echo -e " ${RED}CRITICAL: $ALERT_COUNT${NC} | ${YELLOW}WARNINGS: $WARN_COUNT${NC} | ${GREEN}OK: $OK_COUNT${NC}"
echo -e "${BOLD}══════════════════════════════════════${NC}"
write_alert_log "INFO" "ALERTS" "Done. CRITICAL=$ALERT_COUNT WARN=$WARN_COUNT OK=$OK_COUNT"
