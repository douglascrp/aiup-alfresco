#!/usr/bin/env bash
# Checker: surf (Share Surf extension)
# Usage: surf.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== surf ===\n'

# ---- Surf extension metadata XML ----
EXT_XML=$(find "$GEN" -path "*site-data/extensions*" -name "*.xml" | head -1) || true
assert_file_exists "${EXT_XML:-/nonexistent}" "Surf extension metadata XML exists under site-data/extensions"
if [[ -n "$EXT_XML" ]]; then
    assert_xml_wellformed "$EXT_XML" "Surf extension metadata is well-formed XML"
    assert_grep "<extension>" "$EXT_XML" "declares an <extension>"
    assert_grep "<module>" "$EXT_XML" "declares a Surf <module>"
    assert_grep "<component" "$EXT_XML" "declares at least one <component>"
fi

# ---- Page web script descriptor under site-webscripts ----
DESC=$(find "$GEN" -path "*site-webscripts*" -name "*.get.desc.xml" | head -1) || true
assert_file_exists "${DESC:-/nonexistent}" "a page/component web script descriptor exists under site-webscripts"
if [[ -n "$DESC" ]]; then
    assert_xml_wellformed "$DESC" "web script descriptor is well-formed XML"
    assert_grep "<family>Share</family>\|<family> Share" "$DESC" \
        "descriptor declares the Share family"
fi

# ---- Share-tier boundary ----
assert_not_grep "alfresco/module" "$GEN" \
    "no Surf files under alfresco/module (Share tier only)"

print_summary "surf"
exit_with_status
