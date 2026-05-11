#!/bin/bash
# Main controller for the Linux Monitoring System.
# Loads config + UI modules and dispatches to dashboard/menu/alerts.

set -u

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./config.conf
source "$PROJECT_ROOT/config.conf"
# shellcheck source=./scripts/ui/colors.sh
source "$PROJECT_ROOT/scripts/ui/colors.sh"
# shellcheck source=./scripts/ui/progress_bar.sh
source "$PROJECT_ROOT/scripts/ui/progress_bar.sh"
# shellcheck source=./scripts/ui/dashboard.sh
source "$PROJECT_ROOT/scripts/ui/dashboard.sh"
# shellcheck source=./scripts/ui/menu.sh
source "$PROJECT_ROOT/scripts/ui/menu.sh"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTION]

  --once       Print one dashboard snapshot and exit (default)
  --watch      Live dashboard, refreshes every ${REFRESH_INTERVAL:-5}s
  --menu       Launch the interactive menu
  --alerts     Run the alert engine (scripts/logging/alerts.sh)
  --help, -h   Show this help

With no option, --once is used.
EOF
}

main() {
    local action="${1:---once}"
    case "$action" in
        --once)     render_dashboard ;;
        --watch)    watch_dashboard ;;
        --menu)     run_menu ;;
        --alerts)   bash "$PROJECT_ROOT/scripts/logging/alerts.sh" ;;
        --help|-h)  usage ;;
        *)          printf 'Unknown option: %s\n\n' "$action"
                    usage
                    exit 1
                    ;;
    esac
}

main "$@"
