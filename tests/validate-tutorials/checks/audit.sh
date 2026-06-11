#!/usr/bin/env bash
# Checker: audit (custom audit application + data extractor)
# Usage: audit.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== audit ===\n'

# ---- Common checks ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

MODULE_CTX=$(find "$GEN" -name "module-context.xml" -not -path "*/target/*" | head -1) || true
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"
else
    _fail "module-context.xml exists" "not found under $GEN"
fi

# ---- Audit application XML ----
AUDIT_XML=$(find "$GEN" -path "*/audit/*-audit.xml" -not -path "*/target/*" | head -1) || true
[[ -z "$AUDIT_XML" ]] && AUDIT_XML=$(find "$GEN" -name "*-audit.xml" -not -path "*/target/*" | head -1) || true
assert_file_exists "${AUDIT_XML:-/nonexistent}" "*-audit.xml exists under alfresco/extension/audit/"
if [[ -n "$AUDIT_XML" ]]; then
    assert_xml_wellformed "$AUDIT_XML" "audit XML is well-formed"
    assert_grep "audit/model/3.2" "$AUDIT_XML" "audit XML uses the 3.2 audit model namespace"
    assert_grep "Application" "$AUDIT_XML" "declares an Application"
    assert_grep "key=" "$AUDIT_XML" "Application declares a key"
    assert_grep "RecordValue" "$AUDIT_XML" "declares at least one RecordValue"
    assert_grep "DataExtractor" "$AUDIT_XML" "declares at least one DataExtractor"
fi

# ---- Data extractor class ----
EXTRACTOR_JAVA=$(find "$GEN" -name "*DataExtractor.java" | grep -v "Test" | head -1) || true
assert_file_exists "${EXTRACTOR_JAVA:-/nonexistent}" "*DataExtractor.java exists"
if [[ -n "$EXTRACTOR_JAVA" ]]; then
    assert_grep "extends AbstractDataExtractor" "$EXTRACTOR_JAVA" \
        "extractor extends AbstractDataExtractor"
    assert_grep "isSupported" "$EXTRACTOR_JAVA" "extractor implements isSupported"
    assert_grep "extractData" "$EXTRACTOR_JAVA" "extractor implements extractData"
fi

# ---- Registration ----
AUDIT_CTX=$(find "$GEN" -name "audit-context.xml" -not -path "*/target/*" | head -1) || true
assert_file_exists "${AUDIT_CTX:-/nonexistent}" "audit-context.xml exists"
if [[ -n "$AUDIT_CTX" ]]; then
    assert_xml_wellformed "$AUDIT_CTX" "audit-context.xml is well-formed XML"
    assert_grep "AuditModelRegistrationBean\|auditModelRegistry\|registerModel" "$AUDIT_CTX" \
        "registers the audit model with the registry"
    assert_grep "auditModelExtractorBase" "$AUDIT_CTX" \
        "extractor bean uses auditModelExtractorBase parent"
fi
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "audit-context" "$MODULE_CTX" \
        "module-context.xml imports audit-context.xml"
fi

# ---- Enable properties ----
assert_grep_any_file "audit.enabled" "$GEN" "*.properties" "audit.enabled present in a .properties file"
assert_grep_any_file "audit\..*\.enabled" "$GEN" "*.properties" "an application-specific audit enable flag is present"

print_summary "audit"
exit_with_status
