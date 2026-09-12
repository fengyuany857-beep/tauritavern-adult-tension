# Recovery

## ATN-RECOVERY-001 — Skill unavailable

If the Skill is missing, not visible, unreadable or the Skill read budget is exhausted:

- do not block base RP;
- continue using the existing `adult-tension` + native runtime;
- do not emulate a hidden copy from memory as though it were the installed Skill.

## ATN-RECOVERY-002 — Search miss

A `skill_search` miss is not proof that a rule does not exist.

If the Skill itself is available and the rule is necessary, perform one targeted fallback read of the appropriate known file/range when possible.

Do not loop search variants indefinitely.

## ATN-RECOVERY-003 — Stage validation failure

A failed `rp.stage_turn` is not a successful beat.

Do not render failed consequences as though they happened.

For a recoverable candidate-shape error, repair the candidate within the profile's allowed stage-attempt budget.

If the failure indicates stale scene, participant, authority or runtime assumptions:

1. discard the old narrative plan;
2. re-read current `rp.state`;
3. re-derive AdultEligibility and NarrativePhase;
4. rebuild the candidate beat;
5. retry only if the runtime permits.

Never reuse stale `ACTIVE` assumptions after authority drift.

## ATN-RECOVERY-004 — Exactly one successful stage

One run may repair rejected attempts according to the Agent Profile, but only one `rp.stage_turn` may succeed for the final beat.

The Render Pass must bind to that successful stage.

## ATN-RECOVERY-005 — Render mismatch

If final prose would exceed or contradict the staged beat:

- revise prose;
- do not mutate state a second time merely to make the prose legal.

## ATN-RECOVERY-006 — Branch / regenerate behavior

Narrative phase is derived per current branch.

Regeneration, swipe selection or branch changes must not inherit a cached narrative phase from another branch.

The selected branch's `rp.state` wins.
