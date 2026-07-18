#!/usr/bin/env bash
# Install the Loma Chatbot skill into Claude Code.
#   ./install-claude-code-skill.sh            # install for current project (./.claude/skills)
#   ./install-claude-code-skill.sh --global   # install for all projects (~/.claude/skills)
set -euo pipefail
cd "$(dirname "$0")"

DEST=".claude/skills"
[ "${1:-}" = "--global" ] && DEST="$HOME/.claude/skills"

mkdir -p "$DEST/loma-chatbot"
cp skill/loma-chatbot/SKILL.md "$DEST/loma-chatbot/SKILL.md"
echo "Installed loma-chatbot skill -> $DEST/loma-chatbot/SKILL.md"
echo "Next: add the Loma MCP server. Copy .mcp.json into your project root (or merge it),"
echo "then export MCP_API_BASE and MCP_TOKEN (from your dashboard -> Settings -> AI Connect)."
