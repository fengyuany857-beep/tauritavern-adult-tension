#!/usr/bin/env bash
set -Eeuo pipefail

WORKSPACE_ROOT="${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}"
CONTROL_DIR="${CONTROL_DIR:-$WORKSPACE_ROOT/control}"
SOURCE_DIR="${SOURCE_DIR:-$WORKSPACE_ROOT/source}"
ADULT_TENSION_SOURCE_DIR="${ADULT_TENSION_SOURCE_DIR:-$WORKSPACE_ROOT/adult-tension-src}"
OUT_DIR="${SKILL_OUT_DIR:-$SOURCE_DIR/dist/runtime-skills}"
CONTINUITY_SHA256="4fbead4ed0deaa157f498a32ae6ee7ba077eaee0f046a1b71eb194c31a3d9201"
CONTINUITY_NAME="adult-tension-continuity-graduation-final-v2-tauritavern-fixed.zip"
CONTINUITY_SOURCE="$CONTROL_DIR/vendor/continuity/$CONTINUITY_NAME"
ADULT_TENSION_REVISION="cbfdc623fccc91247cbb37783757fc157406c2a5"
OVERLAY_PATH="$CONTROL_DIR/vendor/adult-tension-overlays/0001-narrative-compat.patch"
COMPAT_VERIFIER="$CONTROL_DIR/ci/verify-adult-tension-narrative-compat.py"
NARRATIVE_SOURCE_DIR="$CONTROL_DIR/extras/adult-tension-narrative"
NARRATIVE_ARCHIVE_SOURCE="$CONTROL_DIR/extras/adult-tension-narrative-v0.3.1.zip"
NARRATIVE_NAME="adult-tension-narrative-v0.3.1.zip"
NARRATIVE_VERIFIER="$CONTROL_DIR/ci/verify-adult-tension-narrative-package.py"

rm -rf "$OUT_DIR" /tmp/adult-tension-package /tmp/adapter-package
mkdir -p "$OUT_DIR" /tmp/adult-tension-package /tmp/adapter-package

test -f "$CONTINUITY_SOURCE"
printf '%s  %s\n' "$CONTINUITY_SHA256" "$CONTINUITY_SOURCE" | sha256sum -c -
cp "$CONTINUITY_SOURCE" "$OUT_DIR/$CONTINUITY_NAME"
unzip -t "$OUT_DIR/$CONTINUITY_NAME" >/dev/null
unzip -p "$OUT_DIR/$CONTINUITY_NAME" SKILL.md | grep -q '^name: adult-tension-continuity$'

rsync -a --exclude='.git' "$ADULT_TENSION_SOURCE_DIR/" /tmp/adult-tension-package/
rsync -a "$SOURCE_DIR/extras/adult-tension-tauritavern-adapter/" /tmp/adapter-package/
test -f /tmp/adult-tension-package/SKILL.md
test -f /tmp/adapter-package/SKILL.md
test "$(git -C "$ADULT_TENSION_SOURCE_DIR" rev-parse HEAD)" = "$ADULT_TENSION_REVISION"
test -f "$OVERLAY_PATH"
test -f "$COMPAT_VERIFIER"
test -d "$NARRATIVE_SOURCE_DIR"
test -f "$NARRATIVE_ARCHIVE_SOURCE"
test -f "$NARRATIVE_VERIFIER"
python3 "$NARRATIVE_VERIFIER" --source "$NARRATIVE_SOURCE_DIR" --archive "$NARRATIVE_ARCHIVE_SOURCE"
python3 "$COMPAT_VERIFIER" --root /tmp/adult-tension-package --mode baseline
git -c core.autocrlf=false -C /tmp/adult-tension-package apply --check --unidiff-zero --whitespace=error "$OVERLAY_PATH"
git -c core.autocrlf=false -C /tmp/adult-tension-package apply --unidiff-zero --whitespace=error "$OVERLAY_PATH"
python3 "$COMPAT_VERIFIER" --root /tmp/adult-tension-package --mode patched
grep -q '^name: adult-tension$' /tmp/adult-tension-package/SKILL.md
grep -q '^name: adult-tension-tauritavern-adapter$' /tmp/adapter-package/SKILL.md
(cd /tmp/adult-tension-package && zip -qr "$OUT_DIR/adult-tension-cbfdc623.zip" .)
(cd /tmp/adapter-package && zip -qr "$OUT_DIR/adult-tension-tauritavern-adapter-build14.zip" .)
unzip -t "$OUT_DIR/adult-tension-cbfdc623.zip" >/dev/null
unzip -t "$OUT_DIR/adult-tension-tauritavern-adapter-build14.zip" >/dev/null
cp "$NARRATIVE_ARCHIVE_SOURCE" "$OUT_DIR/$NARRATIVE_NAME"
unzip -t "$OUT_DIR/$NARRATIVE_NAME" >/dev/null
python3 "$NARRATIVE_VERIFIER" --source "$NARRATIVE_SOURCE_DIR" --archive "$OUT_DIR/$NARRATIVE_NAME"
NARRATIVE_SHA256="$(sha256sum "$OUT_DIR/$NARRATIVE_NAME" | awk '{print $1}')"

(
  cd "$OUT_DIR"
  sha256sum adult-tension-cbfdc623.zip "$CONTINUITY_NAME" adult-tension-tauritavern-adapter-build14.zip "$NARRATIVE_NAME" > SKILL-SHA256SUMS.txt
)

python3 - "$OUT_DIR/skills-manifest.json" "$CONTINUITY_SHA256" "$OVERLAY_PATH" "$NARRATIVE_SHA256" <<'PY'
import json, os, sys
import hashlib
path, continuity_sha, overlay_path, narrative_sha = sys.argv[1:]
with open(overlay_path, "rb") as f:
    overlay_sha = hashlib.sha256(f.read()).hexdigest()
data = {
    "schemaVersion": 1,
    "suite": "adult-tension-runtime-skills",
    "controlSha": os.environ.get("GITHUB_SHA"),
    "githubRunId": os.environ.get("GITHUB_RUN_ID"),
    "githubRunNumber": os.environ.get("GITHUB_RUN_NUMBER"),
    "upstreamSha": os.environ.get("UPSTREAM_SHA", "3a8c5401c859ac15ac11f3339846360615232896"),
    "adultTensionSource": {
        "repository": "daha1216/dsh-adult-tension",
        "revision": "cbfdc623fccc91247cbb37783757fc157406c2a5",
        "overlays": [
            {
                "id": "narrative-compat-v1",
                "path": "vendor/adult-tension-overlays/0001-narrative-compat.patch",
                "sha256": overlay_sha,
                "frozenSpanSha256": "3d00945b22ac887034980b337903a8cd748754f33e0c751156a440524bf7641b"
            }
        ]
    },
    "narrativeSource": {
        "type": "control-repo",
        "path": "extras/adult-tension-narrative",
        "package": "adult-tension-narrative-v0.3.1.zip",
        "version": "0.3.1",
        "ownerProtocol": "adult-tension-narrative-owner-matrix-v1",
        "expectedLegacyOverlayId": "narrative-compat-v1",
        "sha256": narrative_sha
    },
    "continuitySource": {
        "type": "vendored-binary",
        "path": "vendor/continuity/adult-tension-continuity-graduation-final-v2-tauritavern-fixed.zip",
        "package": "adult-tension-continuity-graduation-final-v2-tauritavern-fixed.zip",
        "sha256": continuity_sha
    },
    "adapterSource": "patched TauriTavern tree from this build",
    "installOrder": [
        "adult-tension-cbfdc623.zip",
        "adult-tension-continuity-graduation-final-v2-tauritavern-fixed.zip",
        "adult-tension-tauritavern-adapter-build14.zip",
        "adult-tension-narrative-v0.3.1.zip"
    ]
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

(
  cd "$OUT_DIR"
  zip -q Adult-Tension-4-Skills.zip \
    adult-tension-cbfdc623.zip \
    "$CONTINUITY_NAME" \
    adult-tension-tauritavern-adapter-build14.zip \
    "$NARRATIVE_NAME" \
    skills-manifest.json \
    SKILL-SHA256SUMS.txt
  sha256sum adult-tension-cbfdc623.zip "$CONTINUITY_NAME" adult-tension-tauritavern-adapter-build14.zip "$NARRATIVE_NAME" Adult-Tension-4-Skills.zip skills-manifest.json > SHA256SUMS.txt
)

PACKAGED_LEGACY_CHECK_DIR="$(mktemp -d)"
trap 'rm -rf "$PACKAGED_LEGACY_CHECK_DIR"' EXIT
unzip -q "$OUT_DIR/adult-tension-cbfdc623.zip" SKILL.md PROGRESS.md -d "$PACKAGED_LEGACY_CHECK_DIR"
python3 "$COMPAT_VERIFIER" --root "$PACKAGED_LEGACY_CHECK_DIR" --mode patched

printf 'Packaged Adult Tension runtime Skills into %s\n' "$OUT_DIR"
cat "$OUT_DIR/SHA256SUMS.txt"
