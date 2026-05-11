#!/bin/bash
# Setup automatic scheduling via cron.
# Adds 4 jobs to your user crontab without touching existing entries.
#
# Usage:
#   ./setup_cron.sh          # add monitoring jobs
#   ./setup_cron.sh --remove # remove monitoring jobs
#   ./setup_cron.sh --show   # show current monitoring jobs

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER="# linux-monitoring-system"

# Colors (graceful fallback)
if [ -f "$PROJECT_ROOT/scripts/ui/colors.sh" ]; then
    source "$PROJECT_ROOT/scripts/ui/colors.sh"
else
    GREEN=''; YELLOW=''; RED=''; CYAN=''; BOLD=''; NC=''
fi

print_step() { printf '%b> %s%b\n' "$CYAN$BOLD" "$1" "$NC"; }
ok()         { printf '  %b[OK]%b %s\n' "$GREEN" "$NC" "$1"; }
warn()       { printf '  %b[..]%b %s\n' "$YELLOW" "$NC" "$1"; }

show_jobs() {
    print_step "Current monitoring cron jobs"
    if crontab -l 2>/dev/null | grep -q "$MARKER"; then
        crontab -l 2>/dev/null | grep -A 1 "$MARKER" | sed 's/^/  /'
    else
        warn "No monitoring jobs installed"
    fi
}

remove_jobs() {
    print_step "Removing monitoring cron jobs"
    if ! crontab -l 2>/dev/null | grep -q "$MARKER"; then
        warn "No monitoring jobs to remove"
        return
    fi
    # Remove the marker line and the next line (the actual cron entry)
    crontab -l 2>/dev/null | sed "/$MARKER/,+1d" | crontab -
    ok "Monitoring jobs removed"
}

add_jobs() {
    print_step "Adding monitoring cron jobs"

    # Skip if already installed
    if crontab -l 2>/dev/null | grep -q "$MARKER"; then
        warn "Monitoring jobs already exist - run with --remove first to reinstall"
        return 1
    fi

    # Build the new crontab: existing entries + ours
    {
        crontab -l 2>/dev/null
        echo ""
        echo "$MARKER alerts (every 5 minutes)"
        echo "*/5 * * * * $PROJECT_ROOT/monitor.sh --alerts >/dev/null 2>&1"
        echo ""
        echo "$MARKER file integrity (every hour)"
        echo "0 * * * * $PROJECT_ROOT/scripts/security/file_integrity.sh >/dev/null 2>&1"
        echo ""
        echo "$MARKER log rotation (every hour)"
        echo "0 * * * * $PROJECT_ROOT/scripts/logging/log_rotate.sh --auto >/dev/null 2>&1"
        echo ""
        echo "$MARKER daily report (23:55 every day)"
        echo "55 23 * * * $PROJECT_ROOT/scripts/logging/daily_report.sh >/dev/null 2>&1"
    } | crontab -

    ok "alerts: every 5 minutes"
    ok "file_integrity: every hour"
    ok "log_rotate: every hour (auto-mode, only rotates if needed)"
    ok "daily_report: every day at 23:55"
}

ensure_cron_running() {
    print_step "Checking cron service"
    if systemctl is-active --quiet cron 2>/dev/null \
       || systemctl is-active --quiet crond 2>/dev/null; then
        ok "cron daemon is active"
    else
        warn "cron daemon is NOT running - jobs won't fire"
        echo "  Start it with:"
        echo "    sudo systemctl enable --now cron     # Debian/Kali"
        echo "    sudo systemctl enable --now crond    # Red Hat/CentOS"
    fi
}

case "${1:-}" in
    --remove|-r)
        remove_jobs
        ;;
    --show|-s|--list|-l)
        show_jobs
        ;;
    --help|-h)
        cat <<EOF
Usage: $(basename "$0") [OPTION]

  (no arg)         Install monitoring cron jobs for the current user
  --remove, -r     Remove monitoring cron jobs
  --show, -s       Show currently installed monitoring jobs
  --help, -h       Show this help

The script adds 4 jobs:
  - Alerts engine    (every 5 minutes)
  - File integrity   (every hour)
  - Log rotation     (every hour, auto-mode)
  - Daily report     (every day at 23:55)

Existing crontab entries are preserved.
EOF
        ;;
    "")
        add_jobs
        echo ""
        ensure_cron_running
        echo ""
        show_jobs
        echo ""
        echo "Done. Logs will appear in:"
        echo "  ${LOG_DIR:-/var/log/sysmonitor}/system.log"
        echo "  ${LOG_DIR:-/var/log/sysmonitor}/alerts.log"
        echo "  ${LOG_DIR:-/var/log/sysmonitor}/reports/"
        ;;
    *)
        echo "Unknown option: $1"
        echo "Try: $(basename "$0") --help"
        exit 1
        ;;
esac
