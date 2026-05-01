#!/bin/bash
# UI module - render a percentage progress bar with status colors.
# Depends on colors.sh (source it before using these functions).

# render_bar VALUE [WIDTH=30] [WARN=70] [CRIT=90]
# VALUE is a percentage 0-100 (integer or float - float is rounded down).
# Output:  [############------------------]  47%
render_bar() {
    local value="${1:-0}"
    local width="${2:-30}"
    local warn="${3:-70}"
    local crit="${4:-90}"

    # Strip decimals so integer arithmetic works.
    local pct="${value%%.*}"
    [ -z "$pct" ] && pct=0
    [ "$pct" -gt 100 ] && pct=100
    [ "$pct" -lt 0 ]   && pct=0

    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))

    # Color based on value vs thresholds.
    local color="$GREEN"
    if   [ "$pct" -ge "$crit" ]; then color="$RED$BOLD"
    elif [ "$pct" -ge "$warn" ]; then color="$YELLOW"
    fi

    # Build the bar pieces.
    local bar_filled="" bar_empty="" i
    for (( i=0; i<filled; i++ )); do bar_filled+="#"; done
    for (( i=0; i<empty;  i++ )); do bar_empty+="-";  done

    printf '%b[%s%b%s]%b %3d%%' \
        "$color" "$bar_filled" "$DIM" "$bar_empty" "$NC" "$pct"
}

# Convenience: print a labeled bar on its own line.
#   render_labeled_bar "CPU" 65
render_labeled_bar() {
    local label="$1"
    local value="$2"
    printf '  %-12s ' "$label"
    render_bar "$value"
    printf '\n'
}
