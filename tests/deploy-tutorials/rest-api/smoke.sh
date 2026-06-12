#!/usr/bin/env bash
# Smoke tests for the v1 Public REST API (Platform JAR) deployment.
# Run after ACS is healthy.
#
# Usage: smoke.sh <acs-base-url>
# Default: http://localhost:8080

set -euo pipefail

BASE="${1:-http://localhost:8080}"
API="$BASE/alfresco/api/-default-/public/alfresco/versions/1"
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

printf '\n=== rest-api smoke tests ===\n'

# ACS readiness
check "ACS ready probe" \
    "$API/probes/-ready-"

# Custom v1 entity collection registered and reachable (paged list, even if empty)
check "custom v1 entity collection GET /widgets" \
    "$API/widgets"

# Entity-by-id for a missing id resolves to the resource (404, not 500) — proves routing
check "custom v1 entity readById missing -> 404 (resource routed)" \
    "$API/widgets/does-not-exist" "404"

printf '\n  rest-api: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -gt 0 ]] && exit 1
exit 0
