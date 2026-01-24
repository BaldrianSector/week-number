#!/usr/bin/env bash
set -euo pipefail

APP_NAME="WeekNumber"
DMG_NAME="WeekNumber"
PROJECT="WeekNumberMenuBar.xcodeproj"
SCHEME="WeekNumberMenuBar"
CONFIG="Release"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$DIST_DIR/$DMG_NAME"
APP_PATH="$BUILD_DIR/Build/Products/$CONFIG/$APP_NAME.app"
DMG_RW="$DIST_DIR/$DMG_NAME-rw.dmg"
DMG_FINAL="$DIST_DIR/$DMG_NAME.dmg"

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$STAGING_DIR"

xcodebuild -project "$ROOT_DIR/$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" -derivedDataPath "$BUILD_DIR" build

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found at $APP_PATH" >&2
  exit 1
fi

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "$DMG_NAME" -srcfolder "$STAGING_DIR" -ov -format UDRW "$DMG_RW"

MOUNT_DIR="$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_RW" | awk '/\/Volumes\// {print $3; exit}')"
if [[ -z "$MOUNT_DIR" ]]; then
  echo "Failed to mount DMG." >&2
  exit 1
fi

osascript <<EOF
tell application "Finder"
  tell disk "$DMG_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 200, 900, 600}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 96
    set position of item "$APP_NAME.app" of container window to {200, 200}
    set position of item "Applications" of container window to {500, 200}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
EOF

sync

detach_attempts=0
until hdiutil detach "$MOUNT_DIR" -force; do
  detach_attempts=$((detach_attempts + 1))
  if [[ "$detach_attempts" -ge 5 ]]; then
    echo "Failed to detach DMG after multiple attempts." >&2
    exit 1
  fi
  sleep 1
done

sleep 1

convert_attempts=0
until hdiutil convert "$DMG_RW" -format UDZO -ov -o "$DMG_FINAL"; do
  convert_attempts=$((convert_attempts + 1))
  if [[ "$convert_attempts" -ge 5 ]]; then
    echo "Failed to convert DMG after multiple attempts." >&2
    exit 1
  fi
  sleep 1
done

rm -f "$DMG_RW"

echo "Created $DMG_FINAL"
