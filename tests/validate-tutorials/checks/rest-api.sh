#!/usr/bin/env bash
# Checker: rest-api (v1 Public REST API)
# Usage: rest-api.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== rest-api ===\n'

# ---- Common checks ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

MODULE_CTX=$(find "$GEN" -name "module-context.xml" -not -path "*/target/*" | head -1) || true
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"
else
    _fail "module-context.xml exists" "not found under $GEN"
fi

# ---- Entity resource class ----
ENTITY_JAVA=$(find "$GEN" -name "*EntityResource.java" | grep -v "Test" | head -1) || true
assert_file_exists "${ENTITY_JAVA:-/nonexistent}" "*EntityResource.java exists"
if [[ -n "$ENTITY_JAVA" ]]; then
    assert_grep "@EntityResource" "$ENTITY_JAVA" \
        "entity resource is annotated @EntityResource"
    assert_grep "implements EntityResourceAction" "$ENTITY_JAVA" \
        "entity resource implements an EntityResourceAction interface"
    assert_grep "@WebApiDescription" "$ENTITY_JAVA" \
        "entity resource action methods carry @WebApiDescription"
    assert_grep "CollectionWithPagingInfo" "$ENTITY_JAVA" \
        "entity resource returns CollectionWithPagingInfo (paged)"
    assert_not_grep "DeclarativeWebScript" "$ENTITY_JAVA" \
        "entity resource does not extend DeclarativeWebScript (classic framework)"
    assert_not_grep "@Autowired" "$ENTITY_JAVA" \
        "entity resource does not use forbidden @Autowired"
fi

# ---- Model POJO with @UniqueId ----
assert_grep_any_file "@UniqueId" "$GEN" "*.java" "a model POJO declares @UniqueId"

# ---- Relationship resource class ----
REL_JAVA=$(find "$GEN" -name "*RelationshipResource.java" | grep -v "Test" | head -1) || true
assert_file_exists "${REL_JAVA:-/nonexistent}" "*RelationshipResource.java exists"
if [[ -n "$REL_JAVA" ]]; then
    assert_grep "@RelationshipResource" "$REL_JAVA" \
        "relationship resource is annotated @RelationshipResource"
    assert_grep "entityResource" "$REL_JAVA" \
        "relationship resource references its entityResource"
    assert_grep "@WebApiDescription" "$REL_JAVA" \
        "relationship resource action methods carry @WebApiDescription"
fi

# ---- webscript-context.xml registers the resource beans ----
WS_CTX=$(find "$GEN" -name "webscript-context.xml" -not -path "*/target/*" | head -1) || true
assert_file_exists "${WS_CTX:-/nonexistent}" "webscript-context.xml exists"
if [[ -n "$WS_CTX" ]]; then
    assert_xml_wellformed "$WS_CTX" "webscript-context.xml is well-formed XML"
    assert_grep "EntityResource" "$WS_CTX" \
        "webscript-context.xml registers the entity resource bean"
fi

# ---- module-context.xml imports webscript-context ----
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "webscript-context" "$MODULE_CTX" \
        "module-context.xml imports webscript-context.xml"
fi

# ---- Unit test ----
TEST_JAVA=$(find "$GEN" -name "*EntityResourceTest.java" | head -1) || true
assert_file_exists "${TEST_JAVA:-/nonexistent}" "*EntityResourceTest.java exists"
if [[ -n "$TEST_JAVA" ]]; then
    assert_grep "@ExtendWith(MockitoExtension.class)\|@RunWith(MockitoJUnitRunner" "$TEST_JAVA" \
        "test uses Mockito extension"
    assert_grep "readAll\|readById" "$TEST_JAVA" \
        "test exercises a resource action method"
fi

print_summary "rest-api"
exit_with_status
