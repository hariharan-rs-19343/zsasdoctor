#!/usr/bin/env bash
# intranet.sh — Intranet connectivity validation and guidance

# ── Check ────────────────────────────────────────────────────
check_intranet() {
    log_section "Intranet Check"

    local _intranet_ok=1

    # 1. Ensure wget is available
    if ! command_exists wget; then
        log_error "wget is not installed (required for intranet checks)"
        register_fail
        return 1
    fi

    # 2. Check ~/.wgetrc for credentials
    if [[ -f "$HOME/.wgetrc" ]]; then
        log_success "~/.wgetrc found (credentials source)"
        register_pass
    else
        log_warning "~/.wgetrc not found — wget may lack intranet credentials"
        register_warning
        _intranet_ok=0
    fi

    # 3. File download check using wget (credentials from ~/.wgetrc)
    log_info "Reading intranet URL: ${INTRANET_URL}"
    local tmp_file
    tmp_file="$(mktemp /tmp/zsasdoctor_download_XXXXXX)"
    if wget -q -O "$tmp_file" \
        --timeout="$INTRANET_TIMEOUT" \
        "$INTRANET_DOWNLOAD_URL" 2>/dev/null && [[ -s "$tmp_file" ]]; then
        log_success "File download succeeded ($(wc -c < "$tmp_file" | tr -d ' ') bytes)"
        register_pass
    else
        log_error "Failed to connect from ${INTRANET_URL}"
        register_fail
        _intranet_ok=0
    fi
    rm -f "$tmp_file"

    (( _intranet_ok ))
}

# ── Fix ──────────────────────────────────────────────────────
fix_intranet() {
    log_section "Intranet Configuration"

    log_info "Intranet connectivity cannot be fully auto-fixed."
    echo ""
    echo "  Suggested actions:"
    echo "    1. Ensure you are connected to the corporate VPN"
    echo "    2. Verify DNS settings point to internal DNS servers"
    echo "    3. Check that ${INTRANET_URL} is reachable in a browser"
    echo "       - Generate Token from ${INTRANET_URL} and add to ~/.wgetrc"
    echo "    4. Contact IT support if the issue persists"
    echo ""
    register_warning
}
