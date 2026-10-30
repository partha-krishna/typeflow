#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/Typeflow.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/native/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/native/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
clang -fobjc-arc -O2 -framework AppKit -framework ApplicationServices "$ROOT/native/main.m" -o "$APP/Contents/MacOS/Typeflow"
codesign --force --deep --sign - "$APP"
echo "Built $APP"
echo "Open it, then enable Typeflow in System Settings > Privacy & Security > Accessibility and Input Monitoring. Relaunch after granting access."
