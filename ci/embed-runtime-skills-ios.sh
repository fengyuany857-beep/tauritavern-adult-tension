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
  "adult-tension-narrative-v0.3.1.zip"
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

# On iOS Tauri resolves BaseDirectory::Resource to <App>.app/assets.
# Keep bundled Runtime Skills in that actual runtime resource root instead of
# merely placing them at the .app top level, which is present in the IPA but
# invisible to the normal Tauri resource resolver.
RESOURCE_ROOT="$APP_DIR/assets"
LEGACY_BUNDLE_DIR="$APP_DIR/$BUNDLE_DIR_NAME"
BUNDLE_DIR="$RESOURCE_ROOT/$BUNDLE_DIR_NAME"
rm -rf "$LEGACY_BUNDLE_DIR" "$BUNDLE_DIR"
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
    "adult-tension-narrative-v0.3.1.zip",
]
assert data.get("suite") == "adult-tension-runtime-skills", data
assert data.get("installOrder") == expected, data.get("installOrder")
narrative = data.get("narrativeSource")
assert narrative and narrative.get("version") == "0.3.1", narrative
assert narrative.get("ownerProtocol") == "adult-tension-narrative-owner-matrix-v1", narrative
assert narrative.get("expectedLegacyOverlayId") == "narrative-compat-v1", narrative
assert isinstance(narrative.get("sha256"), str) and len(narrative["sha256"]) == 64, narrative
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

printf 'Embedded four Adult Tension Runtime Skills into iOS resource path %s/assets/%s\n' "$(basename "$APP_DIR")" "$BUNDLE_DIR_NAME"
printf 'Repacked IPA: %s\n' "$IPA"
printf 'Repacked app archive: %s\n' "$APP_ZIP"
cat "$IOS_DIR/SHA256SUMS.txt"
