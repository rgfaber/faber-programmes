# EXP-056 — rung 4: when progress goes in CIRCLES, can a fixed benchmark be fooled, and does it take a master-tournament to see it?

Pre-registration. Written BEFORE the runner. DESIGN gate runs against this first.
Rung 4 of the P7 ladder. 053-055 built the fixed-benchmark instrument (not co-fitness;
graded; aligned). All of that assumes progress CLIMBS. This rung breaks that assumption:
an INTRANSITIVE game where the population cycles (A beats B beats C beats A), so there is
no monotone progress to measure. The question: does the fixed benchmark mislead, and is a
champion-vs-champion-across-time tournament (CIAO / Stanley's dominance tournament) the
tool that actually detects cycling?

- **Programme:** P7 (Coevolution / self-play) — rung 4
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9` (numbers game; no net/NIF)
- **Runner:** `experiments/exp056_coevolution_cycling_tests.erl` (once built)
- **Raw feed:** `faber-ecosystem/insights/056-raw-cycling.txt`
- **Insight:** `faber-ecosystem/insights/056-*.md` (once signed)

## The claim under test

The fixed-benchmark methodology (053-055) presumes a monotone quality: progress is a climb, and
a good benchmark tracks it. But coevolution's third failure mode (after Red Queen and disengagement)
is CYCLING: on an intransitive game the population chases its own tail forever, with no real progress.
The open, non-obvious questions: (1) does an intransitive game actually produce SUSTAINED cycling in
this coevolution (or does it converge)? (2) during that cycling, is the fixed benchmark FOOLED --
does it report apparent progress or oscillation where there is none -- or is it robust (stays flat)?
(3) is a master-tournament (champion of generation i vs champion of generation j) the tool that
reliably detects the cycling that a single fixed benchmark cannot? Report as replication of Watson &
Pollack 2001 (intransitive numbers game) and Cliff & Miller / Stanley (CIAO / dominance tournaments).

## The games (a matched pair: intransitive vs transitive control)

Players are 2D vectors (x1, x2). Two coevolving (mu+lambda) populations, mu=lambda=30, mutation
sigma=0.3 both dims. Stochastic win rules, softened by logistic (tau=0.3):
- **Intransitive (Watson-Pollack):** the deciding dimension is the one of LARGEST absolute
  difference, k = argmax_i |A_i - B_i|; P(A beats B) = logistic((A_k - B_k)/tau). This is
  intransitive -- it can produce A>B>C>A -- so the population should cycle.
- **Transitive control:** P(A beats B) = logistic((sum(A) - sum(B))/tau). Monotone; the population
  should escalate the sum (a genuine arms race), NOT cycle. The SAME tools applied here must show
  the opposite readings (benchmark rises, no intransitivity), which is what makes the intransitive
  result non-tautological.
R=120 generations, n=20 runs per game.

## The three measurements (per game, per run)

1. **Fixed benchmark:** the champion's mean win-probability against a FROZEN, graded set of 2D
   reference players spanning the space, per generation. (Under the intransitive rule, "champion" =
   the current population's best against its own population.)
2. **Co-fitness:** the champion's win-probability against the CURRENT opponent population.
3. **Master-tournament (CIAO):** save the champion of every Kth generation; play champion of gen i
   vs champion of gen j for all pairs. **Intransitivity score** = the fraction of pairs (i < j) where
   the LATER champion (j) LOSES to the EARLIER champion (i) by more than a noise band -- on a truly
   progressing game this is ~0 (later beats earlier); under cycling it is substantial.

## Hypothesis (with direction)

Intransitive game: high intransitivity score (later champions lose to earlier ones -- the population
cycles), while the fixed benchmark does NOT rise monotonically (it is flat, oscillating, or
misleadingly non-zero) and co-fitness looks unremarkable. Transitive control: ~zero intransitivity
score, a monotonically rising benchmark, confirming the tools distinguish the two. The sharpest
sub-claim, and the one that is genuinely open: whether the fixed benchmark is FOOLED (reports
apparent progress/oscillation during pure cycling) or ROBUST (stays flat, correctly showing no
progress). Both outcomes are signable and both are informative.

## Controls + validity (pre-committed)

- **Transitive positive control** run with identical tools; it MUST show a rising benchmark and
  ~zero intransitivity, else the tools/operators are broken (INVALID).
- **Cycling reachability:** the intransitive game must actually cycle (intransitivity score clearly
  above the transitive control's); if it converges (score ~0), that is a signed negative about THIS
  intransitive game producing cycling in this coevolution -- report it, do not force a cycling claim.
- **Master-tournament noise band** pre-committed: a "loss" counts only if the win-probability is
  below 0.5 minus a margin (e.g. < 0.45), so ordinary softness is not miscounted as intransitivity.
- **Benchmark graded** (per 054) so a saturation artifact cannot masquerade as flatness/progress.
- **n = 20 runs per game**; intransitivity score, benchmark trend (Spearman gen vs reading), and
  co-fitness aggregated (median + bootstrap CI).

## Decision rule (pre-committed, all outcomes reachable)

Over n=20, R=120, per game:
- **CYCLING, BENCHMARK FOOLED** iff the intransitive game's intransitivity score CI is disjoint above
  the transitive control's (~0) AND its fixed-benchmark trend is NOT a clean monotone rise (Spearman
  gen-vs-benchmark not clearly positive, or the reading oscillates) -> a fixed benchmark can be fooled
  by cycling; a master-tournament is required to detect it.
- **CYCLING, BENCHMARK ROBUST** iff the intransitivity score is high (disjoint from control) BUT the
  fixed benchmark stays flat (Spearman ~0, no false rise) -> the benchmark is robust to cycling (shows
  no false progress); the master-tournament confirms the cycling but the benchmark is not misled.
- **NO CYCLING** iff the intransitive game's intransitivity score is not clearly above the control's
  -> the game converged; a signed negative about this intransitive game.
- **INVALID** iff the transitive control fails (no rising benchmark or non-zero intransitivity) ->
  tools/operators broken; fix first.

## Fallback interpretation (committed in advance)

If CYCLING is present: P7's methodology gains its fourth and final measurement rule -- when the game
is intransitive the population cycles, and the fixed benchmark alone [is fooled / is robust]; a
champion-vs-champion-across-time master-tournament is the instrument that reveals cycling. Together
053-056 give the full toolkit (co-fitness lies; use a graded, aligned fixed benchmark for progress;
use a master-tournament for cycling) needed to honestly measure the embodied pursuit-evasion rung,
where any of the three failure modes can occur. If no cycling, a signed negative and a redesign of
the intransitive game before the embodied rung.

## Kill criterion

If the transitive control does not produce a rising benchmark with ~zero intransitivity, STOP and fix
the tools/operators before interpreting the intransitive game.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-23) — REDESIGN (pending a strategic fork)

The gate found the rung, as drafted, mostly cannot fail and mostly cannot teach:
- **"A master-tournament detects cycling" is INSTRUMENT, not a finding** (textbook Cliff-Miller 1995).
  It must not be signed as a result.
- **The FOOLED/ROBUST decision rule is INCOHERENT:** a flat benchmark (Spearman ~0) satisfies both
  buckets, and labelling a flat-during-cycling benchmark "fooled" inverts the semantics (a flat
  benchmark is CORRECT -- no false progress). Oscillation is the HONEST signature of a population
  rotating past a fixed panel, not fooling.
- **The only signable, open content:** (a) does this operator SUSTAIN structural cycling (vs collapse
  to the diagonal where the deciding dimension is tau-noise), and (b) does the fixed benchmark show a
  FALSE MONOTONE RISE under confirmed cycling.
- **Champion is ill-defined under intransitivity** (argmax over ~50% win-rates wanders); use
  population-vs-population or the centroid for both the benchmark and the CIAO matrix.
- **Prove STRUCTURE** (intransitive triples A>B>C>A beyond the band; banded vs triangular CIAO), not
  mere non-monotonicity (a random walk also yields later-loses-to-earlier).
- **Pilot the operator first** (confirm separation, not diagonal collapse); justify K/R for the cycle
  period (R=120 with ~10 saved champions is too thin).

Required redesign (if kept): FOOLED = clean monotone benchmark RISE under confirmed cycling; HONEST =
flat OR oscillating, no net rise; centroid/pop-vs-pop measurement; structural-triple cycling proof;
a pilot; reframed insight (the false-rise question, not "CIAO detects cycling").

**Strategic fork the gate raised (attack 6):** this is the LAST place to validate the cycling-detector
against KNOWN ground truth (the embodied pursuit-evasion has no is-it-cycling oracle), which argues to
KEEP it -- but only if it tests the one open question (the false rise). Otherwise carry 053-055
straight to the EMBODIED pursuit-evasion rung (the workbench already shows it DISENGAGES; a signed
experiment would characterise that with the graded/aligned instruments). Awaiting Raf's choice.

## Result

<one line once signed>
