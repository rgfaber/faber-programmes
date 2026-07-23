# EXP-049 — harden 046: does reward-modulated plasticity RELIABLY recover a windy-pole motor reversal, as a rate with a null and a CI?

Pre-registration. Written BEFORE the runner. DESIGN gate runs against this first.

- **Programme:** P3 (046 hardening / engineering bridge)
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9`
- **Runner:** `experiments/exp049_pole_recovery_rate_tests.erl`
- **Raw feed:** `faber-ecosystem/insights/049-raw-pole-recovery-rate.txt`
- **Insight:** `faber-ecosystem/insights/049-*.md` (once signed)

## The claim under test (046's soft spot)

046 claimed reward-modulated plasticity "RELIABLY recovers" a hidden motor reversal on a
windy pole-balancer: nm_plastic 5/5 near-full survival, fixed 3/5, cfc 0/5. But n=5, no
confidence interval, "reliably" from 5 runs, and NO adaptation-off null (so the recovery could
be the evolved base policy, not the online adaptation). This hardens it: n>=10, a recovery
RATE with a Wilson 95% CI, and a paired adaptation-off null.

## The task (pb_sim, matched to 046)

Single pole WITH velocity (sensor variant 4 = [CPos, CVel, PAngle1, PVel1]), goal 400 steps,
`without_damping` (survival = steps). Hidden motor REVERSAL: `shift_at=120, shift_gain=-1.0`
(from step 120 the motor force is negated, unsensed). Constant `wind=5.0` N (forces continuous
control effort so the reversal actually bites). Deterministic: fixed 3.6-deg init, no noise ->
one episode per champion. Topology `[4,8,1]` (confirmed from 046 dims: fixed 49, cfc 57,
nm 54). `sep_cma_es`, evolved WITH the shift active (the champion must survive past step 120).

Reward modulator for the plastic arm (046's): `M = tanh(5*(prev_tilt - cur_tilt))`, tilt =
abs(scaled pole angle) = abs(sensor element 3); M>0 (reinforce) while the pole is righting.
Computed from the sensor stream, no private-state access.

## Arms

| Arm | Evaluator | Adapts? | Role |
|---|---|---|---|
| fixed | `evaluate/2` | no (frozen weights) | non-adapting-architecture null |
| cfc | `evaluate_with_state/2` | via recurrent state | comparison (046: worst) |
| nm_live | `evaluate_with_neuromod/4` {A,B,C,D,Eta}, M live | via online weight change | the claimed winner |
| nm_frozen | the SAME nm champions, redeployed with **M=0** | no (plasticity off) | the ADAPTATION-OFF null (paired, within-genome) |

nm_frozen is the null 046 lacked: same evolved genome as nm_live, but the online adaptation is
switched off at deployment. If nm_live recovers and nm_frozen does not, the recovery is caused
by the adaptation, not the base policy. fixed is the second null (a different architecture that
cannot adapt at all); 046 found it self-immunizes on some runs (a regulable manifold), so it is
NOT at floor -- that is the whole reason a rate + CI is needed.

## Controls (pre-committed)

- **n = 20 independent evolutionary runs per evolved arm** (fixed, cfc, nm). nm_frozen reuses
  the nm champions (paired), so it is n=20 too. Rate over runs, never over steps.
- **Same budget across arms:** identical population / generations / init_sigma. Report per-arm
  genome dims (must be 49/57/54).
- **Recovery is a pre-registered THRESHOLD on survival:** RECOVERED = survived >= 380 of 400
  steps (balanced through to near the goal AFTER the step-120 reversal). Report the rate as
  recovered/20 with a Wilson 95% CI. Also report the raw survival distribution per arm.
- **Sanity:** the pre-reversal task is solvable (a champion reaching step 120 exists); nm_live's
  rate should reproduce 046's direction (high); cfc low.

## Decision rule (pre-committed, both outcomes reachable)

Over n=20/arm:

- **046 CONFIRMED + hardened** iff nm_live's recovery rate exceeds BOTH nulls with non-
  overlapping 95% Wilson CIs: (a) nm_live > nm_frozen (adaptation causes recovery), AND
  (b) nm_live > fixed (adaptation beats the best non-adapting architecture). Report Fisher
  exact p for each.
- **046 OVERSTATED** iff nm_live's rate does not clear the nulls with separated CIs -- e.g. if
  nm_frozen recovers about as often (the base policy, not the adaptation, did the work), or if
  fixed's self-immunization matches nm_live at n=20. Then 046's "reliably... where fixed doesn't"
  is scoped down to what the CIs actually support. A signed correction, like 038/040.
- **INVALID** iff no arm reaches step 120 (the task is mis-set) or dims != 49/57/54.

## Fallback interpretation (committed in advance)

The most likely nuanced outcome (given 046's own Finding 2): fixed self-immunizes on a fraction
of runs, so the SEPARATION is a rate gap, not clean. Pre-state that the headline is the PAIRED
nm_live-vs-nm_frozen contrast (does switching off adaptation break recovery?), because that
isolates the mechanism regardless of how leaky the fixed null is. If nm_live==nm_frozen, the
"adaptation" claim of 046 is refuted even if nm_live still beats fixed.

## Kill criterion

If no champion survives to step 120 in the first few runs, STOP: wind/shift/topology are
mis-set (the champion cannot even reach the reversal). Fix before the full n=20 sweep.

## DESIGN gate verdict (faber-adversary/Fable, 2026-07-23) — REDESIGN REQUIRED

The gate found the hardening still confounded (5 verified leaks). Recorded; ACCEPTED.

1. **nm_frozen is a co-adapted strawman.** M live from step 0 means the base weights were
   CMA-ES-optimised ASSUMING drift; forcing M=0 for the whole episode can break the controller
   PRE-reversal (step 1), scoring a pre-reversal failure as "adaptation was necessary". Fix:
   **clamp-at-reversal** -- plasticity identical up to step 120, then SNAPSHOT + clamp weights
   (nm_clamp) vs keep updating (nm_live). Same valid pre-reversal trajectory; only the
   post-reversal online update differs. Plus log post-120 weight-change magnitude.
2. **Fixed reversal time + determinism = TIMER LEAK.** A stateful net integrates time, so it
   can encode an implicit step counter and switch at t=120 WITHOUT sensing -- contradicting
   "hidden/unsensed". Fix: randomise the reversal time per trial (hidden).
3. **Determinism -> the rate is EVOLVABILITY, not robustness.** One deterministic episode =
   a collapsed 0/1; k/20 measures how often EVOLUTION finds a recoverer, not how reliably a
   controller recovers. Fix: a per-champion battery of K>=50 varied trials -> per-champion
   recovery probability; champion nested in seed.
4. **Evolved-WITH-the-shift = the deepest confound.** The reversal is inside the fitness eval,
   so "nm beats fixed" may only mean plastic nets are EASIER to evolve into robust controllers,
   with ZERO deployment-time adaptation. Fix: evolve on WIND-ONLY, impose the reversal only at
   DEPLOYMENT on unseen champions.
5. **Threshold hides re-stabilisation vs lucky drift.** survival>=380 can't tell "re-controlled"
   from "rode the manifold / wind-motor cancellation". Fix: recovered = survives AND |angle|
   returns under a band within W steps and stays; post-reversal angular variance <= pre-reversal
   baseline; time-to-re-stabilise as graded secondary.
Plus a stats error: paired data needs McNemar / paired bootstrap, NOT non-overlapping
independent Wilson CIs.

## Redesign (the gate's, adopted) — supersedes everything above

- **Evolve on WIND-ONLY** (constant wind, NO reversal), fixed [4,8,1], n>=20 CMA-ES seeds/arm.
- **Impose the reversal only at DEPLOYMENT.** Battery per champion: K>=50 trials, each fresh
  start angle / cart pos / wind sign / reversal time (uniform [80,200], hidden). Per-champion
  recovery probability.
- **Arms:** fixed, cfc, nm_live, **nm_clamp** (plasticity identical up to the reversal, weights
  snapshotted+clamped after; paired with nm_live within the SAME champion and SAME trial seed).
- **Recovered (pre-reg, 2-part):** survives to 400 AND |angle| returns under band B within W
  steps of the reversal and stays. Log post-reversal weight-change as a mechanism check.
- **Decision (symmetric):** CONFIRMED iff paired per-champion (nm_live - nm_clamp) recovery-prob
  gap >= 0.25, McNemar/paired-bootstrap p<0.01, AND holds on wind-only-evolved champions, AND
  post-reversal weight-change correlates with recovery. OVERSTATED/FALSIFIED iff gap < 0.10 OR
  fixed within 0.10 of nm_live. INVALID iff median pre-reversal survival < reversal step.

## VALIDATION FINDING (2026-07-23) — the gate's design has NO SIGNAL

Ran validate/0 (3 runs/arm, K=12). Phase 1 fine: all arms evolve wind-only to 401 (solved).
Phase 2: **survival_prob = 0.000 for EVERY arm** (fixed, cfc, nm_live, nm_clamp). Not a metric
artifact (survival, not just re-stabilisation, is 0): NO wind-only-evolved controller survives a
zero-shot motor reversal. Physics, not a bug -- a negated motor with no adaptation-rule selected
falls the pole.

**Diagnosis:** the gate's "evolve wind-only" over-corrected. Removing the reversal from evolution
kills the evolvability confound (#4) but ALSO removes the selection pressure that makes plasticity
adaptive, so nm_live never evolves a useful adaptation rule -> nothing recovers zero-shot -> the
nm_live-vs-nm_clamp contrast (the headline) has zero signal. The gate reasoned a priori; the run
falsifies the design's usefulness.

**Adjusted design (proposed, preserves the gate's real contributions):** evolve WITH a
DISTRIBUTION of hidden reversals (varied reversal time in [80,200], maybe varied gain), so
plasticity is selected to adapt AND the timer leak (#2) stays dead; test on HELD-OUT reversal
instances; keep the CLAMP ablation (#1) as the deployment-time-adaptation isolator (it controls
evolvability #4 within-champion, same trial, so evolving-with-reversals is fine); keep the varied
battery (#3) and the re-stabilisation readout (#5). The clamp contrast is what actually isolates
"the online post-reversal update did the work", regardless of how the champion was evolved.

Status: **SHELVED 2026-07-23** (Raf's call) to open P4. Not signed -- no insight. The design
record is kept (the gate teardown + the zero-shot finding are the value). Informal bank:
046's "reliably recovers" is n=5 and unhardened; the rigorous hardening (evolve-without-shift +
clamp ablation) has no signal because zero-shot motor-reversal recovery is impossible for these
controllers, so 046's RELIABILITY remains NOT INDEPENDENTLY ESTABLISHED. If revisited: evolve
with a reversal-distribution (varied hidden times) + held-out test + clamp ablation.

## Provenance

*Stamped manually (erl -noshell; eunit swallows the feed).*

## Result

<one line once signed>
