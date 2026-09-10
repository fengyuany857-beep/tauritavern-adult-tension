#!/usr/bin/env python3
import hashlib
import json
import os
from pathlib import Path

source = Path(os.environ.get("SOURCE_DIR", Path.cwd()))
control = Path(os.environ.get("CONTROL_DIR", source.parent / "control"))
out_dir = source / "dist/ios-unsigned"
build_info_path = out_dir / "build-info.json"
ipa_path = out_dir / "TauriTavern-unsigned.ipa"
app_zip_path = out_dir / "TauriTavern.app.zip"
ios_sums_path = out_dir / "SHA256SUMS.txt"
skill_sums_path = source / "dist/runtime-skills/SKILL-SHA256SUMS.txt"

for required in (build_info_path, ipa_path, skill_sums_path):
    if not required.is_file():
        raise SystemExit(f"required provenance input missing: {required}")


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


def refresh_ios_sums() -> None:
    existing_order: list[str] = []
    if ios_sums_path.is_file():
        for raw in ios_sums_path.read_text(encoding="utf-8").splitlines():
            fields = raw.strip().split()
            if len(fields) == 2 and fields[1] not in existing_order:
                existing_order.append(fields[1])

    known = {
        ipa_path.name: ipa_path,
        build_info_path.name: build_info_path,
    }
    if app_zip_path.is_file():
        known[app_zip_path.name] = app_zip_path

    order = existing_order + [name for name in known if name not in existing_order]
    lines: list[str] = []
    for name in order:
        candidate = known.get(name) or (out_dir / name)
        if candidate.is_file() and candidate.name != ios_sums_path.name:
            lines.append(f"{sha256_file(candidate)}  {name}")
    ios_sums_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


skill_hashes = parse_skill_sums(skill_sums_path)
ipa_sha256 = sha256_file(ipa_path)
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
        "runtime_skill_suite_hashes": skill_hashes,
        "final_ipa_sha256": ipa_sha256,
    }
)
build_info_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
refresh_ios_sums()

# Verify the regenerated checksum file itself agrees with the now-final build-info.
parsed_ios_sums = {}
for raw in ios_sums_path.read_text(encoding="utf-8").splitlines():
    digest, filename = raw.split()
    parsed_ios_sums[filename] = digest
for required_path in (ipa_path, build_info_path):
    expected = sha256_file(required_path)
    actual = parsed_ios_sums.get(required_path.name)
    if actual != expected:
        raise SystemExit(
            f"provenance checksum mismatch for {required_path.name}: {actual} != {expected}"
        )

print(f"[BUILD-INFO] augmented {build_info_path}")
print(f"[BUILD-INFO] final_ipa_sha256={ipa_sha256}")
print(f"[BUILD-INFO] SHA256SUMS refreshed at {ios_sums_path}")
