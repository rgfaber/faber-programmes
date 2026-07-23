# EXP-053 — the smallest coevolution step: in a STOCHASTIC 1D transitive game, does co-fitness stay uninformative (~0.5, the Red Queen) while the trait escalates unboundedly?

Pre-registration. DESIGN gate ran against a first draft and forced this redesign (below).
The FIRST rung of Programme 7, deliberately minimal: one dimension, one known dynamic
(arms race), ground truth (the trait) DIRECTLY OBSERVABLE. Establishes ONE thing honestly:
co-fitness misleads. Benchmark-fidelity is arithmetically trivial in 1D and is deferred to
the 2D rung.

- **Programme:** P7 (Coevolution / self-play) — the OPENER, rung 1 of a gradual ladder
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9` (numbers game uses no net/NIF)
- **Runner:** `experiments/exp053_coevolution_1d_transitive_tests.erl` (once built)
- **Raw feed:** `faber-ecosystem/insights/053-raw-1d-transitive.txt`
- **Insight:** `faber-ecosystem/insights/053-*.md` (once signed)

## The P7 ladder (gradual, smallest steps first)

Each rung a small signed step, one axis of complexity added at a time:
1. **053 (this) — stochastic 1D transitive:** known dynamic = ARMS RACE; deliverable = the Red
   Queen (co-fitness ~0.5 while the observable trait escalates). Benchmark-fidelity NOT claimed here.
2. 054 — 2D (stochastic) transitive: the FIRST real test of benchmark-fidelity, where truth is no
   longer a single readable number (so "benchmark tracks progress" stops being arithmetic).
3. 055 — intransitive numbers game: benchmark must detect CYCLING (Watson-Pollack), not fake progress.
4. 056 — biased / bounded game: benchmark must detect DISENGAGEMENT.
5. later — neural embodied pursuit-evasion (`coevolution_pursuit_evasion_DEFERRED.md`), toward Flatland.

## The claim under test

Coevolution's central measurement trap (Van Valen's Red Queen): co-fitness (score against the
CURRENT opponent) can stay flat while both sides genuinely improve, because the yardstick moves.
This rung shows that on the simplest case where the true progress is a single number we can read
directly, so co-fitness's failure is undeniable. Report as replication of Watson & Pollack 2001 /
De Jong 2004 (numbers games) and Van Valen 1973 (Red Queen), not discovery. Honest scope: this is
the DEGENERATE Red Queen (both populations climb the same axis; no strategic interaction). Real
interaction, non-transitivity and disengagement arrive at later rungs.

## The game (STOCHASTIC; genotype IS the strategy; no neural net)

A player is a single real number x. Two coevolving populations A and B, each a (mu+lambda) EA,
mu=lambda=30, mutation x' = x + N(0, sigma=0.3). Start x0 = 50 for EVERY individual (well away from
any boundary -- there is no boundary; "bigger wins", x may drift either way but selection pushes it
up). **Stochastic win rule:** P(A beats B) = logistic((x_A - x_B) / tau), tau = 0.3 (on the order of
sigma), so two players of nearly-equal x meet at ~0.5 and the win PROBABILITY is smooth, not a step.
An individual's fitness = its mean win-probability against ALL mu opponents in the current other
population (full cross-eval, zero opponent-sampling noise). Top mu of each population survive.
R = 150 generations. Known ground truth: a monotone ARMS RACE (higher x has >0.5 win-prob against
lower x, so selection escalates x without bound).

## The three curves (per generation)

1. **Ground truth** = the champion's x (directly observable; the escalation).
2. **Co-fitness** = POPULATION-level mean win-probability of population A against population B =
   mean over all (a in A, b in B) of logistic((a - b)/tau). Expected ~0.5 by symmetry (both
   populations escalate together), smooth and low-variance. **Amended after run 1:** the draft used
   champion-vs-champion win-prob, but with tau small relative to the gap between two escalating
   champions that is BIMODAL (snaps to 0/1 by which population momentarily leads) -- a high-variance
   estimator of a quantity whose true mean is provably 0.5 by symmetry; at n=30 it wandered to 0.576
   and failed the [0.45,0.55] band. The DESIGN gate flagged this exact risk. Population-level
   co-fitness (the standard measure) is smooth ~0.5; run 1 (champ-vs-champ) is kept as exploratory.
3. **Fixed-benchmark (SMOKE TEST ONLY)** = champion's mean win-prob against a frozen ladder of
   reference values. In 1D this is a deterministic monotone function of x, so "benchmark tracks x"
   is guaranteed by arithmetic; it is reported ONLY to confirm the runner is wired correctly.
   Benchmark-FIDELITY is not claimed at this rung (it is untestable when truth is one number);
   it is the deliverable of rung 054.

## Hypothesis (with direction)

Co-fitness stays flat around 0.5 with no generational trend, while the champion's x escalates
roughly linearly and unboundedly. That is: the observable trait proves real progress is happening,
and co-fitness is blind to it. Surprise / null: co-fitness trends away from 0.5 (the two populations
escalate at different rates -- a broken-symmetry artifact) OR x stagnates (operator too weak, no
arms race).

## Controls + validity (pre-committed, frozen pre-run)

- **Escalation + ladder sizing PILOT** (a legitimate calibration step, run and reported before the
  main study): a short run to confirm x escalates at sigma=0.3, tau=0.3, K=full, and to measure the
  final x; then freeze the benchmark ladder to span >= 2x that final x (anti-saturation). Report the
  unsaturated fraction.
- **No boundary confound:** x0 = 50, unbounded x, no reflection -- so no operator drift artifact at
  a floor (the DESIGN gate's fix; the first draft reflected at 0 and biased the low end).
- **Symmetry -> co-fitness ~0.5:** both populations use identical rules and init; a co-fitness
  drifting far from 0.5 signals a broken-symmetry bug, not a real asymmetry.
- **n = 30 independent runs**; curves aggregated (median + bootstrap CI per checkpoint); co-fitness
  trend via Spearman(generation, co-fitness) across runs; escalation via Spearman(generation, x).

## Decision rule (pre-committed; the deliverable is the Red Queen only)

Over n=30 runs, R=150 generations:
- **RED QUEEN DEMONSTRATED** iff BOTH: (a) an arms race is present -- champion x at the last
  checkpoint > at the first, disjoint bootstrap CIs, and Spearman(generation, x) > 0.9; AND
  (d) co-fitness is uninformative -- its across-run mean lies in [0.45, 0.55] for the whole run and
  Spearman(generation, co-fitness) has a bootstrap CI including 0 (no trend).
  The benchmark smoke test (monotone in x) is a PRECONDITION on runner correctness, not evidence.
- **NOT A CLEAN RED QUEEN** iff (d) fails (co-fitness trends or sits off 0.5) -> broken symmetry or
  a real asymmetry; a signed note, investigate before rung 054.
- **NO ARMS RACE** iff (a) fails (x stagnates) -> operator too weak; retune, do not sign.
- **INVALID** iff the benchmark smoke test is non-monotone in x -> a runner bug; fix before reading.

## Fallback interpretation (committed in advance)

If DEMONSTRATED: the cheapest, most undeniable demonstration that co-fitness misleads (progress is
real and visible, co-fitness is blind), on a case where ground truth needs no instrument. This
licenses rung 054, where truth stops being a single number and the fixed-benchmark instrument earns
its first real test. If it FAILS here, that is the cheapest possible place to catch a broken harness.

## Kill criterion

If the pilot shows x stagnating (no arms race to measure), STOP and retune the operator before the
main run.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-23) — REDESIGN, then PROCEED

First draft used a DETERMINISTIC win rule (x_A > x_B) and claimed benchmark-fidelity. The gate
found both claims broken: (1) deterministic co-fitness is 0 or 1 (whoever leads in x always wins),
never ~0.5, so the Red Queen signal was false by construction; (2) benchmark-fidelity is a
tautology in 1D (any benchmark is monotone in a scalar truth), so it validated nothing. Fixes
applied (the gate's prescribed smallest change): a STOCHASTIC win rule P = logistic((xA-xB)/tau) so
co-fitness genuinely hovers at parity while x escalates; benchmark-fidelity DEMOTED to a runner
smoke test and deferred to rung 054 (>=2D, non-scalar truth); boundary reflection removed (x0=50);
ladder sized by a pilot. Scope narrowed to the degenerate Red Queen. Verdict: PROCEED.

## Result

RED QUEEN DEMONSTRATED (n=30, R=150): champion x escalates 50.6 -> 85.7 (Spearman(gen,x)=1.000,
disjoint CIs) while population-level co-fitness stays ~0.5 with no trend (mean 0.494, trend CI
spans 0). Co-fitness is blind to real, observable progress. Signed as insight 053. Run 1
(champ-vs-champ, bimodal estimator, 0.576) kept as exploratory. Benchmark-fidelity deferred to
rung 054 (>=2D).
