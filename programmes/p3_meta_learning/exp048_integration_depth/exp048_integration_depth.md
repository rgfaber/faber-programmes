# EXP-048 — integration depth: is 047's good-arm tracking deep evidence-accumulation or a short reactive window?

Pre-registration. Written BEFORE the runner. Direct follow-up to insight 047, resolving the
one flank it left open. The DESIGN is the faber-adversary's own prescription from the 047
CLAIM gate ("a k-step sensor-history-window decode... if window AUC reaches state AUC,
history-echo suffices and tracking stays shallow"), so no separate DESIGN gate is run; the
CLAIM gate still runs before signing.

- **Programme:** P3 (047 follow-up)
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9`
- **Runner:** `experiments/exp048_integration_depth_tests.erl`
- **Raw feed:** `faber-ecosystem/insights/048-raw-integration-depth.txt`
- **Insight:** `faber-ecosystem/insights/048-*.md` (once signed)
- **Input:** the PERSISTED 047 champions
  (`programmes/p3_meta_learning/exp047_lifetime_mechanism_probe/exp047_champions.eterm`).
  Replay-only, NO re-evolution.

## The question

Insight 047 showed the lifetime substrates decode the current good arm from their internal
state near-ceiling (cfc 0.965, nm_pc 0.956, nm_global 0.908), beat the one-step sensor by
0.05-0.07, and are not clocks (shifted-reversal flat). But 047 explicitly did NOT resolve
DEPTH: a state that merely holds the last 2-3 reward/action pairs (a short reactive shift
register) would also beat the one-step sensor and also survive the shifted-reversal control.
"Tracking" could still be shallow.

## Method

Decode the current good arm from a k-STEP SENSOR-HISTORY WINDOW: the last k observed
[reward, action] pairs (2k features), for k in {1, 3, 5, 10}. Same balanced split, transition
exclusion, logistic-regression decoder, and Mann-Whitney AUC as 047. Windows are built on the
full per-instance sensor sequence (transition trials still count as HISTORY), then transition
trials are dropped from the decoded set exactly as in 047. Compare each arm's window-AUC curve
to its state-AUC (reproduced here from the same champions).

The window at k=1 is the one-step reactive baseline (should reproduce 047's sensor_auc ~0.8).
As k grows, window-AUC rises toward whatever the substrate achieves. The k at which window-AUC
first reaches state-AUC is the substrate's EFFECTIVE MEMORY DEPTH.

Arms: fixed (sentinel), cfc, nm_global, nm_pc. n=10 champions/arm (mean +/- sd of AUC).

## Hypothesis (both directions)

- If the tracking is genuine multi-trial INTEGRATION (the noisy bandit rewards accumulation):
  state-AUC exceeds even the k=10 window, because the state pools more than ten trials of
  evidence to beat per-trial reward noise.
- If it is a SHORT REACTIVE WINDOW: a small-k window (k<=5) already matches state-AUC; the
  state holds nothing a few recent observations don't.

## Decision rule (pre-committed, both reachable)

Per adaptive arm, over n=10 champions:

- **DEEP** iff state-AUC > window-AUC(k=10) + 0.02 (the state integrates beyond a 10-trial
  window). Upgrades 047's "tracking" to "evidence integration".
- **SHALLOW** iff window-AUC(k<=5) >= state-AUC - 0.02 (a <=5-observation window matches the
  state). Scopes 047: the substrates track, but shallowly; "integration" is not licensed.
- **INTERMEDIATE** otherwise: report the effective depth (smallest k with window-AUC >=
  state-AUC - 0.02).

Report per arm; the arms may differ (e.g. cfc deep, nm shallow, or vice versa) and that
difference is itself a finding.

## Sanity checks (must hold or the run is void)

- k=1 window-AUC reproduces 047's sensor_auc (~0.79-0.82 for the adaptive arms) within ~0.03.
- state-AUC reproduces 047 (cfc 0.965, nm_global 0.908, nm_pc 0.956) within ~0.02 (same
  champions, same decoder).
- fixed-arm state-AUC stays ~0.5 (constant state); its window-AUC is the WSLS reactive level,
  reported for reference.

## Fallback interpretation (committed in advance)

- DEEP: 047's positive strengthens to "the substrates genuinely integrate reward over many
  trials", and the mechanisms converge on that same deep computation.
- SHALLOW: 047's "no per-step differences to low-pass" still stands (the refutation of 045's
  mechanism is unaffected), but the positive is scoped to "short-horizon reactive tracking",
  not deep integration. Either way 045's low-pass mechanism stays refuted; only the depth of
  what replaces it changes.

## Kill criterion

If the sanity checks fail (k=1 window does not reproduce 047's sensor_auc, or state-AUC does
not reproduce 047), STOP: the champions or the harness are not the 047 ones. Fix before
reading depth.

## CLAIM gate verdict (faber-adversary/Fable, 2026-07-23) — corrected before signing

The first pass (raw [r,a] window) fired DEEP for cfc/nm_pc. The CLAIM gate refuted it: the
per-step evidence is the INTERACTION r*a, which a raw-linear decoder cannot form, so
"state beats raw-linear window" only proves the state is non-LINEAR in the last 10 raw obs, not
that it integrates beyond them. Prescribed controls, all applied: (1) interaction-augmented
window (+ r*a/step); (2) per-champion PAIRED state - window with sd + sign; (3) decoder to
convergence (1200 iters). Also caught a transcription typo in 047's table (fixed sensor
0.766 -> 0.798; feed always said 0.798), now fixed. With the interaction control the DEEP read
FLIPPED to SHALLOW for all three arms (3-5 step interaction window matches/beats every state;
paired state-intr_w10 negative, positive 0-2/10). The gate PRE-STATED this interpretation
("if the augmented window closes the gap, DEEP dies -> shallow window for all three"), so no
third gate call was needed.

## Provenance

*Stamped manually (erl -noshell; eunit swallows the feed).*

### Run 2026-07-23 (interaction-controlled, the signed record)

| Field | Value |
|---|---|
| Runner | `experiments/exp048_integration_depth_tests.erl` |
| Input champions | `programmes/p3_meta_learning/exp047_lifetime_mechanism_probe/exp047_champions.eterm` |
| Engine commit (built == pin) | `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9` |
| OTP / ERTS | 28 / 16.1 |
| rebar3 | 3.25.1 |
| Entry | `run/0` (replay-only, no re-evolution) |
| Raw feed | `faber-ecosystem/insights/048-raw-integration-depth.txt` |

## Result

SIGNED 048 (2026-07-23). 047's tracking is a SHALLOW ~3-5 trial reactive INTERACTION window, not
deep integration, and uniform across substrates (a 3-5 step [r,a,r*a] window matches/beats every
state; paired state-intr_w10 negative for all three). The raw-window "deep" read was a
decoder-class artifact caught at the CLAIM gate. Refines 047's depth; 045 refutation + 047 core
untouched.
