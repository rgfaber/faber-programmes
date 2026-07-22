# Archive

Finished experiments. One directory per experiment, holding the runner that was
executed and the manifest recording its pre-registration and provenance.

**Nothing here is compiled.** `programmes/` is deliberately absent from every source
path in `rebar.config`. These files are a record of what ran against a specific engine
commit, not code maintained against a moving engine.

To re-run one: read its manifest for the engine commit, set that ref in `rebar.config`,
copy the runner into `experiments/`.

Layout:

```
programmes/
  p3_meta_learning/
    exp047_non_integrable_stressor/
      exp047_non_integrable_stressor_tests.erl
      exp047_non_integrable_stressor.md
```

Raw feeds are not here. They live beside the insights that cite them, in
`faber-ecosystem/insights/NNN-raw-*.txt`.

Archiving begins at insight 047. Runners for 001-046 were never committed and are
unrecoverable, except EXP-023's, which survives in the engine repository at
`test/integration/exp023_tests.erl`. See `faber-ecosystem/insights/INDEX.md` for the
provenance table.
