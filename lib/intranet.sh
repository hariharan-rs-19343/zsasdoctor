#!/usr/bin/env bash
# intranet.sh — Intranet connectivity validation and guidance

# ── Check ────────────────────────────────────────────────────
check_intranet() {
    task_start "Intranet"

    local _intranet_ok=1

    # 1. Ensure wget is available
    if ! command_exists wget; then
        task_error_msg "wget is not installed (required for intranet checks)"
        register_fail
        task_fail
        return 1
    fi

    # 2. Check ~/.wgetrc for credentials
    if [[ -f "$HOME/.wgetrc" ]]; then
        register_pass
    else
        task_error_msg "~/.wgetrc not found — wget may lack intranet credentials"
        register_warning
        _intranet_ok=0
    fi

    # 3. File download check using wget (credentials from ~/.wgetrc)
    local tmp_file
    tmp_file="$(mktemp /tmp/zsasdoctor_download_XXXXXX)"
    if wget -q -O "$tmp_file" \
        --timeout="$INTRANET_TIMEOUT" \
        "$INTRANET_DOWNLOAD_URL" 2>/dev/null && [[ -s "$tmp_file" ]]; then
        local size
        size="$(wc -c < "$tmp_file" | tr -d ' ')"
        register_pass
        rm -f "$tmp_file"
    else
        task_error_msg "Failed to download from ${INTRANET_DOWNLOAD_URL}"
        register_fail
        _intranet_ok=0
        rm -f "$tmp_file"
    fi

    if (( _intranet_ok )); then
        task_pass "connected"
    elif (( ${#_TASK_ERRORS[@]} > 0 )); then
        # Check if there are actual errors (not just warnings)
        local has_fail=0
        for msg in "${_TASK_ERRORS[@]}"; do
            [[ "$msg" == *"Failed"* || "$msg" == *"not installed"* ]] && has_fail=1
        done
        if (( has_fail )); then
            task_fail
        else
            task_warn
        fi
        return 1
    fi
}

# ── Fix ──────────────────────────────────────────────────────
fix_intranet() {
    echo ""
    printf "  ${_CLR_YELLOW}${_CLR_BOLD}Intranet — suggested actions:${_CLR_RESET}\n"
    printf "    ${_CLR_DIM}1.${_CLR_RESET} Ensure you are connected to the corporate VPN\n"
    printf "    ${_CLR_DIM}2.${_CLR_RESET} Verify DNS settings point to internal DNS servers\n"
    printf "    ${_CLR_DIM}3.${_CLR_RESET} Check that ${INTRANET_URL} is reachable in a browser\n"
    printf "       Generate Token from ${INTRANET_URL} and add to ~/.wgetrc\n"
    printf "    ${_CLR_DIM}4.${_CLR_RESET} Contact IT support if the issue persists\n"
    echo ""
    register_warning
}
