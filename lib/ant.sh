#!/usr/bin/env bash
# ant.sh — Apache Ant validation and auto-configuration

# ── Check ────────────────────────────────────────────────────
check_ant() {
    log_section "Ant Check"

    if ! command_exists ant; then
        log_error "Apache Ant is not installed"
        register_fail
        return 1
    fi

    local ant_version_output
    ant_version_output="$(ant -version 2>&1)"
    log_success "Ant installed — ${ant_version_output}"
    register_pass

    # Check that ant is available on PATH
    local ant_path
    ant_path="$(which ant 2>/dev/null)"
    if [[ -n "$ant_path" ]]; then
        log_success "Ant on PATH: ${ant_path}"
        register_pass
    else
        log_warning "Ant not found on PATH"
        register_warning
    fi

    # Check for ANT_HOME or ant reference in shell profile
    if grep -qE "ANT_HOME|ant" "$SHELL_PROFILE" 2>/dev/null; then
        log_success "Ant referenced in ${SHELL_PROFILE}"
    else
        log_warning "Ant not declared in ${SHELL_PROFILE}"
        register_warning
    fi
}

# ── Fix ──────────────────────────────────────────────────────
fix_ant() {
    log_section "Ant Auto-Configuration"

    if ! command_exists brew; then
        log_error "Homebrew is required to auto-install Ant"
        register_fail
        return 1
    fi

    if ! command_exists ant; then
        log_info "Installing Apache Ant via Homebrew..."
        if brew install ant; then
            log_success "Apache Ant installed"
            register_pass
        else
            log_error "Failed to install Apache Ant"
            register_fail
            return 1
        fi
    else
        log_success "Ant already installed"
        register_pass
    fi
}
