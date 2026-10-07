#!/bin/bash
# Prépare une version à publier : Zebo.app compilé en release, zippé dans build/Zebo-<version>.zip.
set -euo pipefail
cd "$(dirname "$0")"

./bundle.sh release
VERSION="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist)"
ARCHIVE="build/Zebo-$VERSION.zip"
rm -f "$ARCHIVE"
ditto -c -k --keepParent build/Zebo.app "$ARCHIVE"
echo "$ARCHIVE"
