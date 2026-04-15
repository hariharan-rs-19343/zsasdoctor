#!/usr/bin/env bash
# utils.sh — Shared helpers for zsasdoctor

# ── Global state ─────────────────────────────────────────────
_PASS_COUNT=0
_WARN_COUNT=0
_FAIL_COUNT=0
FORCE_MODE=0
SKIP_CONFIRM=0

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

# Remove lines matching a pattern from a file.
remove_lines_from_file() {
    local pattern="$1"
    local file="$2"
    if [[ -f "$file" ]]; then
        local tmp
        tmp="$(mktemp)"
        grep -v "$pattern" "$file" > "$tmp" || true
        mv "$tmp" "$file"
    fi
}

# Backup ~/.zshrc before force modifications.
backup_zshrc() {
    local backup="${SHELL_PROFILE}.zsasdoctor.bak"
    if [[ -f "$SHELL_PROFILE" ]]; then
        cp "$SHELL_PROFILE" "$backup"
        log_info "Backed up ${SHELL_PROFILE} → ${backup}"
    fi
}

# Prompt user for confirmation. Returns 0 if confirmed.
# Skipped if SKIP_CONFIRM=1 (--yes flag).
confirm_action() {
    local message="$1"
    if (( SKIP_CONFIRM )); then
        return 0
    fi
    echo ""
    printf "  ${_CLR_YELLOW}${_CLR_BOLD}⚠ %s${_CLR_RESET}\n" "$message"
    local answer
    read -rp "  Continue? (y/n): " answer
    case "$answer" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

# Detect how a tool was installed (brew, manual, sdkman, unknown).
detect_install_source() {
    local cmd="$1"
    local cmd_path
    cmd_path="$(command -v "$cmd" 2>/dev/null)" || true

    if [[ -z "$cmd_path" ]]; then
        echo "none"
        return
    fi

    if [[ "$cmd_path" == *"/homebrew/"* || "$cmd_path" == *"/opt/homebrew/"* || "$cmd_path" == *"/usr/local/Cellar/"* ]]; then
        echo "brew"
    elif [[ "$cmd_path" == *".sdkman"* ]]; then
        echo "sdkman"
    else
        echo "manual"
    fi
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
    printf "\n"
    if (( _FAIL_COUNT > 0 )); then
        printf "  ${_CLR_RED}${_CLR_BOLD}✗ FAILED${_CLR_RESET}  "
    elif (( _WARN_COUNT > 0 )); then
        printf "  ${_CLR_YELLOW}${_CLR_BOLD}! PARTIAL${_CLR_RESET}  "
    else
        printf "  ${_CLR_GREEN}${_CLR_BOLD}✓ Great! Your system environment is ready for development.${_CLR_RESET}  "
    fi
    printf "${_CLR_DIM}(%d passed, %d warnings, %d errors)${_CLR_RESET}\n" "$_PASS_COUNT" "$_WARN_COUNT" "$_FAIL_COUNT"
    printf "\n"

    if (( _FAIL_COUNT > 0 )); then
        return "$EXIT_FAIL"
    elif (( _WARN_COUNT > 0 )); then
        return "$EXIT_PARTIAL"
    fi
    return "$EXIT_OK"
}
