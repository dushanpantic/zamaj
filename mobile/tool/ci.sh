#!/usr/bin/env bash
set -euo pipefail

tool/check_offline_imports.sh
dart run build_runner build --force-jit
dart format .
flutter analyze
flutter test
