#!/usr/bin/env bash
# Regenerate all launcher icons from the SVG masters in design/app_icon/.
#
# Rasterizes the chosen design's four layers to exports/*.png, then runs
# flutter_launcher_icons to fan out every Android/iOS asset. To switch
# designs, change DESIGN here AND the flutter_launcher_icons paths in
# pubspec.yaml.
#
# Requires rsvg-convert: brew install librsvg
set -euo pipefail

cd "$(dirname "$0")/.."

DESIGN="d_z_dumbbell"
SRC="design/app_icon/$DESIGN"
OUT="$SRC/exports"

command -v rsvg-convert >/dev/null 2>&1 || {
  echo "rsvg-convert not found — install with: brew install librsvg" >&2
  exit 1
}

mkdir -p "$OUT"
for layer in full foreground background monochrome; do
  rsvg-convert -w 1024 -h 1024 "$SRC/$layer.svg" -o "$OUT/$layer-1024.png"
done

# Play Store listing icon — not consumed by the build; upload manually.
rsvg-convert -w 512 -h 512 "$SRC/full.svg" -o "$OUT/play_store-512.png"

dart run flutter_launcher_icons

# flutter_launcher_icons 0.14.x clobbers the wrong Xcode build setting when it
# tries to set ASSETCATALOG_COMPILER_APPICON_NAME (which this project already
# has). Restore the boolean it overwrote with an invalid value.
sed -i '' \
  's/ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon;/ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;/g' \
  ios/Runner.xcodeproj/project.pbxproj

echo "Launcher icons regenerated from $SRC."
