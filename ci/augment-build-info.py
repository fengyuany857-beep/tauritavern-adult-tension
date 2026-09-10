#!/usr/bin/env python3
import hashlib
import json
import os
from pathlib import Path

source = Path(os.environ.get("SOURCE_DIR", Path.cwd()))
control = Path(os.environ.get("CONTROL_DIR", source.parent / "control"))
build_info_path = source / "dist/ios-unsigned/build-info.json"
ipa_path = source / "dist/ios-unsigned/TauriTavern-unsigned.ipa"
skill_sums_path = source / "dist/runtime-skills/SKILL-SHA256SUMS.txt"

if not build_info_path.is_file():
    raise SystemExit(f"build-info missing: {build_info_path}")
if not ipa_path.is_file():
    raise SystemExit(f"final IPA missing: {ipa_path}")
if not skill_sums_path.is_file():
    raise SystemExit(f"runtime Skill hashes missing: {skill_sums_path}")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def patch_identity(directory: Path) -> str:
    files = sorted(directory.glob("*.patch"))
    if not files:
        return "NONE"
    h = hashlib.sha256()
    for path in files:
        h.update(path.name.encode("utf-8"))
        h.update(b"\0")
        h.update(path.read_bytes())
        h.update(b"\0")
    return h.hexdigest()


def parse_skill_sums(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        fields = line.split()
        if len(fields) != 2 or len(fields[0]) != 64:
            raise SystemExit(f"malformed Skill checksum line: {raw!r}")
        digest, filename = fields
        result[filename] = digest.lower()
    if len([name for name in result if name.endswith(".zip")]) < 3:
        raise SystemExit("runtime Skill checksum set is incomplete")
    return result


data = json.loads(build_info_path.read_text(encoding="utf-8"))
data.update(
    {
        "control_repo_source_sha": os.environ.get("GITHUB_SHA", "unknown"),
        "workflow_trigger_sha": os.environ.get("GITHUB_SHA", "unknown"),
        "upstream_tauritavern_sha": os.environ.get("UPSTREAM_SHA", "unknown"),
        "adult_tension_skill_sha": "cbfdc623fccc91247cbb37783757fc157406c2a5",
        "bootstrap_patch_identity": patch_identity(control / "bootstrap-post"),
        "agent_fix_identity": patch_identity(control / "agent-fix-post"),
        "data_continuity_identity": patch_identity(control / "continuity-post"),
        "data_continuity_schema": 1,
        "bundle_identifier": "com.tauritavern.client",
        "runtime_skill_suite_hashes": parse_skill_sums(skill_sums_path),
        "final_ipa_sha256": sha256_file(ipa_path),
    }
)
build_info_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"[BUILD-INFO] augmented {build_info_path}")
print(f"[BUILD-INFO] final_ipa_sha256={data['final_ipa_sha256']}")
