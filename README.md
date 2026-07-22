# faber-programmes

Experiment runners for the faber neuroevolution research programmes.

This repository exists to fix one specific hole in the record.

## The problem it solves

The faber corpus publishes signed insights, each backed by a raw feed of numbers.
But the raw feed is produced *by* a runner, and until 2026-07-22 runners were treated
as throwaway and deleted after each experiment. The reasoning was sound as far as it
went: a runner left in `faber-tweann/test/integration/` executes on every
`rebar3 eunit`, and evolutionary runs are slow enough to make the engine's test suite
unusable.

The cost was steep and only visible in hindsight:

- **A buggy runner yields a feed that is wrong and internally consistent.** No amount
  of analysis on the feed alone can detect it. Both retracted insights (038, 040) were
  confounds of exactly that kind.
- **No insight before 047 records which engine version produced it.** faber-tweann has
  changed continuously. Scapes gained features, the optimiser gained a trace, `pb_sim`
  gained wind and a hidden gain. So even with a runner in hand, an old result could not
  be reproduced, because the thing it ran against is unknown.

Insights 001-046 are therefore not auditable at the code level. Their runners were
never committed anywhere and are unrecoverable, with a single exception: EXP-023, whose
runner survives at `faber-tweann/test/integration/exp023_tests.erl`.

That gap is stated openly in the corpus rather than left implicit. See
`faber-ecosystem/insights/INDEX.md`.

## How it fixes it

faber-tweann is consumed here as a **library at a pinned commit**. Runners live in this
repository permanently, and never run on the engine's test suite. The pin in
`rebar.config` is the provenance: `git log rebar.config` is the history of which engine
each experiment ran against.

The record for an experiment is four things, not two:

| Artefact | Lives in |
|---|---|
| Signed insight | `faber-ecosystem/insights/NNN-*.md` |
| Raw feed | `faber-ecosystem/insights/NNN-raw-*.txt` |
| Runner | here, `programmes/pN_*/expNNN_*/` |
| Engine commit + toolchain | here, in the experiment's manifest |

Raw feeds deliberately stay in the corpus, next to the insights that cite them.

## Layout

```
experiments/     the ACTIVE working area. Compiled. One experiment at a time.
programmes/      the ARCHIVE. Never compiled, never on a source path.
scripts/         scaffold, run, archive
src/             the app stub that makes this a rebar3 project
```

`programmes/` is deliberately excluded from every source path. An archived runner is a
record of what was executed against one engine pin, not code we promise to keep
compiling against a moving engine. Trying to keep fifty historical runners green is the
maintenance trap that produced the deletion habit in the first place.

To re-run an archived experiment: read its manifest for the engine commit, set that ref
in `rebar.config`, copy the runner back into `experiments/`.

## The cycle

```sh
scripts/new_experiment.sh 047 non_integrable_stressor
```

Writes a runner stub and a manifest. **Fill in the manifest first.** It is a
pre-registration: hypothesis, arms including the null, controls, and a numeric decision
rule with both outcomes reachable. A decision rule written after seeing data is not a
decision rule.

Then have the adversary attack the design before any runner code exists. That is the
`faber-adversary` agent at its DESIGN gate.

```sh
scripts/run_experiment.sh exp047_non_integrable_stressor_tests
```

Builds against the pin, refuses to run if the built engine disagrees with the pin,
writes the feed into the corpus, and appends a provenance block to the manifest
recording engine commit, OTP, rebar3, command, timing, and exit status. It refuses to
overwrite an existing feed, because a rerun must not silently erase the first run.

Then the adversary attacks the *claim*, with the draft insight, the feed, **and the
runner**. Sign the insight in the corpus.

```sh
scripts/archive_experiment.sh 047 p3_meta_learning
```

Moves runner and manifest into the permanent archive. Refuses to archive an experiment
with no recorded run.

**Ordering matters: sign first, archive after.** The claim gate needs the runner to
still exist.

## House rules that apply here

- `n >= 10` for any rate claim, counting **independent evolutionary runs**, never
  instances scored from a single evolved genome.
- Common random numbers shared **across arms**, not only within an arm.
- Every experiment carries a **null arm that provably cannot do the thing being
  claimed**. Without a floor, a good static prior is indistinguishable from genuine
  within-lifetime adaptation. This is the most common defect the adversary finds.
- Raw fitness is not comparable across instances with different achievable ceilings.
  Normalise against an oracle scored on the same realisation.
- Negatives are first class. Retractions are published inline.
- Style: `rebar3 as lint lint`, ruleset `faber_min` (no deep nesting beyond level 2,
  no nested try/catch, no if-expressions), same as the engine.

## Related

- [faber-tweann](https://codeberg.org/rgfaber/faber-tweann) — the engine
- [faber-ecosystem](https://codeberg.org/rgfaber/faber-ecosystem) — the signed corpus,
  insights, charters, syntheses

## Licence

Apache-2.0.
