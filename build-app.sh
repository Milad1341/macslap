#!/bin/bash
# Build MacSlap as a distributable .app bundle
set -e

cd "$(dirname "$0")"

APP_NAME="MacSlap"
BUNDLE_ID="com.milad.macslap"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_DIR="$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Building $APP_NAME in release mode..."
swift build -c release 2>/dev/null

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS/$APP_NAME"

# Copy bundled resources (SPM puts them next to the binary)
if [ -d "$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle" ]; then
    cp -R "$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle" "$MACOS/"
fi

# Create Info.plist
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>MacSlap</string>
    <key>CFBundleDisplayName</key>
    <string>MacSlap</string>
    <key>CFBundleIdentifier</key>
    <string>com.milad.macslap</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>MacSlap</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSHumanReadableCopyright</key>
    <string>Developed by Milad</string>
</dict>
</plist>
PLIST

# Create .icns from the logo PNG
echo "Creating app icon..."
ICONSET_DIR="$APP_NAME.iconset"
mkdir -p "$ICONSET_DIR"

LOGO="Sources/MacSlap/Resources/MacSlap.png"
if [ -f "$LOGO" ]; then
    sips -z 16 16     "$LOGO" --out "$ICONSET_DIR/icon_16x16.png"      > /dev/null 2>&1
    sips -z 32 32     "$LOGO" --out "$ICONSET_DIR/icon_16x16@2x.png"   > /dev/null 2>&1
    sips -z 32 32     "$LOGO" --out "$ICONSET_DIR/icon_32x32.png"      > /dev/null 2>&1
    sips -z 64 64     "$LOGO" --out "$ICONSET_DIR/icon_32x32@2x.png"   > /dev/null 2>&1
    sips -z 128 128   "$LOGO" --out "$ICONSET_DIR/icon_128x128.png"    > /dev/null 2>&1
    sips -z 256 256   "$LOGO" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256   "$LOGO" --out "$ICONSET_DIR/icon_256x256.png"    > /dev/null 2>&1
    sips -z 512 512   "$LOGO" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512   "$LOGO" --out "$ICONSET_DIR/icon_512x512.png"    > /dev/null 2>&1
    sips -z 1024 1024 "$LOGO" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1

    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES/AppIcon.icns" 2>/dev/null || echo "Warning: iconutil failed, icon may not show in Finder"
    rm -rf "$ICONSET_DIR"
fi

# Ad-hoc sign (needed for macOS to run it without Gatekeeper complaints on same machine)
echo "Signing app bundle..."
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || echo "Warning: codesign failed, app may need manual approval"

echo ""
echo "============================================"
echo "  MacSlap.app built successfully!"
echo "============================================"
echo ""
echo "  Location: $(pwd)/$APP_DIR"
echo ""
echo "  To run:   open $APP_DIR"
echo "  To share: zip the $APP_DIR folder"
echo ""
echo "  Note: Recipients may need to right-click"
echo "  and choose 'Open' the first time, since"
echo "  the app is not notarized."
echo "============================================"
