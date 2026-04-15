#!/usr/bin/env bash
# logger.sh — Task-based status output for zsasdoctor

# ── ANSI codes ───────────────────────────────────────────────
if [[ -t 1 ]]; then
    _CLR_GREEN="\033[0;32m"
    _CLR_YELLOW="\033[1;33m"
    _CLR_RED="\033[0;31m"
    _CLR_CYAN="\033[0;36m"
    _CLR_DIM="\033[2m"
    _CLR_BOLD="\033[1m"
    _CLR_RESET="\033[0m"
else
    _CLR_GREEN="" _CLR_YELLOW="" _CLR_RED="" _CLR_CYAN="" _CLR_DIM="" _CLR_BOLD="" _CLR_RESET=""
fi

# Spinner frames
_SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

# Current task tracking
_CURRENT_TASK=""
_TASK_ERRORS=()
_SPINNER_PID=""

# ── Spinner control ──────────────────────────────────────────

_start_spinner() {
    local task_name="$1"
    _CURRENT_TASK="$task_name"
    _TASK_ERRORS=()

    # Run spinner in background
    (
        local i=0
        while true; do
            printf "\r  ${_CLR_CYAN}%s${_CLR_RESET} %s" "${_SPINNER_FRAMES[$i]}" "$task_name"
            i=$(( (i + 1) % ${#_SPINNER_FRAMES[@]} ))
            sleep 0.08
        done
    ) &
    _SPINNER_PID=$!
    disown "$_SPINNER_PID" 2>/dev/null
}

_stop_spinner() {
    if [[ -n "$_SPINNER_PID" ]]; then
        kill "$_SPINNER_PID" 2>/dev/null
        wait "$_SPINNER_PID" 2>/dev/null
        _SPINNER_PID=""
        printf "\r\033[K"  # clear the spinner line
    fi
}

# ── Task output API ──────────────────────────────────────────

# Start a named task (shows spinner)
task_start() {
    _start_spinner "$1"
}

# Mark current task as success
task_pass() {
    local detail="${1:-}"
    _stop_spinner
    if [[ -n "$detail" ]]; then
        printf "  ${_CLR_GREEN}✓${_CLR_RESET} %s ${_CLR_DIM}(%s)${_CLR_RESET}\n" "$_CURRENT_TASK" "$detail"
    else
        printf "  ${_CLR_GREEN}✓${_CLR_RESET} %s\n" "$_CURRENT_TASK"
    fi
}

# Mark current task as failed, with error messages below
task_fail() {
    _stop_spinner
    printf "  ${_CLR_RED}✗${_CLR_RESET} %s\n" "$_CURRENT_TASK"
    local msg
    for msg in "${_TASK_ERRORS[@]}"; do
        printf "    ${_CLR_RED}→${_CLR_RESET} %s\n" "$msg"
    done
}

# Mark current task as warning (yellow !)
task_warn() {
    _stop_spinner
    printf "  ${_CLR_YELLOW}!${_CLR_RESET} %s\n" "$_CURRENT_TASK"
    local msg
    for msg in "${_TASK_ERRORS[@]}"; do
        printf "    ${_CLR_YELLOW}→${_CLR_RESET} %s\n" "$msg"
    done
}

# Queue an error message for the current task (shown on task_fail)
task_error_msg() {
    _TASK_ERRORS+=("$*")
}

# ── Legacy wrappers (used by fix commands that print inline) ─
log_info()    { printf "  ${_CLR_DIM}%s${_CLR_RESET}\n" "$*"; }
log_success() { printf "  ${_CLR_GREEN}✓${_CLR_RESET} %s\n" "$*"; }
log_warning() { printf "  ${_CLR_YELLOW}!${_CLR_RESET} %s\n" "$*"; }
log_error()   { printf "  ${_CLR_RED}✗${_CLR_RESET} %s\n" "$*"; }
log_section() { echo ""; }
