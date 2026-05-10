#!/usr/bin/env bash
set -euo pipefail

bash tool/check_offline_imports.sh
dart run build_runner build --force-jit
flutter analyze
flutter test
