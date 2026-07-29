# EXP-066 — Robo Rumble phase 0, the COMPETENCE FLOOR gate: does single-population evolution reach or fail to reach the floor, and how would we tell?

Pre-registration. Phase 0's final step on the Robo Rumble front, and the gate every later rung is
held behind. `PLAN_ROBO_RUMBLE.md` section 2 states the reason plainly: absence of cycling is
uninterpretable below a competence floor, because at low competence a tank arena is transitive, so
a null there is a statement about the OPTIMISER and not about the SUBSTRATE. That is verbatim the
search under-convergence confound the closed Flatland programme left open, and running phase 1 on
top of it would reproduce it in a new world.

The DESIGN gate returned **BUILD_WITH_CHANGES** with two fatal flaws and seven required changes,
all binding. **This document records the AMENDED design, not the original.** The amendments are
listed with their reasons in the gate section at the end, and the discarded constants are named
there so no later write-up can quietly reinstate them.

- **Programme:** P7 (Coevolution) x the Robo Rumble front, phase 0 kill gate
- **Opened:** 2026-07-29
- **Engine pin (authoring and run):** `a5e8bcfc5646827e9be49a9629f8a6a9678c814b`. One pin, because
  the engine was not modified. Every frozen constant here is measured at it, and it is the provenance.
- **Builds:** `experiments/exp066_single_population_floor_tests.erl`, one runner and nothing else.
  `robo_sim`, `robo_net`, `robo_gauntlet` and `robo_match` are NOT touched, and gate 1 recomputes
  `robo_match_tests`' golden match vector `DFCD8106…B3895E88` to prove it rather than assert it.

> **RECONCILIATION, 2026-07-29.** This document was written before the runner and disagreed with it
> on three points. The document is the contract, so the disagreement is resolved here rather than
> left in the runner's header.
>
> It named the runner `exp066_competence_floor_tests.erl`; it is
> `exp066_single_population_floor_tests.erl`. It required a new engine module `robo_pilot` in
> faber-tweann; no such module was built and the controller is inlined in the runner. It therefore
> also required a second engine pin for the commit landing `robo_pilot`; there is no such commit,
> and the authoring pin is the run pin.
>
> Inlining the controller is the better outcome and is adopted rather than merely accepted. Arm C is
> the only consumer, the engine stays untouched so the golden vector still holds unchanged, and a
> module in faber-tweann would have required a pin bump whose only content was this experiment.
> Protocol step 0, "land robo_pilot and bump the pin", is struck.
- **Raw feed / insight:** `faber-ecosystem/insights/066-*`
- **Upstream:** `PLAN_ROBO_RUMBLE.md` sections 2, 4, 6; kill gate 0a (engine behaves, ladder ranks in
  order) already executable in `robo_match_tests`; kill gate 0b (representability) is arm C below.

## The question, asked symmetrically

Not "does evolution succeed". The question is two-sided and both sides are signable:

**Does single-population evolution against the scripted gauntlet produce a controller that reliably
beats `predictive_gun`, or does it fail to, and by what pre-registered measurement would we tell the
two apart from an instrument that never asked the question?**

A pass unlocks phase 1 (the cycling question). A failure stops the front and reports "evolution did
not reach the regime where the cycling question is askable", which the plan already names as a
cheaper but still signable finding. The third possibility, and the one this document spends most of
its length guarding against, is that neither is true: the run answers a different question than the
one asked, because the fitness supplied no gradient, or the search collapsed onto a quantisation
lattice, or the champion never fired a shot. Those are enumerated as IF-1 through IF-12 and each is
distinguished from a real negative in advance.

## The primary endpoint

Per-seed **held-out win rate** `W_s = wins / 160`, where a WIN requires the `predictive_gun` tank
DEAD and the champion tank ALIVE at match end.

Draws (turn cap with both alive, or mutual death) count as NOT beating. This is chosen over any
`W + D/2` rule for a specific reason: a pure evader that never fires would score exactly the parity
value under such a rule, which readmits the pre-measured never-fire local optimum through the
scoring door.

`L_s` is the corresponding loss rate. `W_s`, `L_s` and the draw rate sum to 1.

## The controller, and the perception boundary is its shape

17 integer sensor channels in, 5 outputs onto an `#intent{}`. Perception is enforced by the same
code shape `robo_gauntlet:act/4` uses: `act/4` destructures the arena to its `scans` field and
NOTHING else, then filters to this tank's observer id, so an opponent's `#tank{}` record is not in
scope below that line. A comment would not survive review; a shape the compiler can check does.

One boundary, in one place. Splitting it across two modules would put half the defence in each.

**Reconciled:** this section originally specified a `robo_pilot` module in faber-tweann. The
controller is inlined in the runner instead, for the reason given in the header block: arm C is its
only consumer, and adding a module to the engine would have forced a pin bump whose sole content was
this experiment. Everything below about the channels, the encoding and the boundary holds unchanged;
only its address does. Read `robo_pilot:inputs()` below as the runner's `?INPUTS`, which is 17 and
which the topology's first width is asserted against, because `robo_net:fit/2` silently pads or
truncates and a mismatch would never fail a test.

### The 17 channels

Arena scale 256 (`robo_net:eval_q12/3`'s expected input scale), every channel inside -256..256.
`robo_pilot:inputs()` returns 17 and the runner ASSERTS the topology's first width equals it,
because `robo_net:fit/2` silently pads or truncates and a mismatch would never fail a test.

Own state, always live:

| # | Channel | Encoding |
|---|---------|----------|
| 1 | `own_speed` | `vel div 8`. MAX_VEL 2048 maps to 256 exactly. Engine velocity is always along the heading, so one scalar is all of own motion. |
| 2 | `own_energy` | `min(256, energy div 100)`. START_ENERGY 25600 maps to 256; the clamp bites only after a run of hit rewards. |
| 3 | `gun_heat` | `min(256, gun_heat div 2)`. Hottest reachable (power 30) is 409, so this reads 204 at most and the clamp never bites. |
| 4 | `energy_delta` | `clamp((energy - prev_energy) div 16, 256)`. One maximum single-bullet hit is full scale. |

Channel 4 is the ONLY proprioception of incoming fire that exists, and it conflates being shot,
hitting a wall, being rammed, paying to fire and being paid for a hit. This is irreducible:
separating the causes needs engine internals the boundary forbids.

Position and walls, always live. Arena size is a rule of the game, not opponent state, so consulting
it breaks no perception rule (`robo_gauntlet:wall_push/1` already does). Position is given in BODY
frame because acting on a world-frame position requires a rotation, and a rotation is a product of
activations that a fixed-topology MLP cannot form:

| # | Channel | Encoding |
|---|---------|----------|
| 5 | `pos_fwd` | body-frame X of (own position minus arena centre) `div 512`. Max offset 500 whole units, so 250 at most. |
| 6 | `pos_port` | body-frame Y of the same, `div 512`. Positive is to the left, matching the engine's counter-clockwise-positive `turn_body`. |
| 7 | `wall_danger` | `256 - min(256, max(0, C) * 256 div 32768)`, C the minimum of the four wall gaps allowing for TANK_R. Reads 0 beyond 128 whole units of clearance, 256 on contact. |

`wall_danger` is danger rather than clearance so the channel is SILENT in the common case and does
not perturb an untrained baseline.

Contact. ALL EXACTLY ZERO when no contact has ever been seen, which combined with `robo_net`'s
per-neuron bias makes "behave sensibly while blind" a learnable bias term rather than a special case:

| # | Channel | Encoding |
|---|---------|----------|
| 8 | `contact_fresh` | `2048 div (8 + min(age, 1024))`; exactly 0 if never seen. 256 on a scan turn, 128 at eight turns, floor 1 at the cap. The zero is a structural sentinel. |
| 9 | `bear_body_cos` | contact direction in body frame, cosine component |
| 10 | `bear_body_sin` | same, sine component. Positive is to the left. One negative weight from ch 9 holds the contact at ninety degrees, which is orbiting. |
| 11 | `bear_gun_cos` | gun frame cosine. THE ALIGNMENT CHANNEL, and the only EVEN function of aim error in the vector. |
| 12 | `bear_gun_sin` | gun frame sine. THE AIM ERROR: the signed quantity a positive `turn_gun` reduces. Aim is one positive weight. |
| 13 | `bear_radar_cos` | radar frame cosine |
| 14 | `bear_radar_sin` | radar frame sine. THE LOCK ERROR. Radar tracking is one weight. |
| 15 | `contact_prox` | `(256 * 51200) div (51200 + D)`, D the scan distance. 256 at contact, 128 at 200 whole units (the gauntlet's own ORBIT range), 64 at 600. Never saturates. |
| 16 | `target_lateral` | `clamp((UX*VY - UY*VX) div 2048, 256)`. Contact's ABSOLUTE velocity across the line of sight, full scale at the speed cap. |
| 17 | `target_range_rate` | `clamp((UX*VX + UY*VY) div 2048, 256)`. Positive means opening. |

Channel 16 is absolute rather than relative because lead angle is lateral speed over bullet speed
and is range-independent to first order, so ONE weight into `turn_gun` is a working lead. The clamps
on 16 and 17 are mandatory, not decorative: measured pre-clamp maximum is 263.

**THE BEARING TRICK, verified not assumed.** No atan2 and none added. A scan carries a vector, never
a bearing (verified: the scan tuple is `{ObserverId, TargetId, Distance, {DX, DY}}`). The delta is
rotated into a part's frame against `robo_sim`'s own sine table, then BOTH components are divided by
the octagonal norm OF THE ROTATED VECTOR, recomputed rather than reused from the scan's `Distance`
field, because the octagonal metric is not rotation invariant. Measured over 60669 realistic
separations at seven rotations: max component **exactly 256** (not 255; equality holds when the
minor component is zero, so axis-aligned deltas sit exactly ON `robo_net`'s contract edge rather
than inside it), angular error against `atan2` max 0.1640 mean 0.0549 units, pair norm between
0.9318 and 1.0275. The pair-norm wobble is a bounded deterministic gain modulation identical for
every controller, not a direction error. For comparison, `robo_gauntlet:angle_of/1`, which the floor
bot itself uses, has max error 0.5003 mean 0.2493, so this encoding is three times more accurate
than the bisection the opponent aims with, at two multiplies and two divides. The scan's own
`Distance` is used for channel 15, so the range the net sees is the number the engine reported.

**THREE FRAMES, DELIBERATELY REDUNDANT.** Recovering one frame from another is a rotation, a
rotation is a product of activations, and a fixed-topology MLP cannot form products. Spending two
channels to remove a multiplication the architecture cannot perform is the correct trade every time.
Aiming, orbiting and radar tracking each collapse to a single weight.

**GUN AND RADAR OFFSET CHANNELS ARE CUT.** The three frames give the contact relative to each part,
so inter-part offsets matter only when there is no contact at all, and in that state the sensible
behaviours (sweep at a constant rate, drive) need no feedback. Pre-registered fallback if arm C
reaches for them: TWO channels, signed shortest angle of gun minus heading and of radar minus
heading, each `div 128`. Not four. The decision is made by BUILDING arm C, and the encoding freezes
at the same instant `W_0b` does.

### The tracker

`robo_pilot` holds a record with: tick, target id, seen count 0..2, age since last scan, latest
contact absolute position and its tick, previous contact absolute position and its tick, previous
own energy. Contact absolute position is own position plus the scan delta, a derivation from two
permitted facts. On a scan turn the latch shifts and age resets; on a silent turn age increments.
Switching target id resets to a single sighting, so a velocity estimate can never difference two
DIFFERENT opponents (`robo_gauntlet` already took this audit fix). Contact selection is nearest,
strictly closer so ties keep list order.

Velocity is the difference of the two latched positions divided by `max(1, tick gap)`. Dividing by
the gap is arithmetic, not strategy, and it is mandatory: scans arrive only when the radar sweeps,
so successive sightings are not one turn apart. Fewer than two sightings reports zero. There is NO
trust window and NO gating, unlike `robo_gauntlet:enemy_vel/1`: a stale estimate attenuates because
the gap divides it, and channel 8 tells the net how much to believe the track. That call belongs to
evolution.

### Two stated limitations, pre-registered as limitations rather than reinterpreted later

**DEAD RECKONING IS IN, PREDICTION IS OUT.** Channels 9 to 14 report the contact's ESTIMATED
POSITION NOW (latched position plus estimated velocity times age, clamped to arena bounds), not
where it will be when a bullet arrives. Keeping the sensor's meaning constant across turns is what
makes a radar track a track rather than a snapshot; solving flight time is strategy and is withheld,
and channels 16 and 17 let the net learn the lead itself. It does not tilt the floor comparison,
since `predictive_gun` has a BETTER hand-written tracker of its own including the flight-time solve.
It DOES void any future claim that the controller "learned to track" or "learned to handle
intermittent observation". That claim is unavailable to this front from here on.

**BULLETS ARE NOT OBSERVABLE AND CANNOT BE.** The engine's scans carry no bullet and
`#arena.bullets` is outside the boundary. Evasion cannot be a closed loop on an incoming round; only
statistical unpredictability plus the one-turn-late channel 4. This is a live alternative
explanation of a null and is named as one.

**NO CONSTANT BIAS INPUT.** `robo_net` gives every neuron its own bias; a channel for it would waste
12 or more parameters.

### The 5 outputs

From `robo_net:eval_q12/3` so the last four bits are not thrown away, each through
`robo_net:to_range/2` with the ENGINE'S OWN CLAMP as Max, so the network's reachable set is exactly
the legal set and no output is wasted on values the engine will refuse:

| # | Field | Mapping |
|---|-------|---------|
| 1 | `turn_body` | `to_range(A, 7)` |
| 2 | `turn_gun` | `to_range(A, 14)` |
| 3 | `turn_radar` | `to_range(A, 32)` |
| 4 | `accel` | `to_range(A, 512)` |
| 5 | `fire` | `to_range(A, 30)` |

**FIRING IS ONE CONTINUOUS OUTPUT AND THE THRESHOLD IS THE ENGINE'S, NOT MINE.**
`robo_sim:clamp_power/1` already reads anything at or below zero as hold and anything above as a
power in tenths, so `to_range(A, 30)` covers hold and every power on one monotone axis with NO
hand-chosen constant and no second output. It is also economically right: whether to shoot and how
hard are the same question, and marginal shots should be weak.

Two measured facts make the neutral prior safe rather than reckless. Gun heat throttles it: even a
power 1 shot sets 261 heat against 26 per turn of cooling, so a maximally spammy controller fires
about once every eleven turns whatever it wants. And the recorded hazard on this front runs the
OTHER way: `robo_match` measured that energy scoring ranked a sitting duck above a bot that moves
and shoots, so "never fire" is the strong local optimum, and an encoding whose untrained prior is
neutral (a fresh tanh output sits at zero, so an untrained net fires about half its opportunities)
is a mild counterweight rather than an added risk. **Do NOT add a hold-biased encoding or a separate
fire-decision output**; that would be a thumb on exactly the scale that already tips.

**REPRESENTABILITY OF THE TRIGGER, and it sets the topology fallback.** Fire-when-aligned is an EVEN
function of aim error. Channel 12 is odd and cannot supply it. Channel 11 is the even one: a
positive weight on channel 11 plus a negative bias thresholds on alignment. Sharpness is bounded by
the weight cap: weights cap at 8.0 and tanh saturates at 4.875 in Q12, so a linear unit can
threshold at roughly `cos >= 0.9`, about plus or minus 25 degrees, against the floor bot's AIM_TOL
of 2 angle units (about 2.8 degrees). That is the sharpest known representability limit of the
linear arm and it is stated in advance. If arm C cannot clear the precondition on `[17,5]` for this
reason, the pre-registered move is `[17,12,5]`, where a hidden layer builds a sharper conjunction
from channels 11 and 12 (two tanh units differencing into an absolute value), and the fact is
recorded as the reason.

Weight counts, verified against `robo_net:weight_count/1`: `[17,12,5]` gives **281**, `[17,5]` gives
**90**.

**DETERMINISM.** Every operation in `robo_pilot` is integer comparison, addition, subtraction,
multiplication, min, max, Erlang `div` and tuple indexing. No float, no libm, no clock, no rand, no
process, no ETS, no map in any hashed term. `div` truncates toward zero and is therefore exactly
odd; no arithmetic right shift is applied anywhere, so the floor-versus-truncate trap `robo_net`
documents is never reached. The one float boundary in the system stays where `robo_net` put it, in
`quantize/1` at phenotype build time, called inside the fitness and OUTSIDE the match.

## The fitness: a ladder over the scripted gauntlet, graded on damage margin, walked lazily

**It never reads energy and it never reads survival time.**

Per match, from the learner's seat, in ARENA FIXED POINT (raw `#tank.damage_dealt`, never
`robo_match`'s whole-unit `div 256`, because a power 0.1 pellet does 0.4 damage and whole units
report that as 0, and that dead zone sits exactly where cheap exploratory shooting lives):

```
margin = dealt - taken                  when the learner is alive at the end
margin = dealt - max(taken, BAR)        when the learner is dead
BAR    = 25600                          robo_sim's START_ENERGY
```

`taken` is the OPPONENT's `damage_dealt`, which in a duel is exactly the bullet damage the learner
absorbed, so no engine counter is needed. (Melee would need one. Melee is out of scope.)

**Why the death floor is not a tuning knob.** Raw margin pays a losing controller to end the match
early, because dying truncates the damage the opponent can still inflict. Wall contact costs 1.0 per
turn, so a wall suicide takes 100 turns and concedes about half a bar, against the 1.04 bars that
surviving and losing to the floor bot concedes (measured: -104.24 whole units). Flooring the loss at
one bar makes dying weakly worse than surviving with the same damage taken, at every turn. The
constant is the tank's own starting energy, not a chosen number.

**Why it never reads energy.** `robo_gauntlet` budgets every gun so a bot that is MISSING decays
toward its fire floor while a bot that NEVER FIRES keeps a full bar, so ANY energy-derived fitness
structurally rewards not shooting. `robo_match` measured exactly that. An opponent-energy term would
also pay the learner for the opponent's own firing costs, wall grinding and ram damage, none of
which the learner caused. Ram damage is symmetric and credited to nobody in `hit_one/5` (verified:
`damage_dealt` is incremented on bullet hits only), so ram farming is impossible under this rule.

**Why it never reads survival time.** The density a survival term would supply comes from the
curriculum instead, which is cheaper and does not couple fitness to not-firing.

**NO SHAPING.** No term for scans held, radar coverage, gun alignment, near misses, shots fired or
hits counted. The specific reason, not the general one: the floor is defined by PREDICTION, and
every cheap intermediate signal available here is precisely what `circle_strafer` does (hold a lock,
point at the last-seen position, fire when aligned). `circle_strafer` is measured at 0 wins in 160
against the floor bot. Every available shaping term is a proxy for the rung one below the floor. A
per-scan reward is worse than useless: a radar sweeping at maximum rate acquires MORE distinct
contacts than a radar that locks, so it would teach spinning over locking.

### The staircase

```
F = (number of rungs cleared, walking from the bottom) + squash(mean margin on the frontier rung)

cleared(Rung) iff EVERY match of that rung has margin > 0        a sign test, no invented threshold
frontier      = the lowest uncleared rung; once the whole ladder is cleared, the WEAKEST rung by
                mean, so a champion keeps being pushed on its worst opponent rather than its best
squash(M)     = (clamp(M, 2*BAR) + 2*BAR) / (4*BAR + 1)          in [0, 1), strictly below 1
```

`all` for clearing and `mean` for the frontier is deliberate: clearing asks for reliability, because
a rung cleared on average is a rung with a geometry the controller cannot handle, while the mean
grades partial progress so the rung is never a plateau.

**The tail term is an ORDERING, not an exchange rate.** Confined below 1.0, so clearing a rung
outranks every possible margin gain on it. This is sound ONLY because both optimisers select by
RANK: `mu_lambda_es` sorts and keeps the best mu, `sep_cma_es` sorts and recombines the best mu, and
neither reads a magnitude. Verified in both sources. An optimiser that read magnitudes would
silently turn this into a weighted sum with weights nobody chose.

**Walk from the bottom, stop at the first uncleared rung.** Two consequences. Compute: nothing above
the frontier is read, so nothing above it is simulated, and this is EXACT, not an approximation.
Anti-forgetting, which matters more: a rung once cleared must STAY cleared or the count drops, so
the rung-5 landscape's "circle and never fire" attractor cannot eat the marksmanship learned on the
gunless rungs. The never-fire optimum is fenced off, not argued away.

Rung order is `robo_gauntlet:kinds()` unchanged: `sitting_duck`, `spinner`, `rammer`,
`circle_strafer`, `predictive_gun`.

**Why a ladder at all, measured.** Grading directly against the floor bot gives a nearly flat and
MIS-ORDERED landscape: on the held-out 80 starts in both seats the four lower rungs span only about
0.2 bars (-104.24, -90.46, -84.87, -88.51 whole units) and the RAMMER (rung 3) out-damages the
CIRCLE_STRAFER (rung 4), because circling is partial evasion while a non-leading gun spends energy
and lands nothing. Rung 1 by contrast spans a full two bars in correct order, from the rock at 0 to
a competent shooter at about +1.04. The population learns to shoot where shooting is gradable.

**The gate-versus-fitness mismatch, decided rather than patched.** The gate scores KILLS; the
fitness grades MARGIN. No bonus constant is added, because a bullet kill already yields
approximately one full bar of margin, so margin ranks kills far above draws by construction. Adding
a kill bonus would invent an exchange rate that cannot be justified. The residual case, a champion
that out-damages the floor bot but cannot convert inside the turn cap, is a PRE-COMMITTED SECONDARY
READING (below), not a defect to be discovered afterwards.

### Degenerate policies and where each starves

| Policy | Where it starves |
|--------|------------------|
| The rock (all outputs zero; literally `sitting_duck`, and literally `sep_cma_es`'s default x0) | Scores 0.000 on rung 1. Any controller landing one pellet on a stationary target beats it, with the mean grading every step of a two-bar climb. |
| The pacifist / perfect dodger | The duck deals no damage, so surviving it is worth exactly 0.000, and a rung clears only on a POSITIVE margin. It never leaves rung 1. This is why `sitting_duck` must be rung 1 of the FITNESS and not merely a smoke test. |
| Spray and pray | Correct and welcome on rungs 1-2, starved from rung 3 on where wasted energy converts into death at a full bar. Not a local optimum: better aim strictly increases margin everywhere. |
| The self-terminator | Killed by the death floor; weakly dominated at every turn. |
| The wall hugger | 1.0 per turn, dead in 100 turns for a full bar, on every rung including the duck. |
| The circling non-firer (best of the weak policies vs the floor bot) | Fenced off by the anti-forgetting rule: cannot regress out of rungs 1-2 without dropping the count. |
| The draw farmer (margin exactly 0) | Zero is not positive, clears nothing, sits immediately below anything that clears. |
| The pellet spammer | Minimum gun heat is 261 against 26 per turn of cooling, so the engine caps firing near one shot per 11 turns; 180 pellets at 0.4 damage cannot kill inside the cap. The fitness prefers lethal power without a term saying so. |
| The start memoriser | Caught by the held-out ensemble, which is the entire reason it exists. IF-8. |

### What survives phase 1, stated as an explicit DISCARD

The per-match MARGIN is the durable object and is exactly what a cross-play matrix needs. **The
staircase is phase-0 scaffolding with no meaning once the opponent is another evolved net and there
is no ladder.** Written down here so it is not carried forward by inertia.

## Protocol

### Order of operations, and it is load-bearing

Everything that could be tuned is measured and frozen BEFORE the first evolution arm runs, every
generator-dependent constant is measured under the FINAL start rule, and **the bar is frozen before
arm C is built** so that the person building arm C cannot set the difficulty of the gate they then
want evolution to clear.

```
1. Instrument checks (below). Any failure stops here, and run/1 ENFORCES this
   rather than documenting it.
2. Measure P, SE, S_par on held-out with SCRIPTED BOTS ONLY (no evolved controller).
   Compute and FREEZE B, R_line, D_min. Write all of them into this document with their feed.
3. Build arm C on CALIBRATION starts only, against the already-frozen B, under the stop rule.
   FREEZE the encoding at this instant.
4. Measure W_0b on held-out and REPORT it. Arm C does not gate anything.
5. Measure R (best-of-30 random genomes) on held-out, at the frozen encoding.
6. Run arms S, L, D. Then arm M ONLY if S does not clear.
7. Decide IF-1 (below), which needs the arms and therefore cannot be decided before them.
```

Step 0 is struck: no engine module is landed, so there is no pin to bump.

### The start split

One deterministic generator, integer only, no rand and no libm. For index I in 1..120:

```
AX = 60 + (I*137) rem 681,  AY = 60 + (I*191) rem 481
B walked by a fixed stride: BX = 60 + ((I*251) + K*97) rem 681, BY = 60 + ((I*313) + K*89) rem 481,
  K rising from 0 until robo_sim:dist({AX,AY},{BX,BY}) >= 150 whole units, so no match opens inside
  ram range (2*TANK_R = 36). K IS BOUNDED AT 64 with a deterministic reflection fallback
  {800-AX, 600-AY}, so the walk cannot fail to terminate.
Face = robo_gauntlet:angle_of({BX-AX, BY-AY})           bisection on a cross product, no atan2
AH   = wrap(Face + off(I))
BH   = wrap(Face + 128 + off(I div 8 + 3))
off(I) = element(1 + (I rem 8), {-96,-64,-32,-8,8,32,64,96})
```

| Split | Indices | Use |
|-------|---------|-----|
| TRAIN | 1..6 | 12 matches per rung per fitness evaluation, both seats |
| HELD-OUT | 7..86 | 80 starts, 160 matches. **THE GATE LIVES HERE.** |
| CALIBRATION | 87..116 | 30 starts, used to BUILD AND TUNE arm C and for nothing else |
| unused | 117..120 | generated and deliberately unused |

Verified: 120 distinct starts, separation min 150, median 340, max 704.

**THE HEADING OFFSET IS THE CORRECTION THAT MATTERS AND IT WAS MEASURED, NOT REASONED.** Under an
all-mutually-facing start generator, `predictive_gun` against its own clone draws **106 of 160** with
70 percent of matches hitting the 2000-turn cap, parity win rate 0.169. With the per-index offset,
the same 80 geometries give **67 wins / 67 losses / 26 draws**, parity 0.4188, cap share 0.1625.
Same bots, same engine, same geometries. The all-facing rule was manufacturing stalemates by
starting the mirror match perfectly symmetric, and it would have left the primary endpoint 70
percent censored. The offset also kills a second degeneracy: with `|offset| >= 8` angle units on
every start, no tank is ever bore-sighted at turn 1, so "fire straight ahead immediately" cannot
clear rung 1 by itself. And because the offset is ONE RULE applied to all 120 indices, train and
held-out remain exchangeable draws from a single distribution, so a train-to-held-out gap means
overfitting rather than distribution shift.

**BOTH SEATS ALWAYS.** Not assumed: `robo_sim` folds `fire_all/2` and `first_hit/2` in tank list
order, and 27 of 80 held-out starts show `circle_strafer` versus `predictive_gun` differing by seat.
It is also the cheapest anti-overfit device available, since the geometries are asymmetric.

**ENSEMBLE SIZES ARE NOT MATCHED, deliberately.** A win rate is a rate and is comparable across
ensemble sizes, and 160 held-out matches buy resolution that 12 cannot: at 12 matches the parity
reference itself would be 1 win, 1 loss, 10 draws and no threshold on it would mean anything.

**TRAINING STARTS ARE FIXED, NOT RESAMPLED.** sep-CMA-ES degrades under fitness noise, a stochastic
fitness makes "the champion" ill-defined, and resampling would break the exact fitness cache. The
held-out ensemble is the memorisation detector, and IF-8 prescribes the stochastic-start variant as
the next rung if memorisation fires. Settled before the first run precisely so it cannot be settled
after seeing one.

### The match loop

The runner owns its own loop; `robo_match:run/4` is gauntlet-only and is NOT modified. THE
PERCEPTION CONTRACT, as `robo_match` pins it: act on the CURRENT arena, whose scans came from the
step that produced these tanks, and only THEN step. A runner that steps first hands every controller
a one-turn-stale world, silently, and nothing fails. Encoder state is threaded by value exactly as
`robo_gauntlet`'s `#bot{}` is. Only live tanks act, as `robo_match` does. The runner reads raw
`#tank.damage_dealt`, so no engine module changes and the golden match vector still holds.

### The arms

| Arm | Optimiser | Topology | Dim | Fitness | Seeds | Role |
|-----|-----------|----------|-----|---------|-------|------|
| **C** | hand construction | `[17,5]` first, fallback `[17,12,5]` | 90 / 281 | n/a | n/a | KILL GATE 0b. Expressibility. |
| **S** | `sep_cma_es` | `[17,12,5]` | 281 | ladder | 20 | **PRIMARY** |
| **L** | `sep_cma_es` | `[17,5]` | 90 | ladder | 10 | CAPACITY CONTROL, mandatory |
| **D** | `sep_cma_es` | `[17,12,5]` | 281 | DIRECT (rung 5 only; F degenerates to plain margin) | 10 | CURRICULUM CONTROL, mandatory |
| **M** | `mu_lambda_es` | `[17,12,5]` | 281 | ladder | 20 | RUN ONLY IF S DOES NOT CLEAR |

**Arm C is a hand-CONSTRUCTED WEIGHT VECTOR driven through `robo_pilot`, NOT hand-written Erlang.**
Kill gate 0b must prove the NETWORK CLASS expresses the capability; a bespoke Erlang bot that beats
`predictive_gun` proves nothing about it. Built and tuned on CALIBRATION starts only, so its
held-out number is an honest generalisation read with no in-sample advantage. It freezes the
encoding. Its shots per match is recorded, because it is the only source of a firing-rate scale for
an evolved controller and IF-3 otherwise has none. **Arm C does NOT set the bar** (see the gate
section).

**Arm C construction stop rule, pre-registered.** An ATTEMPT is one edit to the weight vector, or
one topology change, followed by one full evaluation on the 30 calibration starts (60 matches).
Construction stops when either (a) the calibration win rate reaches B and 5 consecutive further
attempts fail to raise it, or (b) 40 attempts total (20 per topology, `[17,5]` then `[17,12,5]`)
have been made without the calibration rate reaching B, in which case UNGRADEABLE fires. The attempt
count and the full calibration trajectory go into the raw feed. This exists so the point at which
hand construction stops is not free to be chosen after seeing how it interacts with the bar.

**Why L is mandatory.** The encoding is built to make the floor nearly linearly representable, so a
pass by arm S alone would have to be reported honestly as "a 17-channel linear map suffices and the
ES found it" rather than "neuroevolution reached competence". Without this arm the phase-0 claim is
inflated in a way no later analysis can undo.

**Why D is mandatory.** The staircase is itself a curriculum, so a stall is a statement about the
curriculum. If S stalls at rung 3, "did not reach the floor" would be uninterpretable in exactly the
way the plan says a null must not be. D removes the curriculum entirely.

**Why the asymmetric stopping rule.** CLEARED is an EXISTENCE claim, so one optimiser class
suffices. FAILED is a UNIVERSAL claim, so it needs two, because a negative from a single optimiser
reproduces verbatim the search under-convergence confound this gate exists to remove. Running M
unconditionally would double the spend to harden a claim that does not need hardening. Fixed in
advance so it cannot be used to shop for a result.

**Why `sep_cma_es` leads.** The genome is strongly anisotropic by construction: an output weight
feeding `turn_radar` has range 32 while one feeding `accel` has range 512, and `to_range/2` makes
that a real per-coordinate sensitivity difference. Diagonal covariance scales coordinates
independently. exp063's null against it was ruled uninformative at 31 evaluations per dimension;
this spends 178.

**DROPPED: a held-out-opponent arm** (train rungs 1-4, gate on rung 5). It tests generalisation
across opponent FAMILIES, which is a different and harder question whose failure is not attributable
to the optimiser, which is what phase 0 asks. It also has a specific hazard: rungs 4 and 5 differ
only in the gun, and dodging a direct-aim gun is achieved by constant lateral velocity, which is
exactly the assumption `predictive_gun`'s lead solver makes, so training on rung 4 may actively
teach the policy that rung 5 exists to kill.

### Budget, initialisation, seeds, champion, checkpoints

**BUDGET: 50,000 UNIQUE evaluations per run.** Both optimisers evaluate only offspring
(`mu_lambda_es` uses comma selection, `sep_cma_es` samples lambda fresh points), so evaluations equal
lambda times generations with NO parent re-scoring. That is the accounting defect the exp064 and
exp065 gates found in the hand-rolled EA, and it is absent here. `max_generations = 50000 div
lambda`. Verified defaults: `sep_cma_es` lambda `= 4 + trunc(3*ln N)` gives 20 at Dim 281 (2500
generations) and 17 at Dim 90 (2941); `mu_lambda_es` mu 10 lambda 70 gives 714. At 178 evaluations
per dimension the objection "the covariance had not moved" is unavailable.

**INITIALISATION.** `sep_cma_es` defaults x0 to the ZERO VECTOR, and a zero weight vector makes
every neuron `activate(0) = 0`, so every intent field is zero and **the initial mean IS LITERALLY A
SITTING DUCK**. x0 is therefore set explicitly to a per-seed N(0,1) draw from the run's own seeded
stream. `mu_lambda_es` has NO x0 option (verified in source) and already draws N(0,1) parents, so
the two arms start from the same distribution. `init_sigma` 1.0 on both.

**SEEDS.** Measurement seeds 2001..2020 (S, M) and 2001..2010 (L, D), common random numbers by run
index across arms. Calibration and null seeds 1..30, disjoint. `rand` state is per process, so
parallelism is deterministic.

**CHAMPION.** The ES-returned best-by-TRAINING-fitness vector, NEVER re-picked on held-out. Held-out
is never fed back and never used for early stopping.

**CHECKPOINTS** at 10,000 / 25,000 / 50,000 unique evaluations, captured by wrapping the fitness
with one send to a per-run collector process (`mu_lambda_es` exposes no trace, so the wrapper covers
both arms uniformly). All three are evaluated on held-out. The 50,000 record MUST equal the
ES-returned best; that equality is the wrapper's self-check.

### Instrument checks, all before the arms, all cheap

- **Determinism.** Re-running seed 2001 reproduces the champion bit-identically, and
  `robo_match_tests`' golden vector still matches.
- **Topology width.** Assert first layer width `=:=` `robo_pilot:inputs()`. `robo_net:fit/2`
  silently pads or truncates, so a mismatch would never fail a test.
- **CHANNEL RANGE DIAGNOSTIC.** Over 30 random genomes, report each of the 17 channels' realised
  min, max and variance across a full match. A channel that never leaves a narrow band is invisible
  to selection, and finding that out AFTER a null is worth much less than finding it out before.
- **SOLO OSCILLATION DIAGNOSTIC.** Each champion alone in an empty arena, measuring whether `accel`
  and `turn_body` are non-constant. There is no clock input and no recurrence (deliberately: a
  hand-chosen oscillation period is a hand-designed behaviour smuggled in as a sensor), so weaving
  and radar wobble must arise as limit cycles through the world. A champion flat in isolation that
  loses to a predictive gun has failed for a REPRESENTATIONAL reason, not an optimiser one.

### Per-generation diagnostics, recorded from the first run, not added after a null

- **Count of DISTINCT QUANTISED PHENOTYPES** among the lambda offspring. `quantize/1` puts the
  search on a finite integer lattice at scale 256 with a hard clamp at plus or minus 2048, so once
  sep-CMA's per-coordinate sigma falls below about 1/256 every offspring collapses to the SAME
  phenotype, fitness goes constant, the selection differential vanishes and the covariance keeps
  contracting. A run ending that way looks exactly like a converged negative and is not one (IF-5).
- **Fraction of coordinates at the plus or minus 2048 clamp** (IF-4).

The same determinism makes an EXACT fitness cache possible, keyed on the quantised integer weight
list, and it pays for itself precisely in the late-run regime where duplicates appear.

### Behavioural fingerprint, reported with every gate result, never scored

Trigger pulls (commanded fire > 0), SHOTS ACTUALLY FIRED (gun_heat zero-to-nonzero transitions,
since the engine refuses a hot or unaffordable shot), hits landed both ways, damage both ways, turns
survived, kill versus turn cap, and **whether the floor bot ever fired**.

That last one matters and now carries a verdict label (IF-12). `robo_gauntlet:shoot/4` holds unless
the track is from this turn (age 0), so a controller that stays out of the radar beam faces an
opponent that never shoots. That is legitimate exploitation of the partial observability this
substrate was chosen for, but it is a DIFFERENT finding from out-shooting the floor bot.

### Feed

All per-seed values, seeds, returned evaluation counts, per-checkpoint held-out rates, per-rung
profiles, the arm C calibration trajectory and the full fingerprint go into the raw feed. The exp064
gate found the prior feed had kept 12 summary numbers and discarded the 72 per-run values, leaving
nothing re-analysable. That does not happen again.

## The frozen constants, and how each is obtained

All measured on the FINAL generator, at the engine pin recorded in the header, BEFORE any evolution
arm runs. Constants whose ROLE is fixed here but whose VALUE is measured later are marked, so the
number cannot be chosen to suit a result.

| Symbol | What it is | Status |
|--------|-----------|--------|
| `P` | parity: `predictive_gun` against its own clone, held-out 80 starts x 2 seats | measured at authoring = **0.4188** (67 W / 67 L / 26 D of 160; cap share 0.1625). RE-MEASURED at the run pin; that value is authoritative. |
| `SE` | noise scale of a 160-match win rate | **MEASURE AT FREEZE.** Start-level bootstrap over the 80 held-out starts, both seats of a resampled start kept together, 10,000 resamples, deterministic seed. Floored at the binomial value `sqrt(P(1-P)/160)`, which at P = 0.4188 is **0.0390**. The larger of the two is used. |
| `S_par` | `predictive_gun`'s mean SHOTS FIRED per match in the parity reference | **MEASURE AT FREEZE**, alongside P. Denominator for IF-12. |
| `B` | **THE BAR** | `B = P + 4*SE`. Placeholder at the binomial floor: **0.5748**. |
| `R_line` | reliability line | `R_line = P + 2*SE`. Placeholder: **0.4968**. |
| `D_min` | directional margin | `D_min = 2*SE` as rates. Placeholder: **0.0780**, that is 13 of 160 matches. Exact count fixed when SE freezes. |
| `N` | scripted-ladder null against the floor bot, same 160 matches | measured **<= 0.0125** (`sitting_duck` 0/160, `spinner` 0/160, `rammer` 2/160, `circle_strafer` 0/160). |
| `R` | best-of-30 random-genome held-out win rate | **MEASURE AT FREEZE** (expected `>= N`). |
| `W_0b` | arm C held-out win rate | **MEASURE AT FREEZE.** Precondition: `W_0b >= B`. |

**`k = 4` is the one chosen constant in this document and it is named as such.** Four standard
errors above parity puts CLEARED beyond any reading of "statistically indistinguishable from the
floor bot's own clone". It does not move with the constructor's skill in either direction.

**`W_0b` does NOT enter any threshold.** It is a precondition (the bar must be shown reachable by
construction) and a reported reference point. Arm C's full ladder profile is reported for IF-11.

**ARM C DOES NOT GATE THE EXPERIMENT. Amended 2026-07-29, before any arm was run.**

This document originally said UNGRADEABLE fires and the arms are NOT RUN if `W_0b < B`. The pilot
measured that rule to give the wrong answer on this very encoding. Arm S reached **0.4875 held-out
against the floor bot after 3,000 evaluations**, with a positive damage margin, while the hand
construction scores **0.0000**. Under the original rule the front would have stopped, signed
UNGRADEABLE, and blamed the ENCODING for a failure that belongs entirely to the construction.

It was also the DESIGN gate's own fatal flaw 2 in a new position. That flaw was the experimenter's
construction skill deciding the outcome; the gate removed it from the BAR and it survived as the
PRECONDITION. Moving a dependency from the threshold to the gate does not remove it.

Expressibility is a property of the NETWORK CLASS. An evolved champion that beats the floor bot
demonstrates it a fortiori, and more strongly than any hand construction can. So:

- **Arm C is a DIAGNOSTIC.** `W_0b` is measured, reported, and enters no threshold and no gate. Its
  ladder profile is still reported for IF-11.
- **The arms always run.**
- **IF-1 UNGRADEABLE requires BOTH halves:** the construction did not clear **AND** no evolution arm
  beat its own random-genome null. That is the only reading which implicates the encoding, because
  it is the only one in which nothing, constructed or evolved, could use it.
- If arm C fails and evolution does not, the feed says so explicitly: expressibility is established
  by evolution, the encoding is not implicated, and arm C's failure is a note about the construction.

**Arm C is `[17,5]` only.** `arm_c_weights/1` emits one bias plus 17 weights per output neuron, so
that is the only topology it can build. Passing `[17,12,5]` used to hand a 90-parameter genome to a
281-parameter network, which `robo_net` zero-fills, silently destroying the construction; it now
raises. The original "on both `[17,5]` and `[17,12,5]`" condition is struck along with the gate that
needed it.

## Decision rule (pre-committed; computed on held-out only; all outcomes reachable)

```
CLEARED       iff median W_s >= B
              AND at least 15 of 20 seeds have W_s >= R_line
              AND at least 15 of 20 seeds have W_s - L_s >= D_min
FAILED        iff median W_s <= R                 no better than the best of 30 random nets
PARTIAL       iff not CLEARED but at least 5 of 20 seeds have W_s >= B and W_s - L_s >= D_min
INCONCLUSIVE  otherwise
```

For the 10-seed control arms L and D the counts scale to 8 of 10 and 3 of 10 on the same fractions.

The three CLEARED conditions do distinct work: typical strength, reliability across runs, and
DIRECTION. The third is not decorative: at parity wins equal losses exactly (67 and 67), so "more
wins than losses by at least `D_min`" is a genuine directional test.

**ONLY CLEARED UNLOCKS PHASE 1.** PARTIAL, INCONCLUSIVE, FAILED and UNGRADEABLE all stop the front,
and they prescribe different next moves and MUST NOT be collapsed: FAILED sends the question to P2
(optimiser or representation), PARTIAL to restarts or initialisation, INCONCLUSIVE to budget or
representation, UNGRADEABLE to the encoding.

**FAILED is deliberately near-unreachable, and the expected form of a negative is INCONCLUSIVE.**
This is stated now so no write-up can later treat the absence of a formal FAILED as evidence of
partial success. `R` is a best-of-30 ORDER STATISTIC and therefore inflated relative to a mean
random net; that conservatism is acceptable for a claim as strong as "no better than random", but it
means the FAILED branch will almost never fire and its non-firing carries no information.

### Reading the arms together, pre-committed

| Outcome | Reading |
|---------|---------|
| S clears, L clears | Report "the floor clears at LINEAR capacity and the ES found it". Cheaper and truer than a neuroevolution claim. This is the reading the encoding makes most likely and it is written down in advance. |
| S clears, L does not | The hidden layer is load-bearing; report which channels arm C needed. |
| S fails, D clears | The LADDER was the obstacle, not the substrate. |
| S fails, D fails, M fails | A two-optimiser-class negative, which is the only form of negative this front is entitled to sign. |

### Secondary endpoint, with its reading pre-committed

Mean per-match held-out DAMAGE MARGIN `M_s` (champion bullet damage minus opponent bullet damage;
`robo_sim` credits `damage_dealt` on bullet hits only, never on rams or walls, so this separates
marksmanship from attrition).

- If the primary is FAILED or INCONCLUSIVE but median `M_s >= +25` whole units, the report MUST
  state "the champion OUT-DAMAGES the floor bot but cannot convert inside the 2000-turn cap". That
  is a different finding from not reaching the floor.
- If the primary is CLEARED but median `M_s <= 0`, the champion is winning by ram or wall attrition
  and that must be named.

**THE MARGIN IS NOT A COMPETENCE ORDERING AND MAY NOT BE USED AS ONE.** Measured on the held-out 80:
`sitting_duck` -104.24, `spinner` -90.46, `circle_strafer` -88.51, `rammer` -84.87 whole units. The
RAMMER (rung 3) out-damages the CIRCLE_STRAFER (rung 4) while both lose almost everything, because
the strafer's disciplined non-predictive gun essentially never connects with a moving target. The
margin is a CENSORING DIAGNOSTIC and nothing more. It is, however, generator-robust in a way the win
rate is not: -1.043 bars for `sitting_duck` on the six `robo_match:starts()` and -1.042 on the
generated 80 agree to three digits, while the win rate moved by a factor of two and a half.

**ALSO REPORTED, NOT GATING:** win rate against all five rungs for every final champion (5 x 160
matches), the train-versus-held-out gap, shots fired per match, and the fraction of held-out matches
ending at the turn cap.

## Instrument failure, distinguished from a real negative

Each is pre-committed. IF-1 through IF-6 void or replace a verdict; IF-7, IF-8 and IF-12 are
MODIFIERS that label a verdict; IF-9 through IF-11 are observables that constrain a reading.

| Code | Trip | Reading |
|------|------|---------|
| **IF-1 UNGRADEABLE** | `W_0b < B` **AND** no arm beat its random-genome null | Decided AFTER the arms, which always run. Only this conjunction implicates the ENCODING; arm C failing alone is a note about the construction. |
| **IF-2 SEARCH-INERT** | median champion TRAINING fitness does not exceed the best of 200 random vectors from the same init distribution | The fitness supplies no usable gradient. NOT "evolution cannot reach the floor". |
| **IF-3 DEGENERATE-NON-FIRING** | median champion fires zero SHOTS (not trigger pulls) across held-out | The fitness selected the pre-measured never-fire optimum; the floor question was never asked. Arm C's shots per match supplies the scale for a softer trigger if one is wanted later. |
| **IF-4 SEARCH-DIVERGED** | more than half the median champion's coordinates at the plus or minus 2048 quantize clamp | `sep_cma_es` can emit 1.0e308-scale values from a diverging covariance, which `quantize/1` clamps silently. |
| **IF-5 LATTICE-COLLAPSE** | a run ending with 1 distinct quantised phenotype per generation | It has not answered the question, it has collapsed onto a lattice point. |
| **IF-6 NON-DETERMINISTIC** | seed 2001 does not reproduce bit-identically, or the golden match vector no longer matches | Everything void. |
| **IF-7 CAP-DOMINATED** | more than 40 percent of the median champion's held-out matches end at turn 2000 | Trigger set at 2.5x the measured parity cap share of 0.1625. The verdict is cap-conditional and must be LABELLED so. |
| **IF-8 MEMORISATION** | median TRAIN win rate `>= B` while median held-out `W_s < B` | MODIFIER on whichever verdict applies. Pre-registered next rung: the stochastic-start variant, NOT more budget. |
| **IF-9 BUDGET-LIMITED** | median `W_s` at 50k minus median `W_s` at 25k `>= 0.05` on a FAILED or INCONCLUSIVE verdict | The negative is budget-limited and says nothing about the substrate. |
| **IF-10 LADDER-INVERSION** | median champion loses more than it wins to `sitting_duck` or `spinner` | Recorded as an OBSERVABLE. NOT claimed as intransitivity; that is phase 1's question and claiming it here would merge two phases. |
| **IF-11 CEILING-IS-AN-EXPLOIT** | arm C clears the precondition while LOSING to a lower rung | Signature of a construction that beats `predictive_gun` by exploiting its perception rather than out-fighting it. Arm C's full ladder profile is reported for exactly this reason. NOT a proof of absence, and there is no pre-registered response beyond reporting it, which is the honest state of that question. |
| **IF-12 RADAR-STARVED** | in the median champion's WON held-out matches, the floor bot's mean SHOTS FIRED per match is below `0.25 * S_par` | MODIFIER. The verdict is reported as **CLEARED (radar-starved)** or the equivalent on any other verdict. The champion won by staying out of the beam of an opponent that holds fire unless the track is from this turn, which is a DIFFERENT finding from out-shooting the floor bot. `0.25` is a chosen fraction of a measured quantity, named as chosen. |

## What would falsify the claim

For the experiment:

- **CLEARED is falsified** by median held-out `W_s` below `B`, or by fewer than 15 of 20 seeds
  reaching `R_line`, or by fewer than 15 of 20 seeds clearing `D_min` in direction, or by any of
  IF-1 through IF-6 firing.
- **The expressibility premise is falsified** by arm C failing AND every evolution arm failing to
  beat its random-genome null. Arm C failing alone falsifies nothing about the encoding, and the
  pilot already showed why: it fails at 0.0000 on an encoding arm S uses to reach 0.4875.
- **The two-optimiser negative is falsified** by any single seed of S, D or M clearing.
- **The linear-capacity reading is falsified** by L failing while S clears.
- **The curriculum reading is falsified** by D clearing while S fails, or by neither.

For the constants themselves, so they are not immune to evidence either:

- **The corrected noise scale is falsified** if the start-level bootstrap at freeze returns an SE at
  or below 0.020, in which case the design's discarded 0.0187 band was adequate after all and the
  bar arithmetic should be re-derived from the bootstrap rather than from the binomial floor. The
  bootstrap is run and reported whatever it returns.

> **AND IT VERY NEARLY WAS FALSIFIED. Recorded 2026-07-29, before the run.**
>
> The gate asserted the discarded 0.0187 band understated the true standard error "by roughly 3x".
> The start-level bootstrap it prescribed returns **0.0207**, about ten percent above the discarded
> band, not threefold. The gate's own falsifier was "an SE at or below about 0.020", and 0.0207
> misses that by three and a half percent, which is inside any reasonable reading of "about 0.020".
>
> Worse for the remediation, `constants/1` takes `SE = max(bootstrap, binomial)` and the binomial
> floor is 0.0390, so the bootstrap does not influence `B`, `R_line` or `D_min` at all. The number
> added to fix the thresholds is inoperative on every threshold it was added to fix.
>
> **What survives, and why the change is kept.** The gate's *reasoning* was right and its
> *arithmetic* was wrong. The four subsets genuinely were two overlapping partitions of the same 160
> matches, so the half-range of four correlated draws was never a defensible noise scale whatever
> number it happened to produce. The binomial standard error at n=160 is the defensible one, it is
> what the thresholds actually rest on, and it would be what they rest on even if the bootstrap had
> come back at 0.010. The correction is kept on that ground, not on the 3x claim, and the 3x claim
> is withdrawn here rather than quietly left standing.
- **The offset generator's justification is falsified** if the re-measured parity at the run pin
  differs materially from 0.4188 or the cap share from 0.1625, which would mean the generator is not
  doing what was measured at authoring. Both are re-measured at freeze and both go in the feed.

## Compute budget

> **SUPERSEDED 2026-07-29 by the pilot, which measured the same quantities on the same box and
> found this basis about 3x too pessimistic.** The figures below were an authoring estimate; the
> pilot's are measurements. Corrected: one scripted match **0.94 ms** (not 2.2), one full-length net
> match **3.0 ms** (not 10.4), one fitness evaluation **34.9 ms** over the first thousand evaluations
> and **57.8 ms** marginal in the one-to-three-thousand window, rising to **74.3 ms** for a champion
> whose frontier has reached rung 5 (not 200 ms central, 350 ms pessimistic). The full held-out
> endpoint, 80 starts in both seats, is **0.3 s**.
>
> The error is in the safe direction, but this section claims "measured basis, not assumed", so it
> would have been a false claim to leave standing. With the worker pool repaired (defect D4) the
> projected full run is about **2.4 hours** rather than the 34 hours a serial run would have taken.

Measured basis, on this box, not assumed:

```
scripted match (predictive_gun vs predictive_gun, held-out): 353 ms / 160 = 2.2 ms per match
forward pass [17,12,5] Dim 281: 4.105 us per call ([17,5] proportionally about 1.5 us)
full-length (2000-turn) net match: about 2.2 + 8.2 = 10.4 ms
turn-cap share at parity: 0.1625
```

**Cost per fitness evaluation.** Early in a run nearly every individual halts on rung 1, and rung 1
is the EXPENSIVE case, not the cheap one: a controller that cannot kill the sitting duck runs all 12
of its matches to the 2000-turn cap, that is 12 x 10.4 = 125 ms. Once lethal, rung 1 shortens
sharply but rungs 2 to 5 open, giving 60 matches of mixed length, about 250 to 350 ms. Working
central figure **200 ms**, pessimistic **350 ms**. A flat per-match figure is wrong in both
directions and the lazy ladder is what makes the difference.

Per run, 50,000 unique evaluations: **2.8 CPU-hours central, 4.9 pessimistic.**

| Arm | Central | Pessimistic |
|-----|---------|-------------|
| S (20 seeds, Dim 281, ladder) | 56 CPU-h | 97 |
| L (10 seeds, Dim 90, ladder, cheaper pass) | 22 | 40 |
| D (10 seeds, Dim 281, rung 5 only, ~0.09 s per evaluation) | 13 | 22 |
| C (construction, calibration, null and instrument measurements) | 3 | 3 |
| P / SE / S_par measurement and bootstrap (scripted only, pure arithmetic over stored outcomes) | <0.1 | <0.1 |
| held-out evaluation: 40 runs x (3 checkpoints + a 5-rung profile) x 160 matches x 10.4 ms | 0.15 | 0.2 |
| **UNCONDITIONAL TOTAL** | **94 CPU-h** | **162 CPU-h** |
| arm M if triggered (20 seeds, lambda 70) | +56 | +97 |
| **WORST CASE, all four arms** | **150 CPU-h** | **259 CPU-h** |

The spend is now bimodal: if IF-1 fires at step 4 the arms are not run at all and the total is about
**3 CPU-h**. The raised precondition makes that branch more likely than it was in the original
design.

**BOX:** 32 cores, 125 GB. Runs are independent and pure, `rand` state is per process, so 20-way
parallelism is free and deterministic. Wall clock about 3 hours central and 5 pessimistic
unconditional; about 5 and 8 with arm M. Arm S alone is roughly 2 hours.

**Compute is NOT a reason to cut seeds or evaluations.** If spare compute appears, spend it on MORE
HELD-OUT STARTS before more generations: SE is the noise floor on every threshold in this document
and halving it is cheap. Enlarging the TRAINING set is the second call, because 12 situations per
rung against 281 parameters with zero evaluation noise is the ideal condition for exact
memorisation.

## Out of scope, stated so it is not drifted into

- **Melee.** The nearest-contact rule becomes a target-selection STRATEGY the moment a third tank
  exists, and it would be mine, not evolution's.
- **Any change to MAX_TURNS.** It changes the engine hash and voids the golden vector, so it is a
  decision to take BEFORE this runs, not after seeing an INCONCLUSIVE result.
- **Any mesh, ReckonDB or evoq work.** `PLAN_ROBO_RUMBLE.md` re-raise trigger 2 and 3.
- **Opponent-family generalisation.** Deferred with its hazard named (see the dropped arm).

## Hypothesis

Stated in advance so the write-up cannot claim to have expected whatever happened.

Arm C clears the precondition, probably on `[17,12,5]` rather than `[17,5]`, because the trigger's
`cos >= 0.9` linear threshold is roughly plus or minus 25 degrees against the floor bot's plus or
minus 2.8, and a hidden layer sharpens the conjunction. Arm S reaches PARTIAL rather than CLEARED,
with the median short of `B` and a minority of seeds over it, and the modal failure is IF-7
(cap-dominated) rather than IF-3 (non-firing), because the ladder's anti-forgetting rule fences off
the never-fire optimum but nothing fences off "survive and do not convert". If S clears, L clears
too, and the honest report is the linear-capacity one.

## DESIGN gate verdict (faber-adversary / Fable, 2026-07-29) — BUILD_WITH_CHANGES, all changes applied above

The gate did NOT find the experiment circular. It verified against the engine that training on the
gate opponent is legitimate here (the plan DEFINES the floor as beating this specific deterministic
bot, so the claim is bot-specific by construction), that the fitness and the gate are different
instruments with the mismatch pre-committed, and that each degenerate-policy starvation argument
holds. It found **two fatal flaws**, both about the thresholds, both fixed here.

**FATAL FLAW 1: the band was statistically invalid and every threshold inherited it.** The original
design derived a noise scale of 0.0187 as half the spread of P over "four disjoint 40-start
subsets". **They are not disjoint.** First/last and odd/even are TWO OVERLAPPING PARTITIONS of the
same 160 matches (first shares 20 starts with odd), so the four rates are two correlated pairs,
which is visible in the numbers themselves: first = odd = 0.4375, last = even = 0.4000. The
half-range of four correlated draws understates the ~0.039 binomial SE of a 160-match rate at
p = 0.42 by roughly 3x, and seat-pairing within a start makes effective n < 160, so worse.
Consequence: at the original minimum precondition `W_0b = 0.4813` the bar `B` equalled `R_line` at
0.4563, about ONE standard error above parity, and the directional condition needed only one match
of daylight. A champion statistically indistinguishable from the floor bot's own CLONE would have
been CLEARED and phase 1 unlocked on it.

**FATAL FLAW 2: the bar was endogenous to the experimenter's own hand construction, in both
directions.** With `B = P + 0.60*(W_0b - P)`, an arm C parked just past its precondition set B at the
parity noise floor (a mediocre champion passes), and an exceptional arm C at 0.90 set B at 0.71
(a champion at 0.60 that decisively and reliably beats the floor bot FAILS). The person who builds
arm C set the difficulty of the gate they then wanted evolution to clear, with no stop rule on arm C
tuning. The floor question is an ABSOLUTE property of champion versus `predictive_gun`; arm C's
legitimate job is expressibility (kill gate 0b), not bar-setting.

### The seven required changes and where each landed

1. **Defensible noise scale.** The 0.0187 band is DISCARDED. `SE` is a start-level bootstrap over
   the 80 held-out starts with seat pairs kept together, floored at the binomial `sqrt(P(1-P)/160)`
   = 0.0390. Precondition and `R_line` re-derived from it.
2. **B decoupled from `W_0b`.** `B = P + 4*SE` (~0.575), with `k = 4` pre-registered and named as
   the one chosen constant. The precondition becomes `W_0b >= B`: arm C must itself clear the bar,
   which proves the bar is reachable BY CONSTRUCTION while leaving it independent of constructor
   skill in both directions. The gap-closing form and its `0.60` are DISCARDED.
3. **Directional condition strengthened** from `W_s > L_s` to `W_s - L_s >= D_min = 2*SE`, about 13
   of 160 matches. One match of daylight is a coin flip, not direction.
4. **Radar-starvation check extended from arm C to the evolved champions** as IF-12, a LABELLED
   modifier on the verdict, exactly as IF-7 makes a verdict cap-conditional. The design already
   called this "a different finding" but only fingerprinted it; a verdict that unlocks phase 1 must
   CARRY the label.
5. **Arm C construction stop rule pre-registered** (clear B on calibration then 5 consecutive
   non-improving attempts; or 40 attempts total across both topologies, then UNGRADEABLE). Largely
   defanged by the absolute bar, kept because the stopping point should not be free either.
6. **The false independence claim is corrected wherever it appeared**, and the correction is
   recorded above rather than silently dropped.
7. **FAILED's near-unreachability is stated in advance**, together with the fact that `R` is an
   inflated best-of-30 order statistic, so the absence of a formal FAILED can never be read as
   partial success.

Two consequences the gate named and this document accepts rather than argues with. The UNGRADEABLE
risk RISES (the precondition moved from 0.4813 to about 0.575); that is the honest cost of a
defensible noise scale. And all four verdicts remain reachable, but most negatives will land
INCONCLUSIVE rather than FAILED, which is acceptable because INCONCLUSIVE also stops the front.

**The gate's own falsifier, recorded so its critique is not immune either:** the band critique is
falsified if a proper start-level bootstrap yields an SE at or below about 0.020, in which case the
original 0.4813 / 0.4563 constants were adequately separated and changes 1 to 3 collapse to wording.
The bootstrap is run at freeze and reported whatever it returns.

## Result

PENDING. No arm has been run and no verdict exists.

What HAS been done, 2026-07-29, and none of it commits an arm:

- The runner is built as `exp066_single_population_floor_tests.erl`, compiles clean under
  `warnings_as_errors`, and passes elvis `faber_min` with zero findings.
- **All seven instrument checks pass** in about four seconds, including gate 1, which recomputes
  `robo_match_tests`' golden match vector `DFCD8106…B3895E88` and so proves `robo_sim`, `robo_net`,
  `robo_gauntlet` and `robo_match` are untouched by this experiment.
- A pilot measured unit costs and found this document's compute basis about 3x pessimistic; the
  corrected figures are in the superseding note above.
- Nine defects were found between the runner and this document and all nine are closed. Six were in
  the runner (arm C silently building a wrong-sized genome for an unsupported topology; a
  self-check that compared a value with itself; the 50,000 checkpoint dropped for two arms; a
  worker option that was not a pool and defaulted to serial; `run/1` skipping the instrument checks
  the protocol calls mandatory; and arm C blocking the arms). Three were in this document and are
  corrected above: the runner name and the struck `robo_pilot` module and second pin; the DESIGN
  gate's withdrawn 3x arithmetic; and the compute basis.

The amendments to the DECISION RULE are the substantive ones and are dated, reasoned and recorded
in place rather than folded in silently, because this document is the contract and a pre-registration
edited without a visible trail is not one.
