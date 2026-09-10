#!/usr/bin/env bash
set -Eeuo pipefail

WORKSPACE_ROOT="${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}"
SOURCE_DIR="${SOURCE_DIR:-$WORKSPACE_ROOT/source}"
SKILL_DIR="${SKILL_DIR:-$SOURCE_DIR/dist/runtime-skills}"
IOS_DIR="${IOS_DIR:-$SOURCE_DIR/dist/ios-unsigned}"
IPA="${IPA:-$IOS_DIR/TauriTavern-unsigned.ipa}"
APP_ZIP="${APP_ZIP:-$IOS_DIR/TauriTavern.app.zip}"
BUNDLE_DIR_NAME="AdultTensionRuntimeSkills"

required_files=(
  "adult-tension-cbfdc623.zip"
  "adult-tension-continuity-graduation-final-v2-tauritavern-fixed.zip"
  "adult-tension-tauritavern-adapter-build14.zip"
  "skills-manifest.json"
  "SKILL-SHA256SUMS.txt"
)

for file in "${required_files[@]}"; do
  test -f "$SKILL_DIR/$file"
done

test -f "$IPA"
test -f "$APP_ZIP"

(
  cd "$SKILL_DIR"
  sha256sum -c SKILL-SHA256SUMS.txt
)

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/ipa"
unzip -q "$IPA" -d "$TMP_DIR/ipa"

APP_DIR=""
for candidate in "$TMP_DIR"/ipa/Payload/*.app; do
  if [[ -d "$candidate" ]]; then
    APP_DIR="$candidate"
    break
  fi
done
test -n "$APP_DIR"

BUNDLE_DIR="$APP_DIR/$BUNDLE_DIR_NAME"
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"

for file in "${required_files[@]}"; do
  cp "$SKILL_DIR/$file" "$BUNDLE_DIR/$file"
  chmod 0644 "$BUNDLE_DIR/$file"
done

python3 - "$BUNDLE_DIR/skills-manifest.json" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
expected = [
    "adult-tension-cbfdc623.zip",
    "adult-tension-continuity-graduation-final-v2-tauritavern-fixed.zip",
    "adult-tension-tauritavern-adapter-build14.zip",
]
assert data.get("suite") == "adult-tension-runtime-skills", data
assert data.get("installOrder") == expected, data.get("installOrder")
PY

(
  cd "$BUNDLE_DIR"
  sha256sum -c SKILL-SHA256SUMS.txt
)

rm -f "$TMP_DIR/TauriTavern-unsigned.ipa"
(
  cd "$TMP_DIR/ipa"
  zip -qry "$TMP_DIR/TauriTavern-unsigned.ipa" Payload
)
mv "$TMP_DIR/TauriTavern-unsigned.ipa" "$IPA"

rm -f "$TMP_DIR/TauriTavern.app.zip"
(
  cd "$(dirname "$APP_DIR")"
  zip -qry "$TMP_DIR/TauriTavern.app.zip" "$(basename "$APP_DIR")"
)
mv "$TMP_DIR/TauriTavern.app.zip" "$APP_ZIP"

(
  cd "$IOS_DIR"
  sha256sum TauriTavern-unsigned.ipa TauriTavern.app.zip build-info.json > SHA256SUMS.txt
)

printf 'Embedded Adult Tension Runtime Skills into %s/%s\n' "$(basename "$APP_DIR")" "$BUNDLE_DIR_NAME"
printf 'Repacked IPA: %s\n' "$IPA"
printf 'Repacked app archive: %s\n' "$APP_ZIP"
cat "$IOS_DIR/SHA256SUMS.txt"
