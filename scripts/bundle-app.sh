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

echo "==> Signing app bundle..."
codesign --force --deep --sign - "$BUNDLE_DIR"

echo "==> Done: $BUNDLE_DIR"
echo ""
echo "Run with:"
echo "  open \"$BUNDLE_DIR\""
echo ""
echo "Or directly:"
echo "  \"$BUNDLE_DIR/Contents/MacOS/$PRODUCT\""
