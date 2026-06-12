#!/usr/bin/env bash
# Smoke tests for the custom audit application (Platform JAR) deployment.
# Run after ACS is healthy.
#
# Usage: smoke.sh <acs-base-url>
# Default: http://localhost:8080

set -euo pipefail

BASE="${1:-http://localhost:8080}"
PASS=0
FAIL=0

check() {
    local label="$1"
    local url="$2"
    local expected_status="${3:-200}"
    local extra_args="${4:-}"

    http_status=$(curl -s -o /dev/null -w "%{http_code}" \
        -u admin:admin \
        $extra_args \
        "$url" 2>/dev/null) || http_status="000"

    if [[ "$http_status" == "$expected_status" ]]; then
        printf '  PASS  %s (HTTP %s)\n' "$label" "$http_status"
        PASS=$((PASS+1))
    else
        printf '  FAIL  %s — expected HTTP %s, got %s\n' "$label" "$expected_status" "$http_status"
        FAIL=$((FAIL+1))
    fi
}

# check_body <label> <url> <pattern> — passes if the admin response body matches <pattern>
check_body() {
    local label="$1"
    local url="$2"
    local pattern="$3"
    local body
    body=$(curl -s -u admin:admin "$url" 2>/dev/null) || body=""
    if echo "$body" | grep -q "$pattern"; then
        printf '  PASS  %s (matched "%s")\n' "$label" "$pattern"
        PASS=$((PASS+1))
    else
        printf '  FAIL  %s — response did not match "%s"\n' "$label" "$pattern"
        FAIL=$((FAIL+1))
    fi
}

printf '\n=== audit smoke tests ===\n'

# ACS readiness
check "ACS ready probe" \
    "$BASE/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-"

# Audit control web script lists applications (admin only)
check "audit control endpoint reachable" \
    "$BASE/alfresco/s/api/audit/control"

# The custom 'sc' application is registered and enabled
check_body "custom audit application 'sc' registered" \
    "$BASE/alfresco/s/api/audit/control" \
    '"sc"'

printf '\n  audit: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
exit 0
