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

# ── Force ────────────────────────────────────────────────────
force_ant() {
    task_start "Ant (force)"
    _stop_spinner

    if ! command_exists brew; then
        task_error_msg "Homebrew is required"
        register_fail
        task_fail
        return 1
    fi

    if command_exists ant; then
        local ant_source
        ant_source="$(detect_install_source ant)"
        log_info "Detected Ant (installed via ${ant_source})"

        if ! confirm_action "This will remove and reinstall Apache Ant"; then
            log_info "Skipped"
            return 0
        fi

        # Uninstall
        if [[ "$ant_source" == "brew" ]]; then
            log_info "Uninstalling Ant via Homebrew..."
            brew uninstall ant 2>/dev/null || true
        else
            log_info "Manual Ant installation at $(command -v ant) — remove manually if needed"
        fi
    else
        if ! confirm_action "This will install Apache Ant"; then
            log_info "Skipped"
            return 0
        fi
    fi

    # Backup and clean zshrc
    backup_zshrc
    remove_lines_from_file "ANT_HOME" "$SHELL_PROFILE"

    # Fresh install
    log_info "Installing Apache Ant..."
    if ! brew install ant; then
        task_error_msg "Failed to install Apache Ant"
        register_fail
        task_fail
        return 1
    fi

    # Set env vars
    local ant_home_line='export ANT_HOME=$(brew --prefix ant)/libexec'
    local ant_path_line='export PATH=$ANT_HOME/bin:$PATH'
    ensure_line_in_file "$ant_home_line" "$SHELL_PROFILE"
    ensure_line_in_file "$ant_path_line" "$SHELL_PROFILE"

    # Validate
    if command_exists ant; then
        local new_ver
        new_ver="$(ant -version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
        register_pass
        task_pass "Ant ${new_ver}"
    else
        task_error_msg "Ant not available after install"
        register_fail
        task_fail
    fi
}
