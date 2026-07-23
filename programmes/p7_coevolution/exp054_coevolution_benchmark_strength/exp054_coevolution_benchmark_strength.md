# EXP-054 — rung 2: even a FIXED benchmark can go blind. Does benchmark STRENGTH decide whether it tracks progress?

Pre-registration. DESIGN gate REDESIGNED a first draft (a 2D "alignment" test that was
circular: benchmark references scored by the game's own rule, min-game stays on the
diagonal, and a time-correlation statistic that is tautological). This is the redesign
the gate prescribed: the smallest non-circular step, on the 1D game 053 already validated.

- **Programme:** P7 (Coevolution / self-play) — rung 2
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9` (numbers game; no net/NIF)
- **Runner:** `experiments/exp054_coevolution_benchmark_strength_tests.erl` (once built)
- **Raw feed:** `faber-ecosystem/insights/054-raw-benchmark-strength.txt`
- **Insight:** `faber-ecosystem/insights/054-*.md` (once signed)

## The claim under test

053 established: never use co-fitness, use a FIXED benchmark. But "fixed" is not enough. A benchmark
also needs adequate STRENGTH/range: if its reference opponents are too weak, the champion clears them
early, the benchmark SATURATES at its ceiling, and from then on it reports "no more progress" while
the true trait keeps climbing without bound. This rung tests that a fixed-but-too-weak benchmark goes
blind, while a graded benchmark with adequate range keeps tracking. This is exactly the failure mode
that killed the deferred pursuit-evasion opener (a random/weak benchmark saturates), isolated here on
a game where true progress is directly observable. Report as replication of the graded-benchmark /
dominance methodology (Cliff & Miller; Nolfi & Floreano). Scoped to this game.

## The game (unchanged from rung 1, 053)

The stochastic 1D transitive numbers game exactly as signed in 053: a player is a real x; two
coevolving (mu+lambda) populations, mu=lambda=30, mutation x'=x+N(0,0.3), start x0=50; stochastic
win rule P(A beats B)=logistic((x_A - x_B)/0.3); fitness = population-level mean win-prob vs all
opponents. R=150, n=30. Known ground truth: an unbounded arms race; true progress = champion x,
DIRECTLY OBSERVABLE (so we can check each benchmark against a truth we can see).

## The two fixed benchmarks (the crux)

Both frozen before the run, both "fixed" (never drawn from the evolving populations):
- **Graded (adequate range)** = a ladder of references spanning x0 .. >= 2x the pilot's final x, so
  the champion never clears it -> stays unsaturated and keeps resolving progress.
- **Weak (too narrow)** = a ladder of references clustered LOW, all in [x0, x0+5] (i.e. near the
  start). The champion clears these within a few generations, after which the benchmark is pinned at
  ~1.0 (won every reference) and cannot see any further progress.

Both benchmarks report the champion's mean win-prob against their reference set, per generation.

## The metric (a late-window MAGNITUDE test)

The DESIGN gate's fix: comparing a monotone-in-time benchmark to monotone-in-time truth is
tautological. Validation then caught that a late-window Spearman ALSO fails: a saturated benchmark
still creeps up infinitesimally (0.999 -> 0.9999), so its rank order keeps rising and Spearman reads
1.0 despite being flat and blind. The correct measure is MAGNITUDE, not rank. Metrics, in the LATE
window (generations R/2 .. R) where true x is still climbing strongly:
1. **Unsaturated fraction** per benchmark = fraction of generations where its reading < 0.99. Graded
   ~1.0; weak ~small (saturates early).
2. **Late-window range** = max(reading) - min(reading) over the second half = how much the reading
   can still MOVE while real progress continues. Graded should be substantial; weak ~0 (pinned at
   its ceiling, unable to resolve any further progress).
3. **Blindness gap** = (champion x at R) - (champion x at the generation where the weak benchmark
   first saturated): how much real progress the weak benchmark was blind to.

## Hypothesis (with direction)

Both benchmarks track early; then the weak one saturates and goes flat (~1.0) while true x keeps
climbing, so its late-window tracking collapses to ~0; the graded one stays unsaturated and its
late-window tracking stays high. A fixed benchmark of inadequate strength reports "no progress"
during a large, real, ongoing arms race. Surprise / null: the weak benchmark does NOT saturate (the
arms race is too slow to clear even a narrow ladder in R generations -> lengthen R or narrow the
ladder), or both track equally (no strength effect -> investigate).

## Controls + validity (pre-committed, frozen pre-run)

- **Pilot:** confirm the arms race escalates and measure final x, to size the graded ladder
  (>= 2x final) and to confirm the weak ladder (x0..x0+5) is cleared well before R (so there is a
  saturated late window to measure). Report the weak benchmark's saturation generation.
- **Both ladders frozen** before the run.
- **n = 30 runs**; per-benchmark unsaturated fraction and late-window Spearman aggregated (median +
  bootstrap CI); blindness gap reported.

## Decision rule (pre-committed, all outcomes reachable)

Over n=30, R=150:
- **STRENGTH MATTERS** iff the graded benchmark's late-window range is substantial (median > 0.03)
  with unsaturated fraction > 0.9, AND the weak benchmark's late-window range is ~0 (median < 0.01,
  flat/blind) with unsaturated fraction < 0.3, and the two ranges have disjoint bootstrap CIs. A
  fixed-but-weak benchmark goes blind to real progress.
- **NO STRENGTH EFFECT** iff the weak benchmark's late-window range is comparable to the graded one
  (it never saturated) -> a signed note; narrow the weak ladder or lengthen R before concluding.
- **INVALID** iff the arms race does not escalate (operator too weak, contradicts 053) -> fix first.

## Fallback interpretation (committed in advance)

If STRENGTH MATTERS: the fixed-benchmark rule from 053 gets its first important caveat -- the
benchmark must be graded with adequate range, or it saturates and silently reports stagnation during
real progress. This is precisely the fix the deferred pursuit-evasion rung needs (a graded
hall-of-fame, not a naive/random benchmark). ALIGNMENT/aggregation of multi-dimensional progress
(does a benchmark whose scoring is DECOUPLED from true quality misrank lopsided players?) is a
separate, later rung: a coevolution-free ranking test on a hand-built player panel (the gate's
option b), not attempted here.

## Kill criterion

If the pilot shows the arms race not escalating, or the weak ladder never saturating within R, STOP
and retune (operator or ladder width) before the main run.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-23) — REDESIGN accepted (from the first draft)

First draft (2D min-game, aligned-vs-misaligned ladders) was fatally circular: benchmark references
scored by the game's own min rule collapse to a constant quality-50 opponent (no alignment contrast
possible); the min rule keeps the population on the diagonal (no sustained imbalance to exploit); and
Spearman-over-generations is tautological. The gate prescribed the smallest non-circular step:
benchmark STRENGTH on the 1D game (this), with a late-window/unsaturated metric rather than a
time-correlation, and it flagged that STRENGTH (does a too-weak benchmark saturate) and ALIGNMENT
(does a mis-aggregated benchmark misrank) are orthogonal -- this rung tests STRENGTH; alignment is
deferred to a decoupled-scoring ranking rung. Adopted in full.

## Result

STRENGTH MATTERS (n=30, R=150): the weak benchmark saturated after ~13% of the run (late-window
range 0.0000, dead flat) and was blind to ~30.8 of the ~35 units of real progress, while the graded
benchmark resolved throughout (range 0.130, disjoint CIs). A fixed benchmark must also be GRADED.
Signed as insight 054. Validation caught a Spearman-fooled-by-monotone-creep metric, fixed to
late-window range before the signed run.
