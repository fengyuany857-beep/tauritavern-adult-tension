#!/usr/bin/env python3
"""Validate the frozen adult-tension-narrative v0.3.1 artifact."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import zipfile
from pathlib import Path


EXPECTED_SHA256 = "52ce3f32d5d8cae4dec45382135c94aca37654dd9d32b75ce468e4d27a22a346"
EXPECTED_NAME = "adult-tension-narrative"
EXPECTED_VERSION = "0.3.1"
EXPECTED_PROTOCOL = "adult-tension-narrative-owner-matrix-v1"
EXPECTED_OVERLAY = "narrative-compat-v1"
EXPECTED_FILES = {
    "SKILL.md",
    "BUILD-MANIFEST.json",
    "agents/tauritavern.json",
    "contracts/cross-skill-owner-map.json",
    "contracts/narrative-policy.contract.json",
    "references/ACCEPTANCE_CASES.md",
    "references/ACTIVATION.md",
    "references/AFTERMATH.md",
    "references/CONFLICT_PRIORITY.md",
    "references/INTEGRATION_CONTRACT.md",
    "references/NARRATIVE_STACK.md",
    "references/OWNER_MATRIX.md",
    "references/PROVENANCE.md",
    "references/RECOVERY.md",
    "references/ROUTING.md",
    "references/RUNTIME_CONTRACT.md",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_source(root: Path) -> None:
    required = [root / name for name in EXPECTED_FILES]
    missing = [str(path.relative_to(root)) for path in required if not path.is_file()]
    if missing:
        raise ValueError(f"source files missing: {', '.join(sorted(missing))}")

    skill = (root / "SKILL.md").read_text(encoding="utf-8")
    if not re.search(r"^name:\s*adult-tension-narrative\s*$", skill, re.MULTILINE):
        raise ValueError("SKILL.md name mismatch")
    if not re.search(r'^  version:\s*"0\.3\.1"\s*$', skill, re.MULTILINE):
        raise ValueError("SKILL.md version mismatch")

    manifest = json.loads((root / "BUILD-MANIFEST.json").read_text(encoding="utf-8"))
    if manifest.get("name") != EXPECTED_NAME or manifest.get("version") != EXPECTED_VERSION:
        raise ValueError("BUILD-MANIFEST identity mismatch")
    if manifest.get("crossSkillOwnerProtocol") != EXPECTED_PROTOCOL:
        raise ValueError("BUILD-MANIFEST owner protocol mismatch")
    if manifest.get("expectedLegacyCompatibilityOverlayId") != EXPECTED_OVERLAY:
        raise ValueError("BUILD-MANIFEST legacy overlay mismatch")

    owner_map = json.loads(
        (root / "contracts/cross-skill-owner-map.json").read_text(encoding="utf-8")
    )
    if owner_map.get("protocol") != EXPECTED_PROTOCOL:
        raise ValueError("owner map protocol mismatch")
    if owner_map.get("expectedLegacyCompatibilityOverlayId") != EXPECTED_OVERLAY:
        raise ValueError("owner map legacy overlay mismatch")

    policy = json.loads(
        (root / "contracts/narrative-policy.contract.json").read_text(encoding="utf-8")
    )
    if policy.get("crossSkillOwnerProtocol") != EXPECTED_PROTOCOL:
        raise ValueError("policy owner protocol mismatch")
    if policy.get("expectedLegacyCompatibilityOverlayId") != EXPECTED_OVERLAY:
        raise ValueError("policy legacy overlay mismatch")


def validate_archive(archive: Path) -> None:
    actual = sha256(archive)
    if actual != EXPECTED_SHA256:
        raise ValueError(f"archive SHA-256 mismatch: {actual}")
    with zipfile.ZipFile(archive) as bundle:
        prefix = "adult-tension-narrative/"
        names = {name[len(prefix):] for name in bundle.namelist() if name.startswith(prefix)}
        if EXPECTED_FILES - names:
            raise ValueError(f"archive files missing: {sorted(EXPECTED_FILES - names)}")
        if names - EXPECTED_FILES:
            raise ValueError(f"archive contains unexpected files: {sorted(names - EXPECTED_FILES)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--archive", required=True, type=Path)
    args = parser.parse_args()
    try:
        validate_source(args.source)
        validate_archive(args.archive)
    except (OSError, ValueError, json.JSONDecodeError, zipfile.BadZipFile) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    print(
        f"PASS narrative name={EXPECTED_NAME} version={EXPECTED_VERSION} "
        f"sha256={EXPECTED_SHA256} ownerProtocol={EXPECTED_PROTOCOL}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
