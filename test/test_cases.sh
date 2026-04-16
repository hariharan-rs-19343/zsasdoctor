#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  test_cases.sh — Tests for zsasdoctor
# ─────────────────────────────────────────────────────────────
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN="$ROOT_DIR/bin/zsasdoctor"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ── Helpers ──────────────────────────────────────────────────
pass() { (( TESTS_PASSED++ )); echo "  ✅ $1"; }
fail() { (( TESTS_FAILED++ )); echo "  ❌ $1"; }

run_test() {
    (( TESTS_RUN++ ))
    local name="$1"
    shift
    if "$@"; then
        pass "$name"
    else
        fail "$name"
    fi
}

# ── Unit Tests ───────────────────────────────────────────────

echo "══════════════════════════════════════"
echo "  zsasdoctor — Test Suite"
echo "══════════════════════════════════════"

# -- Version command --
echo ""
echo "▸ version command"

run_test "version outputs version string" bash -c "$BIN version | grep -q 'v1.0.1'"

# -- Help command --
echo ""
echo "▸ help command"

run_test "help mentions 'check'" bash -c "$BIN help | grep -q 'check'"
run_test "help mentions 'config'" bash -c "$BIN help | grep -q 'config'"
run_test "help mentions exit codes" bash -c "$BIN help | grep -q 'Exit Codes'"

# -- Check command (integration) --
echo ""
echo "▸ check command (integration)"

run_test "check runs without crashing" bash -c "$BIN check; [[ \$? -le 2 ]]"

# -- Config with bad flag --
echo ""
echo "▸ config error handling"

run_test "config with unknown flag fails" bash -c "! $BIN config --bogus 2>&1"

# -- Unknown command --
echo ""
echo "▸ unknown command handling"

run_test "unknown command exits non-zero" bash -c "! $BIN foobar 2>&1"

# -- Utils unit tests --
echo ""
echo "▸ utils.sh unit tests"

source "$ROOT_DIR/config/constants.sh"
source "$ROOT_DIR/lib/logger.sh"
source "$ROOT_DIR/lib/utils.sh"

test_extract_major_version() {
    local result
    result="$(extract_major_version 'psql (PostgreSQL) 14.9')"
    [[ "$result" == "14" ]]
}
run_test "extract_major_version parses PostgreSQL" test_extract_major_version

test_extract_major_java() {
    local result
    result="$(extract_major_version 'openjdk version \"17.0.1\" 2021-10-19')"
    [[ "$result" == "17" ]]
}
run_test "extract_major_version parses Java" test_extract_major_java

test_extract_major_mysql() {
    local result
    result="$(extract_major_version 'mysql  Ver 8.0.32')"
    [[ "$result" == "8" ]]
}
run_test "extract_major_version parses MySQL" test_extract_major_mysql

# -- Boundary version tests --
echo ""
echo "▸ version boundary checks"

test_java_boundary_low() {
    local v=11
    (( v >= JAVA_MIN_VERSION && v <= JAVA_MAX_VERSION ))
}
run_test "Java 11 is within range" test_java_boundary_low

test_java_boundary_high() {
    local v=17
    (( v >= JAVA_MIN_VERSION && v <= JAVA_MAX_VERSION ))
}
run_test "Java 17 is within range" test_java_boundary_high

test_java_below_min() {
    local v=8
    ! (( v >= JAVA_MIN_VERSION && v <= JAVA_MAX_VERSION ))
}
run_test "Java 8 is out of range" test_java_below_min

test_java_above_max() {
    local v=21
    ! (( v >= JAVA_MIN_VERSION && v <= JAVA_MAX_VERSION ))
}
run_test "Java 21 is out of range" test_java_above_max

test_postgres_boundary() {
    local v=14
    (( v >= POSTGRES_MIN_VERSION ))
}
run_test "PostgreSQL 14 meets minimum" test_postgres_boundary

test_postgres_below() {
    local v=13
    ! (( v >= POSTGRES_MIN_VERSION ))
}
run_test "PostgreSQL 13 below minimum" test_postgres_below

test_mysql_boundary() {
    local v=5
    (( v >= MYSQL_MIN_VERSION && v <= MYSQL_MAX_VERSION ))
}
run_test "MySQL 5 within range" test_mysql_boundary

test_mysql_above() {
    local v=9
    ! (( v >= MYSQL_MIN_VERSION && v <= MYSQL_MAX_VERSION ))
}
run_test "MySQL 9 out of range" test_mysql_above

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════"
echo "  Results: ${TESTS_PASSED}/${TESTS_RUN} passed, ${TESTS_FAILED} failed"
echo "══════════════════════════════════════"

(( TESTS_FAILED == 0 ))
