#!/usr/bin/env bash
# Install the platform skills (chatbot operator + open-platform integrator) into Claude Code.
#   ./install-claude-code-skill.sh            # install for current project (./.claude/skills)
#   ./install-claude-code-skill.sh --global   # install for all projects (~/.claude/skills)
set -euo pipefail
cd "$(dirname "$0")"

DEST=".claude/skills"
[ "${1:-}" = "--global" ] && DEST="$HOME/.claude/skills"

for name in skill/*/; do
  name="$(basename "$name")"
  mkdir -p "$DEST/$name"
  cp "skill/$name/SKILL.md" "$DEST/$name/SKILL.md"
  echo "Installed $name skill -> $DEST/$name/SKILL.md"
done
echo "Next: add the MCP server. Copy .mcp.json into your project root (or merge it),"
echo "then export MCP_API_BASE and MCP_TOKEN (from your dashboard -> Settings -> AI Connect)."
