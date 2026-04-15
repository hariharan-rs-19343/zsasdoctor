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

# ── Force ────────────────────────────────────────────────────
force_java() {
    task_start "Java (force)"
    _stop_spinner

    if ! command_exists brew; then
        task_error_msg "Homebrew is required"
        register_fail
        task_fail
        return 1
    fi

    # Detect current state
    local current_version=""
    local source="none"
    if command_exists java; then
        current_version="$(java -version 2>&1 | grep -oE '"[0-9]+' | tr -d '"' | head -1)"
        [[ -z "$current_version" ]] && current_version="$(java -version 2>&1 | grep -oE '[0-9]+' | head -1)"
        source="$(detect_install_source java)"
        log_info "Detected Java ${current_version} (installed via ${source})"
    else
        log_info "No existing Java installation found"
    fi

    # Confirm
    if ! confirm_action "This will remove existing Java and reinstall OpenJDK ${JAVA_RECOMMENDED_VERSION}"; then
        log_info "Skipped"
        return 0
    fi

    # Backup ~/.zshrc
    backup_zshrc

    # Uninstall based on source
    if [[ "$source" == "brew" ]]; then
        log_info "Uninstalling Java via Homebrew..."
        # Remove all openjdk versions installed via brew
        local formula
        for formula in $(brew list --formula 2>/dev/null | grep -i "openjdk"); do
            brew uninstall --ignore-dependencies "$formula" 2>/dev/null || true
        done
    elif [[ "$source" == "sdkman" ]]; then
        log_info "Uninstalling Java via SDKMAN..."
        if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
            source "$HOME/.sdkman/bin/sdkman-init.sh"
            sdk uninstall java 2>/dev/null || true
        fi
    elif [[ "$source" == "manual" ]]; then
        log_info "Manual Java installation detected at $(command -v java)"
        log_info "You may need to remove it from /Library/Java/JavaVirtualMachines manually"
    fi

    # Clean old JAVA_HOME entries from zshrc
    remove_lines_from_file "JAVA_HOME" "$SHELL_PROFILE"

    # Install fresh
    log_info "Installing OpenJDK ${JAVA_RECOMMENDED_VERSION}..."
    if ! brew install "openjdk@${JAVA_RECOMMENDED_VERSION}"; then
        task_error_msg "Failed to install OpenJDK ${JAVA_RECOMMENDED_VERSION}"
        register_fail
        task_fail
        return 1
    fi

    # Symlink for system java wrappers
    local jdk_path
    jdk_path="$(brew --prefix "openjdk@${JAVA_RECOMMENDED_VERSION}")/libexec/openjdk.jdk"
    if [[ -d "$jdk_path" ]]; then
        sudo ln -sfn "$jdk_path" "/Library/Java/JavaVirtualMachines/openjdk-${JAVA_RECOMMENDED_VERSION}.jdk" 2>/dev/null || true
    fi

    # Set fresh env vars in zshrc
    local java_home_line="export JAVA_HOME=\$(/usr/libexec/java_home -v ${JAVA_RECOMMENDED_VERSION})"
    local path_line='export PATH=$JAVA_HOME/bin:$PATH'
    ensure_line_in_file "$java_home_line" "$SHELL_PROFILE"
    ensure_line_in_file "$path_line" "$SHELL_PROFILE"

    # Validate
    export JAVA_HOME="$(/usr/libexec/java_home -v ${JAVA_RECOMMENDED_VERSION} 2>/dev/null)" || true
    export PATH="$JAVA_HOME/bin:$PATH"

    if command_exists java; then
        local new_ver
        new_ver="$(java -version 2>&1 | grep -oE '"[0-9]+' | tr -d '"' | head -1)"
        register_pass
        task_pass "Java ${new_ver}"
    else
        task_error_msg "Java not available after install"
        register_fail
        task_fail
    fi
}
