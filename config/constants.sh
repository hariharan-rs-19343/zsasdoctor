#!/usr/bin/env bash
# constants.sh — Central configuration for zsasdoctor

# ── Tool metadata ────────────────────────────────────────────
ZSASDOCTOR_VERSION="1.0.0"
ZSASDOCTOR_NAME="zsasdoctor"

# ── Java constraints ─────────────────────────────────────────
JAVA_MIN_VERSION=11
JAVA_MAX_VERSION=17
JAVA_RECOMMENDED_VERSION=17

# ── PostgreSQL constraints ───────────────────────────────────
POSTGRES_MIN_VERSION=14
POSTGRES_MAX_VERSION=15

# ── MySQL constraints ────────────────────────────────────────
MYSQL_MIN_VERSION=5
MYSQL_MAX_VERSION=8
MYSQL_RECOMMENDED_VERSION=8

# ── Intranet connectivity ────────────────────────────────────
# Override these via environment variables if needed
INTRANET_HOST="${ZSASDOCTOR_INTRANET_HOST:-build.zohocorp.com}"
INTRANET_URL="${ZSASDOCTOR_INTRANET_URL:-https://build.zohocorp.com}"
INTRANET_DOWNLOAD_URL="${ZSASDOCTOR_INTRANET_DOWNLOAD_URL:-https://build.zohocorp.com/integ/hg_utils/milestones/stable/hg_utils.zip}"
INTRANET_TIMEOUT=5          # seconds

# ── Shell profile ────────────────────────────────────────────
SHELL_PROFILE="$HOME/.zshrc"

# ── Exit codes ───────────────────────────────────────────────
EXIT_OK=0
EXIT_FAIL=1
EXIT_PARTIAL=2
EXIT_MISSING=127
