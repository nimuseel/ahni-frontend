#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

mkdir -p "$temp_dir/bin" "$temp_dir/scripts"
cp "$repo_root/scripts/dev" "$temp_dir/scripts/dev"

printf '%s\n' \
  'APP_ENV=development' \
  'SUPABASE_URL=https://example.supabase.co' \
  'SUPABASE_PUBLISHABLE_KEY=test-publishable-key' \
  'API_BASE_URL=http://localhost:8080' \
  > "$temp_dir/.env.local"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf '\''%s\n'\'' "$@" > "$FLUTTER_ARGS_OUTPUT"' \
  > "$temp_dir/bin/flutter"
chmod +x "$temp_dir/bin/flutter"

args_output="$temp_dir/flutter-args"
env \
  -u APP_ENV \
  -u SUPABASE_URL \
  -u SUPABASE_PUBLISHABLE_KEY \
  -u API_BASE_URL \
  PATH="$temp_dir/bin:$PATH" \
  FLUTTER_ARGS_OUTPUT="$args_output" \
  "$temp_dir/scripts/dev"

expected_output="$temp_dir/expected-args"
printf '%s\n' \
  'run' \
  '--dart-define=APP_ENV=development' \
  '--dart-define=SUPABASE_URL=https://example.supabase.co' \
  '--dart-define=SUPABASE_PUBLISHABLE_KEY=test-publishable-key' \
  '--dart-define=API_BASE_URL=http://localhost:8080' \
  > "$expected_output"

diff -u "$expected_output" "$args_output"
