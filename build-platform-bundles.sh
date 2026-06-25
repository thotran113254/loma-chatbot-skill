#!/usr/bin/env bash
# Assemble self-contained per-platform instruction bundles from the single source of truth
# (skill/loma-chatbot/SKILL.md). Keeps one canonical skill body; emits ready-to-paste files for
# Codex (AGENTS.md) and ChatGPT Custom GPT. Re-run after editing the SKILL.md body.
set -euo pipefail
cd "$(dirname "$0")"

SKILL="skill/loma-chatbot/SKILL.md"

# Strip the YAML frontmatter (everything between the first two '---' lines) to get the body.
strip_frontmatter() {
  awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{f=0; next} !f{print}' "$1"
}

# Codex bundle -> AGENTS.md at repo root
{ cat platforms/codex-header.md; echo; strip_frontmatter "$SKILL"; } > AGENTS.md

# ChatGPT Custom GPT bundle
{ cat platforms/chatgpt-custom-gpt-header.md; echo; strip_frontmatter "$SKILL"; } \
  > platforms/chatgpt-custom-gpt-instructions.md

echo "Built: AGENTS.md, platforms/chatgpt-custom-gpt-instructions.md"
