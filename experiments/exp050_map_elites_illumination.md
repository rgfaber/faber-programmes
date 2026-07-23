# EXP-050 — MAP-Elites illuminates the pole-balancer solution space: a diverse archive, and does illumination cost peak quality?

Pre-registration. Written BEFORE the runner. DESIGN gate runs against this first.
First experiment of Programme 4 (Objectives / Quality-Diversity).

- **Programme:** P4 (Objectives / selection pressure) — the opener
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9`
- **Runner:** `experiments/exp050_map_elites_illumination_tests.erl`
- **Raw feed:** `faber-ecosystem/insights/050-raw-map-elites.txt`
- **Insight:** `faber-ecosystem/insights/050-*.md` (once signed)

## The claim under test

Every faber programme so far optimised a SINGLE objective. P4 varies the objective. The QD
thesis (Mouret & Clune 2015, "Illuminating search spaces"): MAP-Elites fills an ARCHIVE of
diverse, high-performing solutions instead of seeking one optimum, and often finds the
objective optimum as a BY-PRODUCT (the "QD free lunch": stepping-stones across the behaviour
space reach peaks a direct objective search stalls before). First test on faber: illuminate the
pole-balancer, and check whether illumination costs peak quality vs an objective-only baseline.

(NB: the charter's original opener -- novelty-on-DPNV as a deception test -- is moot; insight
028 already localised the DPNV wall to optimizer+representation, not deception. This opens P4 on
its forward QD value instead. Report as replication of Mouret & Clune, not discovery.)

## Task and quality

Single pole WITH velocity (sensor variant 4, feedforward-solvable), NO wind, goal 400 steps,
deterministic 3.6-deg init, `[4,8,1]` net (reuses the 049 pole harness). QUALITY = survival
steps (max ~400). `without_damping` fitness (1/step).

## The behavioural descriptor (the one new concept -- the gate's main target)

2D, chosen to be roughly ORTHOGONAL to survival (many ways to balance for 400 steps):
- **BD1 = mean cart position** over the episode, in [-2.4, 2.4] (where on the track it balances).
- **BD2 = mean |applied force|** over the episode, in [0, 10] (how much control effort it uses).

A controller can survive at many track positions and many effort levels, so the archive should
fill a 2D region of survivors, not collapse onto one cell. Grid: 25 x 25 cells (BD1 x BD2).
Descriptor computed from the SAME episode as quality (mean of sensor cart-pos x 2.4, and mean of
|sum(output)| per step).

## Method — MAP-Elites

- Genome = the flat [4,8,1] weight vector (dim 49). Init: 100 random genomes evaluated and
  placed. Iterate E = 60,000 evaluations: sample a uniformly-random elite from the archive,
  MUTATE it (add Gaussian noise sigma=0.1 to the weight vector), evaluate -> (BD1, BD2, quality),
  place into cell (BD1,BD2) iff quality > the cell's incumbent (or the cell is empty).
- Archive = a map from (i,j) grid cell to {genome, quality, bd}.

## Objective baseline (the free-lunch comparison)

`sep_cma_es` maximising survival on the SAME pole, SAME total evaluation budget E. Record its
best survival. This is the peak-quality a direct objective search reaches.

## Metrics (pre-committed)

- **Coverage** = filled cells / 625 (illumination breadth).
- **QD-score** = sum of cell qualities (the standard QD metric: breadth x quality).
- **Max quality in the archive** vs **objective-ES best** (the free-lunch test).
- Archive fitness heatmap (for the insight / Notebook figure).

## Decision rule (pre-committed, both outcomes reachable)

- **ILLUMINATES** iff coverage >= 0.15 (>= ~94 of 625 cells filled with survivors) AND the filled
  cells span a non-trivial range on BOTH axes (BD1 range >= half the track, BD2 range >= half the
  effort axis). A single-blob archive (all mass in a few adjacent cells) FAILS this.
- **QD FREE LUNCH** iff archive max quality >= 0.95 x objective-ES best (illumination reaches the
  same peak). **DIVERSITY COSTS QUALITY** iff archive max < 0.90 x objective-ES best.
- **DEGENERATE DESCRIPTOR** (invalid) iff coverage is high BUT quality is near-flat across cells
  (the descriptor separates trivial behaviours, not meaningful ones) OR the descriptor is highly
  correlated with quality (|corr(BD, quality)| large -> not orthogonal, so "diversity" is just a
  quality gradient). Report the BD-vs-quality correlation as the descriptor-validity check.

## Fallback interpretation (committed in advance)

If the pole is TOO EASY (most random-ish nets survive 400), the archive fills with max-quality
cells everywhere and "coverage" is trivial -- illumination of an un-deceptive, easy task shows
little. Pre-state that then the interesting readout is the SHAPE of the reachable behaviour space
(which cart-position x effort combinations can sustain balance), not the free-lunch comparison.
This is still a valid first QD illumination, just a modest one; the machinery (archive, BD,
QD-score) is the reusable deliverable P8/P9 consume.

## Kill criterion

If < 5% of the initial 100 random genomes produce ANY survivor (survival > ~50 steps), the task
is mis-set (nets cannot balance at all) -> stop and fix before the 60k-eval run.

## DESIGN gate verdict (faber-adversary/Fable, 2026-07-23) — REDESIGN (accepted)

Three defects, each fatal to a decision-rule branch:
1. **Descriptor unreachable + a quality proxy.** BD1=mean cart position collapses near 0 (a
   400-step survivor MUST keep the cart centred), so most of the 625-cell grid is UNFILLABLE ->
   "coverage>=0.15" measures GEOMETRY, not illumination. BD2=mean force is a quality proxy
   (high force -> falls -> empty-by-dynamics), which manufactures "diversity costs quality".
2. **Free-lunch is apples-to-oranges.** sep-CMA-ES (covariance-adapting) vs MAP-Elites (weak
   isotropic Gaussian sigma=0.1) -> a gap means CMA-ES is a better OPTIMIZER, not that diversity
   costs quality. The rule attributes an optimizer-strength gap to a QD tradeoff.
3. **Task too easy -> quality PLATEAU.** Feedforward single pole: everything that balances hits
   400 -> quality flat -> QD-score ~= 400*coverage (a restatement) -> MAP-Elites reduces to
   novelty-with-a-survival-gate; free-lunch is vacuous (both hit the cap).
Determinism is FINE (preferable), but scope claims to the "single-start behavioural manifold".

## Redesign (the gate's, adopted) — supersedes the design above

- **Horizon calibration (pre-run, frozen):** set the survival cap so a random-genome sample has
  MEDIAN survival ~40-60% of cap -> quality gets a gradient (kills the plateau).
- **Descriptor (reachable + orthogonal-to-falling):** BD1 = mean SIGNED pole angle (lean-left vs
  lean-right control styles, which survivors genuinely spread across); BD2 = force-sign reversals
  per 100 steps (bang-bang vs smooth style). Both same-episode.
- **Reachable-set R (pre-run, frozen):** sample 5000 random genomes, record (BD1,BD2) for those
  surviving a minimal threshold, define R. **Coverage = filled/|R|**, NOT filled/625. Publish R.
- **Operator-fair baseline:** the free-lunch comparator is an objective maximiser with the
  IDENTICAL operator (isotropic Gaussian sigma=0.1, (1+lambda) hill-climb on survival, same init,
  same budget). sep-CMA-ES kept only as a labelled "strong-optimizer CEILING", never the
  comparator.
- **Descriptor-validity gate (checked FIRST):** |Spearman(BD, quality)| < 0.3 on both axes over
  filled cells, else the descriptor is a quality proxy and the illumination verdict is VOID.
- **Decision rule:** ILLUMINATION iff coverage(rel R) >= 0.50 AND spans >= half each reachable
  axis. FREE LUNCH iff archive-max >= 0.95x fair-baseline; DIVERSITY COSTS QUALITY iff < 0.90x;
  0.90-0.95 inconclusive; VOID the free-lunch test if fair-baseline is within 2% of the cap
  (no headroom -> report "task too easy for a free-lunch claim"). Sign with the single-start
  scope caveat.

Status: REDESIGNED, build-ready. (Session paused here after opening P4; the redesigned runner is
the next build.)

## Provenance

*Stamped manually (erl -noshell; eunit swallows the feed).*

## Result

<one line once signed>
