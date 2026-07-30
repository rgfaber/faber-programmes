# EXP-069. How narrow is the phase 0 floor result? Two perturbations of the opponent, read independently

**Status: PRE-REGISTERED 2026-07-30. NOT RUN. DESIGN gate not yet passed.**

Small by design. **ONE endpoint, ONE bar, applied INDEPENDENTLY to two arms.** Not a conjunction:
each arm is read on its own and neither gates the other. EXP-067 needed four gate rounds because one
decision rule had to serve a positive branch, a negative branch, an instrument-failure branch and
two sub-labels at once. This document does not do that.

**No evolution runs anywhere.** Every number comes from replaying ARCHIVED champions through the
existing match loop. No genome is modified, no optimiser is called, no arm is re-run.

---

## Why this exists

Insight 066 signed a median held-out win rate of **0.9750** against `predictive_gun`, against a
pre-registered bar of **0.5748**. It also names, in its own caveats, two reasons that result may be
narrower than it reads, and **tests neither**:

> **The floor is bot-specific by construction**, and narrower than "non-trivial evasion": the win is
> a damage exchange at a range where the opponent halves its own gun power.

> **Champion aim is fitted to one trajectory family.** A 0.574 hit rate with no lead solver, against
> an opponent whose movement is identical in every start, has no support against an opponent that
> moves differently. That is the largest risk to reading any phase 1 matrix as a fact about the
> substrate.

Both are cheap to test and both can NARROW a signed result of ours. That is the point of running
them. The corpus's standing habit is to attack its own claims before someone else does, and these
two attacks are already written down in the claim itself, unexecuted.

---

## The question, asked so that every answer is signable

Does the phase 0 competence result survive an opponent that is **the same strength** but **not the
same shape**?

---

## The primary endpoint

**Median held-out win rate of the 20 archived arm S champions against a PERTURBED `predictive_gun`,
over the same 80 pre-registered held-out starts, both seats, 160 matches per champion.**

Win definition unchanged and carried verbatim from phase 0: the opponent tank **DEAD** and the
subject tank **ALIVE** at match end; **draws count as not beating**.

---

## The two arms, each read independently

### Arm P: the orbit is mirrored

`robo_gauntlet:steer/3` computes the orbiting body heading as

```
Tangent = wrap(Aim + 64 - range_error(Dist))
```

where `+64` is the quarter turn that makes the bot circle its contact and `range_error/1` pulls it
off tangent in proportion to the range error. **The perturbation mirrors both terms:**

```
Tangent = wrap(Aim - 64 + range_error(Dist))
```

**Why this perturbation and not another.** It reverses the direction of circulation while leaving
every other property intact: the same range-holding behaviour, the same wall avoidance, the same
gun, the same power rule, the same energy budget. It is one mirrored sign. A perturbation that made
the bot faster, or slower, or dumber would confound "champion aim is over-fitted" with "the task got
easier", and the resulting number would answer nothing. This one changes **the shape of the
trajectory family and nothing else**, which is exactly the hypothesis under test.

### Arm G: the range-power rule is flattened

`robo_gauntlet:range_power/1` is

```
range_power(D) when D < ?FP * 150 -> 30;
range_power(D) when D < ?FP * 350 -> 20;
range_power(_D)                   -> 10.
```

Every standoff champion holds a mean range **above 150 whole units**, which is exactly where the bot
drops from power 30 to 20 and its damage per hit from 16 to 10, for the whole match, while the
champion fires at 29.2 tenths throughout. The perturbation replaces the rule with a **constant 30**.

**The direction of this bias is stated and it is conservative.** Constant 30 is the CLOSE-range
value, so the perturbed bot is **strictly stronger at every range** and unchanged at close range. A
champion that still wins is therefore beating a harder opponent, and the result is stronger than the
original rather than weaker. A champion that collapses tells us the win was an exploit of one
scripted rule. Both readings are informative and neither depends on us having guessed a
difficulty-neutral change.

---

## Decision rule, pre-committed, computed on held-out only, every outcome reachable

Applied to **each arm separately**. There is no conjunction and no combined verdict.

Let `W` be the arm's median held-out win rate, `B = 0.5748` the phase 0 pre-registered bar, and
`R = 0.0125` the phase 0 random-genome null.

| Reading | Condition | What it means |
|---|---|---|
| **SURVIVES** | `W >= B` | The competence claim holds against this perturbation. The original bar is reused deliberately: it was set to mean "reliably beats this opponent", so asking it of a perturbed opponent asks the same question of a different shape. |
| **NARROWED** | `R < W < B` | The champions retain some competence but the signed 0.9750 does not generalise across this perturbation. Insight 066's scope must be tightened by an appended correction naming this arm. |
| **REFUTED AS GENERAL** | `W =< R` | Performance falls to the untrained baseline. The phase 0 result is specific to the exact opponent instance, and every downstream use of "cleared the competence floor" must say so. |

**The drop from 0.9750 is reported as an EFFECT SIZE and gates nothing.** It is the interesting
number and it is not a threshold, because no threshold on it was registered before the data existed.

**Per-tier reporting is required, not optional.** Phase 0's champions are bimodal: 13 in a kill mode
and 6 near parity, and the two are behaviourally distinct (the near-parity six close to ram contact,
the kill-mode thirteen never do). A median over both hides which mode broke. Report the median and
both tiers.

---

## Instrument failure, distinguished from a real negative

- **IF-1 THE PERTURBATION CHANGED THE BOT'S STRENGTH.** The whole design rests on the perturbed bot
  being no weaker. **Control, mandatory, run BEFORE the champions:** play the perturbed bot against
  the ORIGINAL bot over the same 80 held-out starts, both seats. Pre-committed reading: if the
  perturbed bot's win rate against the original falls **below 0.40**, the perturbation weakened it
  and that arm is **UNGRADEABLE**, because a champion beating a weakened opponent proves nothing.
  Arm G is expected to sit ABOVE 0.5 by construction, which is itself a check on the argument that
  constant 30 is strictly stronger; if it does not, that argument is wrong and must be recorded as
  wrong.
- **IF-2 TURN-CAP CENSORING.** If the perturbation drives matches into the turn cap, the win rate
  falls for a reason unrelated to competence. Report the cap share per arm. Phase 0's measured
  parity cap share is **0.1625** and its median champion's is **0.000**. A cap share above 0.40
  makes the arm **CAP-CONDITIONAL** and the reading must be labelled so.
- **IF-3 DRAWS.** Draws count as not beating, so a perturbation that manufactures draws depresses
  `W` without any loss of competence. Report the draw share; phase 0's whole-matrix share was
  0.01553.
- **IF-4 THE HARNESS DIVERGED.** The replay must reproduce each champion's ORIGINAL held-out win
  rate exactly when run with the perturbation DISABLED. Any mismatch means the harness is not the
  phase 0 harness and the arm is ungradeable. **This check runs first and halts on failure.**

---

## What would falsify what

- **Falsifies "champion competence is general across trajectory families":** arm P reading NARROWED
  or REFUTED.
- **Falsifies "the phase 0 win is not merely a range-power exploit":** arm G reading NARROWED or
  REFUTED.
- **Falsifies this experiment's own hypothesis (below):** either arm reading SURVIVES.
- **Falsifies the measurement itself:** IF-1 or IF-4 firing.

---

## Out of scope, stated so it is not drifted into

- **Nothing here bears on champion-versus-champion competence**, which is unregistered and lives in
  the unsigned cross-play note.
- **Nothing here re-opens the floor verdict itself.** Insight 066's 0.9750 against the UNPERTURBED
  bot stands whatever this returns; what is at stake is how far it generalises.
- **Two perturbations are not a family.** A SURVIVES on both means competence survived THESE TWO
  changes, not that it is robust in general. The honest claim is enumerative.
- **No claim about prediction or tracking is available** to this front by pre-registration, since
  the controller cannot see bullets and reports estimated position NOW.

---

## Hypothesis, with a prediction that can be wrong

**H1, arm P: NARROWED.** Insight 066 measured that champions do not weave (lateral reversal 0.82 per
100 turns against a bullet flight of 8 to 22 turns) and that a constant-velocity ghost is hit at
essentially the same rate. The policy is a range-locked orbit, and an orbit's stability depends on
the relative circulation direction of both parties. Mirroring one of them is predicted to cost more
than a general policy would lose.

**H2, arm G: NARROWED, and more sharply than P.** Every standoff champion parks beyond the 150-unit
boundary where the bot halves its own power. That is the mechanism insight 066 identifies for the
win. Removing it removes the mechanism.

**If both SURVIVE, both hypotheses are refuted and insight 066 is broader than its own caveats
allow**, which would be a genuinely good outcome and is the reason both readings are pre-committed
rather than only the pessimistic one.

---

## Reproduce

Archived champions: `programmes/p7_coevolution/exp066_competence_floor/exp066_champions_s.eterm`.
Engine pin `a5e8bcfc5646827e9be49a9629f8a6a9678c814b` for the UNPERTURBED harness check (IF-4); the
perturbed arms necessarily run a modified gauntlet and the modification must be a **parameter, not
an edit to the pinned module**, so the pin remains the provenance of the control.

The controller is now `faber_tweann/src/robo_pilot.erl`, extracted 2026-07-30. **The extraction's own
equivalence proof is OWED and is a precondition of IF-4**: until archived champions are shown to
reproduce their phase 0 held-out rates through the extracted pilot, this experiment cannot
distinguish a perturbation effect from an extraction defect.

---

## DESIGN gate verdict

*(empty; to be filled by the adversary before any runner is written)*
