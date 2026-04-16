#!/usr/bin/env bash
# database.sh — PostgreSQL / MySQL validation and auto-configuration

# ── Check ────────────────────────────────────────────────────
check_database() {
    task_start "Database"

    local detail_parts=()
    local has_valid=0

    # ── PostgreSQL ───────────────────────────────────────────
    if command_exists psql; then
        local pg_major
        pg_major="$(extract_major_version "$(psql --version 2>&1)")"

        if [[ -n "$pg_major" ]] && (( pg_major >= POSTGRES_MIN_VERSION )); then
            detail_parts+=("PostgreSQL ${pg_major}")
            has_valid=1
            register_pass
        elif [[ -n "$pg_major" ]]; then
            task_error_msg "PostgreSQL ${pg_major} — required >= ${POSTGRES_MIN_VERSION}"
        fi
    fi

    # ── MySQL ────────────────────────────────────────────────
    if command_exists mysql; then
        local my_major
        my_major="$(extract_major_version "$(mysql --version 2>&1)")"

        if [[ -n "$my_major" ]] && (( my_major >= MYSQL_MIN_VERSION && my_major <= MYSQL_MAX_VERSION )); then
            detail_parts+=("MySQL ${my_major}")
            has_valid=1
            register_pass
        elif [[ -n "$my_major" ]]; then
            task_error_msg "MySQL ${my_major} — required ${MYSQL_MIN_VERSION}–${MYSQL_MAX_VERSION}"
        fi
    fi

    # At least one valid database is enough
    if (( has_valid )); then
        local detail
        detail="$(IFS=', '; echo "${detail_parts[*]}")"
        task_pass "$detail"
        return 0
    fi

    # No valid database at all
    if (( ${#_TASK_ERRORS[@]} == 0 )); then
        task_error_msg "No database (PostgreSQL or MySQL) found"
    fi
    register_fail
    task_fail
    return 1
}

# ── Fix ──────────────────────────────────────────────────────
fix_database() {
    task_start "Database"
    _stop_spinner

    if ! command_exists brew; then
        task_error_msg "Homebrew is required to auto-install databases"
        register_fail
        task_fail
        return 1
    fi

    # Ask user to pick one database (radio-button style)
    echo ""
    echo "  Select a database to install (↑/↓ to move, Enter to confirm):"
    echo ""

    local choice
    radio_select choice \
        "PostgreSQL ${POSTGRES_MAX_VERSION} (Recommended)" \
        "MySQL ${MYSQL_MAX_VERSION}"

    echo ""
    case "$choice" in
        0) _install_postgres ;;
        1) _install_mysql ;;
    esac
}

_install_postgres() {
    task_start "PostgreSQL"

    if ! command_exists psql; then
        _stop_spinner
        log_info "Installing PostgreSQL ${POSTGRES_MAX_VERSION} via Homebrew..."
        if ! brew install "postgresql@${POSTGRES_MAX_VERSION}"; then
            task_error_msg "Failed to install PostgreSQL"
            register_fail
            task_fail
            return 1
        fi
        register_pass

        _stop_spinner
        log_info "Starting PostgreSQL service..."
        if ! brew services start "postgresql@${POSTGRES_MAX_VERSION}"; then
            task_error_msg "Could not start PostgreSQL service automatically"
            register_warning
        fi
    fi

    # Ensure PostgreSQL home path in shell profile (idempotent)
    local pg_home_line="export POSTGRES_HOME=\$(brew --prefix postgresql@${POSTGRES_MAX_VERSION})"
    local pg_path_line='export PATH=$POSTGRES_HOME/bin:$PATH'
    ensure_line_in_file "$pg_home_line" "$SHELL_PROFILE"
    ensure_line_in_file "$pg_path_line" "$SHELL_PROFILE"

    register_pass
    _stop_spinner
    task_pass "configured"
}

_install_mysql() {
    task_start "MySQL"

    if ! command_exists mysql; then
        _stop_spinner
        log_info "Installing MySQL ${MYSQL_MAX_VERSION} via Homebrew..."
        if ! brew install "mysql@${MYSQL_MAX_VERSION}"; then
            task_error_msg "Failed to install MySQL"
            register_fail
            task_fail
            return 1
        fi
        register_pass
    fi

    # Ensure MySQL home path in shell profile (idempotent)
    local my_home_line="export MYSQL_HOME=\$(brew --prefix mysql@${MYSQL_MAX_VERSION})"
    local my_path_line='export PATH=$MYSQL_HOME/bin:$PATH'
    ensure_line_in_file "$my_home_line" "$SHELL_PROFILE"
    ensure_line_in_file "$my_path_line" "$SHELL_PROFILE"

    register_pass
    _stop_spinner
    task_pass "configured"
}

# ── Force ────────────────────────────────────────────────────
force_database() {
    task_start "Database (force)"
    _stop_spinner

    if ! command_exists brew; then
        task_error_msg "Homebrew is required"
        register_fail
        task_fail
        return 1
    fi

    # Ask user to pick one database
    echo ""
    echo "  Select a database to force install (↑/↓ to move, Enter to confirm):"
    echo ""

    local choice
    radio_select choice \
        "PostgreSQL ${POSTGRES_MAX_VERSION} (Recommended)" \
        "MySQL ${MYSQL_MAX_VERSION}"

    echo ""
    case "$choice" in
        0) _force_postgres ;;
        1) _force_mysql ;;
    esac
}

_force_postgres() {
    task_start "PostgreSQL (force)"
    _stop_spinner

    # Warn about data loss
    if command_exists psql; then
        local pg_source
        pg_source="$(detect_install_source psql)"
        log_info "Detected PostgreSQL (installed via ${pg_source})"

        if ! confirm_action "This will remove existing PostgreSQL. Databases may be lost."; then
            log_info "Skipped"
            return 0
        fi

        # Backup data if pg_dumpall is available
        if command_exists pg_dumpall; then
            local dump_file="$HOME/pg_backup_$(date +%Y%m%d_%H%M%S).sql"
            log_info "Backing up databases → ${dump_file}"
            pg_dumpall > "$dump_file" 2>/dev/null || log_info "Backup skipped (server may not be running)"
        fi

        # Stop and uninstall
        log_info "Stopping PostgreSQL service..."
        brew services stop postgresql 2>/dev/null || true
        local formula
        for formula in $(brew list --formula 2>/dev/null | grep -i "postgresql"); do
            brew services stop "$formula" 2>/dev/null || true
            log_info "Uninstalling ${formula}..."
            brew uninstall --ignore-dependencies "$formula" 2>/dev/null || true
        done
    else
        if ! confirm_action "This will install PostgreSQL ${POSTGRES_MAX_VERSION}"; then
            log_info "Skipped"
            return 0
        fi
    fi

    # Backup and clean zshrc
    backup_zshrc
    remove_lines_from_file "POSTGRES_HOME" "$SHELL_PROFILE"

    # Fresh install
    log_info "Installing PostgreSQL ${POSTGRES_MAX_VERSION}..."
    if ! brew install "postgresql@${POSTGRES_MAX_VERSION}"; then
        task_error_msg "Failed to install PostgreSQL ${POSTGRES_MAX_VERSION}"
        register_fail
        task_fail
        return 1
    fi

    log_info "Starting PostgreSQL service..."
    brew services start "postgresql@${POSTGRES_MAX_VERSION}" 2>/dev/null || true

    # Set env vars
    local pg_home_line="export POSTGRES_HOME=\$(brew --prefix postgresql@${POSTGRES_MAX_VERSION})"
    local pg_path_line='export PATH=$POSTGRES_HOME/bin:$PATH'
    ensure_line_in_file "$pg_home_line" "$SHELL_PROFILE"
    ensure_line_in_file "$pg_path_line" "$SHELL_PROFILE"

    # Validate
    if command_exists psql; then
        local new_ver
        new_ver="$(extract_major_version "$(psql --version 2>&1)")"
        register_pass
        task_pass "PostgreSQL ${new_ver}"
    else
        task_error_msg "PostgreSQL not available after install"
        register_fail
        task_fail
    fi
}

_force_mysql() {
    task_start "MySQL (force)"
    _stop_spinner

    if command_exists mysql; then
        local my_source
        my_source="$(detect_install_source mysql)"
        log_info "Detected MySQL (installed via ${my_source})"

        if ! confirm_action "This will remove existing MySQL. Databases may be lost."; then
            log_info "Skipped"
            return 0
        fi

        # Stop and uninstall
        log_info "Stopping MySQL service..."
        brew services stop mysql 2>/dev/null || true
        local formula
        for formula in $(brew list --formula 2>/dev/null | grep -i "mysql"); do
            brew services stop "$formula" 2>/dev/null || true
            log_info "Uninstalling ${formula}..."
            brew uninstall --ignore-dependencies "$formula" 2>/dev/null || true
        done
    else
        if ! confirm_action "This will install MySQL ${MYSQL_MAX_VERSION}"; then
            log_info "Skipped"
            return 0
        fi
    fi

    # Backup and clean zshrc
    backup_zshrc
    remove_lines_from_file "MYSQL_HOME" "$SHELL_PROFILE"

    # Fresh install
    log_info "Installing MySQL ${MYSQL_MAX_VERSION}..."
    if ! brew install "mysql@${MYSQL_MAX_VERSION}"; then
        task_error_msg "Failed to install MySQL ${MYSQL_MAX_VERSION}"
        register_fail
        task_fail
        return 1
    fi

    # Set env vars
    local my_home_line="export MYSQL_HOME=\$(brew --prefix mysql@${MYSQL_MAX_VERSION})"
    local my_path_line='export PATH=$MYSQL_HOME/bin:$PATH'
    ensure_line_in_file "$my_home_line" "$SHELL_PROFILE"
    ensure_line_in_file "$my_path_line" "$SHELL_PROFILE"

    # Validate
    if command_exists mysql; then
        local new_ver
        new_ver="$(extract_major_version "$(mysql --version 2>&1)")"
        register_pass
        task_pass "MySQL ${new_ver}"
    else
        task_error_msg "MySQL not available after install"
        register_fail
        task_fail
    fi
}