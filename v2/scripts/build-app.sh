#!/bin/bash
# Builds a universal (Apple silicon + Intel) Kalk.app into dist/. Pass --dmg to also create a disk image.
set -euo pipefail
cd "$(dirname "$0")/.."

ARCHS=(--arch arm64 --arch x86_64)
swift build -c release "${ARCHS[@]}"
BIN_DIR=$(swift build -c release "${ARCHS[@]}" --show-bin-path)

APP=dist/Kalk.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Kalk" "$APP/Contents/MacOS/Kalk"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns Resources/logo.png "$APP/Contents/Resources/"
# mathjs and the KaTeX page, which SwiftPM would otherwise put in resource bundles beside the binary.
cp Sources/KalkMath/Resources/math.min.js "$APP/Contents/Resources/"
cp -R Sources/Kalk/Web "$APP/Contents/Resources/Web"

# Ad-hoc signature so the app runs locally. Use a Developer ID identity to distribute it.
codesign --force --sign "${CODESIGN_IDENTITY:--}" "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--dmg" ]]; then
  DMG=dist/Kalk.dmg
  STAGING=$(mktemp -d)
  cp -R "$APP" "$STAGING/"
  ln -s /Applications "$STAGING/Applications"
  rm -f "$DMG"
  hdiutil create -volname Kalk -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
  rm -rf "$STAGING"
  echo "Built $DMG"
fi
