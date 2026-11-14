#!/usr/bin/env bash
# Export every target. Run tools/setup_godot.sh first; Android also needs the
# JDK 17 + Android SDK described in the README.
set -euo pipefail

GODOT="${GODOT:-$HOME/tools/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p build/web build/linux build/windows

"$GODOT" --headless --path . --export-release "Web" "build/web/index.html"
"$GODOT" --headless --path . --export-release "Linux" "build/linux/Chainfall.x86_64"
"$GODOT" --headless --path . --export-release "Windows" "build/windows/Chainfall.exe"

echo "web:     build/web/index.html"
echo "linux:   build/linux/Chainfall.x86_64"
echo "windows: build/windows/Chainfall.exe"

# Android needs a debug keystore and an SDK path registered in Godot's editor
# settings; export the signed debug APK only when that toolchain is present.
if [ -d "$HOME/android/sdk" ] && [ -f "$HOME/.local/share/godot/keystores/debug.keystore" ]; then
  export JAVA_HOME="${JAVA_HOME:-$HOME/android/jdk}"
  mkdir -p build/android
  "$GODOT" --headless --path . --export-debug "Android" "build/android/Chainfall-debug.apk"
  echo "android: build/android/Chainfall-debug.apk"
else
  echo "android: skipped (Android SDK / debug keystore not installed)"
fi
