#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_DIR="${SOURCE_DIR:-$GITHUB_WORKSPACE/source}"
CONTROL_DIR="${CONTROL_DIR:-$GITHUB_WORKSPACE/control}"
STATUS_DIR="$CONTROL_DIR/ci-status"
LOG_DIR="$GITHUB_WORKSPACE/ci-stage-logs"
STATUS_BRANCH="${TAURITAVERN_CI_STATUS_BRANCH:-ci-status/ios-agent-continuity-20260910}"
mkdir -p "$STATUS_DIR" "$LOG_DIR"

export GIT_TERMINAL_PROMPT=0

git -C "$CONTROL_DIR" config user.name "github-actions[bot]"
git -C "$CONTROL_DIR" config user.email "41898282+github-actions[bot]@users.noreply.github.com"

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

publish_status() {
  local stage="$1"
  local state="$2"
  local exit_code="${3:-0}"
  local log_file="${4:-}"
  local slug
  slug="$(slugify "$stage")"
  local now
  now="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

  python3 - "$STATUS_DIR/latest.json" "$stage" "$state" "$exit_code" "$now" <<'PY'
import json, os, sys
path, stage, state, exit_code, now = sys.argv[1:]
data = {
    "run_id": os.environ.get("GITHUB_RUN_ID"),
    "run_number": os.environ.get("GITHUB_RUN_NUMBER"),
    "run_attempt": os.environ.get("GITHUB_RUN_ATTEMPT"),
    "repository": os.environ.get("GITHUB_REPOSITORY"),
    "control_repo_source_sha": os.environ.get("GITHUB_SHA"),
    "workflow_trigger_sha": os.environ.get("GITHUB_SHA"),
    "upstream_sha": os.environ.get("UPSTREAM_SHA"),
    "stage": stage,
    "state": state,
    "exit_code": int(exit_code),
    "updated_at": now,
}
release_file = os.path.join(os.path.dirname(path), "latest-release.txt")
if os.path.exists(release_file):
    release = open(release_file, encoding="utf-8").read().strip()
    if release:
        data["release_url"] = release
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

  cat > "$STATUS_DIR/latest.md" <<EOF
# TauriTavern Adult Tension iOS build status

- State: **$state**
- Stage: **$stage**
- Exit code: **$exit_code**
- Run: **${GITHUB_RUN_NUMBER:-?} / attempt ${GITHUB_RUN_ATTEMPT:-?}**
- Control source: \`${GITHUB_SHA:-unknown}\`
- Upstream: \`${UPSTREAM_SHA:-unknown}\`
- Updated: **$now**
EOF

  if [[ -f "$STATUS_DIR/latest-release.txt" ]]; then
    printf '\n- Self-sign release: %s\n' "$(cat "$STATUS_DIR/latest-release.txt")" >> "$STATUS_DIR/latest.md"
  fi

  if [[ -n "$log_file" && -f "$log_file" ]]; then
    {
      echo "# Diagnostic matches"
      grep -nEi 'AGENT-IOS|BUNDLE-ID|SECRET-ABSENCE|BUILD-INFO|continuity|error|failed|failure|warning:|clippy|panic|denied|xcodebuild|codesign|provision|undefined reference|linker command' "$log_file" | head -n 300 || true
      echo
      echo "# Tail"
      tail -n 400 "$log_file" || true
    } > "$STATUS_DIR/latest.log"
  else
    : > "$STATUS_DIR/latest.log"
  fi

  git -C "$CONTROL_DIR" add ci-status
  if ! git -C "$CONTROL_DIR" diff --cached --quiet; then
    git -C "$CONTROL_DIR" commit -m "ci-status: $state $slug [skip ci]"
    git -C "$CONTROL_DIR" push origin "HEAD:refs/heads/$STATUS_BRANCH"
  fi
}

run_stage() {
  local slug="$1"
  local title="$2"
  local command="$3"
  local log="$LOG_DIR/${slug}.log"
  local heartbeat_seconds=30
  local tick_seconds=2
  local elapsed=0

  : > "$log"
  publish_status "$title" "RUNNING" 0 "$log"
  echo "===== $title ====="

  set +e
  (cd "$SOURCE_DIR" && bash -lc "$command") >"$log" 2>&1 &
  local pid=$!
  set -e

  while kill -0 "$pid" 2>/dev/null; do
    sleep "$tick_seconds"
    elapsed=$((elapsed + tick_seconds))
    if (( elapsed >= heartbeat_seconds )) && kill -0 "$pid" 2>/dev/null; then
      publish_status "$title" "RUNNING" 0 "$log"
      elapsed=0
    fi
  done

  set +e
  wait "$pid"
  local rc=$?
  set -e

  cat "$log"
  if [[ "$rc" -ne 0 ]]; then
    publish_status "$title" "FAIL" "$rc" "$log"
    exit "$rc"
  fi
  publish_status "$title" "PASS" 0 "$log"
}

publish_status "Environment ready" "RUNNING" 0 ""

run_stage "bundle-id-source" "Source Bundle ID identity" \
  "EXPECTED_BUNDLE_ID=com.tauritavern.client bash '${CONTROL_DIR}/ci/verify-ios-bundle-id.sh' source"
run_stage "native-contracts" "Native RP and Agent contracts" \
  "node --test tests/agent-rp-native-contract.test.mjs tests/agent-api-contract.test.mjs tests/personal-ios-unsigned-build.test.mjs tests/ios-runtime-acceptance-contract.test.mjs tests/adult-tension-open-box-contract.test.mjs"
run_stage "frontend-guardrails" "Frontend guardrails" "pnpm run check:frontend"
run_stage "typescript" "TypeScript" "pnpm run check:types"
run_stage "logging-boundaries" "Logging boundaries" "pnpm run check:logging-boundaries"
run_stage "rust-boundaries" "Rust crate boundaries" "pnpm run check:rust-boundaries"
run_stage "contracts" "Full contract tests" "pnpm run test:contracts"
run_stage "rust-tests" "Rust tests" "pnpm run test:rust"
run_stage "clippy" "Rust Clippy" "pnpm run check:rust:clippy"
run_stage "agent-production-smoke" "Agent System minified production smoke" \
  "pnpm run web:build && node '${CONTROL_DIR}/ci/agent-system-ios-bundle-diagnostic.mjs'"
run_stage "frontend-build" "Frontend production build" "pnpm run web:build"
run_stage "runtime-skills" "Runtime Skill packages" \
  "CONTROL_DIR='${CONTROL_DIR}' SOURCE_DIR='${SOURCE_DIR}' ADULT_TENSION_SOURCE_DIR='${GITHUB_WORKSPACE}/adult-tension-src' bash '${CONTROL_DIR}/ci/package-runtime-skills.sh'"
run_stage "mobile-http" "iOS mobile HTTP compatibility" "./scripts/ci/configure-mobile-http.sh enable ios"
run_stage "ios-arm64" "Unsigned iPhone arm64 build" \
  "TAURITAVERN_CONTROL_SHA=${GITHUB_SHA} TAURITAVERN_BUILD_RUN_ID=${GITHUB_RUN_ID} TAURITAVERN_BUILD_RUN_NUMBER=${GITHUB_RUN_NUMBER} TAURITAVERN_UPSTREAM_SHA=${UPSTREAM_SHA} TAURITAVERN_BUILD_BRANCH=repair/ios-agent-continuity-20260910 TAURITAVERN_BUILD_REVISION=${UPSTREAM_SHA}+ios-agent-continuity TAURITAVERN_IOS_POLICY_PROFILE=full ./scripts/ci/build-ios-unsigned.sh"
run_stage "bundle-id-built" "Built app Bundle ID identity" \
  "EXPECTED_BUNDLE_ID=com.tauritavern.client bash '${CONTROL_DIR}/ci/verify-ios-bundle-id.sh' built"
run_stage "embed-runtime-skills" "Embed three Runtime Skills into iOS app bundle" \
  "SOURCE_DIR='${SOURCE_DIR}' bash '${CONTROL_DIR}/ci/embed-runtime-skills-ios.sh'"
run_stage "bundle-id-final" "Final unsigned IPA Bundle ID identity" \
  "EXPECTED_BUNDLE_ID=com.tauritavern.client bash '${CONTROL_DIR}/ci/verify-ios-bundle-id.sh' final"
run_stage "ipa-verify" "Unsigned IPA verification" \
  "./scripts/ci/verify-ios-unsigned.sh dist/ios-unsigned/TauriTavern-unsigned.ipa"
run_stage "bundled-skills-verify" "Bundled Runtime Skills verification" \
  "SOURCE_DIR='${SOURCE_DIR}' bash '${CONTROL_DIR}/ci/verify-bundled-runtime-skills-ios.sh' dist/ios-unsigned/TauriTavern-unsigned.ipa"
run_stage "secret-absence" "Final IPA secret/private-file absence" \
  "bash '${CONTROL_DIR}/ci/verify-no-embedded-secrets.sh' dist/ios-unsigned/TauriTavern-unsigned.ipa"
run_stage "build-provenance" "Build info provenance" \
  "SOURCE_DIR='${SOURCE_DIR}' CONTROL_DIR='${CONTROL_DIR}' python3 '${CONTROL_DIR}/ci/augment-build-info.py' && cat dist/ios-unsigned/build-info.json"

release_tag="selfsign-ios-${GITHUB_RUN_NUMBER}-a${GITHUB_RUN_ATTEMPT}"
release_url="https://github.com/${GITHUB_REPOSITORY}/releases/tag/${release_tag}"
run_stage "release" "Publish self-sign IPA with embedded auto-registering three-Skill bundle" \
  "gh release create '${release_tag}' \
    dist/ios-unsigned/TauriTavern-unsigned.ipa \
    dist/ios-unsigned/TauriTavern.app.zip \
    dist/ios-unsigned/build-info.json \
    dist/ios-unsigned/SHA256SUMS.txt \
    dist/runtime-skills/adult-tension-cbfdc623.zip \
    dist/runtime-skills/adult-tension-continuity-graduation-final-v2-tauritavern-fixed.zip \
    dist/runtime-skills/adult-tension-tauritavern-adapter-build14.zip \
    dist/runtime-skills/Adult-Tension-3-Skills.zip \
    dist/runtime-skills/skills-manifest.json \
    dist/runtime-skills/SKILL-SHA256SUMS.txt \
    --repo '${GITHUB_REPOSITORY}' \
    --target '${GITHUB_SHA}' \
    --title 'TauriTavern Adult Tension iOS Self-sign ${GITHUB_RUN_NUMBER}.${GITHUB_RUN_ATTEMPT}' \
    --notes 'Unsigned iPhone arm64 build with the matching three Adult Tension Runtime Skills embedded at the iOS Tauri resource path TauriTavern.app/assets/AdultTensionRuntimeSkills. Data continuity preflight classifies legacy data before DataDirectory initialization, snapshots legacy worlds before the continuity marker is created, and only then allows bundled Skill reconciliation. Agent System readiness resolves the current model through the host context so the independent production bundle no longer duplicates the main chat runtime. Final IPA Bundle ID, Runtime Skill hashes, secret-file absence, and build provenance are verified. Re-sign the IPA with your own iOS self-signing tool before installation.'"

printf '%s\n' "$release_url" > "$STATUS_DIR/latest-release.txt"
publish_status "Complete: self-sign IPA + Agent fix + continuity + three Skills ready" "COMPLETE" 0 "$LOG_DIR/release.log"

echo "SELF_SIGN_RELEASE=$release_url"
