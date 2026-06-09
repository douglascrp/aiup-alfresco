#!/usr/bin/env bash
# Cursor afterFileEdit — inject reminder to update REQUIREMENTS.md traceability
# (same intent as scripts/post-generate-traceability.sh). stdout: JSON with
# additional_context when applicable, else empty.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '
  .tool_input.file_path // .tool_input.path // .file_path // .path // .uri // empty
')

if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
  exit 0
fi

IS_GENERATED=false
ARTEFACT_TYPE=""

case "$FILE_PATH" in
  *-model*.xml|*content-model*.xml|*-context.xml|*bootstrap-context.xml)
    ARTEFACT_TYPE="content-model"
    IS_GENERATED=true
    ;;
  *.desc.xml|*.get.js|*.get.java|*.post.js|*.post.java|*.get.json.ftl|*.post.json.ftl)
    ARTEFACT_TYPE="web-script"
    IS_GENERATED=true
    ;;
  *Behaviour.java|*behavior*.xml|*service-context.xml)
    ARTEFACT_TYPE="behaviour"
    IS_GENERATED=true
    ;;
  *ActionExecuter.java)
    ARTEFACT_TYPE="action"
    IS_GENERATED=true
    ;;
  *compose.yaml|*Dockerfile)
    ARTEFACT_TYPE="docker-compose"
    IS_GENERATED=true
    ;;
  *IT.java|*/http-tests/*.sh|http-tests/*.sh)
    ARTEFACT_TYPE="test"
    IS_GENERATED=true
    ;;
esac

if [ "$IS_GENERATED" != true ]; then
  exit 0
fi

PROJECT_DIR=$(pwd)
REQ_FILE=""
for candidate in "$PROJECT_DIR/REQUIREMENTS.md" "$PROJECT_DIR/docs/REQUIREMENTS.md"; do
  if [ -f "$candidate" ]; then
    REQ_FILE="$candidate"
    break
  fi
done

if [ -z "$REQ_FILE" ]; then
  exit 0
fi

MSG="Artefact of type '${ARTEFACT_TYPE}' was written to ${FILE_PATH}. Update the traceability section in ${REQ_FILE} to reflect this generated artefact."

jq -n --arg m "$MSG" '{additional_context: $m}'
exit 0
