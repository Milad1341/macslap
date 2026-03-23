#!/bin/bash
# MacSlap launcher — builds and creates a proper .app bundle
set -e
cd "$(dirname "$0")"

echo "Building MacSlap..."
swift build 2>/dev/null

APP="MacSlap.app"
rm -rf "$APP"

# Create .app bundle structure
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

# Copy binary
cp .build/debug/MacSlap "$APP/Contents/MacOS/"

# Copy resource bundle (sound packs)
if [ -d ".build/debug/MacSlap_MacSlap.bundle" ]; then
    cp -r .build/debug/MacSlap_MacSlap.bundle "$APP/Contents/Resources/"
fi

# Copy app icon
if [ -f "MacSlap.icns" ]; then
    cp MacSlap.icns "$APP/Contents/Resources/"
fi

# Create Info.plist
cat > "$APP/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacSlap</string>
    <key>CFBundleIdentifier</key>
    <string>com.macslap.app</string>
    <key>CFBundleName</key>
    <string>MacSlap</string>
    <key>CFBundleIconFile</key>
    <string>MacSlap</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Created MacSlap.app"
echo ""
echo "Launching MacSlap — look for ✋ in your menu bar!"
echo "If the sensor needs root, a password prompt will appear."
echo ""

# Launch the .app bundle — this properly connects to the GUI session
open "$APP"
