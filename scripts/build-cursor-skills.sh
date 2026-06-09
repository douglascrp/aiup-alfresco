#!/usr/bin/env bash
# Regenerate .cursor/skills/ from skills/, agents/, and commands/.
# Source files under skills/ keep Claude Code frontmatter; Cursor copies use name + description only.

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CURSOR_SKILLS="$ROOT_DIR/.cursor/skills"
COMMANDS_DIR="$ROOT_DIR/commands"

strip_claude_frontmatter() {
    awk '
        NR == 1 && $0 == "---" { in_fm = 1; next }
        in_fm && $0 == "---" { in_fm = 0; next }
        !in_fm { print }
    ' "$1"
}

extract_yaml_field() {
    local file="$1"
    local field="$2"
    awk -v field="$field" '
        /^---$/ { if (++block == 1) next; if (block == 2) exit }
        block == 1 && $0 ~ "^" field ":" {
            sub("^" field ":[[:space:]]*", "")
            gsub(/^"/, "")
            gsub(/"$/, "")
            print
            exit
        }
    ' "$file"
}

write_cursor_skill() {
    local name="$1"
    local description="$2"
    local body_file="$3"
    local dest="$CURSOR_SKILLS/$name"

    mkdir -p "$dest"
    {
        echo "---"
        echo "name: $name"
        echo "description: $description"
        echo "---"
        echo ""
        strip_claude_frontmatter "$body_file"
    } > "$dest/SKILL.md"
}

rm -rf "$CURSOR_SKILLS"
mkdir -p "$CURSOR_SKILLS"

# --- Validator / helper skills (from skills/) ---
for skill_dir in "$ROOT_DIR/skills"/*/; do
    [ -f "${skill_dir}SKILL.md" ] || continue
    name=$(basename "$skill_dir")
    description=$(extract_yaml_field "${skill_dir}SKILL.md" "description")
    [ -n "$description" ] || description="AIUP Alfresco skill: $name"
    write_cursor_skill "$name" "$description" "${skill_dir}SKILL.md"
done

# --- Deep-guidance agents (from agents/) ---
for agent_file in "$ROOT_DIR/agents"/*.md; do
    [ -f "$agent_file" ] || continue
    name=$(extract_yaml_field "$agent_file" "name")
    [ -n "$name" ] || name=$(basename "$agent_file" .md)
    description=$(extract_yaml_field "$agent_file" "description")
    [ -n "$description" ] || description="AIUP Alfresco agent guidance: $name"
    write_cursor_skill "$name" "$description" "$agent_file"
done

# --- Orchestrator skill (commands index) ---
ORCH="$CURSOR_SKILLS/aiup-alfresco/SKILL.md"
mkdir -p "$(dirname "$ORCH")"

{
    echo "---"
    echo "name: aiup-alfresco"
    echo "description: Runs AIUP Alfresco extension workflow steps (requirements, scaffold, content-model, web-scripts, docker-compose, test, and more). Use when the user asks to execute an AIUP command or develop Alfresco extensions following AGENTS.md."
    echo "---"
    echo ""
    echo "# AIUP Alfresco — command orchestrator"
    echo ""
    echo "Cursor has no \`/scaffold\` slash commands. AIUP steps live in \`commands/<name>.md\`."
    echo ""
    echo "## Before any step"
    echo ""
    echo "1. Read \`AGENTS.md\` at the repository root."
    echo "2. Open \`commands/<name>.md\` for the requested step."
    echo "3. Apply referenced skills under \`.cursor/skills/\` or \`skills/\` when the command mentions them."
    echo "4. Create or update real files; do not stop at a summary unless the user asked for a plan only."
    echo ""
    echo "## Available commands"
    echo ""
    echo "| Command | Description |"
    echo "|---------|-------------|"
} > "$ORCH"

while IFS= read -r file; do
    cmd=$(basename "$file" .md)
    desc=$(extract_yaml_field "$file" "description")
    printf '| `%s` | %s |\n' "$cmd" "$desc" >> "$ORCH"
done < <(find "$COMMANDS_DIR" -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort)

{
    echo ""
    echo "## Typical order"
    echo ""
    echo "1. \`requirements\` — architecture decision + REQUIREMENTS.md"
    echo "2. \`scaffold\` — project skeleton (requires REQUIREMENTS.md)"
    echo "3. Feature commands as needed, for example:"
    echo "   - Platform JAR: \`content-model\`, \`behaviours\`, \`web-scripts\`, \`actions\`, \`workflow\`, \`scheduled-jobs\`, \`bootstrap-loader\`, \`rule-conditions\`, \`repository-patch\`, \`transforms\`"
    echo "   - Out-of-process: \`events\`"
    echo "   - Share JAR: \`share-config\`, \`surf\`, \`aikau\`"
    echo "   - ACA/ADW: \`aca-extension\`"
    echo "4. \`docker-compose\` — before integration tests"
    echo "5. \`test\` — last"
    echo ""
    echo "## Rendered prompt (optional)"
    echo ""
    echo "\`\`\`bash"
    echo "./scripts/aiup-command.sh render --agent cursor <command> [args...]"
    echo "\`\`\`"
    echo ""
    echo "See \`CURSOR.md\` for hooks, @ references, and troubleshooting."
} >> "$ORCH"

skill_dirs=$(find "$CURSOR_SKILLS" -mindepth 1 -maxdepth 1 -type d | wc -l)
cmd_count=$(find "$COMMANDS_DIR" -maxdepth 1 -type f -name '*.md' | wc -l)
orch_count=$(grep -c '^| `' "$ORCH" || true)

if [ "$cmd_count" -ne "$orch_count" ]; then
    printf 'Error: orchestrator lists %s commands but commands/ has %s\n' "$orch_count" "$cmd_count" >&2
    exit 1
fi

printf 'Generated %s Cursor skills (%s commands in orchestrator) in %s\n' "$skill_dirs" "$orch_count" "$CURSOR_SKILLS"
