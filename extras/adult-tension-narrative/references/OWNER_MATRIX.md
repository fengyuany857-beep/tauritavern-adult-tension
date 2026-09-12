# Cross-Skill Owner Matrix

This file is normative.

Machine-readable mirror: `contracts/cross-skill-owner-map.json`.
Both must describe the same ownership split.

It exists to prevent `adult-tension` and `adult-tension-narrative` from acting as two independent adult-scene owners.

## ATN-OWNER-001 — Native RP Runtime / adult-tension ownership

The existing stack remains the only owner of:

- adult eligibility and age qualification;
- runtime safety state;
- current grants and boundaries;
- player narrative sovereignty;
- immutable character identity and Canon;
- accepted continuity;
- NPC knowledge provenance;
- relationship/event/state truth;
- `sexuality_profile`;
- `sexuality_development`;
- `active_voice_mode` and persistent voice semantics;
- POV mode and its knowledge boundary;
- state mutation and transaction semantics;
- the default adult-scene directness baseline.

The Narrative Skill may consume these values as inputs. It does not duplicate or rewrite them.

## ATN-OWNER-002 — Narrative Skill ownership

When the derived phase is `ACTIVE`, this Skill owns only:

- beat-level physical/spatial planning;
- scene-local psychophysical continuity;
- interactive pacing and response granularity;
- primary sensory focal selection;
- prose rhythm / literary breathing;
- anti-slop / anti-template cleanup;
- aftermath presentation timing.

These are presentation/planning responsibilities, not persistent truth.

## ATN-OWNER-003 — Directness is composed, not transferred

Directness has split ownership:

1. `adult-tension` supplies the existing character/profile and adult-scene directness baseline.
2. `adult-tension-narrative` prevents automatic sanitization of an already-authorized staged beat and keeps presentation clear.
3. a current explicit user request may narrow detail, request summary, fade, less detail, fast-forward or wider temporal scope.

The Narrative Skill must not reinterpret directness as permission, character voice, or a reason to intensify the event.

`no automatic fade` means the system should not silently fade an adult scene merely because it is adult.

It does **not** mean a current user request for fade/summary is forbidden.

## ATN-OWNER-004 — Voice mode and narrator clarity

Persistent character voice mode remains owned by `adult-tension`.

Voice mode controls how the character speaks and expresses themself.

Narrator clarity is separate.

A reserved or surface voice mode does not automatically require vague narration of an already-staged event.

Conversely, Narrative directness must not force a character to switch voice modes or use dialogue inconsistent with the current `active_voice_mode`.

## ATN-OWNER-005 — Scene-local versus persistent development

N2 Progressive Psychophysical Continuity is scene-local.

It may track immediate continuity within the current scene/beat, but it must not:

- create a persistent psychophysical meter;
- rewrite `sexuality_profile`;
- rewrite `sexuality_development`;
- count itself as sufficient evidence for a persistent profile change;
- bypass the existing cross-turn evidence requirements owned by `adult-tension`.

Persistent profile development remains wholly governed by the existing Adult Tension semantics.

## ATN-OWNER-006 — Sensory focus

Each coherent beat should have one **primary sensory focal subject / viewpoint**.

Other participants may have externally observable reactions rendered in the same beat.

Do not enter multiple private subjective sensory centers or interior states unless the current POV/runtime explicitly authorizes that presentation.

## ATN-OWNER-007 — Aftermath split

The existing Adult Tension runtime owns aftermath **facts**:

- what consequence actually happened;
- what state changed;
- what was staged/committed.

The Narrative Skill owns aftermath **presentation timing**:

- how many beats are used to render those already-valid consequences;
- whether the direct aftermath continues across multiple turns;
- when the presentation phase naturally returns to `INACTIVE`.

Do not duplicate or re-stage an already committed consequence simply because it remains relevant in `AFTERMATH`.

## ATN-OWNER-008 — No broad override

Never use this rule:

`adult-tension-narrative wins over adult-tension prose`

Use the field/responsibility matrix above.

When a rule does not clearly fall inside Narrative ownership, preserve the existing Adult Tension / Native RP behavior.
