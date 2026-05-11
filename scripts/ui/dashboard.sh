#!/bin/bash
# UI module - format and display the monitoring dashboard.
#
# Reads metrics in the standardized format: NAME|VALUE|STATUS|TIMESTAMP
# (see docs/output_format.md). Calls M1 + M2 scripts via real_metrics().

UI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$UI_DIR/../.." && pwd)"

# shellcheck source=./colors.sh
source "$UI_DIR/colors.sh"
# shellcheck source=./progress_bar.sh
source "$UI_DIR/progress_bar.sh"
# shellcheck source=../../config.conf
[ -f "$PROJECT_ROOT/config.conf" ] && source "$PROJECT_ROOT/config.conf"

# ---------- helpers ----------

ts_now() { date '+%Y-%m-%d %H:%M:%S'; }

# ---------- metric source ----------
# Calls every M1 + M2 script and concatenates their canonical output.
# Each script prints lines in NAME|VALUE|STATUS|TIMESTAMP format.

real_metrics() {
    # --- M1 Resources ---
    bash "$PROJECT_ROOT/scripts/resources/cpu.sh"     2>/dev/null
    bash "$PROJECT_ROOT/scripts/resources/memory.sh"  2>/dev/null
    bash "$PROJECT_ROOT/scripts/resources/disk.sh"    2>/dev/null
    bash "$PROJECT_ROOT/scripts/resources/load.sh"    2>/dev/null
    bash "$PROJECT_ROOT/scripts/resources/network.sh" 2>/dev/null

    # --- M2 Security ---
    bash "$PROJECT_ROOT/scripts/security/services.sh"       2>/dev/null
    bash "$PROJECT_ROOT/scripts/security/ssh_attempts.sh"   2>/dev/null
    bash "$PROJECT_ROOT/scripts/security/open_ports.sh"     2>/dev/null
    bash "$PROJECT_ROOT/scripts/security/users.sh"          2>/dev/null
    bash "$PROJECT_ROOT/scripts/security/zombies.sh"        2>/dev/null
    bash "$PROJECT_ROOT/scripts/security/file_integrity.sh" 2>/dev/null
}

# ---------- rendering ----------

render_header() {
    clear
    printf '%b' "$CYAN$BOLD"
    echo "=============================================================="
    printf  "   LINUX SYSTEM MONITOR        %s\n" "$(ts_now)"
    echo "=============================================================="
    printf '%b' "$NC"
}

render_footer() {
    local ok="$1" warn="$2" crit="$3"
    echo
    printf '%b' "$BOLD"
    echo "--------------------------------------------------------------"
    printf '  %bOK: %d%b   %bWARNING: %d%b   %bCRITICAL: %d%b\n' \
        "$GREEN"      "$ok"   "$NC" \
        "$YELLOW"     "$warn" "$NC" \
        "$RED$BOLD"   "$crit" "$NC"
    echo "--------------------------------------------------------------"
    printf '%b' "$NC"
}

# render_metric NAME VALUE STATUS TIMESTAMP
# Percentage metrics get a progress bar; everything else gets a value column.
render_metric() {
    local name="$1" value="$2" status="$3" _ts="$4"
    local color icon
    color=$(status_color "$status")
    icon=$(status_icon "$status")

    case "$name" in
        CPU_USAGE|MEMORY_USAGE|DISK_*)
            printf '  %b%s%b  %-18s ' "$color" "$icon" "$NC" "$name"
            render_bar "$value"
            printf '  %b%s%b\n' "$color" "$status" "$NC"
            ;;
        *)
            printf '  %b%s%b  %-18s %-12s %b%s%b\n' \
                "$color" "$icon" "$NC" \
                "$name" "$value" \
                "$color" "$status" "$NC"
            ;;
    esac
}

# Read metric lines from a producer command (default: real_metrics)
# and render them, tallying status counts. Producer must emit lines
# in NAME|VALUE|STATUS|TIMESTAMP format.
render_dashboard() {
    local producer="${1:-real_metrics}"
    local ok=0 warn=0 crit=0
    local name value status timestamp

    render_header
    printf '\n  %bSystem Metrics%b\n\n' "$BOLD" "$NC"

    while IFS='|' read -r name value status timestamp; do
        [ -z "$name" ] && continue
        render_metric "$name" "$value" "$status" "$timestamp"
        case "$status" in
            OK)       ok=$((ok+1)) ;;
            WARNING)  warn=$((warn+1)) ;;
            CRITICAL) crit=$((crit+1)) ;;
        esac
    done < <("$producer")

    render_footer "$ok" "$warn" "$crit"
}

# Continuously refresh until interrupted (Ctrl+C).
# Args: [interval] [producer]
watch_dashboard() {
    local interval="${1:-${REFRESH_INTERVAL:-5}}"
    local producer="${2:-real_metrics}"
    trap 'echo; echo "Stopped."; exit 0' INT
    while true; do
        render_dashboard "$producer"
        printf '\n  %b(refreshing every %ds - Ctrl+C to stop)%b\n' \
            "$DIM" "$interval" "$NC"
        sleep "$interval"
    done
}

# If run directly (not sourced), show one snapshot.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    render_dashboard
fi
