#!/bin/bash
LOG_DIR="/var/log/sysmonitor"
LOG_FILE="$LOG_DIR/system.log"
REPORT_DIR="$LOG_DIR/reports"
REPORT_DATE=$(date '+%Y-%m-%d')
REPORT_TIME=$(date '+%H:%M:%S')
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
mkdir -p "$LOG_DIR" "$REPORT_DIR"
write_log() {
    local level="$1" message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [DAILY_REPORT] $message" >> "$LOG_FILE"
}
draw_bar() {
    local pct="$1" width=30
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local color
    [ "$pct" -ge 90 ] && color="$RED" || { [ "$pct" -ge 75 ] && color="$YELLOW" || color="$GREEN"; }
    printf "${color}["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "]${NC} ${BOLD}%3d%%${NC}" "$pct"
}
get_cpu() {
    local l1 l2
    l1=$(awk '/^cpu /{print $2,$3,$4,$5}' /proc/stat); sleep 0.3
    l2=$(awk '/^cpu /{print $2,$3,$4,$5}' /proc/stat)
    local u1 n1 s1 i1 u2 n2 s2 i2
    read -r u1 n1 s1 i1 <<< "$l1"; read -r u2 n2 s2 i2 <<< "$l2"
    local tdiff=$(( (u2+n2+s2+i2)-(u1+n1+s1+i1) ))
    local idiff=$(( i2-i1 ))
    local pct=0; [ "$tdiff" -gt 0 ] && pct=$(( (tdiff-idiff)*100/tdiff ))
    echo "$pct"
}
print_dashboard() {
    local cpu_pct; cpu_pct=$(get_cpu)
    local mem_total mem_used mem_pct
    mem_total=$(free -m | awk '/^Mem/{print $2}')
    mem_used=$(free -m | awk '/^Mem/{print $3}')
    mem_pct=$(( mem_used*100/mem_total ))
    local load_avg; load_avg=$(awk '{print $1,$2,$3}' /proc/loadavg)
    local uptime_sec; uptime_sec=$(awk '{print int($1)}' /proc/uptime)
    local uptime_str="${uptime_sec}s"
    local days=$(( uptime_sec/86400 )) hrs=$(( (uptime_sec%86400)/3600 )) mins=$(( (uptime_sec%3600)/60 ))
    uptime_str="${days}d ${hrs}h ${mins}m"
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║         SYSTEM RESOURCE & HEALTH DASHBOARD          ║"
    printf "║  Host: %-20s  Date: %s  ║\n" "$(hostname)" "$REPORT_DATE"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${BLUE}${BOLD}SYSTEM${NC}"
    echo -e "  Uptime:  $uptime_str"
    echo -e "  Kernel:  $(uname -r)"
    echo -e "  OS:      $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -s)"
    echo -e "  Procs:   $(ps aux | wc -l)"
    echo ""
    echo -e "${BLUE}${BOLD}CPU${NC}"
    printf "  Usage:   "; draw_bar "$cpu_pct"; echo ""
    echo -e "  Load:    $load_avg  |  Cores: $(nproc)"
    echo ""
    echo -e "${BLUE}${BOLD}MEMORY${NC}"
    printf "  RAM:     "; draw_bar "$mem_pct"
    echo -e "   ${mem_used}MB / ${mem_total}MB"
    local swap_total swap_used swap_pct=0
    swap_total=$(free -m | awk '/^Swap/{print $2}')
    swap_used=$(free -m | awk '/^Swap/{print $3}')
    if [ "${swap_total:-0}" -gt 0 ]; then
        swap_pct=$(( swap_used*100/swap_total ))
        printf "  Swap:    "; draw_bar "$swap_pct"
        echo -e "   ${swap_used}MB / ${swap_total}MB"
    fi
    echo ""
    echo -e "${BLUE}${BOLD}DISK${NC}"
    df -h --output=pcent,used,avail,target 2>/dev/null | grep -vE "^(Use|tmpfs|devtmpfs|none)" | while read -r pct used avail mnt; do
        local p=${pct%%%}
        echo "$p" | grep -qE '^[0-9]+$' || continue
        printf "  %-15s " "$mnt"; draw_bar "$p"
        echo -e "  ${used} used, ${avail} free"
    done
    echo ""
    echo -e "${BLUE}${BOLD}NETWORK${NC}"
    for iface_dir in /sys/class/net/*/; do
        local iface; iface=$(basename "$iface_dir")
        [ "$iface" = "lo" ] && continue
        local state; state=$(cat "$iface_dir/operstate" 2>/dev/null)
        local ip; ip=$(ip addr show "$iface" 2>/dev/null | awk '/inet /{print $2}' | head -1)
        if [ "$state" = "up" ]; then
            echo -e "  ${GREEN}● ${BOLD}$iface${NC}  UP  |  IP: ${ip:-none}"
        else
            echo -e "  ${RED}● ${BOLD}$iface${NC}  ${RED}DOWN${NC}"
        fi
    done
    echo ""
    echo -e "${BLUE}${BOLD}SERVICES${NC}"
    for svc in sshd cron; do
        if systemctl is-active --quiet "$svc" 2>/dev/null || pgrep -x "$svc" > /dev/null 2>&1; then
            echo -e "  ${GREEN}● ${BOLD}$svc${NC}  RUNNING"
        else
            echo -e "  ${RED}● ${BOLD}$svc${NC}  ${RED}STOPPED ⚠${NC}"
        fi
    done
    echo ""
    echo -e "${BLUE}${BOLD}TOP PROCESSES${NC}"
    printf "  ${DIM}%-20s %6s %6s${NC}\n" "COMMAND" "CPU%" "MEM%"
    ps aux --sort=-%cpu 2>/dev/null | head -6 | tail -5 | awk '{printf "  %-20s %5s%% %5s%%\n", substr($11,1,20), $3, $4}'
    echo ""
    echo -e "${DIM}Generated: $REPORT_DATE $REPORT_TIME | Log: $LOG_FILE${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
}
write_log "INFO" "Dashboard started"
print_dashboard
write_log "INFO" "Dashboard completed"
