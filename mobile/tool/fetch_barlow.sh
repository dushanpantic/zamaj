#!/usr/bin/env bash
# Downloads the four bundled Barlow weights (OFL-1.1) + the license into
# assets/fonts/. Run once from mobile/:
#
#   tool/fetch_barlow.sh
#
# Then add the `fonts:` block under `flutter:` in pubspec.yaml (see below /
# plan Step 8.1) and run tool/ci.sh. AppTypography already references the
# 'Barlow' family; until these files are bundled the app falls back to the
# platform face.
set -euo pipefail

dest="assets/fonts"
base="https://github.com/google/fonts/raw/main/ofl/barlow"
mkdir -p "$dest"

for f in Barlow-Regular.ttf Barlow-Medium.ttf Barlow-SemiBold.ttf Barlow-Bold.ttf; do
  echo "Fetching $f"
  curl -fsSL "$base/$f" -o "$dest/$f"
done
curl -fsSL "$base/OFL.txt" -o "$dest/OFL.txt"

cat <<'EOF'

Barlow weights + OFL license are now in assets/fonts/.

Add this under `flutter:` in pubspec.yaml, then run tool/ci.sh:

  fonts:
    - family: Barlow
      fonts:
        - asset: assets/fonts/Barlow-Regular.ttf
          weight: 400
        - asset: assets/fonts/Barlow-Medium.ttf
          weight: 500
        - asset: assets/fonts/Barlow-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Barlow-Bold.ttf
          weight: 700
EOF
