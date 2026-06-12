#!/usr/bin/env bash
# Checker: aikau (Share Aikau page)
# Usage: aikau.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== aikau ===\n'

# ---- Aikau page web script descriptor ----
DESC=$(find "$GEN" -path "*site-webscripts*" -name "*.get.desc.xml" | head -1) || true
assert_file_exists "${DESC:-/nonexistent}" "an Aikau page descriptor (*.get.desc.xml) exists under site-webscripts"
if [[ -n "$DESC" ]]; then
    assert_xml_wellformed "$DESC" "page descriptor is well-formed XML"
    assert_grep "<family>Share</family>\|<family> Share" "$DESC" \
        "descriptor declares the Share family"
fi

# ---- Aikau page model JavaScript with a widgets model ----
PAGE_JS=$(find "$GEN" -path "*site-webscripts*" -name "*.get.js" | head -1) || true
assert_file_exists "${PAGE_JS:-/nonexistent}" "an Aikau page model (*.get.js) exists"
if [[ -n "$PAGE_JS" ]]; then
    assert_grep "widgets" "$PAGE_JS" "page model declares a widgets array"
fi

# ---- Share-tier boundary ----
assert_not_grep "alfresco/module" "$GEN" \
    "no Aikau files under alfresco/module (Share tier only)"

print_summary "aikau"
exit_with_status
