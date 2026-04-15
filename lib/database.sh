#!/usr/bin/env bash
# database.sh — PostgreSQL / MySQL validation and auto-configuration

# ── Check ────────────────────────────────────────────────────
check_database() {
    log_section "Database Check"

    local found_any=0

    # ── PostgreSQL ───────────────────────────────────────────
    if command_exists psql; then
        found_any=1
        local pg_version_output
        pg_version_output="$(psql --version 2>&1)"
        local pg_major
        pg_major="$(extract_major_version "$pg_version_output")"

        if [[ -n "$pg_major" ]] && (( pg_major >= POSTGRES_MIN_VERSION )); then
            log_success "PostgreSQL ${pg_major} detected"
            register_pass
        elif [[ -n "$pg_major" ]]; then
            log_error "PostgreSQL ${pg_major} detected — required >= ${POSTGRES_MIN_VERSION}"
            register_fail
        else
            log_error "Unable to determine PostgreSQL version"
            register_fail
        fi
    fi

    # ── MySQL ────────────────────────────────────────────────
    if command_exists mysql; then
        found_any=1
        local my_version_output
        my_version_output="$(mysql --version 2>&1)"
        local my_major
        my_major="$(extract_major_version "$my_version_output")"

        if [[ -n "$my_major" ]] && (( my_major >= MYSQL_MIN_VERSION && my_major <= MYSQL_MAX_VERSION )); then
            if (( my_major == MYSQL_RECOMMENDED_VERSION )); then
                log_success "MySQL ${my_major} detected (recommended)"
            else
                log_success "MySQL ${my_major} detected"
            fi
            register_pass
        elif [[ -n "$my_major" ]]; then
            log_error "MySQL ${my_major} detected — required ${MYSQL_MIN_VERSION}–${MYSQL_MAX_VERSION}"
            register_fail
        else
            log_error "Unable to determine MySQL version"
            register_fail
        fi
    fi

    if (( ! found_any )); then
        log_error "No database (PostgreSQL or MySQL) found"
        register_fail
    fi
}

# ── Fix ──────────────────────────────────────────────────────
fix_database() {
    log_section "Database Auto-Configuration"

    if ! command_exists brew; then
        log_error "Homebrew is required to auto-install databases"
        register_fail
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
        0)
            _install_postgres
            ;;
        1)
            _install_mysql
            ;;
    esac
}

_install_postgres() {
    if ! command_exists psql; then
        log_info "Installing PostgreSQL ${POSTGRES_MAX_VERSION} via Homebrew..."
        if brew install "postgresql@${POSTGRES_MAX_VERSION}"; then
            log_success "PostgreSQL ${POSTGRES_MAX_VERSION} installed"
            register_pass

            log_info "Starting PostgreSQL service..."
            if brew services start "postgresql@${POSTGRES_MAX_VERSION}"; then
                log_success "PostgreSQL service started"
                register_pass
            else
                log_warning "Could not start PostgreSQL service automatically"
                register_warning
            fi
        else
            log_error "Failed to install PostgreSQL"
            register_fail
            return 1
        fi
    else
        log_success "PostgreSQL already installed"
        register_pass
    fi

    # Ensure PostgreSQL home path in shell profile (idempotent)
    local pg_home_line="export POSTGRES_HOME=\$(brew --prefix postgresql@${POSTGRES_MAX_VERSION})"
    local pg_path_line='export PATH=$POSTGRES_HOME/bin:$PATH'

    if ensure_line_in_file "$pg_home_line" "$SHELL_PROFILE"; then
        log_success "Added POSTGRES_HOME to ${SHELL_PROFILE}"
    else
        log_success "POSTGRES_HOME already in ${SHELL_PROFILE}"
    fi
    ensure_line_in_file "$pg_path_line" "$SHELL_PROFILE"
    register_pass
}

_install_mysql() {
    if ! command_exists mysql; then
        log_info "Installing MySQL ${MYSQL_MAX_VERSION} via Homebrew..."
        if brew install "mysql@${MYSQL_MAX_VERSION}"; then
            log_success "MySQL ${MYSQL_MAX_VERSION} installed"
            register_pass
        else
            log_error "Failed to install MySQL"
            register_fail
            return 1
        fi
    else
        log_success "MySQL already installed"
        register_pass
    fi

    # Ensure MySQL home path in shell profile (idempotent)
    local my_home_line="export MYSQL_HOME=\$(brew --prefix mysql@${MYSQL_MAX_VERSION})"
    local my_path_line='export PATH=$MYSQL_HOME/bin:$PATH'

    if ensure_line_in_file "$my_home_line" "$SHELL_PROFILE"; then
        log_success "Added MYSQL_HOME to ${SHELL_PROFILE}"
    else
        log_success "MYSQL_HOME already in ${SHELL_PROFILE}"
    fi
    ensure_line_in_file "$my_path_line" "$SHELL_PROFILE"
    register_pass
}
