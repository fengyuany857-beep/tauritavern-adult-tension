# Narrative Stack

The stack has two passes.

Do not let Render Pass rules choose or intensify the event itself.

# ATN-PLAN — Beat Planning Pass

## N1 Physical-Spatial Continuity

Constrain the candidate beat so that:

- positions are reachable from the immediately prior state;
- movement has necessary transitions;
- objects and environment remain coherent;
- simultaneous actions are physically compatible;
- scene geography does not drift without cause.

This is a planning constraint, not a persistent state store.

## N2 Progressive Psychophysical Continuity

Reactions should develop from the current beat plus already established immediate context.

Avoid unexplained jumps in intensity or emotional posture.

This module is **scene-local only**.

Do not:

- invent the player's private internal state;
- create hidden numeric meters;
- rewrite `sexuality_profile`;
- rewrite `sexuality_development`;
- treat one scene's progression as sufficient persistent-development evidence.

Persistent character-profile development remains owned by `adult-tension`.

## N3 Character / Context / POV Calibration

The candidate beat must remain compatible with:

- established personality;
- character voice;
- current voice mode when present;
- current emotion and goal;
- relationship posture;
- actual knowledge and knowledge provenance;
- current POV permissions;
- active boundaries and runtime authority.

Adult-scene activation must not flatten characters into one generic voice.

Persistent voice mode controls character dialogue/expression, not narrator clarity.

Do not force a reserved/surface-speaking character into a more explicit dialogue register merely because N6 is active.

Do not use a reserved voice mode as a reason to obscure an already-staged event in narration.

## N4 Interactive Pacing

Default to one coherent beat that leaves appropriate response space.

A useful shape is:

`action or development -> immediate reaction -> immediate consequence -> response space`

Do not consume a meaningful player choice merely to make the reply feel complete.

### Explicit scope override

If the current user explicitly requests a wider temporal unit, summary, less detail, fade, fast progression or multiple connected developments, pacing/presentation may narrow or widen to that requested scope when runtime authority allows it.

This overrides the **default no-automatic-fade presentation behavior**, not runtime authority.

Even then:

- do not invent player decisions that were not supplied;
- do not create unstaged consequences;
- do not widen grants or boundaries;
- do not convert an attempted action into a successful result without runtime support.

## ATN-AUTH-001 — BeatAuthority check

After N1-N4 produce a candidate beat, check that specific beat against current runtime authority.

If it is not currently valid, do not use style to smuggle it through.

Choose a runtime-valid beat, preserve an attempt as an attempt when appropriate, or stop escalation according to the existing RP semantics.

Then stage only the consequences that actually occur through `rp.stage_turn`.

# ATN-RENDER — Render Pass

Run only after one `rp.stage_turn` succeeds.

Render only the successfully staged beat.

## N5 Sensory Grounding

Use concrete perception when it materially clarifies the beat, such as:

- touch;
- temperature;
- pressure;
- breathing;
- sound;
- movement;
- distance;
- environmental feedback.

Do not mechanically enumerate every sense.

For each coherent beat, choose one **primary sensory focal subject / viewpoint**.

Other participants may have externally observable reactions in the same beat, but do not enter multiple private subjective sensory centers or interior states unless the current POV/runtime explicitly authorizes that presentation.

Select details by relevance to character, action and viewpoint.

## N6 Directness / Anti-Sanitization

Directness is a composed rule, not sole Narrative ownership.

Use the existing Adult Tension character/profile and adult-scene directness baseline as input.

When `ACTIVE`, do not automatically replace an already-authorized staged beat with vague summary, unexplained skip-over or euphemistic abstraction merely because the scene is adult.

This does **not** mean the system must refuse a current user request for less detail, summary, fade or fast-forward.

This module cannot:

- intensify the staged event;
- invent permission;
- override a boundary;
- force a response;
- change `active_voice_mode`;
- rewrite persistent character/profile state;
- consume the player's next action;
- create new Canon.

Narrator clarity and character dialogue register are separate. Follow the current voice mode for dialogue while keeping already-staged narration as clear as the selected presentation scope requires.

## N7 Prose Rhythm / Literary Breathing

Match sentence and paragraph rhythm to the staged beat.

Control:

- sentence length;
- pause density;
- paragraph breaks;
- repetition;
- focus distance;
- tempo.

Do not sacrifice physical clarity or character voice for ornament.

## N8 Anti-Slop / Anti-Template

Remove or reduce:

- generic AI phrasing;
- repetitive sentence frames;
- redundant interpretation;
- generic therapy-style analysis;
- voice homogenization;
- unnecessary purple prose;
- empty echoing of the user's wording;
- explanations already made clear by action.

Do not delete continuity-critical information for the sake of elegance.

## ATN-PARITY-001 — Render / stage parity

Before user-visible output, verify that prose does not introduce a material consequence that was not included in the successfully staged beat.

If prose exceeds the staged beat, revise the prose.

Do not perform a second state mutation merely to justify accidental prose expansion.
