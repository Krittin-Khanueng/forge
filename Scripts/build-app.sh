#!/usr/bin/env bash
# Build a runnable Forge.app from the SwiftPM package.
#
# `swift build` only emits a bare executable — no bundle identifier, so the
# login item (SMAppService) and notifications (UNUserNotificationCenter) refuse
# to work. This wraps the release binary in a proper .app and ad-hoc signs it.
#
# Usage: Scripts/build-app.sh [version]   (version defaults to 1.0)
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-1.0}"
APP="dist/Forge.app"
BUNDLE_ID="com.forge.app"   # matches the Logger subsystem used throughout the code

echo "▸ swift build -c release"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

echo "▸ assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/Forge" "$APP/Contents/MacOS/Forge"

# SwiftPM compiles the asset catalog into a resource bundle; place it where
# Bundle.module (= Bundle.main.resourceURL for an .app) will find it.
for bundle in "$BIN_DIR"/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>          <string>Forge</string>
	<key>CFBundleIdentifier</key>          <string>$BUNDLE_ID</string>
	<key>CFBundleName</key>                <string>Forge</string>
	<key>CFBundlePackageType</key>         <string>APPL</string>
	<key>CFBundleShortVersionString</key>  <string>$VERSION</string>
	<key>CFBundleVersion</key>             <string>$VERSION</string>
	<key>LSMinimumSystemVersion</key>      <string>26.0</string>
	<key>NSPrincipalClass</key>            <string>NSApplication</string>
	<key>NSHumanReadableCopyright</key>    <string>Copyright © 2026 Forge. All rights reserved.</string>
</dict>
</plist>
PLIST

echo "▸ ad-hoc codesign (hardened runtime + entitlements)"
codesign --force --sign - \
    --entitlements Forge/Resources/Forge.entitlements \
    --options runtime \
    "$APP"

codesign --verify --strict "$APP"
echo "✓ built $APP (v$VERSION) — run: open $APP"
# ponytail: no app icon embedded — the asset catalog ships no .icns, so the app
# gets the generic icon. Add an AppIcon.icns to Contents/Resources here if wanted.
