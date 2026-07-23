# EXP-056 — rung 4: under structural cycling, is a fixed benchmark FOOLED (false rise) or merely honest-but-blind?

Pre-registration. DESIGN gate REDESIGNED a first draft (incoherent FOOLED/ROBUST rule;
"master-tournament detects cycling" is textbook instrument, not a finding; champion
ill-defined under intransitivity; the Watson-Pollack rule risked diagonal collapse).
This is the gate's prescribed redesign: a game that RELIABLY produces structural cycling,
a centroid measurement, a coherent decision rule hinging on the one open question (does
the benchmark show a FALSE monotone rise), intransitive-triple structural proof, and a pilot.

- **Programme:** P7 (Coevolution / self-play) — rung 4 (the last numbers-game methodology rung)
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9` (numbers game; no net/NIF)
- **Runner:** `experiments/exp056_coevolution_cycling_tests.erl` (once built)
- **Raw feed:** `faber-ecosystem/insights/056-raw-cycling.txt`
- **Insight:** `faber-ecosystem/insights/056-*.md` (once signed)

## The claim under test

053-055 built the fixed-benchmark instrument (not co-fitness; graded; aligned) -- all assuming
progress CLIMBS. Coevolution's third failure mode is CYCLING: on an intransitive game the population
goes in circles, with no real progress. "A master-tournament detects cycling" is a textbook result
(Cliff & Miller 1995) and is our INSTRUMENT, not a finding. The one genuinely open, signable question:
under confirmed STRUCTURAL cycling, is the fixed benchmark FOOLED (does it report a FALSE monotone
rise, as if there were progress) or merely HONEST-BUT-BLIND (it oscillates / stays flat, correctly
showing no net progress, but cannot reveal the cyclic structure -- only the master-tournament can)?
The expected answer is honest-but-blind; a false rise would be the surprise. Report as replication of
Watson & Pollack 2001 (intransitive coevolution) and Cliff & Miller / Stanley (CIAO / dominance).

## The games (a matched pair; the intransitive one RELIABLY cycles)

Two coevolving (mu+lambda) populations, mu=lambda=30, mutation sigma=0.3, softness tau=0.3.
- **Intransitive (cyclic dominance):** a strategy is an angle theta. A beats B when it is "just
  ahead" on the circle: P(A beats B) = logistic(sin(theta_A - theta_B)/tau). This is rock-paper-
  scissors on the circle (intransitive), and selection favours being slightly ahead, so the
  population ROTATES around the circle without bound -- sustained structural cycling by construction
  of the dynamics (verified in the pilot), not diagonal noise.
- **Transitive control:** a strategy is a scalar x. P(A beats B) = logistic((x_A - x_B)/tau) -- the
  053 "bigger wins" game. The population escalates x (a genuine arms race), does NOT cycle. The SAME
  measurements applied here must show the opposite readings (benchmark rises, no intransitivity),
  which is what makes the intransitive result non-tautological.
R and the champion-save interval K are set from the pilot (below) to capture several full rotations.

## The measurement point: the CENTROID (not an argmax champion)

Under intransitivity there is no dominant individual (argmax over ~0.5 win-rates wanders), so all
measurements use the population CENTROID: mean x (transitive) / the population's mean angle
(intransitive, tracked as an unwrapped running mean so rotation is monotone in the raw theta).

## The three measurements (per game, per run)

1. **Fixed benchmark:** the centroid's mean win-probability against a FROZEN, graded set of reference
   strategies (a graded half-circle ARC for the cyclic game, so a rotating centroid's win-rate
   OSCILLATES visibly; a graded x-ladder for the transitive). Trend by MAGNITUDE: the end-minus-start
   delta (mean of the last fifth minus mean of the first fifth), NOT Spearman. Validation caught that
   Spearman(gen, benchmark) reads a spurious ~0.36 on a benchmark that is constant up to float noise
   (rank correlation of float-noise); the magnitude delta is the honest test (same lesson as 054).
2. **Co-fitness:** the centroid vs the current opponent population (expected ~0.5).
3. **Master-tournament (CIAO):** save the centroid every K generations; for all pairs (i, j) play
   centroid_i vs centroid_j. **Structural cycling** is proven by (a) intransitive TRIPLES: saved
   centroids A, B, C with A beats B beats C beats A, each margin beyond the noise band (win-prob
   outside [0.45, 0.55]); and (b) a BANDED CIAO pattern (later beats earlier for a partial rotation,
   then loses past a half-rotation) rather than a triangular (monotone-progress) pattern. Report the
   intransitive-triple count and the fraction of (i<j) pairs where the LATER centroid LOSES.

## Hypothesis (with direction)

Intransitive game: the population rotates (mean angle climbs steadily); the master-tournament shows
many intransitive triples and a banded pattern (structural cycling confirmed); co-fitness ~0.5; and
the fixed benchmark OSCILLATES with NO net upward trend (Spearman ~0) -- honest-but-blind, NOT fooled.
Transitive control: zero intransitive triples, a triangular CIAO, a monotonically RISING benchmark
(Spearman clearly > 0). Surprise (the real finding if it occurs): the benchmark shows a clean
monotone RISE under confirmed cycling (FOOLED).

## Controls + validity (pre-committed)

- **PILOT (run and reported first):** confirm the intransitive game ROTATES (raw mean angle increases
  roughly linearly, not converging) and the transitive game escalates; measure the rotation speed to
  set R (>= 4 full rotations) and K (>= 40 saved centroids). If the intransitive game does NOT rotate
  (converges / diagonal-collapses), STOP and retune tau/sigma before the main run.
- **Transitive positive control** with identical tools: MUST show a rising benchmark and zero
  intransitive triples, else INVALID.
- **Noise band [0.45, 0.55]** for counting a CIAO "win/loss" so softness is not miscounted.
- **Benchmark graded** (per 054) so saturation cannot masquerade as flatness.
- **n = 20 runs per game**; benchmark Spearman, intransitive-triple count, and co-fitness aggregated
  (median + bootstrap CI).

## Decision rule (pre-committed; coherent partition on the ONE open question)

Cycling must first be CONFIRMED on the intransitive game: intransitive-triple count CI disjoint above
the transitive control's (~0). Given confirmed cycling:
- **BENCHMARK FOOLED** iff the benchmark end-minus-start DELTA bootstrap CI is entirely > 0 (a clean
  net rise, like the transitive control's) -> a fixed benchmark can report false progress under
  cycling; the surprise.
- **BENCHMARK HONEST-BUT-BLIND** iff the benchmark delta CI INCLUDES 0 (no net rise; it oscillates,
  confirmed by a non-trivial oscillation range) -> the benchmark is not fooled by cycling (no false
  progress) but cannot reveal the cyclic structure; only the master-tournament can. Expected outcome,
  and a real signed result.
- **NO CYCLING** iff the intransitive game does not produce intransitive triples above the control ->
  it converged; a signed negative, retune the game.
- **INVALID** iff the transitive control fails (no rising benchmark, or non-zero intransitive triples)
  -> tools/operators broken; fix first.

## Fallback interpretation (committed in advance)

Whichever way the benchmark goes, P7's methodology gains its fourth rule: co-fitness lies (053); use a
graded (054), aligned (055) fixed benchmark for PROGRESS; and for CYCLING the fixed benchmark is
[honest-but-blind / fooled], so a master-tournament is [necessary to see structure / necessary to
avoid false progress]. Together 053-056 are the full toolkit to honestly measure the embodied
pursuit-evasion rung, where Red Queen, disengagement, OR cycling can each occur. Validated here
against KNOWN ground truth -- the last place such an oracle exists.

## Kill criterion

If the pilot shows the intransitive game NOT rotating (converges), or the transitive control not
escalating, STOP and retune before the main run.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-23) — REDESIGN accepted; kept per Raf's fork choice

Gate found the first draft mostly could not fail/teach: "master-tournament detects cycling" is textbook
INSTRUMENT not a finding; the FOOLED/ROBUST rule was incoherent (a flat benchmark satisfied both, and
flat-during-cycling is CORRECT not fooled); champion ill-defined under intransitivity; the Watson-
Pollack rule risked diagonal collapse (tau-noise, not structural cycling). Redesign adopted in full: a
cyclic-dominance game that reliably rotates (structural cycling by construction), CENTROID measurement,
a coherent decision rule hinging on the ONE open question (a false monotone benchmark rise under
confirmed cycling), intransitive-TRIPLE + banded-CIAO structural proof, and a PILOT gate. Raf chose to
finish this rung before the embodied one (it is the last place to validate the cycling-detector against
a ground-truth oracle).

## Result

BENCHMARK HONEST-BUT-BLIND (n=20, R=200): the intransitive game cycles structurally (centroid rotates
~8 turns; 1055 intransitive triples vs the transitive control's 0), yet the fixed benchmark shows NO
false rise (delta -0.017, CI [-0.035,0.009] includes 0) while visibly oscillating (range 0.557) -- not
fooled, but blind to the cyclic structure; only the master-tournament reveals it. Completes the P7
toolkit (053-056). Signed as insight 056. Run-1 (Spearman float artifact) kept exploratory.
