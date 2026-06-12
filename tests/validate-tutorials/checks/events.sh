#!/usr/bin/env bash
# Checker: events (Out-of-Process Spring Boot event listener)
# Usage: events.sh <project-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== events ===\n'

# ---- Out-of-Process pom uses alfresco-java-sdk parent (NOT alfresco-sdk-aggregator) ----
assert_grep_any_file "alfresco-java-sdk" "$GEN" "pom.xml" \
    "a pom.xml uses the alfresco-java-sdk parent (Out-of-Process SDK)"

# ---- Event handler class ----
HANDLER_JAVA=$(find "$GEN" -name "*EventHandler.java" | grep -v "Test" | head -1) || true
assert_file_exists "${HANDLER_JAVA:-/nonexistent}" "*EventHandler.java exists"
if [[ -n "$HANDLER_JAVA" ]]; then
    assert_grep "@AlfrescoEventListener" "$HANDLER_JAVA" \
        "handler is annotated @AlfrescoEventListener"
fi

# ---- application.properties broker + exchange config ----
APP_PROPS=$(find "$GEN" -name "application.properties" -not -path "*/target/*" | head -1) || true
assert_file_exists "${APP_PROPS:-/nonexistent}" "application.properties exists"
if [[ -n "$APP_PROPS" ]]; then
    assert_grep "spring.activemq.broker-url" "$APP_PROPS" \
        "application.properties sets spring.activemq.broker-url"
    assert_grep "alfresco.events.defaultExchangeName" "$APP_PROPS" \
        "application.properties sets alfresco.events.defaultExchangeName"
fi

# ---- Out-of-Process boundary: no in-process module layout, no classic web scripts ----
assert_not_grep "alfresco/module" "$GEN" \
    "no in-process alfresco/module layout (Out-of-Process project)"
assert_not_grep "DeclarativeWebScript" "$GEN" \
    "no DeclarativeWebScript (Out-of-Process has no in-process web scripts)"

print_summary "events"
exit_with_status
