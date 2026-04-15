#!/usr/bin/env bash
# ant.sh — Apache Ant validation and auto-configuration

# ── Check ────────────────────────────────────────────────────
check_ant() {
    task_start "Ant"

    if ! command_exists ant; then
        task_error_msg "Apache Ant is not installed"
        register_fail
        task_fail
        return 1
    fi

    register_pass

    # Check PATH
    local ant_path
    ant_path="$(which ant 2>/dev/null)"
    if [[ -z "$ant_path" ]]; then
        task_error_msg "Ant not found on PATH"
        register_warning
        task_warn
        return 0
    fi

    # Check shell profile
    if ! grep -qE "ANT_HOME|ant" "$SHELL_PROFILE" 2>/dev/null; then
        task_error_msg "Ant not declared in ${SHELL_PROFILE}"
        register_warning
        task_warn
        return 0
    fi

    task_pass "$(ant -version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
}

# ── Fix ──────────────────────────────────────────────────────
fix_ant() {
    task_start "Ant"

    if ! command_exists brew; then
        task_error_msg "Homebrew is required to auto-install Ant"
        register_fail
        task_fail
        return 1
    fi

    if ! command_exists ant; then
        _stop_spinner
        log_info "Installing Apache Ant via Homebrew..."
        if ! brew install ant; then
            task_error_msg "Failed to install Apache Ant"
            register_fail
            task_fail
            return 1
        fi
    fi

    register_pass
    _stop_spinner
    task_pass "configured"
}
