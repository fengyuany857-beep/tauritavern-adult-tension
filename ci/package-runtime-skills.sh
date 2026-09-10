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
grep -q '^name: adult-tension$' /tmp/adult-tension-package/SKILL.md
grep -q '^name: adult-tension-tauritavern-adapter$' /tmp/adapter-package/SKILL.md
(cd /tmp/adult-tension-package && zip -qr "$OUT_DIR/adult-tension-cbfdc623.zip" .)
(cd /tmp/adapter-package && zip -qr "$OUT_DIR/adult-tension-tauritavern-adapter-build14.zip" .)
unzip -t "$OUT_DIR/adult-tension-cbfdc623.zip" >/dev/null
unzip -t "$OUT_DIR/adult-tension-tauritavern-adapter-build14.zip" >/dev/null

(
  cd "$OUT_DIR"
  sha256sum adult-tension-cbfdc623.zip "$CONTINUITY_NAME" adult-tension-tauritavern-adapter-build14.zip > SKILL-SHA256SUMS.txt
)

python3 - "$OUT_DIR/skills-manifest.json" "$CONTINUITY_SHA256" <<'PY'
import json, os, sys
path, continuity_sha = sys.argv[1:]
data = {
    "schemaVersion": 1,
    "suite": "adult-tension-runtime-skills",
    "controlSha": os.environ.get("GITHUB_SHA"),
    "githubRunId": os.environ.get("GITHUB_RUN_ID"),
    "githubRunNumber": os.environ.get("GITHUB_RUN_NUMBER"),
    "upstreamSha": os.environ.get("UPSTREAM_SHA", "3a8c5401c859ac15ac11f3339846360615232896"),
    "adultTensionSource": {
        "repository": "daha1216/dsh-adult-tension",
        "revision": "cbfdc623fccc91247cbb37783757fc157406c2a5"
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
        "adult-tension-tauritavern-adapter-build14.zip"
    ]
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

(
  cd "$OUT_DIR"
  zip -q Adult-Tension-3-Skills.zip \
    adult-tension-cbfdc623.zip \
    "$CONTINUITY_NAME" \
    adult-tension-tauritavern-adapter-build14.zip \
    skills-manifest.json \
    SKILL-SHA256SUMS.txt
  sha256sum adult-tension-cbfdc623.zip "$CONTINUITY_NAME" adult-tension-tauritavern-adapter-build14.zip Adult-Tension-3-Skills.zip skills-manifest.json > SHA256SUMS.txt
)

printf 'Packaged Adult Tension runtime Skills into %s\n' "$OUT_DIR"
cat "$OUT_DIR/SHA256SUMS.txt"
