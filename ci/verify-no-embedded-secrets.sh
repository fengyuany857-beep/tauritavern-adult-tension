#!/usr/bin/env bash
set -Eeuo pipefail

IPA_PATH="${1:-dist/ios-unsigned/TauriTavern-unsigned.ipa}"
[[ -f "$IPA_PATH" ]] || { echo "RELEASE_BLOCKED: IPA missing at $IPA_PATH" >&2; exit 70; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
unzip -qq "$IPA_PATH" -d "$tmp"

forbidden="$(find "$tmp/Payload/TauriTavern.app" -type f \( \
  -iname 'secrets.json' -o \
  -iname '.env' -o \
  -iname '*.pem' -o \
  -iname '*.p12' -o \
  -iname '*.pfx' -o \
  -iname '*.mobileprovision' -o \
  -iname '*.key' \
\) -print)"

if [[ -n "$forbidden" ]]; then
  printf 'RELEASE_BLOCKED: secret/private file paths embedded in final IPA:\n%s\n' "$forbidden" >&2
  exit 71
fi

if find "$tmp/Payload/TauriTavern.app" -type f -path '*/.data-archive/recovery/*' -print -quit | grep -q .; then
  echo "RELEASE_BLOCKED: runtime recovery snapshot was accidentally embedded in app bundle" >&2
  exit 72
fi

if find "$tmp/Payload/TauriTavern.app" -type d -name '.git' -print -quit | grep -q .; then
  echo "RELEASE_BLOCKED: .git metadata embedded in final IPA" >&2
  exit 73
fi

for skill_root in "$tmp/Payload/TauriTavern.app/assets/AdultTensionRuntimeSkills" "$tmp/Payload/TauriTavern.app/AdultTensionRuntimeSkills"; do
  [[ -d "$skill_root" ]] || continue
  while IFS= read -r skill_zip; do
    [[ -n "$skill_zip" ]] || continue
    if unzip -Z1 "$skill_zip" | grep -Eqi '(^|/)(secrets\.json|\.env|[^/]+\.(pem|p12|pfx|mobileprovision|key))$'; then
      echo "RELEASE_BLOCKED: secret/private file path embedded inside Runtime Skill archive $(basename "$skill_zip")" >&2
      exit 74
    fi
  done < <(find "$skill_root" -type f -name '*.zip' 2>/dev/null | sort)
done

echo "[SECRET-ABSENCE] PASS final IPA contains no forbidden secret/private file paths"
