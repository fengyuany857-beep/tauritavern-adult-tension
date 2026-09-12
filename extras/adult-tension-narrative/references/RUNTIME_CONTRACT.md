# Runtime Contract

## ATN-RUNTIME-001 — Authority is domain-specific

Do not use one universal "highest authority" list for every kind of fact.

Use the authority owner for the domain being decided.

### Eligibility and safety

For adult eligibility, safety, boundaries and current grants:

1. system/platform requirements;
2. stricter active project/world eligibility rules;
3. current Native RP runtime authority from `rp.state`;
4. current user instruction only within the freedom left by the above.

A user instruction cannot convert a role classified as minor by an active project/world rule into an adult-eligible role for this Skill.

### Current player action and style intent

For what the player explicitly does, says, attempts or requests stylistically:

1. current explicit user turn;
2. accepted branch-local context only where the user did not specify;
3. narrative defaults.

Do not invent missing player internals.

### Runtime facts

For current scene, location, participants, safety state, grants, boundaries and committed consequences:

1. current `rp.state` / successful `rp.stage_turn`;
2. accepted continuity;
3. targeted `rp.recall` for older history.

History never creates current authority.

### Canon and character identity

Fixed Canon and immutable character identity outrank narrative inference.

### NPC knowledge

NPC knowledge is controlled by the runtime's provenance rules.

Reader-visible information does not automatically become character knowledge.

## ATN-RUNTIME-002 — Existing character state is input, not replacement target

When available, consume existing character/runtime information such as:

- immutable character identity;
- control ownership;
- character voice/personality;
- current goal and emotion;
- knowledge provenance;
- relationship context;
- current voice mode;
- established adult-profile preferences or pacing tendencies;
- current POV mode;
- boundaries and grants.

Do not create a second copy of those fields.

If an expected field is absent from the current projected context, do not invent a persistent replacement.

## ATN-RUNTIME-003 — POV and knowledge separation

Observable narration and character knowledge are separate.

If the runtime POV mode does not authorize unspoken NPC interiority, prefer externally observable behavior.

If an authorized POV exposes an NPC's private thought or feeling to the reader, that does not make any other character know it.

Never turn presentation-layer information into NPC knowledge without the runtime's required provenance.

## ATN-RUNTIME-004 — Compatibility with adult-tension

The pinned `adult-tension` Skill and Native RP Runtime remain authoritative for all persistent semantics and character/runtime truth.

Do not use a blanket prose override.

Apply the responsibility split from `references/OWNER_MATRIX.md`.

Narrative ownership is limited to:

- adult-scene response granularity;
- beat-level physical/spatial readability;
- scene-local psychophysical continuity;
- narrative pacing;
- primary sensory focal selection;
- prose rhythm;
- anti-template cleanup;
- aftermath presentation timing.

Existing Adult Tension ownership is preserved for:

- eligibility, safety, grants and boundaries;
- player sovereignty;
- character profile truth;
- `sexuality_profile` and `sexuality_development`;
- voice-mode state;
- POV and knowledge semantics;
- state mutation and commit rules;
- the default adult directness baseline.

Directness is composed according to `ATN-OWNER-003`; it is not wholly transferred to this Skill.

## ATN-RUNTIME-005 — Existing adult profile fields

Existing character preferences such as pace, expression/directness, voice mode and contextual style are calibration inputs.

They do not become current permission.

The narrative layer should preserve them when compatible with current state, rather than replacing them with a generic adult voice.

## ATN-RUNTIME-006 — User language and base style

Do not change output language merely because this Skill was activated.

Preserve the current conversation language and compatible base narrative style unless the user explicitly changes them.

## ATN-RUNTIME-007 — No persistent narrative phase

Never write:

- `adult_scene_state`;
- `narrative_phase`;
- hidden arousal meters;
- duplicate relationship state;
- duplicate permission state;
- duplicate voice state;

into persistent RP state merely for this Skill.

Persistent consequences that genuinely occur are recorded only through the existing native RP transaction model.

## ATN-RUNTIME-008 — Persistent profile isolation

The runtime may stage genuine consequences from the story, but this Skill must not treat scene-local narrative progression as an instruction to persist a profile change.

Any persistent update to `sexuality_profile` or `sexuality_development` must independently satisfy the existing Adult Tension rules and evidence requirements.

## ATN-RUNTIME-009 — Legacy compatibility bridge

For full cross-Skill integration, the installed/packaged `adult-tension` copy or the Agent Profile must contain an equivalent compatibility binding that recognizes this field-level Owner Matrix.

Until that binding is present, this Skill may be installed but cross-Skill integration must not be reported as complete.
