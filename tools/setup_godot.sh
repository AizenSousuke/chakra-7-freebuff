#!/usr/bin/env bash
# Installs the Godot 4.7.2 editor + export templates outside the project so
# they are never committed. Re-run after a fresh sandbox/restore.
set -euo pipefail

VERSION="4.7.2"
FLAVOR="stable"
BASE="https://github.com/godotengine/godot/releases/download/${VERSION}-${FLAVOR}"
TOOLS="$HOME/tools"
TEMPLATES="$HOME/.local/share/godot/export_templates/${VERSION}.${FLAVOR}"

mkdir -p "$TOOLS" "$(dirname "$TEMPLATES")"

if [ ! -x "$TOOLS/Godot_v${VERSION}-${FLAVOR}_linux.x86_64" ]; then
  curl -sSL --fail -o "$TOOLS/godot.zip" "$BASE/Godot_v${VERSION}-${FLAVOR}_linux.x86_64.zip"
  unzip -oq "$TOOLS/godot.zip" -d "$TOOLS"
  chmod +x "$TOOLS/Godot_v${VERSION}-${FLAVOR}_linux.x86_64"
fi
ln -sf "$TOOLS/Godot_v${VERSION}-${FLAVOR}_linux.x86_64" "$TOOLS/godot"

if [ ! -d "$TEMPLATES" ]; then
  curl -sSL --fail -o "$TOOLS/templates.tpz" "$BASE/Godot_v${VERSION}-${FLAVOR}_export_templates.tpz"
  rm -rf "$TOOLS/tpl" && mkdir -p "$TOOLS/tpl"
  unzip -oq "$TOOLS/templates.tpz" -d "$TOOLS/tpl"
  mv "$TOOLS/tpl/templates" "$TEMPLATES"
fi

"$TOOLS/godot" --version
echo "templates: $TEMPLATES"
