---
name: adult-tension-narrative
description: Conditional adult-only narrative planning and rendering policy for the Adult Tension TauriTavern RP stack. Use only after rp.state. It never owns authority, consent/grants, canon, character identity, continuity, or persistence.
metadata:
  version: "0.3.1"
  tags:
    - roleplay
    - adult-only
    - narrative-policy
    - conditional
    - tauritavern
---

# Adult Tension Narrative

`adult-tension-narrative` is one conditional Skill with internal modules. It is not a second RP runtime.

Its job is to improve **beat planning and prose rendering** when an already-valid fictional-adult scene enters the adult narrative domain, while leaving all persistent truth and authority in the existing Native RP Runtime.

## ATN-CORE-001 — Single source of truth

The Native RP Runtime remains authoritative for:

- scene, location and participants
- current safety state
- current boundaries and grants
- character identity and control ownership
- Canon and accepted continuity
- NPC knowledge and provenance
- memories, events, commitments, threads and agendas
- branch-local persistence
- `rp.stage_turn` validation and transaction semantics

This Skill must not create or persist a parallel `AdultSceneState`, permission cache, relationship store, character store, Canon layer or continuity database.

## ATN-CORE-002 — Strict adult eligibility

Adult narrative activation requires every relevant participant to be unambiguously fictional and adult under **all applicable runtime, project and world rules**.

A numeric age field is not sufficient when a stricter active project/world rule classifies that role as a minor or otherwise excludes adult-content eligibility.

Ambiguity fails closed.

## ATN-CORE-003 — Two-pass architecture

Do not run all narrative modules as one undifferentiated chain.

Use:

1. `rp.state`
2. optional `rp.recall`
3. phase derivation
4. **Beat Planning Pass** (`N1-N4`)
5. beat-specific authority check
6. `rp.stage_turn`
7. **Render Pass** (`N5-N8`) using only the successfully staged beat
8. render/stage parity check
9. normal workspace commit/finish

This prevents style rules from silently changing what happened.

## ATN-CORE-004 — Four derived phases

The phase is recomputed each turn and is never persisted by this Skill:

- `INACTIVE`
- `ELIGIBLE`
- `ACTIVE`
- `AFTERMATH`

Read `references/ACTIVATION.md` for the exact gate.

## ATN-CORE-005 — One Skill, eight internal modules

Beat Planning Pass:

1. Physical-Spatial Continuity
2. Progressive Psychophysical Continuity
3. Character / Context / POV Calibration
4. Interactive Pacing

Render Pass:

5. Sensory Grounding
6. Directness / Anti-Sanitization
7. Prose Rhythm / Literary Breathing
8. Anti-Slop / Anti-Template

Read `references/NARRATIVE_STACK.md`.

## ATN-CORE-006 — Current authority is not historical continuity

Past intimacy, relationship labels, previous grants, character archetypes, lore, old dialogue and prior scene outcomes do not create current permission.

`ACTIVE` means "use the adult narrative policy for this scene", not "every possible action in the scene is authorized".

Every candidate beat still passes the current beat-authority rules owned by the Native RP Runtime.

## ATN-CORE-007 — Player sovereignty

Never author the player's dialogue, action, attempt, feeling, intention, decision or internal state beyond what the current user explicitly supplied.

A style module may change wording only. It cannot consume a player choice.

## ATN-CORE-008 — Cross-Skill Owner Matrix

This Skill is a synthesized adult-scene narrative layer over the existing `adult-tension` stack.

It does **not** broadly supersede older adult-scene prose guidance.

Ownership is split by responsibility:

- existing `adult-tension` / Native RP Runtime owns eligibility, safety, grants, boundaries, player sovereignty, Canon, continuity, character-profile truth, `sexuality_profile`, `sexuality_development`, voice-mode state, POV state, knowledge provenance, transaction semantics and the default adult directness baseline;
- `adult-tension-narrative` owns only beat-level physical/spatial planning, scene-local psychophysical continuity, response granularity, sensory focal selection, prose rhythm, anti-template cleanup and aftermath presentation timing;
- current explicit user style requests may narrow presentation detail or widen temporal scope when runtime authority permits, but never widen permission or invent player decisions.

See `references/OWNER_MATRIX.md`, `references/RUNTIME_CONTRACT.md` and `references/CONFLICT_PRIORITY.md`.

## ATN-CORE-009 — Conditional reading

Ordinary turns should not load the full Skill.

Recommended retrieval anchors:

- possible activation: `ATN-GATE`
- beat planning: `ATN-PLAN`
- rendering: `ATN-RENDER`
- precedence conflict: `ATN-PRECEDENCE`
- recovery: `ATN-RECOVERY`
- aftermath: `ATN-AFTERMATH`

See `references/ROUTING.md`.

## ATN-CORE-010 — Failure behavior

If this Skill is missing, unreadable, out of read budget, or cannot establish activation, continue using the base Adult Tension RP runtime.

Narrative-policy failure must never corrupt RP state.

Do not retry an identical failed stage blindly. Follow `references/RECOVERY.md`.


## ATN-CORE-010A — No persistent-profile promotion

Scene-local narrative progression is presentation evidence for the current beat only.

It must not by itself update, satisfy the evidence threshold for, or replace persistent `sexuality_profile` / `sexuality_development` semantics owned by `adult-tension`.

## ATN-CORE-011 — External integration hook required

This Skill cannot reliably discover when it should be read from inside itself.

The Agent Profile must provide the minimal always-on router and cross-Skill precedence binding defined in `references/INTEGRATION_CONTRACT.md`.

A package that is merely installed but lacks that router is **installed, not integrated**.
