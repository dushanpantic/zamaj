#!/usr/bin/env bash
set -euo pipefail

SEARCH_DIRS=(
  "lib/core"
  "lib/modules/domain"
  "lib/modules/persistence"
)

FORBIDDEN_PATTERNS=(
  "import 'dart:io'"
  'import "dart:io"'
  "import 'package:http/"
  'import "package:http/'
  "import 'package:dio/"
  'import "package:dio/'
  "import 'package:web_socket_channel/"
  'import "package:web_socket_channel/'
  "import 'package:grpc/"
  'import "package:grpc/'
  "import 'package:socket_io_client/"
  'import "package:socket_io_client/'
)

found=0

for dir in "${SEARCH_DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    continue
  fi

  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    matches=$(grep -rn --include="*.dart" -F "$pattern" "$dir" 2>/dev/null || true)
    if [ -n "$matches" ]; then
      echo "FORBIDDEN IMPORT FOUND: $pattern"
      echo "$matches"
      found=1
    fi
  done
done

if [ "$found" -ne 0 ]; then
  echo ""
  echo "ERROR: Offline-first isolation violated. Remove the imports listed above."
  exit 1
fi

echo "check_offline_imports: OK"
