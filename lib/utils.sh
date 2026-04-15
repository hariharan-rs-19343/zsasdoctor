#!/usr/bin/env bash
# utils.sh — Shared helpers for zsasdoctor

# Global counters for final report
_PASS_COUNT=0
_WARN_COUNT=0
_FAIL_COUNT=0

register_pass()    { (( _PASS_COUNT++ )); }
register_warning() { (( _WARN_COUNT++ )); }
register_fail()    { (( _FAIL_COUNT++ )); }

# Check if a command exists on PATH
command_exists() {
    command -v "$1" &>/dev/null
}

# Extract the major version number from a version string.
# Handles formats like "17.0.1", "openjdk 17.0.1", "14.2", etc.
extract_major_version() {
    echo "$1" | grep -oE '[0-9]+' | head -1
}

# Ensure a line exists in a file (idempotent append).
ensure_line_in_file() {
    local line="$1"
    local file="$2"
    if ! grep -qF "$line" "$file" 2>/dev/null; then
        echo "$line" >> "$file"
        return 0   # added
    fi
    return 1       # already present
}

# Interactive radio-button selector.
# Usage: radio_select selected_index "Option A" "Option B" ...
# Writes the 0-based selected index into the variable named by $1.
# Navigate with ↑/↓ (or k/j), confirm with Enter.
radio_select() {
    local _result_var="$1"
    shift
    local options=("$@")
    local count=${#options[@]}
    local current=0

    # Hide cursor
    printf "\033[?25l"

    # Draw options
    _radio_draw() {
        local i
        for (( i = 0; i < count; i++ )); do
            if (( i == current )); then
                printf "  ${_CLR_GREEN}● %s${_CLR_RESET}\n" "${options[$i]}"
            else
                printf "  ○ %s\n" "${options[$i]}"
            fi
        done
    }

    # Initial draw
    _radio_draw

    # Read keys
    while true; do
        local key
        IFS= read -rsn1 key

        case "$key" in
            $'\x1b')  # Escape sequence (arrow keys)
                read -rsn2 rest
                case "$rest" in
                    '[A') (( current > 0 )) && (( current-- )) ;;        # Up
                    '[B') (( current < count - 1 )) && (( current++ )) ;; # Down
                esac
                ;;
            k|K) (( current > 0 )) && (( current-- )) ;;               # vim up
            j|J) (( current < count - 1 )) && (( current++ )) ;;        # vim down
            '')  break ;;                                               # Enter
        esac

        # Move cursor up and redraw
        printf "\033[${count}A"
        _radio_draw
    done

    # Show cursor
    printf "\033[?25h"

    eval "$_result_var=$current"
}

# Print aggregated final status line
print_final_status() {
    echo ""
    echo "─────────────────────────────────────────"
    if (( _FAIL_COUNT > 0 )); then
        printf "Final Status: ${_CLR_RED}❌ FAILED${_CLR_RESET}  "
    elif (( _WARN_COUNT > 0 )); then
        printf "Final Status: ${_CLR_YELLOW}⚠  PARTIAL${_CLR_RESET}  "
    else
        printf "Final Status: ${_CLR_GREEN}✅ PASSED${_CLR_RESET}  "
    fi
    echo "(${_PASS_COUNT} passed, ${_WARN_COUNT} warnings, ${_FAIL_COUNT} errors)"
    echo "─────────────────────────────────────────"

    if (( _FAIL_COUNT > 0 )); then
        return "$EXIT_FAIL"
    elif (( _WARN_COUNT > 0 )); then
        return "$EXIT_PARTIAL"
    fi
    return "$EXIT_OK"
}
