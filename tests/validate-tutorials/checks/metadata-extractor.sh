#!/usr/bin/env bash
# Checker: metadata-extractor (custom AbstractMappingMetadataExtracter)
# Usage: metadata-extractor.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== metadata-extractor ===\n'

# ---- Common checks ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

MODULE_CTX=$(find "$GEN" -name "module-context.xml" -not -path "*/target/*" | head -1) || true
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"
else
    _fail "module-context.xml exists" "not found under $GEN"
fi

# ---- Extractor class ----
EXTR_JAVA=$(find "$GEN" -name "*MetadataExtracter.java" | grep -v "Test" | head -1) || true
assert_file_exists "${EXTR_JAVA:-/nonexistent}" "*MetadataExtracter.java exists"
if [[ -n "$EXTR_JAVA" ]]; then
    assert_grep "extends AbstractMappingMetadataExtracter" "$EXTR_JAVA" \
        "extractor extends AbstractMappingMetadataExtracter"
    assert_grep "extractRaw" "$EXTR_JAVA" "extractor implements extractRaw"
    assert_not_grep "new File(" "$EXTR_JAVA" \
        "extractor does not access the filesystem directly"
    assert_not_grep "@Autowired" "$EXTR_JAVA" \
        "extractor does not use forbidden @Autowired"
fi

# ---- Colocated mapping properties ----
assert_dir_has_file_matching "$GEN" "*MetadataExtracter.properties" \
    "a colocated *MetadataExtracter.properties mapping file exists"
MAP_PROPS=$(find "$GEN" -name "*MetadataExtracter.properties" | head -1) || true
if [[ -n "$MAP_PROPS" ]]; then
    assert_grep "namespace.prefix" "$MAP_PROPS" \
        "mapping declares at least one namespace.prefix"
fi

# ---- Spring registration ----
EXTR_CTX=$(find "$GEN" -name "metadata-extractor-context.xml" -not -path "*/target/*" | head -1) || true
assert_file_exists "${EXTR_CTX:-/nonexistent}" "metadata-extractor-context.xml exists"
if [[ -n "$EXTR_CTX" ]]; then
    assert_xml_wellformed "$EXTR_CTX" "metadata-extractor-context.xml is well-formed XML"
    assert_grep "baseMetadataExtracter" "$EXTR_CTX" \
        "extractor bean uses baseMetadataExtracter parent"
    assert_grep "metadataExtracterRegistry" "$EXTR_CTX" \
        "extractor bean injects metadataExtracterRegistry"
fi
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "metadata-extractor-context" "$MODULE_CTX" \
        "module-context.xml imports metadata-extractor-context.xml"
fi

# ---- Unit test ----
TEST_JAVA=$(find "$GEN" -name "*MetadataExtracterTest.java" | head -1) || true
assert_file_exists "${TEST_JAVA:-/nonexistent}" "*MetadataExtracterTest.java exists"

print_summary "metadata-extractor"
exit_with_status
