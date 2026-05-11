#!/bin/bash
# UI module - interactive menu for the monitoring system.
# Wraps the dashboard, alerts, log tailing and config viewer.

UI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$UI_DIR/../.." && pwd)"

# shellcheck source=./colors.sh
source "$UI_DIR/colors.sh"
# shellcheck source=./dashboard.sh
source "$UI_DIR/dashboard.sh"
# shellcheck source=../../config.conf
[ -f "$PROJECT_ROOT/config.conf" ] && source "$PROJECT_ROOT/config.conf"

print_menu() {
    clear
    printf '%b' "$CYAN$BOLD"
    echo "+----------------------------------------------+"
    echo "|         LINUX SYSTEM MONITOR - MENU          |"
    echo "+----------------------------------------------+"
    printf '%b' "$NC"
    echo
    echo "  1) Show dashboard (snapshot)"
    echo "  2) Watch dashboard (live refresh)"
    echo "  3) Run alert engine"
    echo "  4) Tail system log"
    echo "  5) Show today's report"
    echo "  6) Show current config"
    echo "  q) Quit"
    echo
}

pause() {
    echo
    read -rp "Press Enter to continue..." _
}

action_alerts() {
    local script="$PROJECT_ROOT/scripts/logging/alerts.sh"
    if [ -x "$script" ]; then
        bash "$script"
    else
        printf '%bAlerts script not found or not executable: %s%b\n' \
            "$RED" "$script" "$NC"
    fi
    pause
}

action_tail_log() {
    local file="${LOG_FILE:-/var/log/sysmonitor/system.log}"
    local lines="${DEFAULT_TAIL_LINES:-20}"
    if [ -r "$file" ]; then
        printf '%b-- tail -n %d %s --%b\n' "$CYAN$BOLD" "$lines" "$file" "$NC"
        tail -n "$lines" "$file"
    else
        printf '%bLog file not readable: %s%b\n' "$YELLOW" "$file" "$NC"
    fi
    pause
}

action_daily_report() {
    local script="$PROJECT_ROOT/scripts/logging/daily_report.sh"
    if [ -x "$script" ]; then
        bash "$script"
    else
        printf '%bDaily report script not found: %s%b\n' \
            "$YELLOW" "$script" "$NC"
    fi
    pause
}

action_show_config() {
    local cfg="$PROJECT_ROOT/config.conf"
    printf '%b-- %s --%b\n' "$CYAN$BOLD" "$cfg" "$NC"
    if [ -r "$cfg" ]; then
        cat "$cfg"
    else
        printf '%bConfig file not found.%b\n' "$RED" "$NC"
    fi
    pause
}

run_menu() {
    local choice
    while true; do
        print_menu
        read -rp "Choose an option: " choice
        case "$choice" in
            1)   render_dashboard; pause ;;
            2)   watch_dashboard ;;
            3)   action_alerts ;;
            4)   action_tail_log ;;
            5)   action_daily_report ;;
            6)   action_show_config ;;
            q|Q) echo "Goodbye."; break ;;
            *)   printf '%bInvalid option: %s%b\n' "$RED" "$choice" "$NC"
                 sleep 1
                 ;;
        esac
    done
}

# Run if not sourced.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_menu
fi
