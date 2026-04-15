#!/usr/bin/env bash
# logger.sh — Coloured, levelled logging for zsasdoctor

# ── ANSI colours ─────────────────────────────────────────────
if [[ -t 1 ]]; then
    _CLR_GREEN="\033[0;32m"
    _CLR_YELLOW="\033[0;33m"
    _CLR_RED="\033[0;31m"
    _CLR_CYAN="\033[0;36m"
    _CLR_RESET="\033[0m"
else
    _CLR_GREEN="" _CLR_YELLOW="" _CLR_RED="" _CLR_CYAN="" _CLR_RESET=""
fi

# ── Logging functions ────────────────────────────────────────

log_info() {
    printf "${_CLR_CYAN}[INFO]${_CLR_RESET} %s\n" "$*"
}

log_success() {
    printf "${_CLR_GREEN}[SUCCESS]${_CLR_RESET} %s\n" "$*"
}

log_warning() {
    printf "${_CLR_YELLOW}[WARNING]${_CLR_RESET} %s\n" "$*"
}

log_error() {
    printf "${_CLR_RED}[ERROR]${_CLR_RESET} %s\n" "$*"
}

# Print a section header
log_section() {
    echo ""
    printf "${_CLR_CYAN}[INFO]${_CLR_RESET} %s\n" "$*"
}
