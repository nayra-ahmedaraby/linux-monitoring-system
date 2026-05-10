 #!/bin/bash
# UI module - format and display the monitoring dashboard.
#
# Reads metrics in the standardized format: NAME|VALUE|STATUS|TIMESTAMP
# (see docs/output_format.md).
#
# Until M1 (resources) and M2 (security) ship their modules, mock_metrics()
# pulls real values from /proc, free, df, systemctl, etc., and emits them
# in the canonical format. When M1/M2 are ready, swap render_dashboard's
# default producer to call their scripts instead.

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

# Categorize a percent value -> status word.
#   classify_pct VALUE WARN CRIT
classify_pct() {
    local v="${1%%.*}" warn="$2" crit="$3"
    [ -z "$v" ] && v=0
    if   [ "$v" -ge "$crit" ]; then echo "CRITICAL"
    elif [ "$v" -ge "$warn" ]; then echo "WARNING"
    else                            echo "OK"
    fi
}

# Same, but for floats (uses awk).
classify_float() {
    local v="$1" warn="$2" crit="$3"
    awk -v v="$v" -v w="$warn" -v c="$crit" 'BEGIN {
        if (v+0 >= c)      print "CRITICAL"
        else if (v+0 >= w) print "WARNING"
        else               print "OK"
    }'
}

# ---------- cross-distro helpers ----------
# Service names differ between distros:
#   cron daemon  -> Debian/Kali = "cron"        | Red Hat = "crond"
#   ssh service  -> Debian/Kali = "ssh.service" | Red Hat = "sshd.service"
#   (binary on both is "sshd", so pgrep -x sshd works everywhere)
# These helpers try the common aliases so the same config works on both.

# is_service_active NAME -> 0 if any alias of NAME is active, 1 otherwise.
is_service_active() {
    local svc="$1" candidate
    local aliases
    case "$svc" in
        cron|crond) aliases="cron crond" ;;
        ssh|sshd)   aliases="ssh sshd" ;;
        *)          aliases="$svc" ;;
    esac
    for candidate in $aliases; do
        systemctl is-active --quiet "$candidate" 2>/dev/null && return 0
        pgrep -x "$candidate" >/dev/null 2>&1 && return 0
    done
    return 1
}

# count_failed_ssh -> number of "Failed password" entries from any source.
# Tries Debian path, then Red Hat path, then journalctl with both unit names.
count_failed_ssh() {
    local count=0 unit
    if [ -r /var/log/auth.log ]; then
        count=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null)
    elif [ -r /var/log/secure ]; then
        count=$(grep -c "Failed password" /var/log/secure 2>/dev/null)
    elif command -v journalctl >/dev/null 2>&1; then
        for unit in ssh sshd; do
            count=$(journalctl -u "$unit" --since "24 hours ago" 2>/dev/null \
                    | grep -c "Failed password")
            [ "${count:-0}" -gt 0 ] && break
        done
    fi
    [ -z "$count" ] && count=0
    echo "$count"
}

# ---------- mock metric source (until M1 + M2 deliver) ----------

# Sample CPU usage from /proc/stat over a short interval.
_sample_cpu() {
    local a b u1 n1 s1 i1 u2 n2 s2 i2 td id
    a=$(awk '/^cpu /{print $2,$3,$4,$5}' /proc/stat); sleep 0.3
    b=$(awk '/^cpu /{print $2,$3,$4,$5}' /proc/stat)
    read -r u1 n1 s1 i1 <<< "$a"
    read -r u2 n2 s2 i2 <<< "$b"
    td=$(( (u2+n2+s2+i2) - (u1+n1+s1+i1) ))
    id=$(( i2 - i1 ))
    [ "$td" -le 0 ] && { echo 0; return; }
    echo $(( (td - id) * 100 / td ))
}

# Emit one metric per line in NAME|VALUE|STATUS|TIMESTAMP form.
mock_metrics() {
    local now; now=$(ts_now)
    local val status

    # CPU
    val=$(_sample_cpu)
    status=$(classify_pct "$val" "$CPU_WARN_THRESHOLD" "$CPU_CRIT_THRESHOLD")
    echo "CPU_USAGE|${val}|${status}|${now}"

    # Memory
    val=$(free -m | awk '/^Mem:/ {printf "%d", $3*100/$2}')
    status=$(classify_pct "$val" "$RAM_WARN_THRESHOLD" "$RAM_CRIT_THRESHOLD")
    echo "MEMORY_USAGE|${val}|${status}|${now}"

    # Disk root
    val=$(df -P / | awk 'NR==2 {gsub("%",""); print $5}')
    status=$(classify_pct "$val" "$DISK_WARN_THRESHOLD" "$DISK_CRIT_THRESHOLD")
    echo "DISK_ROOT|${val}|${status}|${now}"

    # Load average (1-min) - float compare
    val=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    [ -z "$val" ] && val=0
    status=$(classify_float "$val" "$LOAD_WARN_THRESHOLD" "$LOAD_CRIT_THRESHOLD")
    echo "LOAD_AVG_1M|${val}|${status}|${now}"

    # Services (M2 territory) - is_service_active handles distro aliases
    local svc up_name
    for svc in $MONITORED_SERVICES; do
        up_name=$(echo "$svc" | tr '[:lower:]' '[:upper:]')
        if is_service_active "$svc"; then
            echo "${up_name}_SERVICE|active|OK|${now}"
        else
            echo "${up_name}_SERVICE|inactive|CRITICAL|${now}"
        fi
    done

    # Failed SSH attempts (last 24h) - count_failed_ssh handles distro paths
    local failed; failed=$(count_failed_ssh)
    status="OK"
    [ "$failed" -ge 5 ]  && status="WARNING"
    [ "$failed" -ge 20 ] && status="CRITICAL"
    echo "FAILED_SSH|${failed}|${status}|${now}"
}


real_metrics_partial() {
    # --- M1 Resources (live) ---
    bash "$PROJECT_ROOT/scripts/resources/cpu.sh"     2>/dev/null
    bash "$PROJECT_ROOT/scripts/resources/memory.sh"  2>/dev/null
    bash "$PROJECT_ROOT/scripts/resources/disk.sh"    2>/dev/null
    bash "$PROJECT_ROOT/scripts/resources/load.sh"    2>/dev/null
    bash "$PROJECT_ROOT/scripts/resources/network.sh" 2>/dev/null

    # --- M2 Security (live - all scripts now follow canonical format) ---
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

# Read metric lines from a producer command (default: mock_metrics)
# and render them, tallying status counts. Producer must emit lines
# in NAME|VALUE|STATUS|TIMESTAMP format.
render_dashboard() {
    local producer="${1:-mock_metrics}"
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
    local producer="${2:-mock_metrics}"
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
