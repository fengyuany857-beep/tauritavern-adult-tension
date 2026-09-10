#!/usr/bin/env bash
set -Eeuo pipefail

MODE="${1:-all}"
EXPECTED_BUNDLE_ID="${EXPECTED_BUNDLE_ID:-com.tauritavern.client}"
IPA_PATH="${IPA_PATH:-dist/ios-unsigned/TauriTavern-unsigned.ipa}"
APP_ZIP_PATH="${APP_ZIP_PATH:-dist/ios-unsigned/TauriTavern.app.zip}"

read_plist_bundle_id() {
  local plist="$1"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist" 2>/dev/null || plutil -extract CFBundleIdentifier raw -o - "$plist"
}

verify_equal() {
  local label="$1"
  local actual="$2"
  if [[ "$actual" != "$EXPECTED_BUNDLE_ID" ]]; then
    echo "RELEASE_BLOCKED: $label Bundle ID '$actual' != expected '$EXPECTED_BUNDLE_ID'" >&2
    exit 64
  fi
  echo "[BUNDLE-ID] $label=$actual VERIFIED_MATCH"
}

verify_source() {
  local config="src-tauri/crates/tauritavern/tauri.conf.json"
  [[ -f "$config" ]] || { echo "RELEASE_BLOCKED: source tauri.conf.json missing" >&2; exit 65; }
  local actual
  actual="$(node -e 'const fs=require("fs"); const p=process.argv[1]; const j=JSON.parse(fs.readFileSync(p,"utf8")); process.stdout.write(String(j.identifier||""));' "$config")"
  verify_equal "source tauri.conf.json" "$actual"
}

verify_built() {
  local app plist actual tmp
  app="$(find dist/ios-unsigned src-tauri/target -type d -name 'TauriTavern.app' -print 2>/dev/null | head -n 1 || true)"
  if [[ -n "$app" ]]; then
    plist="$app/Info.plist"
    [[ -f "$plist" ]] || { echo "RELEASE_BLOCKED: built Info.plist missing at $plist" >&2; exit 67; }
    actual="$(read_plist_bundle_id "$plist")"
    verify_equal "built TauriTavern.app/Info.plist" "$actual"
    return
  fi

  [[ -f "$APP_ZIP_PATH" ]] || {
    echo "RELEASE_BLOCKED: neither built TauriTavern.app nor $APP_ZIP_PATH exists" >&2
    exit 66
  }
  tmp="$(mktemp -d)"
  unzip -qq "$APP_ZIP_PATH" -d "$tmp"
  plist="$(find "$tmp" -type f -path '*/TauriTavern.app/Info.plist' -print -quit)"
  if [[ -z "$plist" || ! -f "$plist" ]]; then
    rm -rf "$tmp"
    echo "RELEASE_BLOCKED: built app archive does not contain TauriTavern.app/Info.plist" >&2
    exit 67
  fi
  actual="$(read_plist_bundle_id "$plist")"
  verify_equal "built TauriTavern.app.zip Info.plist" "$actual"
  rm -rf "$tmp"
}

verify_final_ipa() {
  [[ -f "$IPA_PATH" ]] || { echo "RELEASE_BLOCKED: final unsigned IPA missing at $IPA_PATH" >&2; exit 68; }
  local tmp plist actual
  tmp="$(mktemp -d)"
  unzip -qq "$IPA_PATH" -d "$tmp"
  plist="$tmp/Payload/TauriTavern.app/Info.plist"
  [[ -f "$plist" ]] || {
    rm -rf "$tmp"
    echo "RELEASE_BLOCKED: final IPA Info.plist missing" >&2
    exit 69
  }
  actual="$(read_plist_bundle_id "$plist")"
  verify_equal "final unsigned IPA Info.plist" "$actual"
  rm -rf "$tmp"
}

case "$MODE" in
  source)
    verify_source
    ;;
  built)
    verify_source
    verify_built
    ;;
  final)
    verify_source
    verify_final_ipa
    ;;
  all)
    verify_source
    verify_built
    verify_final_ipa
    ;;
  *)
    echo "usage: $0 {source|built|final|all}" >&2
    exit 2
    ;;
esac
