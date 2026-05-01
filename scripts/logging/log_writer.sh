#!/bin/bash
LOG_DIR="/var/log/sysmonitor"
LOG_FILE="$LOG_DIR/system.log"
MAX_LOG_SIZE_MB=50
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
mkdir -p "$LOG_DIR"
get_timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
write_log() {
    local level="${1:-INFO}" component="${2:-SYSTEM}" message="$3"
    local timestamp; timestamp=$(get_timestamp)
    local entry="[$timestamp] [$level] [$component] $message"
    echo "$entry" >> "$LOG_FILE"
    case "$level" in
        CRITICAL|ERROR) echo -e "${RED}${BOLD}$entry${NC}" ;;
        WARN)           echo -e "${YELLOW}$entry${NC}" ;;
        *)              echo -e "${GREEN}$entry${NC}" ;;
    esac
    local size_mb; size_mb=$(du -m "$LOG_FILE" 2>/dev/null | cut -f1)
    if [ "${size_mb:-0}" -ge "$MAX_LOG_SIZE_MB" ]; then
        local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        [ -x "$script_dir/log_rotate.sh" ] && bash "$script_dir/log_rotate.sh" --auto
    fi
}
case "${1:-}" in
    --tail|-t)
        tail -n "${2:-20}" "$LOG_FILE" 2>/dev/null || echo "No log file found" ;;
    --help|-h)
        echo "Usage: $0 [LEVEL] [COMPONENT] \"message\""
        echo "Levels: INFO, WARN, ERROR, CRITICAL" ;;
    *)
        if [ $# -ge 3 ]; then write_log "$1" "$2" "$3"
        elif [ $# -eq 2 ]; then write_log "INFO" "$1" "$2"
        elif [ $# -eq 1 ]; then write_log "INFO" "SYSTEM" "$1"
        else echo "Usage: $0 [LEVEL] [COMPONENT] \"message\""; exit 1
        fi ;;
esac
