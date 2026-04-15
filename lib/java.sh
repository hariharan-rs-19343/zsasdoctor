#!/usr/bin/env bash
# java.sh — Java validation and auto-configuration

# ── Check ────────────────────────────────────────────────────
check_java() {
    log_section "Java Check"

    # 1. Installed?
    if ! command_exists java; then
        log_error "Java is not installed"
        register_fail
        return 1
    fi

    # 2. Version in range?
    local version_output
    version_output="$(java -version 2>&1 | head -1)"
    local major
    major="$(echo "$version_output" | grep -oE '"[0-9]+\.[0-9]+' | grep -oE '[0-9]+' | head -1)"

    if [[ -z "$major" ]]; then
        # Fallback: try "openjdk 17.0.1" style
        major="$(echo "$version_output" | grep -oE '[0-9]+' | head -1)"
    fi

    if [[ -z "$major" ]]; then
        log_error "Unable to determine Java version"
        register_fail
        return 1
    fi

    if (( major < JAVA_MIN_VERSION || major > JAVA_MAX_VERSION )); then
        log_error "Java ${major} detected — required ${JAVA_MIN_VERSION}–${JAVA_MAX_VERSION}"
        register_fail
        return 1
    fi

    if (( major == JAVA_RECOMMENDED_VERSION )); then
        log_success "Java ${major} installed (recommended)"
    else
        log_success "Java ${major} installed"
    fi
    register_pass

    # 3. JAVA_HOME set?
    if [[ -z "${JAVA_HOME:-}" ]]; then
        log_warning "JAVA_HOME is not set in current environment"
        register_warning
    else
        log_success "JAVA_HOME=${JAVA_HOME}"
        register_pass
    fi

    # 4. JAVA_HOME in shell profile?
    if ! grep -q "JAVA_HOME" "$SHELL_PROFILE" 2>/dev/null; then
        log_warning "JAVA_HOME not found in ${SHELL_PROFILE}"
        register_warning
    fi
}

# ── Fix ──────────────────────────────────────────────────────
fix_java() {
    log_section "Java Auto-Configuration"

    if ! command_exists brew; then
        log_error "Homebrew is required to auto-install Java"
        register_fail
        return 1
    fi

    # Install OpenJDK if missing or wrong version
    local need_install=0
    if ! command_exists java; then
        need_install=1
    else
        local major
        major="$(java -version 2>&1 | grep -oE '"[0-9]+' | tr -d '"' | head -1)"
        [[ -z "$major" ]] && major="$(java -version 2>&1 | grep -oE '[0-9]+' | head -1)"
        if (( major < JAVA_MIN_VERSION || major > JAVA_MAX_VERSION )); then
            need_install=1
        fi
    fi

    if (( need_install )); then
        log_info "Installing OpenJDK ${JAVA_RECOMMENDED_VERSION} via Homebrew..."
        if brew install "openjdk@${JAVA_RECOMMENDED_VERSION}"; then
            log_success "OpenJDK ${JAVA_RECOMMENDED_VERSION} installed"
            register_pass
        else
            log_error "Failed to install OpenJDK ${JAVA_RECOMMENDED_VERSION}"
            register_fail
            return 1
        fi
    else
        log_success "Java already installed with a valid version"
        register_pass
    fi

    # Ensure JAVA_HOME in shell profile (idempotent)
    local java_home_line="export JAVA_HOME=\$(/usr/libexec/java_home -v ${JAVA_RECOMMENDED_VERSION})"
    local path_line='export PATH=$JAVA_HOME/bin:$PATH'

    if ensure_line_in_file "$java_home_line" "$SHELL_PROFILE"; then
        log_success "Added JAVA_HOME to ${SHELL_PROFILE}"
    else
        log_success "JAVA_HOME already in ${SHELL_PROFILE}"
    fi

    ensure_line_in_file "$path_line" "$SHELL_PROFILE"
    register_pass
}
