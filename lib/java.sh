#!/usr/bin/env bash
# java.sh — Java validation and auto-configuration

# ── Check ────────────────────────────────────────────────────
check_java() {
    task_start "Java"

    # 1. Installed?
    if ! command_exists java; then
        task_error_msg "Java is not installed"
        register_fail
        task_fail
        return 1
    fi

    # 2. Version in range?
    local version_output
    version_output="$(java -version 2>&1 | head -1)"
    local major
    major="$(echo "$version_output" | grep -oE '"[0-9]+\.[0-9]+' | grep -oE '[0-9]+' | head -1)"
    [[ -z "$major" ]] && major="$(echo "$version_output" | grep -oE '[0-9]+' | head -1)"

    if [[ -z "$major" ]]; then
        task_error_msg "Unable to determine Java version"
        register_fail
        task_fail
        return 1
    fi

    if (( major < JAVA_MIN_VERSION || major > JAVA_MAX_VERSION )); then
        task_error_msg "Java ${major} detected — required ${JAVA_MIN_VERSION}–${JAVA_MAX_VERSION}"
        register_fail
        task_fail
        return 1
    fi

    # 3. JAVA_HOME set?
    local warnings=0
    if [[ -z "${JAVA_HOME:-}" ]]; then
        task_error_msg "JAVA_HOME is not set in current environment"
        (( warnings++ ))
        register_warning
    fi
    if ! grep -q "JAVA_HOME" "$SHELL_PROFILE" 2>/dev/null; then
        task_error_msg "JAVA_HOME not found in ${SHELL_PROFILE}"
        (( warnings++ ))
        register_warning
    fi

    register_pass
    if (( warnings > 0 )); then
        task_warn
    else
        task_pass "Java ${major}"
    fi
}

# ── Fix ──────────────────────────────────────────────────────
fix_java() {
    task_start "Java"

    if ! command_exists brew; then
        task_error_msg "Homebrew is required to auto-install Java"
        register_fail
        task_fail
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
        _stop_spinner
        log_info "Installing OpenJDK ${JAVA_RECOMMENDED_VERSION} via Homebrew..."
        if ! brew install "openjdk@${JAVA_RECOMMENDED_VERSION}"; then
            task_error_msg "Failed to install OpenJDK ${JAVA_RECOMMENDED_VERSION}"
            register_fail
            task_fail
            return 1
        fi
        register_pass
    fi

    # Ensure JAVA_HOME in shell profile (idempotent)
    local java_home_line="export JAVA_HOME=\$(/usr/libexec/java_home -v ${JAVA_RECOMMENDED_VERSION})"
    local path_line='export PATH=$JAVA_HOME/bin:$PATH'
    ensure_line_in_file "$java_home_line" "$SHELL_PROFILE"
    ensure_line_in_file "$path_line" "$SHELL_PROFILE"

    register_pass
    _stop_spinner
    task_pass "configured"
}
