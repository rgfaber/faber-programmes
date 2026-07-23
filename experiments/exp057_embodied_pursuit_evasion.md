# EXP-057 — the embodied rung: at the most-balanced competent-play point, does neural pursuit-evasion arms-race, disengage, or cycle?

Pre-registration. DESIGN gate REDESIGNED a first draft (a coarse 4-point speed sweep
that under-samples, never targets the competent-play crossover, has saturated dead
cells at the extremes, a circular pilot-HoF benchmark, an endpoint progress rule with
no cell for the overfitting winner, and the argmax champion 056 proved unreliable).
This is the gate's prescribed redesign: ONE balance done deeply, non-foregone, with the
instruments fixed.

- **Programme:** P7 (Coevolution / self-play) — the first embodied rung
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9`
- **Runner:** `experiments/exp057_embodied_pursuit_evasion_tests.erl` (once built; uses network_evaluator)
- **Raw feed:** `faber-ecosystem/insights/057-raw-embodied.txt`
- **Insight:** `faber-ecosystem/insights/057-*.md` (once signed)

## The claim under test

The 053-056 toolkit was validated on numbers games where truth was knowable; this applies it to real
faber-tweann networks coevolving on pursuit-evasion. The workbench exploration (unsigned) showed
disengagement at the SPEED EXTREMES (equal -> evader escapes; fast pursuer -> pursuer dominates) but
never characterised the one place a two-sided gradient could exist: the balance where COMPETENT play
is near 50/50. This rung characterises THAT single balance deeply and asks: is it a (possibly brief)
ARMS RACE, DISENGAGEMENT, or CYCLING? A non-foregone question, because the crossover was never
measured. Report as an embodied replication of Nolfi & Floreano 1998 and its known fragility.

## The game (neural pursuit-evasion, real engine)

9x9 torus. Pursuer P and evader E, each a `[2, 6, 4]` feedforward net (sensors = opponent's shortest
wrap-around relative position; argmax of 4 outputs = N/E/S/W; simultaneous moves). Capture = Chebyshev
<= 1. Episode T=40. The evader skips 1 move every m steps -> pursuer speed factor s. Two coevolving
(mu+lambda) populations, mu=lambda=20, sigma=0.2.

## Step 1 -- CALIBRATE the balance (frozen pre-run; it PLACES the experiment)

Hand-code a greedy pursuer (step to reduce Chebyshev distance) and an optimal-flee evader (step to
increase it). Play greedy-vs-flee across a FINE grid of speed factors s. **s\* = the s where competent
play is nearest 50/50** (catch-rate ~ 0.5). This is the only balance where a two-sided gradient can
exist, and the one the workbench skipped. The whole experiment runs at s\* (a single balance, done
deeply). Report the greedy-vs-flee catch-rate curve and s\*.

## Step 2 -- REPRESENTABILITY + HoF verification (kill gates)

- **Representability:** confirm the `[2,6,4]` net class can FIT the greedy pursuer and the flee evader
  (behavioural clone or champion-seed reaches high catch/survival). If not, INVALID (capacity limit,
  not dynamics) -- STOP.
- **Graded HoF verification:** harvest a hall-of-fame from a throwaway pilot coevolution at s\* PLUS a
  competence-tunable greedy family (greedy with probability p of a random move, p in {0.8..0.0} = weak
  ..strong) and the flee evader. **VERIFY the benchmark is difficulty-GRADED:** each rung's win-rate
  against a fixed probe must be monotone and spread across [0,1]. If the pilot HoF is degenerate
  (one-sided specialists, no spread -> saturation), REJECT it and use the graded greedy/flee family
  alone. A benchmark that cannot be verified graded is INVALID (the 054 saturation demon).

## Step 3 -- Coevolve at s\*, measure with the fixed toolkit (NOT co-fitness)

n coevolution runs at s\*, R generations. Every generation, measure BOTH sides against the frozen,
verified-graded benchmark: pursuer progress = catch-rate vs the benchmark evaders; evader progress =
survival vs the benchmark pursuers.
- **Progress on the FULL TRAJECTORY, not endpoints:** a side's progress = best-so-far (peak) benchmark
  reading minus its start, with a bootstrap CI. This captures the inverted-U (rise then overfit-fall)
  that IS the disengagement signature; endpoint-only would miss it.
- **Master-tournament (056), POPULATION-LEVEL:** save the whole population every K generations; score
  population_i vs population_j (mean win-prob), NOT an argmax champion (the 056 lesson: argmax over
  ~0.5 wanders). Count intransitive triples with a noise band re-derived for this game from the
  start-position/skip-phase variance. Distinguishes DISENGAGEMENT (monotone dominance) from CYCLING.
- **Co-fitness reported, NEVER used to judge progress (053).**

## The three questions (at s\*)

1. Does EITHER side show real progress (peak benchmark > start, disjoint CI)?
2. What is the WINNER's benchmark TRAJECTORY -- monotone rise, or inverted-U (rises then falls as it
   overfits the coevolving opponent and loses to the frozen benchmark)?
3. Is it disengagement (monotone dominance in the population master-tournament) or cycling
   (intransitive triples above the noise band)?

## Hypothesis (with direction)

At the balanced s\*, the most likely outcome is still DISENGAGEMENT (one side's benchmark progress rises
then plateaus/overfits, the other stalls) rather than a sustained two-sided arms race -- but because
s\* is the competent crossover, a brief two-sided race BEFORE one side breaks away is genuinely
possible, and that is the open, non-foregone content. Cycling is a third live outcome the population
master-tournament will catch.

## Controls + validity (pre-committed)

- Calibration (greedy-vs-flee) PLACES the run at s\* -- not a fixed a-priori grid.
- Representability + HoF-graded verification are KILL gates (above).
- Progress scored on the full trajectory (peak vs start); an explicit outcome cell exists for a
  coevolution winner whose FROZEN benchmark stalls or FALLS (overfitting to the live opponent).
- Population-level master-tournament with a game-specific noise band.
- **n set from the pilot's variance for disjoint-CI power** (local compute is free; power is not an
  afterthought). Report the power calc.

## Decision rule (pre-committed, all outcomes reachable) -- at s\* only

- **DISENGAGEMENT** iff exactly ONE side shows peak-progress (disjoint CI) and the population
  master-tournament shows monotone dominance (triples ~ 0) -> the favoured side improves, the other's
  gradient dies, even at the balanced crossover.
- **BRIEF ARMS RACE** iff BOTH sides show peak-progress (both peak-benchmarks rise, disjoint) before a
  breakaway -> a two-sided gradient existed at s\*, the non-foregone positive.
- **CYCLING** iff the population master-tournament shows intransitive triples above the noise band.
- **OVERFIT-WINNER** iff one side dominates head-to-head yet its FROZEN benchmark stalls/falls (an
  explicit cell): a coevolution winner that is not absolutely better -- itself a signed result about
  frozen-benchmark measurement in embodiment.
- **STASIS** iff neither side progresses and no cycling.
- **INVALID** iff representability fails or the benchmark cannot be verified graded.

## Fallback interpretation (committed in advance)

Whatever s\* shows is the first embodied P7 result, measured with validated instruments and read at the
one balance where a race could exist. If DISENGAGEMENT even at the crossover: neural pursuit-evasion
does not sustain an arms race, and Flatland-scale escape needs added structure (space, resources, many
agents) -- shaping P5/P6. If a BRIEF ARMS RACE: a two-sided gradient exists at s\*, the substrate for
denser sampling around s\* and the ecological rungs. Only THEN widen to a sweep around s\*.

## Kill criterion

If representability fails (the net class cannot express competent pursuit/evasion) or the benchmark
cannot be verified difficulty-graded, STOP and fix before interpreting.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-23) — REDESIGN accepted (sweep -> one balance, deep)

The 4-point sweep was under-sampling dressed as a result: it never targeted the competent-play
crossover (the only place a two-sided race can live), its extremes were saturated dead cells, and
"disengagement dominates" merely restated the unsigned workbench. Three instrument defects: the
pilot-HoF benchmark was circular (a disengaged pilot -> degenerate one-sided benchmark -> the 054
saturation demon), the endpoint progress rule had no cell for the overfitting winner (whose frozen
benchmark falls), and it reverted to the argmax champion 056 proved unreliable. Redesign adopted:
calibrate s\* (competent crossover) and run there deeply; verify the HoF is difficulty-graded (reject
if degenerate; a tunable greedy family as fallback); score progress on the full trajectory (peak vs
start) with an explicit overfit-winner cell; population-level master-tournament with a game-specific
noise band; n powered from pilot variance. Widen to a sweep only after s\* is characterised.

## Result

<one line once signed>
