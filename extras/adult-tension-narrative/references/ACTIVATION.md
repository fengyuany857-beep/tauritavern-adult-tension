# Activation

## ATN-GATE-001 — Separate eligibility, phase and beat authority

Do not collapse these three questions:

1. **AdultEligibility** — may this participant set ever use this Skill?
2. **NarrativePhase** — is the current story beat in the adult narrative domain?
3. **BeatAuthority** — is the specific candidate action/transition valid now?

`ACTIVE` answers only question 2.

It is never blanket permission for question 3.

## ATN-GATE-002 — AdultEligibility

Eligibility requires all relevant participants to be:

- fictional;
- unambiguously adult;
- adult-eligible under the current runtime;
- adult-eligible under any stricter active project/world classification.

If a role is classified as minor by the active project/world rules, a nominal numeric age does not override that classification.

Unknown, conflicting or unprovable eligibility fails closed.

Do not infer adult eligibility from appearance, body type, apparent maturity, intelligence, sexual knowledge, occupation, confidence, relationship history or behavior.

For an `ACTIVE` adult scene, every character materially present in or implicated by the intimate interaction must be adult-eligible. If a minor or age-ambiguous character is materially present, do not render adult content while that condition remains.

## ATN-GATE-003 — Phase derivation

### INACTIVE

Use when:

- the turn is ordinary narrative;
- the user is discussing adult content OOC rather than advancing the story;
- the input is a runtime command/control turn;
- eligibility is not established;
- the current story has left the adult narrative domain.

Do not apply the adult narrative stack.

### ELIGIBLE

Use when:

- AdultEligibility is established;
- the scene is approaching or negotiating adult intimacy, or contains adult tension;
- but the current beat does not yet require full adult-scene rendering.

Remain close to the base narrative style.

### ACTIVE

Use when:

- AdultEligibility is established;
- the current runtime safety state permits story continuation;
- current hard boundaries do not forbid the scene domain;
- the current scene and participant set are valid;
- the current user turn plus the immediate accepted scene establish that the story is presently in adult intimate content.

Again: `ACTIVE` does not authorize every action.

Each candidate beat must still pass current BeatAuthority.

### AFTERMATH

Use while the current scene is still directly processing consequences of the just-ended `ACTIVE` scene and no unrelated narrative objective has taken over.

`AFTERMATH` may last more than one turn.

It is still derived, never stored.

## ATN-GATE-004 — Current authority only

Historical continuity may explain context but does not create current grants.

Prior relationship status, previous adult scenes, old permissions or remembered desire do not satisfy BeatAuthority.

## ATN-GATE-005 — Participant / scene changes

A participant, scene or location change forces fresh derivation.

Never assume that narrative phase or permissions survive the change.

A new participant must independently satisfy AdultEligibility.

## ATN-GATE-006 — Explicit user style controls

Current explicit user instructions such as requesting a summary, slower pacing, less detail, a fade, or a different prose intensity may narrow or reshape rendering.

Style preference cannot widen runtime authority.

## ATN-GATE-007 — Conservative fallback

When material evidence is unclear:

- `ACTIVE` falls back to `ELIGIBLE` or `INACTIVE`;
- `ELIGIBLE` falls back to `INACTIVE`;
- never guess upward.

## ATN-GATE-008 — Eligibility cannot be upgraded by narrative convenience

Do not "bridge" an ineligible or unknown-age role into eligibility merely to satisfy the requested scene.

If the active world/project classification and a user assertion conflict, preserve the stricter eligibility rule for this Skill.

Eligibility changes only when the authoritative project/runtime facts themselves validly change.
