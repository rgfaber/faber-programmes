# EXP-055 — rung 3: does selecting on a MISALIGNED proxy decouple from true quality, and only when improvement costs are asymmetric?

Pre-registration. DESIGN gate REDESIGNED a first draft (a static-panel ranking test)
as a tautology: two aggregation functions differ by construction, computable at the
desk, no coevolution content, unreachable null. This is the gate's prescribed redesign:
make the misalignment DRIVE SELECTION and ask, empirically, whether it decouples from
true quality -- with a live null (symmetric mutation may make a sum-proxy harmless).

- **Programme:** P7 (Coevolution / self-play) — rung 3
- **Opened:** 2026-07-23
- **Engine pin at open:** `9bb43e6b974bd2b62b8e35687e4aea164f0a31d9` (numbers game; no net/NIF)
- **Runner:** `experiments/exp055_coevolution_benchmark_alignment_tests.erl` (once built)
- **Raw feed:** `faber-ecosystem/insights/055-raw-benchmark-alignment.txt`
- **Insight:** `faber-ecosystem/insights/055-*.md` (once signed)

## The claim under test

053: don't use co-fitness. 054: a fixed benchmark must be graded (strength). This rung: when the
proxy you SELECT ON is misaligned with true quality, does the population improve the proxy while
true quality stagnates? True quality is CONJUNCTIVE (good at BOTH dimensions = min); a plausible
researcher's proxy is COMPENSATORY (the sum/mean, which a big dimension can prop up). Whether that
misalignment actually bites is genuinely open: under symmetric per-dimension improvement costs,
sum-pressure is dimension-symmetric and might pull both dimensions up together (min tracks sum,
proxy harmless); the misalignment should bite only when costs are ASYMMETRIC, so the population can
cheaply pump the easy dimension and neglect the expensive one. Both outcomes are signable, and the
"benign under symmetric costs, bites under asymmetric" caveat is the more valuable one. Report as a
methodological demonstration (De Jong numbers games; shaped-proxy / reward-misspecification). Scoped
to this synthetic quality structure.

## The game (2D coevolution, conjunctive true quality)

Players are 2D vectors (x1, x2). Two coevolving (mu+lambda) populations, mu=lambda=30. True win rule
is CONJUNCTIVE: P(A beats B) = logistic((min_A - min_B)/tau), min = min(x1, x2), tau=0.3. True
quality = min(x1, x2). R=150, n=30 runs per cell.

## The 2x2 design (selection proxy x improvement-cost regime)

- **Selection proxy** (the only thing that changes fitness):
  - **Aligned** = fitness = mean win-prob vs the opponent population under the TRUE min rule.
  - **Proxy (sum)** = fitness = mean win-prob vs the opponent population under a MEAN rule:
    P = logistic((mean_A - mean_B)/tau), mean = (x1+x2)/2. A plausible, compensatory proxy.
- **Improvement-cost regime** (mutation step per dimension):
  - **Symmetric** = both dimensions mutate sigma=0.3.
  - **Asymmetric** = x1 mutates sigma=0.3 (cheap), x2 mutates sigma=0.03 (10x more expensive), so
    the population CAN drift lopsided (pump x1, neglect x2) if selection lets it.

Four cells: {aligned, proxy} x {symmetric, asymmetric}.

## Measurement (with the 054 methodology: a graded ALIGNED benchmark)

Every generation, measure the champion of each cell against a FROZEN, GRADED, ALIGNED (min-scored)
benchmark ladder -- the true-quality reading -- plus the proxy (mean) reading. Track:
1. **True quality** = champion min(x1, x2) (also read via the aligned benchmark, which by 054 must be
   graded so it does not saturate).
2. **Proxy value** = champion (x1+x2)/2.
3. **Lopsidedness** = champion |x1 - x2|.

## Hypothesis (with direction)

- **Symmetric regime:** proxy-selection and aligned-selection reach comparable TRUE quality (min);
  the sum-proxy is benign because raising the sum symmetrically also raises the min.
- **Asymmetric regime:** proxy-selection reaches markedly LOWER true quality (min) than
  aligned-selection at the same budget, and its champions are much more lopsided (it pumps the cheap
  x1 and lets the expensive x2 -- the true bottleneck -- stagnate), while aligned-selection is forced
  to invest in x2 and reaches higher min. The misalignment bites only under asymmetric costs.
Surprise / nulls: proxy decouples even under symmetric costs (misalignment always bites); or proxy is
benign even under asymmetric costs (selection still finds the min somehow).

## Controls + validity (pre-committed)

- **Aligned-condition escalation (kill gate):** in both regimes the aligned-selection condition must
  escalate true min-quality (contradicts 053/054 if not) -> else INVALID, fix first.
- **Benchmark is graded (054):** the aligned measurement ladder spans beyond the champions' final min
  (pilot-sized), so a saturation artifact cannot masquerade as stagnation.
- **Runner unit test (NOT signed):** a fixed 36-player panel (x1,x2 in {10,30,50,70,90,110}); assert
  the min-ranking and mean-ranking are DISCORDANT on lopsided pairs (e.g. mean ranks (110,10) above
  (50,50) while min ranks it below). This only verifies the scoring code; it is a worked example, not
  a finding (the DESIGN gate's ruling), and is reported as such.
- **n = 30 runs per cell**; true-quality and lopsidedness aggregated (median + bootstrap CI).

## Decision rule (pre-committed, all outcomes reachable)

Over n=30, R=150, per regime compare aligned-selection vs proxy-selection on champion true min-quality
at R:
The symmetric comparison is DIRECTION-AWARE (amended after an exploratory run 1): "no bite in the
symmetric regime" means aligned-selection does NOT strictly OUTPERFORM proxy-selection on true min
(aligned CI-lo not > proxy CI-hi) -- which correctly includes the case where the proxy is
comparable OR marginally better. Run 1 used "CIs overlap", which is direction-blind: a tiny disjoint
gap with the PROXY marginally higher (a benign outcome) wrongly failed the overlap test and
mislabelled the result. Corrected and pre-committed.
- **PROXY MISALIGNMENT BITES (asymmetric only)** iff in the ASYMMETRIC regime aligned-selection's
  final true min-quality exceeds proxy-selection's with disjoint CIs AND proxy champions are more
  lopsided (disjoint |x1-x2| CIs), WHILE in the SYMMETRIC regime aligned does NOT strictly outperform
  proxy. The valuable caveat: a compensatory proxy is safe under symmetric costs, harmful under
  asymmetric ones.
- **PROXY ALWAYS BITES** iff aligned strictly > proxy on true min in BOTH regimes (disjoint CIs).
- **PROXY BENIGN** iff aligned does NOT strictly outperform proxy on true min in the asymmetric regime
  -> selecting on the sum did not decouple from the min here; a signed negative about this proxy/task.
- **INVALID** iff the aligned condition does not escalate true min-quality (kill gate).

## Fallback interpretation (committed in advance)

If BITES (asymmetric): P7's methodology gains a third rule with teeth -- a misaligned SELECTION proxy
(not just a misaligned yardstick) decouples the population from true quality when improvement costs
are uneven, exactly the regime real problems live in; the fixed aligned benchmark (054) is what
reveals the decoupling that the proxy's own reading hides. If BENIGN, a signed negative: this
compensatory proxy is harmless on this conjunctive task, and misalignment needs sharper structure to
bite. Either sharpens what the embodied pursuit-evasion rung must watch for.

## Kill criterion

If the aligned-selection condition does not escalate true min-quality in either regime, STOP and
retune (operator/tau) before interpreting.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-23) — REDESIGN accepted (static panel -> proxy-driven selection)

First draft (static 36-player ranking test) was a tautology: two aggregation functions differ by
construction, the Kendall tau is desk-computable, the null is unreachable, and there is zero
coevolution content (generic multi-criteria aggregation). The gate (self-correcting its own 054-review
suggestion) prescribed making the misalignment DRIVE SELECTION: two coevolution conditions (aligned
vs sum-proxy fitness) x two cost regimes (symmetric vs asymmetric), measured by the graded aligned
benchmark, with a LIVE null (sum may be benign under symmetric costs). The static panel is demoted to
a runner unit test, not signed. Adopted in full.

## Result

<one line once signed>
