#!/usr/bin/env bash
# Validate a single tutorial scenario against a committed known-good fixture.
#
# Usage:
#   run-scenario.sh <scenario> [<project-dir>]
#
# <scenario>     : any scenario that has a checks/<scenario>.sh checker
# <project-dir>  : optional; the artefact tree to validate.
#                  Defaults to scenarios/<scenario>/fixture/ (committed, offline).
#                  Pass a path to validate a real generated project instead.
#
# Fully self-contained: no sibling repository, no pre-populated generated/ directory,
# no claude CLI, no network, no Docker. Just bash + xmllint + grep.

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

SCENARIOS_DIR="$SCRIPT_DIR/scenarios"
CHECKS_DIR="$SCRIPT_DIR/checks"

usage() {
    printf 'Usage: %s <scenario> [<project-dir>]\n' "$(basename "$0")"
    printf 'Scenarios: ' >&2
    find "$CHECKS_DIR" -maxdepth 1 -name '*.sh' -exec basename {} .sh \; 2>/dev/null \
        | sort | tr '\n' ' ' >&2
    printf '\n' >&2
}

[[ $# -lt 1 ]] && { usage >&2; exit 1; }

SCENARIO="$1"
# Default the project dir to the committed fixture for this scenario.
PROJECT_DIR="${2:-$SCENARIOS_DIR/$SCENARIO/fixture}"

CHECKER="$CHECKS_DIR/${SCENARIO}.sh"

# Scenario validity is defined by the existence of its checker — no hardcoded list,
# so any future scenario that adds a checks/<name>.sh works automatically.
if [[ ! -f "$CHECKER" ]]; then
    printf 'Unknown scenario: %s (no checker at %s)\n' "$SCENARIO" "$CHECKER" >&2
    usage >&2
    exit 1
fi

# Count real artefacts (ignore the REQUIREMENTS.md doc and any placeholder). The guard
# keeps the find crash-safe under set -euo pipefail when the directory is absent.
if [[ -d "$PROJECT_DIR" ]]; then
    FILE_COUNT=$(find "$PROJECT_DIR" -type f \
        -not -name '.gitkeep' -not -name 'REQUIREMENTS.md' 2>/dev/null | wc -l | tr -d ' ')
else
    FILE_COUNT=0
fi

# A missing/empty fixture is a clean skip, never a crash. run-all.sh classifies SKIPs by
# grepping stdout for the literal "SKIP —", so keep that token verbatim.
if [[ "$FILE_COUNT" -eq 0 ]]; then
    printf '\n[%s] SKIP — no artefacts to check at %s\n' "$SCENARIO" "$PROJECT_DIR"
    printf '  Provide a project dir argument, or add a fixture at scenarios/%s/fixture/.\n' "$SCENARIO"
    printf '  (To exercise live generation instead, use generate-all.sh.)\n'
    exit 0
fi

printf '\n[%s] Checking artefacts in: %s\n' "$SCENARIO" "$PROJECT_DIR"
chmod +x "$CHECKER"
if bash "$CHECKER" "$PROJECT_DIR"; then
    printf '[%s] PASSED\n' "$SCENARIO"
    exit 0
else
    printf '[%s] FAILED — review artefacts at %s\n' "$SCENARIO" "$PROJECT_DIR"
    exit 1
fi
