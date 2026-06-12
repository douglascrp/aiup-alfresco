#!/usr/bin/env bash
# Checker: permissions (custom permission model + dynamic authority)
# Usage: permissions.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== permissions ===\n'

# ---- Common checks ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

MODULE_CTX=$(find "$GEN" -name "module-context.xml" -not -path "*/target/*" | head -1) || true
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"
else
    _fail "module-context.xml exists" "not found under $GEN"
fi

# ---- Permission model XML ----
PERM_XML=$(find "$GEN" -name "*permissionDefinitions.xml" -not -path "*/target/*" | head -1) || true
assert_file_exists "${PERM_XML:-/nonexistent}" "*permissionDefinitions.xml exists"
if [[ -n "$PERM_XML" ]]; then
    assert_xml_wellformed "$PERM_XML" "permissionDefinitions.xml is well-formed XML"
    assert_grep "permissionSet" "$PERM_XML" "declares a permissionSet"
    assert_grep "permissionGroup" "$PERM_XML" "declares at least one permissionGroup"
    assert_grep "permission " "$PERM_XML" "declares at least one permission"
    # Must not redefine a built-in group as a top-level custom group name
    assert_not_grep 'permissionGroup name="Coordinator"' "$PERM_XML" \
        "does not redefine built-in Coordinator group"
    assert_not_grep 'permissionGroup name="Collaborator"' "$PERM_XML" \
        "does not redefine built-in Collaborator group"
fi

# ---- Registration as an extension model (not a replacement) ----
PERM_CTX=$(find "$GEN" -name "permissions-context.xml" -not -path "*/target/*" | head -1) || true
assert_file_exists "${PERM_CTX:-/nonexistent}" "permissions-context.xml exists"
if [[ -n "$PERM_CTX" ]]; then
    assert_xml_wellformed "$PERM_CTX" "permissions-context.xml is well-formed XML"
    assert_grep "permissionModelBootstrap" "$PERM_CTX" \
        "registers extension model via permissionModelBootstrap parent"
fi
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "permissions-context" "$MODULE_CTX" \
        "module-context.xml imports permissions-context.xml"
fi

# ---- Dynamic authority class ----
DA_JAVA=$(find "$GEN" -name "*DynamicAuthority.java" | grep -v "Test" | head -1) || true
assert_file_exists "${DA_JAVA:-/nonexistent}" "*DynamicAuthority.java exists"
if [[ -n "$DA_JAVA" ]]; then
    assert_grep "implements DynamicAuthority" "$DA_JAVA" \
        "dynamic authority implements DynamicAuthority"
    assert_grep "hasAuthority" "$DA_JAVA" "dynamic authority implements hasAuthority"
    assert_grep "getAuthority" "$DA_JAVA" "dynamic authority implements getAuthority"
    assert_not_grep "runAsSystem" "$DA_JAVA" \
        "hasAuthority does not use forbidden runAsSystem"
    assert_not_grep "@Autowired" "$DA_JAVA" \
        "dynamic authority does not use forbidden @Autowired"
fi

# ---- Unit test ----
TEST_JAVA=$(find "$GEN" -name "*DynamicAuthorityTest.java" | head -1) || true
assert_file_exists "${TEST_JAVA:-/nonexistent}" "*DynamicAuthorityTest.java exists"

print_summary "permissions"
exit_with_status
