#!/usr/bin/env bash
set -Eeuo pipefail

WORKSPACE_ROOT="${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}"
SOURCE_DIR="${SOURCE_DIR:-$WORKSPACE_ROOT/source}"
SKILL_DIR="${SKILL_DIR:-$SOURCE_DIR/dist/runtime-skills}"
CONTROL_DIR="${CONTROL_DIR:-$WORKSPACE_ROOT/control}"
IPA="${1:-$SOURCE_DIR/dist/ios-unsigned/TauriTavern-unsigned.ipa}"
BUNDLE_DIR_NAME="AdultTensionRuntimeSkills"
COMPAT_VERIFIER="$CONTROL_DIR/ci/verify-adult-tension-narrative-compat.py"

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
unzip -t "$IPA" >/dev/null

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

# Runtime contract, not just packaging presence: on iOS Tauri resolves
# BaseDirectory::Resource beneath <App>.app/assets. A bundle at the .app root
# is physically present but invisible to assets::read_resource_bytes().
RESOURCE_ROOT="$APP_DIR/assets"
BUNDLE_DIR="$RESOURCE_ROOT/$BUNDLE_DIR_NAME"
LEGACY_BUNDLE_DIR="$APP_DIR/$BUNDLE_DIR_NAME"

test -d "$RESOURCE_ROOT"
test -d "$BUNDLE_DIR"
test ! -e "$LEGACY_BUNDLE_DIR"

for file in "${required_files[@]}"; do
  test -f "$BUNDLE_DIR/$file"
  cmp -s "$SKILL_DIR/$file" "$BUNDLE_DIR/$file"
done

(
  cd "$BUNDLE_DIR"
  sha256sum -c SKILL-SHA256SUMS.txt
)

python3 - "$BUNDLE_DIR/skills-manifest.json" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
expected = [
    "adult-tension-cbfdc623.zip",
    "adult-tension-continuity-graduation-final-v2-tauritavern-fixed.zip",
    "adult-tension-tauritavern-adapter-build14.zip",
]
assert data.get("schemaVersion") == 1, data.get("schemaVersion")
assert data.get("suite") == "adult-tension-runtime-skills", data.get("suite")
assert data.get("installOrder") == expected, data.get("installOrder")
source = data.get("adultTensionSource")
assert source and source.get("repository") == "daha1216/dsh-adult-tension", source
assert source.get("revision") == "cbfdc623fccc91247cbb37783757fc157406c2a5", source
overlays = source.get("overlays")
assert isinstance(overlays, list) and len(overlays) == 1, overlays
overlay = overlays[0]
assert overlay.get("id") == "narrative-compat-v1", overlay
assert overlay.get("path") == "vendor/adult-tension-overlays/0001-narrative-compat.patch", overlay
assert isinstance(overlay.get("sha256"), str) and len(overlay["sha256"]) == 64 and all(c in "0123456789abcdef" for c in overlay["sha256"]), overlay
assert overlay.get("frozenSpanSha256") == "3d00945b22ac887034980b337903a8cd748754f33e0c751156a440524bf7641b", overlay
PY

unzip -t "$BUNDLE_DIR/adult-tension-cbfdc623.zip" >/dev/null
unzip -p "$BUNDLE_DIR/adult-tension-cbfdc623.zip" SKILL.md | grep -q '^name: adult-tension$'
ZIP_SKILL_DIR="$TMP_DIR/adult-tension-cbfdc623"
mkdir -p "$ZIP_SKILL_DIR"
unzip -q "$BUNDLE_DIR/adult-tension-cbfdc623.zip" SKILL.md PROGRESS.md -d "$ZIP_SKILL_DIR"
python3 "$COMPAT_VERIFIER" --root "$ZIP_SKILL_DIR" --mode patched
unzip -t "$BUNDLE_DIR/adult-tension-continuity-graduation-final-v2-tauritavern-fixed.zip" >/dev/null
unzip -p "$BUNDLE_DIR/adult-tension-continuity-graduation-final-v2-tauritavern-fixed.zip" SKILL.md | grep -q '^name: adult-tension-continuity$'
unzip -t "$BUNDLE_DIR/adult-tension-tauritavern-adapter-build14.zip" >/dev/null
unzip -p "$BUNDLE_DIR/adult-tension-tauritavern-adapter-build14.zip" SKILL.md | grep -q '^name: adult-tension-tauritavern-adapter$'

printf 'VERIFIED: final IPA exposes the exact three Adult Tension Runtime Skills at the iOS Tauri resource path %s/assets/%s\n' "$(basename "$APP_DIR")" "$BUNDLE_DIR_NAME"
