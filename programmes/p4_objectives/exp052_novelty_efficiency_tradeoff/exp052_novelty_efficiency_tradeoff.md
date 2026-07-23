# EXP-052 — the price of ignoring the objective: what does novelty search trade away where goal-chasing already wins?

Pre-registration. Written BEFORE the runner. DESIGN gate ran against it and forced a
REDESIGN (below); this is the amended, PROCEED-approved version. Closes the open
efficiency thread insight 051 named. The last P4 characterisation before P7 opens.

- **Programme:** P4 (Objectives / selection pressure)
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9`
- **Runner:** `experiments/exp052_novelty_efficiency_tradeoff_tests.erl` (once built)
- **Raw feed:** `faber-ecosystem/insights/052-raw-efficiency-tradeoff.txt`
- **Insight:** `faber-ecosystem/insights/052-*.md` (once signed)

## The claim under test

051 established the up-side of abandoning the objective: under genuine landscape
deception, novelty search solves where goal-chasing and a strong optimiser are trapped.
Most tasks are NOT deceptive. The complement (Lehman & Stanley's own caveat, and the
"no free lunch" intuition): where the objective gradient DOES lead to the goal, rewarding
novelty instead of proximity should cost something. This measures WHAT novelty trades,
and how much, on a non-deceptive task where goal-chasing wins outright. Framed as a
TRADE, not a one-sided tax: goal-chasing buys speed-to-goal; novelty buys behavioural
coverage. Both sides get measured, and both are separately falsifiable.

## The task — maze E (non-deceptive, non-degenerate), matched to D

Reuse the EXP-051 engine unchanged (11x11 grid, position-only Markov sensors, `[6,10,4]`
net, one (mu+lambda) EA, mu=lambda=20, sigma=0.15). **Maze E:** the SAME wall+gap as the
deceptive maze D (wall at y=5, gap at x=9-10) but the goal moved to G=(9,9); start
S=(1,1). Because the gap now sits ON the greedy right-then-up route to G, closeness-to-goal
descends monotonically to the goal (non-deceptive), and objective-EA solves it reliably.
D and E are thus a matched pair differing only in goal placement (D deceptive, E not).

### Why E, not the old twin N (DESIGN-gate fix 2, frozen pre-run validity check)

The originally-planned twin N (gap at x=1, straight-up route) is DEGENERATE: an
always-north constant policy solves it, and a random genome solves it 20% of the time, so
the shared mu=20 init population contains a solver in 98.8% of runs and EFG floors for
every search. Retired. Frozen validity probe (20000 random genomes / 30 EA runs, engine pin above):

| maze | random single-genome solve | P(mu=20 init has a solver) | constant-north solves | objective-EA solve | objective median EFG | random-search median EFG |
|---|---|---|---|---|---|---|
| N (retired, degenerate) | 0.199 | 0.988 | YES | (floored) | (floored) | (floored) |
| **E (adopted)** | 0.0006 | 0.012 | no | 30/30 | 436 | 864 |
| D (051 deceptive) | 0.000 | 0.000 | no | 1/40 (051) | — | — |

E passes the pre-committed floor gate: objective median EFG (436) < random median EFG
(864), i.e. selection is genuinely accelerating the search, not riding a random floor.

## The two measurements (per search, per run)

1. **Evaluations-to-first-reach-goal (EFG)** = the 1-based index, in evaluation order, of
   the first evaluated genome whose rollout reaches G. Evaluation order is: the mu init
   genomes (1..mu), then each generation's lambda offspring in generation order. Metric
   resolution is +/- lambda (=20); CI separation is only interpreted beyond that granularity.
   Fair to both arms: novelty reaches G incidentally while exploring, objective by converging;
   EFG is a neutral "when is the goal first reached" clock, not an assumption that either is trying.
2. **Behavioural coverage** = the number of distinct **visited cells** (union of all
   trajectories) reached by a fixed budget E, reported as a curve at several budgets
   (e.g. 2k / 6k / 15k). Visited-cells is chosen deliberately (DESIGN-gate fix 3):
   final-position novelty is selected BY final-cell dispersion, so distinct-final-cells is
   a MANIPULATION CHECK, not a finding; distinct-visited-cells is a good novelty does not
   directly optimise, so a novelty advantage there is a real traded good.

## The searches (equal operator + budget)

- **objective-EA** (score = closeness to G). Expected: small EFG, low coverage.
- **novelty-EA[final-pos]** (score = final-position k-NN novelty, the 051 winner). Expected:
  larger EFG, higher coverage.
- **random search** (floor for BOTH metrics; in the decision rule, not just present).

## Hypothesis (with direction)

On non-deceptive maze E: objective-EA reaches G in FEWER evaluations than novelty-EA (a
speed tax on novelty), while novelty-EA achieves HIGHER distinct-visited-cell coverage than
objective-EA at matched budget. The two trade. Surprises / nulls: novelty reaches G as fast
as objective (no speed tax -> free lunch here); OR objective's coverage matches novelty's
(no coverage gain); OR novelty is FASTER than objective (reversal).

## Controls + validity (pre-committed)

- **Floor gate (fix 2, amended after run 1):** the speed comparison is interpreted only if
  objective is faster than random by a TWO-SAMPLE test (bootstrap 95% CI on median(obj EFG) -
  median(rnd EFG) entirely below 0). Run 1's disjoint-one-sample-CI version was mis-specified
  (a textbook error: overlapping one-sample CIs are compatible with a clearly significant
  two-sample difference) and fired a false INVALID; corrected and pre-committed here BEFORE the
  confirmatory run.
- **Coverage floor (fix 4):** a novelty coverage gain is signable only if novelty's coverage
  CI exceeds RANDOM's coverage CI at the same budget (random may saturate the ~110-cell
  reachable set); report the coverage curve so ceiling effects are visible.
- **Censoring (fix 5):** primary EFG estimator = median over ALL runs with censored (never
  solved within E) assigned EFG=+infinity (well-defined whenever solve rate > 50%). If any
  search's solve rate on E is <= 50%, switch to Kaplan-Meier P(solved by budget b) curves
  compared by logrank. Solved-only median = secondary descriptive only (survivorship-biased).
  Report solve rate and censored fraction per search.
- **Matched operator, budget, population** across all three searches. **n >= 40** runs/search.

## Decision rule (pre-committed; two INDEPENDENT axes) — amended after run 1

Coverage and speed are adjudicated SEPARATELY (CLAIM-gate fix: a passing, independently-gated
coverage finding must not be discarded because the speed gate is inconclusive; run 1's single
mutually-exclusive ladder wrongly did that). All EFG tests are TWO-SAMPLE (bootstrap 95% CI on a
median DIFFERENCE), not disjoint one-sample CIs (run 1's floor gate used the latter and fired a
false INVALID: it failed on a 40-eval tail overlap despite a 3.9x median gap, obj 282 vs rnd 1092).

**COVERAGE axis** (own floor: novelty must beat random), over budget E:
- **NOVELTY WINS** iff novelty visited-cell coverage CI > objective's AND > random's (disjoint).
- **NO GAIN** otherwise.

**SPEED axis** (valid only if objective solves E at high rate AND the two-sample floor gate holds:
bootstrap 95% CI on median(objective EFG) - median(random EFG) entirely < 0):
- **TAX** iff bootstrap CI on median(obj EFG - nov EFG) lies entirely below 0 (objective faster).
- **REVERSAL** iff that CI lies entirely above 0 (novelty faster).
- **NO TAX** iff that CI lies within +/- 0.25 * median(obj EFG) (equivalent within 25%).
- **INCONCLUSIVE (unsigned)** iff that CI spans the equivalence margin (underpowered at this n).
- **INVALID** iff objective solve rate <= 0.9 OR the two-sample floor gate fails.

**n = 120 per arm** for the confirmatory run. (Run 1 at n=40 left novelty's EFG CI half-width
~105 against a ~61 equivalence margin; half-width ~ 1/sqrt(n) -> n ~ 40*(105/61)^2 ~ 120.)

## Fallback interpretation (committed in advance)

If TRADE CONFIRMED: P4 closes with the full picture. Novelty is not a free lunch; it is
insurance whose premium is speed-to-goal on non-deceptive tasks, paid for in behavioural
coverage. This motivates P7 / Flatland: once the task is open-ended (no single goal), the
"tax" is not a tax, because coverage IS the objective.

## Scope (fix 7)

Any finding is scoped to this maze family and representation (one 11x11 grid pair,
position-only sensors, one net shape, sigma=0.15). No general "efficiency tax" claim; a
representation/sigma sweep or P7 would be needed to generalise.

## Kill criterion

If objective-EA fails to solve E at a high rate, or the floor gate fails at n>=40, STOP and
find the regression before any interpretation.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-23) — REDESIGN, then PROCEED

REDESIGN accepted; all fixes applied. Fatal flaw caught: the twin N was DEGENERATE (fix 2),
empirically confirmed (random solves N 20%; init-floor 98.8%) and replaced by maze E, which
passes the floor gate (objective EFG 436 < random EFG 864). Other fixes applied: EFG defined
as 1-based eval-order index with +/- lambda resolution (fix 1); coverage = distinct-visited-
cells, with distinct-final-cells demoted to a manipulation check (fix 3); random added to the
decision rule for coverage, with a coverage curve (fix 4); censoring via all-runs median with
+infinity for censored and a Kaplan-Meier/logrank fallback below 50% solve rate (fix 5);
decision rule extended with a REVERSAL outcome and a 1.25x equivalence margin for NO SPEED TAX,
overlap-without-margin = INCONCLUSIVE (fix 6); claim scoped (fix 7). Recorded engine note
(fix 8): the exp051 runner's `?ARCH_CAP` macro (300) is DEAD (the archive is unbounded
append-only); it must not be cited as an archive bound anywhere. With these, the gate's
verdict is PROCEED.

## CLAIM gate verdict, run 1 (n=40, Fable, 2026-07-23) — SIGN-NARROW + RERUN

Run 1 (n=40) results: objective solved 40/40 EFG median 282, novelty 40/40 EFG median 292,
random 40/40 EFG median 1092; coverage@15k obj 81.5 / nov 111.5 / rnd 67 (novelty wins, disjoint).
The runner fired INVALID from a mis-specified floor gate (disjoint one-sample CIs; false fail on a
40-eval tail overlap despite obj being 3.9x faster than random). The CLAIM gate ruled:
- **INVALID is procedural, not substantive**, but must NOT be rescued post hoc (p-hacking). Amend
  the rule (two-sample floor gate + decoupled coverage/speed axes), pre-commit, rerun. Done above.
- **Coverage gain is real and signable** (verified visited-cells, not final-cells), with mandatory
  hedges: ~66 cells are a shared random floor (attributable gains nov +45 / obj +15 / rnd +1) and
  the gain is ceiling-bounded (novelty saturated ~112 of a small maze).
- **Speed side UNSIGNED**: near-identical medians (282 vs 292) but INCONCLUSIVE (equivalence margin
  missed; underpowered at n=40). "No tax" / "free lunch" would be overreach.
- **E confirmed non-deceptive** (14 generations is optimisation time, not deception; obj 40/40 vs
  D's 1/40).
Run 1 preserved as exploratory (`052-raw-run1-n40-exploratory.txt`). Confirmatory run: n=120 under
the amended, pre-committed rule.

## Result

Confirmatory n=120: COVERAGE=NOVELTY WINS (112 of ~112 cells vs objective 79, random 68; disjoint
CIs). SPEED=no tax detected (EFG medians novelty 268 vs objective 305, both ~2.3x faster than random
690; median-difference CI [-36,+132] straddles zero) but formally INCONCLUSIVE for a strict
equivalence claim. Signed as insight 052 (coverage confirmed + no-tax signed negative + method).
Run 1 (n=40) kept as the exploratory false-INVALID predecessor.

