#!/usr/bin/env bash
# Checker: content-store (custom ContentStore connector)
# Usage: content-store.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== content-store ===\n'

# ---- Common checks ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

# ---- Content store class ----
STORE_JAVA=$(find "$GEN" -name "*ContentStore.java" | grep -v "Test" | head -1) || true
assert_file_exists "${STORE_JAVA:-/nonexistent}" "*ContentStore.java exists"
if [[ -n "$STORE_JAVA" ]]; then
    assert_grep "extends AbstractContentStore" "$STORE_JAVA" \
        "store extends AbstractContentStore"
    assert_grep "isWriteSupported" "$STORE_JAVA" "store implements isWriteSupported"
    assert_grep "getReader" "$STORE_JAVA" "store implements getReader"
    assert_grep "getWriterInternal\|getWriter" "$STORE_JAVA" "store implements a writer accessor"
    assert_not_grep "new File(" "$STORE_JAVA" \
        "store does not access the filesystem directly via new File()"
    assert_not_grep "@Autowired" "$STORE_JAVA" \
        "store does not use forbidden @Autowired"
fi

# ---- Reader / Writer ----
assert_grep_any_file "extends AbstractContentReader" "$GEN" "*ContentReader.java" \
    "a content reader extends AbstractContentReader"
assert_grep_any_file "extends AbstractContentWriter" "$GEN" "*ContentWriter.java" \
    "a content writer extends AbstractContentWriter"

# ---- Spring wiring ----
STORE_CTX=$(find "$GEN" -name "*content-store-context.xml" -not -path "*/target/*" | head -1) || true
[[ -z "$STORE_CTX" ]] && STORE_CTX=$(find "$GEN" -name "*content*context.xml" -not -path "*/target/*" | head -1) || true
assert_file_exists "${STORE_CTX:-/nonexistent}" "content store context XML exists"
if [[ -n "$STORE_CTX" ]]; then
    assert_xml_wellformed "$STORE_CTX" "content store context is well-formed XML"
    assert_grep "fileContentStore\|ContentStore" "$STORE_CTX" \
        "context activates the custom store (fileContentStore override)"
fi
assert_grep_any_file "dir.contentstore" "$GEN" "*.xml" \
    "root location is configurable via dir.contentstore property"

# ---- Unit test ----
TEST_JAVA=$(find "$GEN" -name "*ContentStoreTest.java" | head -1) || true
assert_file_exists "${TEST_JAVA:-/nonexistent}" "*ContentStoreTest.java exists"

print_summary "content-store"
exit_with_status
