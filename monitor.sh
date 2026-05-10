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

  --once       Print one dashboard snapshot using mock data (default)
  --real       Print one snapshot using live M1 metrics + mocked M2 signals
  --watch      Live dashboard with mock data, refreshes every ${REFRESH_INTERVAL:-5}s
  --watch-real Live dashboard with real M1 metrics + mocked M2 signals
  --menu       Launch the interactive menu
  --alerts     Run the alert engine (scripts/logging/alerts.sh)
  --test       Run the smoke test suite (tests/smoke_test.sh)
  --help, -h   Show this help

With no option, --once is used.
EOF
}

main() {
    local action="${1:---once}"
    case "$action" in
        --once)       render_dashboard ;;
        --real)       render_dashboard real_metrics_partial ;;
        --watch)      watch_dashboard ;;
        --watch-real) watch_dashboard "${REFRESH_INTERVAL:-5}" real_metrics_partial ;;
        --menu)       run_menu ;;
        --alerts)     bash "$PROJECT_ROOT/scripts/logging/alerts.sh" ;;
        --test)       bash "$PROJECT_ROOT/tests/smoke_test.sh" ;;
        --help|-h)    usage ;;
        *)            printf 'Unknown option: %s\n\n' "$action"
                      usage
                      exit 1
                      ;;
    esac
}

main "$@"
