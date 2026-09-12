# Integration Contract

This file defines requirements that cannot be self-enforced from inside the Skill.

## ATN-INTEGRATION-001 — Always-on Agent Profile router

This Skill is not self-bootstrapping.

The `adult-tension-rp` Agent Profile must contain a small always-on routing rule visible before any Skill read:

- call/read current `rp.state` first;
- when the current story turn may start, continue, change or end fictional-adult intimate content, or is a neutral continuation of an immediately accepted adult-domain beat, search `adult-tension-narrative` for `ATN-GATE`;
- when the phase is `ACTIVE`, retrieve `ATN-PLAN` and `ATN-RENDER` as needed;
- when the phase is `AFTERMATH`, retrieve `ATN-AFTERMATH`;
- ordinary turns must not routinely read the Skill.

Without this external router, the Skill cannot reliably trigger because its own routing instructions are not visible until after it has already been read.

## ATN-INTEGRATION-002 — Explicit Owner Matrix binding

The Agent Profile must bind the field/responsibility Owner Matrix from `references/OWNER_MATRIX.md`.

Do **not** use a blanket rule that `adult-tension-narrative` wins over older Adult Tension prose.

The profile/runtime binding must preserve:

1. Native RP safety / authority / Canon / continuity semantics.
2. Existing Adult Tension ownership of character profiles, persistent development, voice modes, POV, permissions and the default adult directness baseline.
3. Narrative ownership only for beat granularity, physical/spatial planning, scene-local progression, sensory focal selection, prose rhythm, anti-slop and aftermath presentation timing.
4. Current explicit user presentation requests as a narrowing/widening control that never expands permission.

Do not rely on the two Skills to infer this split implicitly.

## ATN-INTEGRATION-003 — Skill visibility

`adult-tension-narrative` must be visible to the `adult-tension-rp` Agent Profile.

If profile visibility excludes the Skill, routing is considered not integrated even if the ZIP is installed globally.

## ATN-INTEGRATION-004 — Read budget

The profile's per-call Skill read budget must be large enough to read any individual normative file in this package.

The design target is every individual normative file below 16,000 UTF-8 characters and targeted reads rather than full-package reads.

## ATN-INTEGRATION-005 — Version observability

Bundled bootstrap currently preserves a different installed copy instead of replacing it.

Therefore readiness must distinguish at least:

- missing;
- exact bundled/audited copy;
- different/custom installed copy.

A different installed copy may be intentionally preserved, but the UI/runtime must not claim that the exact audited bundled version is active.

Version/hash observability is an integration concern. Do not solve it by changing all `Different` conflicts to unconditional replacement.

## ATN-INTEGRATION-006 — Four-Skill package contract

The integrated Adult Tension suite becomes:

1. `adult-tension`
2. `adult-tension-continuity`
3. `adult-tension-tauritavern-adapter`
4. `adult-tension-narrative`

Narrative is installed last because it depends on the other layers for context but they do not depend on it for persistent truth.

## ATN-INTEGRATION-007 — Failure isolation

If the narrative Skill is missing or different, the base RP system must remain usable.

Packaging/readiness failures related only to this optional presentation layer must not corrupt existing RP persistence or silently mutate other installed Skills.

## ATN-INTEGRATION-008 — Legacy compatibility requirement

Cross-Skill integration is not complete until either:

- the packaged `adult-tension` Skill includes a compatibility bridge equivalent to this Owner Matrix; or
- the Agent Profile contains an equally explicit binding that both Skills must obey.

Installing this Narrative Skill alone is not sufficient evidence that cross-Skill conflict is resolved.

## ATN-INTEGRATION-009 — Compatibility protocol identity

The cross-Skill ownership protocol is:

`adult-tension-narrative-owner-matrix-v1`

The expected legacy compatibility overlay identifier is:

`narrative-compat-v1`

An equivalent implementation may use a different physical mechanism, but integration verification must prove semantic equivalence to the machine-readable owner map rather than relying on package names alone.
