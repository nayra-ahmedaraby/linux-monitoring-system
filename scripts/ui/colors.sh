#!/bin/bash
# UI module - ANSI color codes and status helpers.
# Source this file before any other UI module:
#     source scripts/ui/colors.sh

# ---------- Foreground colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GREY='\033[0;90m'

# ---------- Backgrounds ----------
RED_BG='\033[41m'
GREEN_BG='\033[42m'
YELLOW_BG='\033[43m'

# ---------- Styles ----------
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
NC='\033[0m'   # reset / no color

# Map a STATUS keyword (OK | WARNING | CRITICAL) to its color escape.
status_color() {
    case "$1" in
        OK)       printf '%b' "$GREEN" ;;
        WARNING)  printf '%b' "$YELLOW" ;;
        CRITICAL) printf '%b' "$RED$BOLD" ;;
        *)        printf '%b' "$NC" ;;
    esac
}

# Map a STATUS keyword to a small icon.
status_icon() {
    case "$1" in
        OK)       printf '%s' "OK" ;;
        WARNING)  printf '%s' "!!" ;;
        CRITICAL) printf '%s' "XX" ;;
        *)        printf '%s' "??" ;;
    esac
}

# Print a colored status badge: status_badge OK
status_badge() {
    local s="$1"
    printf '%b %s %b' "$(status_color "$s")$BOLD" "$s" "$NC"
}
