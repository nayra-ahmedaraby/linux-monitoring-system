#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/config.conf"
source "$PROJECT_ROOT/scripts/ui/colors.sh"

ARCHIVE_DIR="$LOG_DIR/archive"
MAX_ARCHIVES=7

mkdir -p "$LOG_DIR" "$ARCHIVE_DIR"

log_msg() {
    local level="$1" message="$2"
    local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] [LOG_ROTATE] $message" >> "$LOG_FILE"
    case "$level" in
        ERROR) echo -e "${RED}$message${NC}" ;;
        WARN)  echo -e "${YELLOW}$message${NC}" ;;
        *)     echo -e "${GREEN}$message${NC}" ;;
    esac
}

needs_rotation() {
    [ ! -f "$LOG_FILE" ] && return 1
    local size_mb; size_mb=$(du -m "$LOG_FILE" 2>/dev/null | cut -f1)
    [ "${size_mb:-0}" -ge "$MAX_LOG_SIZE_MB" ]
}

do_rotate() {
    local reason="${1:-manual}"
    [ ! -f "$LOG_FILE" ] && echo "No log file to rotate" && return 0
    local timestamp; timestamp=$(date '+%Y%m%d_%H%M%S')
    local rotated="$ARCHIVE_DIR/system_${timestamp}.log"
    cp "$LOG_FILE" "$rotated" || { log_msg "ERROR" "Failed to archive log"; return 1; }
    gzip "$rotated" && rotated="${rotated}.gz"
    > "$LOG_FILE"
    log_msg "INFO" "Log rotated: $(basename "$rotated") (reason: $reason)"
    cleanup_old
}

cleanup_old() {
    local count; count=$(ls -1 "$ARCHIVE_DIR"/system_*.log* 2>/dev/null | wc -l)
    if [ "$count" -gt "$MAX_ARCHIVES" ]; then
        local to_delete=$(( count - MAX_ARCHIVES ))
        ls -1t "$ARCHIVE_DIR"/system_*.log* 2>/dev/null | tail -n "$to_delete" | xargs rm -f
        log_msg "INFO" "Cleaned $to_delete old archive(s)"
    fi
}

show_status() {
    echo -e "${CYAN}${BOLD}=== Log Rotation Status ===${NC}"
    if [ -f "$LOG_FILE" ]; then
        echo "  File:    $LOG_FILE"
        echo "  Size:    $(du -sh "$LOG_FILE" | cut -f1)"
        echo "  Lines:   $(wc -l < "$LOG_FILE")"
        needs_rotation && echo -e "  Status:  ${RED}ROTATION NEEDED${NC}" || echo -e "  Status:  ${GREEN}OK${NC}"
    else
        echo "  No log file found"
    fi
    echo ""
    echo "  Archives: $(ls -1 "$ARCHIVE_DIR"/system_*.log* 2>/dev/null | wc -l) / $MAX_ARCHIVES"
}

case "${1:---status}" in
    --force|-f)  do_rotate "forced" ;;
    --auto|-a)   needs_rotation && do_rotate "size_limit" ;;
    --daily|-d)  do_rotate "daily" ;;
    --status|-s) show_status ;;
    --list|-l)   ls -lh "$ARCHIVE_DIR"/system_*.log* 2>/dev/null || echo "No archives found" ;;
    --help|-h)
        echo "Usage: $0 [--force|--auto|--daily|--status|--list]"
        echo "  --force   Rotate now"
        echo "  --auto    Rotate only if size exceeded"
        echo "  --daily   Daily scheduled rotation"
        echo "  --status  Show status"
        echo "  --list    List archives" ;;
    *) echo "Unknown option. Use --help"; exit 1 ;;
esac
