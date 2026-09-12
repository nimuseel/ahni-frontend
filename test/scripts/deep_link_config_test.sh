#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

grep -A1 '<key>FlutterDeepLinkingEnabled</key>' "$repo_root/ios/Runner/Info.plist" \
  | grep -q '<false/>'

grep -A2 'android:name="flutter_deeplinking_enabled"' \
  "$repo_root/android/app/src/main/AndroidManifest.xml" \
  | grep -q 'android:value="false"'
