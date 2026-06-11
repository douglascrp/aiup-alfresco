#!/usr/bin/env bash
# Run all tutorial scenario validations and print a summary table.
#
# Usage:
#   run-all.sh
#
# Each scenario is validated against its committed fixture
# (scenarios/<scenario>/fixture/) — fully offline, no sibling repo, no generated/
# directory, no claude/network/Docker. A scenario with a missing/empty fixture is
# reported as SKIP (not FAIL). Exit code: 0 if all non-skipped scenarios pass, 1 if any fail.

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

SCENARIOS="maven-sdk-baseline content-types actions behaviours web-scripts rest-api workflows scheduled-jobs bootstrap-loader rule-conditions permissions audit repository-patch transforms content-store metadata-extractor subsystem events share-config surf aikau aca-extension"

PASS=0
FAIL=0
SKIP=0
SUMMARY=""

for scenario in $SCENARIOS; do
    output=$(bash "$SCRIPT_DIR/run-scenario.sh" "$scenario" 2>&1)
    status=$?
    printf '%s\n' "$output"

    if echo "$output" | grep -q "SKIP —"; then
        SKIP=$((SKIP + 1))
        SUMMARY="${SUMMARY}$(printf '%-30s' "$scenario") SKIP\n"
    elif [[ $status -eq 0 ]]; then
        PASS=$((PASS + 1))
        SUMMARY="${SUMMARY}$(printf '%-30s' "$scenario") PASS\n"
    else
        FAIL=$((FAIL + 1))
        SUMMARY="${SUMMARY}$(printf '%-30s' "$scenario") FAIL\n"
    fi
done

printf '\n%-30s Result\n' "Scenario"
printf '%s\n' "----------------------------------------------"
printf '%b' "$SUMMARY"
printf '%s\n' "----------------------------------------------"
printf '%-30s PASS:%d  FAIL:%d  SKIP:%d\n' "TOTAL" "$PASS" "$FAIL" "$SKIP"

[[ $FAIL -gt 0 ]] && exit 1
exit 0
