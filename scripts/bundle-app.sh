#!/bin/bash
set -euo pipefail

MODE="${1:-debug}"
PRODUCT="GitHubSentry"
APP_NAME="GitHub Sentry"
BUNDLE_DIR="build/${APP_NAME}.app"

echo "==> Building ($MODE)..."
if [ "$MODE" = "release" ]; then
    swift build -c release
    BINARY=".build/release/$PRODUCT"
else
    swift build
    BINARY=".build/debug/$PRODUCT"
fi

echo "==> Creating app bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

cp "$BINARY" "$BUNDLE_DIR/Contents/MacOS/$PRODUCT"
cp Resources/Info.plist "$BUNDLE_DIR/Contents/"

# Generate app icon
echo "==> Generating app icon..."
ICONSET="build/AppIcon.iconset"
mkdir -p "$ICONSET"
for SIZE in 16 32 64 128 256 512; do
    sips -z $SIZE $SIZE github-sentry.png --out "$ICONSET/icon_${SIZE}x${SIZE}.png" > /dev/null 2>&1
done
for SIZE in 16 32 128 256 512; do
    DOUBLE=$((SIZE * 2))
    sips -z $DOUBLE $DOUBLE github-sentry.png --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" > /dev/null 2>&1
done
iconutil -c icns "$ICONSET" -o "$BUNDLE_DIR/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

echo "==> Signing app bundle..."
codesign --force --deep --sign - "$BUNDLE_DIR"

echo "==> Done: $BUNDLE_DIR"
echo ""
echo "Run with:"
echo "  open \"$BUNDLE_DIR\""
echo ""
echo "Or directly:"
echo "  \"$BUNDLE_DIR/Contents/MacOS/$PRODUCT\""
