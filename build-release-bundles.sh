#!/usr/bin/env bash
# Package each skill as an upload-ready zip for Claude desktop/web and ChatGPT,
# and regenerate the Codex AGENTS.md pointer.
#
#   ./build-release-bundles.sh
#
# Output: release/chatbot-builder.zip, release/chatbot-ops.zip
# Each zip contains the skill folder at its root (SKILL.md, agents/, references/),
# which is what both upload flows expect.
set -euo pipefail
cd "$(dirname "$0")"

SKILLS=(chatbot-builder chatbot-ops)
mkdir -p release

# Zip with the `zip` CLI when present, else fall back to python3's zipfile so the
# script works on a bare box without extra packages.
zip_skill() {
  local skill="$1"
  if command -v zip >/dev/null; then
    ( cd skills && zip -qr "../release/$skill.zip" "$skill" -x '*.DS_Store' )
  elif command -v python3 >/dev/null; then
    python3 - "$skill" <<'PY'
import os, sys, zipfile
skill = sys.argv[1]
root = os.path.join('skills', skill)
with zipfile.ZipFile(os.path.join('release', f'{skill}.zip'), 'w', zipfile.ZIP_DEFLATED) as z:
    for dirpath, _, files in os.walk(root):
        for name in files:
            if name == '.DS_Store':
                continue
            full = os.path.join(dirpath, name)
            z.write(full, os.path.relpath(full, 'skills'))
PY
  else
    echo "need either the zip CLI or python3 to build bundles" >&2
    exit 1
  fi
}

for skill in "${SKILLS[@]}"; do
  [ -f "skills/$skill/SKILL.md" ] || { echo "missing skills/$skill/SKILL.md" >&2; exit 1; }
  rm -f "release/$skill.zip"
  zip_skill "$skill"
  echo "built release/$skill.zip"
done

# Sanity check: the limits the skill standard cares about.
for f in skills/*/SKILL.md skills/*/references/*.md; do
  lines=$(wc -l < "$f")
  [ "$lines" -le 300 ] || echo "WARNING: $f is $lines lines (keep under 300)"
done
