#!/usr/bin/env bash
# database.sh — PostgreSQL / MySQL validation and auto-configuration

# ── Check ────────────────────────────────────────────────────
check_database() {
    task_start "Database"

    local found_any=0
    local detail_parts=()

    # ── PostgreSQL ───────────────────────────────────────────
    if command_exists psql; then
        found_any=1
        local pg_major
        pg_major="$(extract_major_version "$(psql --version 2>&1)")"

        if [[ -n "$pg_major" ]] && (( pg_major >= POSTGRES_MIN_VERSION )); then
            detail_parts+=("PostgreSQL ${pg_major}")
            register_pass
        elif [[ -n "$pg_major" ]]; then
            task_error_msg "PostgreSQL ${pg_major} — required >= ${POSTGRES_MIN_VERSION}"
            register_fail
        else
            task_error_msg "Unable to determine PostgreSQL version"
            register_fail
        fi
    fi

    # ── MySQL ────────────────────────────────────────────────
    if command_exists mysql; then
        found_any=1
        local my_major
        my_major="$(extract_major_version "$(mysql --version 2>&1)")"

        if [[ -n "$my_major" ]] && (( my_major >= MYSQL_MIN_VERSION && my_major <= MYSQL_MAX_VERSION )); then
            detail_parts+=("MySQL ${my_major}")
            register_pass
        elif [[ -n "$my_major" ]]; then
            task_error_msg "MySQL ${my_major} — required ${MYSQL_MIN_VERSION}–${MYSQL_MAX_VERSION}"
            register_fail
        else
            task_error_msg "Unable to determine MySQL version"
            register_fail
        fi
    fi

    if (( ! found_any )); then
        task_error_msg "No database (PostgreSQL or MySQL) found"
        register_fail
        task_fail
        return 1
    fi

    if (( ${#_TASK_ERRORS[@]} > 0 )); then
        task_fail
        return 1
    fi

    local detail
    detail="$(IFS=', '; echo "${detail_parts[*]}")"
    task_pass "$detail"
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
