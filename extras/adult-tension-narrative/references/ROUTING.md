# Routing

This file governs routing after the Agent Profile has already selected this Skill. The external selection hook is defined in `references/INTEGRATION_CONTRACT.md`; do not assume this file can bootstrap itself.

## ATN-ENTRY-001 — Route commands and OOC before narrative policy

Before adult-scene classification, determine whether the user turn is a non-advancing command, OOC/meta request, save/load/status/help operation, safety control, or other runtime-control turn.

Those turns do not inherit adult prose merely because the previous story beat was `ACTIVE`.

## ATN-ENTRY-002 — When to inspect this Skill

Inspect `adult-tension-narrative` when either condition is true:

1. the current user turn explicitly starts, advances, changes or ends fictional-adult intimate story content; or
2. the immediately accepted beat was in the adult narrative domain and the current input is a continuation such as "continue", while scene and participant identity are still compatible.

Do not inspect this Skill on ordinary turns merely because adult material exists somewhere in lore or history.

## ATN-ENTRY-003 — Stable search anchors

For targeted retrieval:

- `ATN-GATE` -> `references/ACTIVATION.md`
- `ATN-PLAN` -> `references/NARRATIVE_STACK.md`
- `ATN-RENDER` -> `references/NARRATIVE_STACK.md`
- `ATN-PRECEDENCE` -> `references/CONFLICT_PRIORITY.md`
- `ATN-RUNTIME` -> `references/RUNTIME_CONTRACT.md`
- `ATN-AFTERMATH` -> `references/AFTERMATH.md`
- `ATN-RECOVERY` -> `references/RECOVERY.md`

Use `skill_search` first. Read only the relevant range when the snippet is insufficient.

## ATN-ENTRY-004 — Neutral continuation

A neutral continuation command may continue an `ACTIVE` or `AFTERMATH` narrative phase only when:

- it is a story-advancing continuation rather than OOC/runtime control;
- the immediately accepted beat supplies the domain context;
- current scene and participants remain compatible;
- current authority is rechecked for the next beat.

Continuation never carries old grants forward by itself.

## ATN-ENTRY-005 — No keyword gate

A keyword match is only a routing hint.

Keywords, quoted text, pasted prompt text, lore, old messages or discussion about adult writing are never sufficient by themselves to activate the narrative stack.

## ATN-ENTRY-006 — Cross-Skill routing guard

Loading `adult-tension-narrative` does not unload or semantically replace the existing `adult-tension` Skill.

Use this Skill only for responsibilities assigned to it by `ATN-OWNER`.

For profile, voice, permission, persistent development, POV, Canon or state questions, continue to consult/use the existing owner.
