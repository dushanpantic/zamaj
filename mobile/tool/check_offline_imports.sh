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

# --- UI module superset check (program_management, workout_day_picker) ---

PM_DIRS=(
  "lib/modules/program_management"
  "lib/modules/workout_day_picker"
  "lib/modules/workout_overview"
  "lib/modules/export"
  "lib/modules/exercise_library"
  "lib/modules/exercise_progress"
)

PM_NETWORKING_PATTERNS=(
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

PM_DRIFT_PATTERNS=(
  "import 'package:drift/"
  'import "package:drift/'
  "import 'package:drift_flutter/"
  'import "package:drift_flutter/'
  "import 'package:sqlite3/"
  'import "package:sqlite3/'
)

PM_DART_IO_SYMBOLS=(
  "HttpClient"
  "HttpServer"
  "Socket"
  "ServerSocket"
  "RawSocket"
  "SecureSocket"
  "SecureServerSocket"
)

PM_DB_SYMBOLS=(
  "AppDatabase"
  "NativeDatabase"
  "driftDatabase"
  "GeneratedDatabase"
)

pm_found=0

emit_violation() {
  local file="$1"
  local line="$2"
  local symbol="$3"
  echo "${file}:${line}:${symbol}"
  pm_found=1
}

for PM_DIR in "${PM_DIRS[@]}"; do
  if [ ! -d "$PM_DIR" ]; then
    continue
  fi

  # Check networking import patterns
  for pattern in "${PM_NETWORKING_PATTERNS[@]}"; do
    while IFS=: read -r file line _rest; do
      [ -n "$file" ] && emit_violation "$file" "$line" "$pattern"
    done < <(grep -rn --include="*.dart" \
      --exclude="*.freezed.dart" --exclude="*.g.dart" \
      -F "$pattern" "$PM_DIR" 2>/dev/null || true)
  done

  # Check drift/sqlite import patterns
  for pattern in "${PM_DRIFT_PATTERNS[@]}"; do
    while IFS=: read -r file line _rest; do
      [ -n "$file" ] && emit_violation "$file" "$line" "$pattern"
    done < <(grep -rn --include="*.dart" \
      --exclude="*.freezed.dart" --exclude="*.g.dart" \
      -F "$pattern" "$PM_DIR" 2>/dev/null || true)
  done

  # Check imports of *.g.dart files under lib/modules/persistence/
  while IFS=: read -r file line _rest; do
    [ -n "$file" ] && emit_violation "$file" "$line" "import of persistence *.g.dart"
  done < <(grep -rn --include="*.dart" \
    --exclude="*.freezed.dart" --exclude="*.g.dart" \
    -E "import ['\"]package:zamaj/modules/persistence/[^'\"]*\.g\.dart['\"]" \
    "$PM_DIR" 2>/dev/null || true)

  # Also catch relative imports of persistence .g.dart files
  while IFS=: read -r file line _rest; do
    [ -n "$file" ] && emit_violation "$file" "$line" "import of persistence *.g.dart"
  done < <(grep -rn --include="*.dart" \
    --exclude="*.freezed.dart" --exclude="*.g.dart" \
    -E "import ['\"][^'\"]*lib/modules/persistence/[^'\"]*\.g\.dart['\"]" \
    "$PM_DIR" 2>/dev/null || true)

  # Check dart:io socket/HTTP symbol references
  for symbol in "${PM_DART_IO_SYMBOLS[@]}"; do
    while IFS=: read -r file line _rest; do
      [ -n "$file" ] && emit_violation "$file" "$line" "$symbol"
    done < <(grep -rn --include="*.dart" \
      --exclude="*.freezed.dart" --exclude="*.g.dart" \
      -w "$symbol" "$PM_DIR" 2>/dev/null || true)
  done

  # Check forbidden database symbols
  for symbol in "${PM_DB_SYMBOLS[@]}"; do
    while IFS=: read -r file line _rest; do
      [ -n "$file" ] && emit_violation "$file" "$line" "$symbol"
    done < <(grep -rn --include="*.dart" \
      --exclude="*.freezed.dart" --exclude="*.g.dart" \
      -w "$symbol" "$PM_DIR" 2>/dev/null || true)
  done
done

if [ "$pm_found" -ne 0 ]; then
  echo ""
  echo "ERROR: UI module offline-first isolation violated. Remove the symbols listed above."
  exit 1
fi

echo "check_offline_imports: OK"
