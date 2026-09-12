#!/usr/bin/env python3
"""Verify the Adult Tension frozen span and the narrative compatibility bridge."""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path


FROZEN_SHA256 = "3d00945b22ac887034980b337903a8cd748754f33e0c751156a440524bf7641b"
START_ANCHOR = "当场景中已发生"
END_ANCHOR = "不得用一句话跳过整段性行为。"
COMPAT_HEADING = "### adult-tension-narrative 兼容桥（表现层）"


def read_utf8(path: Path) -> str:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return handle.read()


def frozen_span(skill: str) -> str:
    start = skill.find(START_ANCHOR)
    end_anchor = skill.find(END_ANCHOR, start + len(START_ANCHOR))
    if start < 0 or end_anchor < 0:
        raise ValueError("frozen span anchors are missing or out of order")
    end = end_anchor + len(END_ANCHOR)
    return skill[start:end]


def require_all(text: str, label: str, markers: tuple[str, ...]) -> None:
    missing = [marker for marker in markers if marker not in text]
    if missing:
        raise ValueError(f"{label} missing: {', '.join(missing)}")


def verify(root: Path, mode: str) -> None:
    skill_path = root / "SKILL.md"
    progress_path = root / "PROGRESS.md"
    if not skill_path.is_file():
        raise ValueError("SKILL.md is missing")
    if not progress_path.is_file():
        raise ValueError("PROGRESS.md is missing")

    skill = read_utf8(skill_path)
    progress = read_utf8(progress_path)
    span = frozen_span(skill)
    digest = hashlib.sha256(span.encode("utf-8")).hexdigest()
    if digest != FROZEN_SHA256:
        raise ValueError(f"frozen span SHA-256 mismatch: {digest}")

    if mode == "patched":
        if skill.count(COMPAT_HEADING) != 1:
            raise ValueError("compatibility heading must occur exactly once")
        require_all(skill, "conditional fallback", (
            "adult-tension-narrative",
            "实际可用",
            "未安装",
            "读取失败",
            "旧 `adult-tension` 行为保持不变",
        ))
        require_all(skill, "old-owner boundary", (
            "成人资格与年龄判定",
            "当前许可、边界与暂停",
            "玩家叙事主权",
            "sexuality_profile",
            "sexuality_development",
            "active_voice_mode",
            "状态更新与回合事务",
            "Canon / continuity 的事实语义",
        ))
        require_all(skill, "narrative-owner boundary", (
            "字段级优先级",
            "scene-local 身心反应连续性",
            "物理 / 空间可读性",
            "感官焦点选择",
            "prose rhythm",
            "anti-slop / anti-template",
            "不是对旧成人场景规则的整体覆盖",
        ))
        require_all(skill, "user-requested presentation override", (
            "no automatic fade",
            "user-requested fade",
            "summary",
            "fast-forward",
            "wider temporal scope",
            "不扩大许可",
            "不创造新行为",
            "不替玩家做决定",
        ))
        require_all(skill, "voice-mode and narrator layering", (
            "active_voice_mode",
            "表层语态",
            "里层语态",
            "dialogue voice",
            "narrator clarity",
            "不符合当前 voice mode 的台词",
        ))
        require_all(skill, "scene-local progression boundary", (
            "scene-local psychophysical progression",
            "不创建新 persistent state",
            "不自动修改 `sexuality_profile`",
            "不自动修改 `sexuality_development`",
            "跨回合证据要求",
        ))
        require_all(skill, "sensory focus boundary", (
            "primary sensory focal subject / focal viewpoint",
            "coherent beat",
            "外部可观察",
            "没有 POV 授权时",
        ))
        require_all(skill, "aftermath ownership", (
            "aftermath factual semantics",
            "aftermath presentation timing",
            "stage / commit",
            "不得要求旧 Skill 在 `ACTIVE` 最后一条回复里一次性消费全部 aftermath",
        ))
        require_all(progress, "progress compatibility record", (
            "2026-09-12",
            "adult-tension-narrative",
            "位于冻结段之外",
            FROZEN_SHA256,
        ))

    print(f"PASS mode={mode} root={root} frozenSpanSHA256={digest}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--mode", choices=("baseline", "patched"), required=True)
    args = parser.parse_args()
    try:
        verify(args.root, args.mode)
    except (OSError, ValueError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
