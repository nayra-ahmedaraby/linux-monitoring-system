#!/bin/bash
# Install / set up the Linux Monitoring System.
# Idempotent - safe to run more than once.

set -u

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Reuse colors if available, fall back to plain text otherwise.
if [ -f "$PROJECT_ROOT/scripts/ui/colors.sh" ]; then
    # shellcheck source=./scripts/ui/colors.sh
    source "$PROJECT_ROOT/scripts/ui/colors.sh"
else
    GREEN=''; YELLOW=''; RED=''; CYAN=''; BOLD=''; NC=''
fi

# Source config so create_dirs sees LOG_DIR.
[ -f "$PROJECT_ROOT/config.conf" ] && source "$PROJECT_ROOT/config.conf"

# Tools we expect. Most are coreutils so likely already there.
REQUIRED_TOOLS="bash awk grep sed cut tail head sort uniq wc df free ps top date"
OPTIONAL_TOOLS="systemctl journalctl pgrep ss netstat sha256sum"

print_step() { printf '%b> %s%b\n'  "$CYAN$BOLD" "$1" "$NC"; }
ok()         { printf '  %b[OK]%b %s\n'   "$GREEN"  "$NC" "$1"; }
warn()       { printf '  %b[..]%b %s\n'   "$YELLOW" "$NC" "$1"; }
fail()       { printf '  %b[!!]%b %s\n'   "$RED"    "$NC" "$1"; }

check_tools() {
    print_step "Checking required tools"
    local missing=0 t
    for t in $REQUIRED_TOOLS; do
        if command -v "$t" >/dev/null 2>&1; then
            ok "$t"
        else
            fail "$t (missing - install via your package manager)"
            missing=$((missing + 1))
        fi
    done

    print_step "Checking optional tools"
    for t in $OPTIONAL_TOOLS; do
        if command -v "$t" >/dev/null 2>&1; then
            ok "$t"
        else
            warn "$t (optional - some features may degrade)"
        fi
    done

    return "$missing"
}

make_executable() {
    print_step "Making project scripts executable"
    local count=0 f
    while IFS= read -r -d '' f; do
        chmod +x "$f" && count=$((count + 1))
    done < <(find "$PROJECT_ROOT" -type f -name '*.sh' -print0)
    ok "chmod +x applied to $count script(s)"
}

create_dirs() {
    print_step "Creating runtime directories"

    local log_dir="${LOG_DIR:-/var/log/sysmonitor}"
    if mkdir -p "$log_dir" 2>/dev/null; then
        ok "log dir: $log_dir"
    else
        warn "no write access to $log_dir - falling back to ./logs"
        mkdir -p "$PROJECT_ROOT/logs"
        ok "log dir: $PROJECT_ROOT/logs"
    fi

    mkdir -p "$PROJECT_ROOT/baseline"
    ok "baseline dir: $PROJECT_ROOT/baseline"
}

summary() {
    echo
    printf '%b==============================================%b\n' "$BOLD" "$NC"
    printf '%b Setup complete.%b\n' "$GREEN$BOLD" "$NC"
    echo
    echo "  Try one of:"
    echo "    ./monitor.sh --once       # one snapshot"
    echo "    ./monitor.sh --watch      # live view"
    echo "    ./monitor.sh --menu       # interactive menu"
    printf '%b==============================================%b\n' "$BOLD" "$NC"
}

check_tools || true     # don't abort if a few tools are missing
make_executable
create_dirs
summary
