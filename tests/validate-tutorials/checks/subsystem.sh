#!/usr/bin/env bash
# Checker: subsystem (custom ChildApplicationContextFactory subsystem)
# Usage: subsystem.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== subsystem ===\n'

# ---- Common checks ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

MODULE_CTX=$(find "$GEN" -name "module-context.xml" -not -path "*/target/*" | head -1) || true
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"
else
    _fail "module-context.xml exists" "not found under $GEN"
fi

# ---- Subsystem layout: a default .properties file ----
DEFAULT_PROPS=$(find "$GEN" -path "*subsystems*" -name "*default*.properties" | head -1) || true
[[ -z "$DEFAULT_PROPS" ]] && DEFAULT_PROPS=$(find "$GEN" -name "*-default.properties" | head -1) || true
assert_file_exists "${DEFAULT_PROPS:-/nonexistent}" "subsystem default properties file exists"

INSTANCE_PROPS=$(find "$GEN" -path "*extension/subsystems*" -name "*.properties" | head -1) || true
assert_file_exists "${INSTANCE_PROPS:-/nonexistent}" \
    "an instance override .properties exists under extension/subsystems"

# ---- ChildApplicationContextFactory registration OR authentication chain ----
# Generic mode -> ChildApplicationContextFactory / abstractPropertyBackedBean
# Auth mode    -> authentication.chain
FOUND_GENERIC=$(find "$GEN" -name "*.xml" -not -path "*/target/*" -exec grep -l "abstractPropertyBackedBean\|ChildApplicationContextFactory" {} \; 2>/dev/null | head -1) || true
FOUND_AUTH=$(find "$GEN" -name "*.properties" -exec grep -l "authentication.chain" {} \; 2>/dev/null | head -1) || true
if [[ -n "$FOUND_GENERIC" ]]; then
    _pass "subsystem declared via abstractPropertyBackedBean / ChildApplicationContextFactory"
    assert_xml_wellformed "$FOUND_GENERIC" "subsystem factory context is well-formed XML"
elif [[ -n "$FOUND_AUTH" ]]; then
    _pass "authentication chain configured (authentication.chain present)"
else
    _fail "subsystem declared (factory bean) or authentication.chain present" \
        "neither abstractPropertyBackedBean nor authentication.chain found under $GEN"
fi

# ---- Subsystem context well-formed ----
SUB_CTX=$(find "$GEN" -name "*subsystem-context.xml" -not -path "*/target/*" | head -1) || true
if [[ -n "$SUB_CTX" ]]; then
    assert_xml_wellformed "$SUB_CTX" "subsystem context XML is well-formed"
fi

# ---- No committed secrets ----
assert_not_grep "password=[^$]" "$GEN" \
    "no hardcoded password= literal (must use env placeholders)"
assert_not_grep "secret=[^$]" "$GEN" \
    "no hardcoded secret= literal (must use env placeholders)"

print_summary "subsystem"
exit_with_status
