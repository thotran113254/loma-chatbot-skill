#!/usr/bin/env bash
# Install the chatbot skills into a skill-capable AI client.
#
#   ./install.sh claude-code             -> ./.claude/skills        (this project)
#   ./install.sh claude-code --global    -> ~/.claude/skills        (all projects)
#   ./install.sh codex                   -> ~/.agents/skills        (user-wide)
#   ./install.sh codex --project         -> ./.agents/skills        (this workspace)
#
# Claude desktop/web and ChatGPT take uploads instead: run ./build-release-bundles.sh
# and upload the zips from release/.
set -euo pipefail
# "This project" means the directory you ran the installer FROM, not the clone.
# Sources are read from the clone; a project-scoped destination stays where the
# user is standing, which is what every line below advertises.
INVOKE_DIR="$PWD"
cd "$(dirname "$0")"
SRC_DIR="$PWD"

TARGET="${1:-}"
SCOPE="${2:-}"
SKILLS=(chatbot-builder chatbot-ops)

usage() {
  echo "usage: $0 {claude-code|codex} [--global|--project]" >&2
  exit 1
}

case "$TARGET" in
  claude-code)
    DEST="$INVOKE_DIR/.claude/skills"
    [ "$SCOPE" = "--global" ] && DEST="$HOME/.claude/skills"
    ;;
  codex)
    DEST="$HOME/.agents/skills"
    [ "$SCOPE" = "--project" ] && DEST="$INVOKE_DIR/.agents/skills"
    ;;
  *) usage ;;
esac

for skill in "${SKILLS[@]}"; do
  rm -rf "$DEST/$skill"
  mkdir -p "$DEST"
  cp -R "$SRC_DIR/skills/$skill" "$DEST/$skill"
  echo "installed $skill -> $DEST/$skill"
done

echo
echo "Next: attach the MCP connector."
case "$TARGET" in
  claude-code)
    echo "  copy .mcp.json into your project root, then export MCP_API_BASE and MCP_TOKEN"
    ;;
  codex)
    echo "  add [mcp_servers.chatbot] to ~/.codex/config.toml with your URL + Bearer token"
    echo "  (see README.md), then restart Codex"
    ;;
esac
echo "Values come from your dashboard -> Settings -> AI Connect."
