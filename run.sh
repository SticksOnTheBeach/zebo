#!/bin/bash
# Compile Zebo, assemble le bundle Zebo.app et le lance.
set -euo pipefail
cd "$(dirname "$0")"

swift build
BIN_DIR="$(swift build --show-bin-path)"

APP="build/Zebo.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/Zebo" "$APP/Contents/MacOS/Zebo"
cp Info.plist "$APP/Contents/Info.plist"
# Ressources des modules (logos des langages…), là où l'app les cherche.
mkdir -p "$APP/Contents/Resources"
for bundle in "$BIN_DIR"/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done
# iCloud (~/Documents) ajoute des attributs Finder qui empêchent la signature : on les retire.
xattr -cr "$APP"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1

pkill -x Zebo || true
open "$APP"
