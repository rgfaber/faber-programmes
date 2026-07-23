%%%-------------------------------------------------------------------
%%% @doc EXP-053 — smallest coevolution step: stochastic 1D transitive numbers game.
%%%
%%% Pre-registration (design-gated): experiments/exp053_coevolution_1d_transitive.md
%%% Run: erl -noshell -pa <ebin> -eval 'exp053_coevolution_1d_transitive_tests:run(), init:stop().'
%%%
%%% Deliverable = the Red Queen: co-fitness (champ A vs champ B win-prob) stays ~0.5
%%% while the champion's trait x escalates unboundedly. Stochastic win rule
%%% P(A beats B) = logistic((xA-xB)/tau). Two (mu+lambda) populations, full cross-eval
%%% (no opponent-sampling noise). Benchmark ladder = a runner SMOKE TEST only (monotone
%%% in x by arithmetic; fidelity is deferred to the 2D rung). Pure Erlang, no net/NIF.
%%% @end
%%%-------------------------------------------------------------------
-module(exp053_coevolution_1d_transitive_tests).

-export([run/0, run/1, validate/0]).

-define(MU, 30).
-define(LAMBDA, 30).
-define(SIGMA, 0.3).
-define(TAU, 0.3).
-define(X0, 50.0).
-define(BOOT, 2000).
-define(FEED, "exp053_feed.txt").

run() -> run(#{n => 30, r => 150}).
validate() -> run(#{n => 5, r => 40}).

run(#{n := N, r := R}) ->
    {ok, Fd} = file:open(?FEED, [write]),
    emit(Fd, "== EXP-053 stochastic 1D transitive: the Red Queen (co-fitness ~~0.5 while x escalates) ==~n"),
    emit(Fd, "config: mu=~p lambda=~p sigma=~.2f tau=~.2f x0=~.1f R=~p n=~p~n",
         [?MU, ?LAMBDA, ?SIGMA, ?TAU, ?X0, R, N]),
    %% Pilot: one run to size the anti-saturation benchmark ladder.
    PilotSeries = coevolve(R),
    FinalX = champx(lists:last(PilotSeries)),
    Ladder = ladder(FinalX),
    emit(Fd, "pilot final champion x=~.1f -> ladder [~.1f .. ~.1f] (20 refs)~n",
         [FinalX, hd(Ladder), lists:last(Ladder)]),
    %% Main study.
    Runs = [series_metrics(coevolve(R), Ladder) || _ <- lists:seq(1, N)],
    report(Fd, R, Runs),
    file:close(Fd),
    ok.

%%%============================================================================
%%% Coevolution: two (mu+lambda) populations, full cross-eval, stochastic rule.
%%% Returns a per-generation series of {Gen, MeanChampX, CoFitness, ChampxA, ChampxB}.
%%%============================================================================
coevolve(R) ->
    A0 = [?X0 || _ <- lists:seq(1, ?MU)],
    B0 = [?X0 || _ <- lists:seq(1, ?MU)],
    gen_loop(1, R, A0, B0, []).

gen_loop(G, R, _A, _B, Acc) when G > R -> lists:reverse(Acc);
gen_loop(G, R, A, B, Acc) ->
    Aoff = [mutate(pick(A)) || _ <- lists:seq(1, ?LAMBDA)],
    Boff = [mutate(pick(B)) || _ <- lists:seq(1, ?LAMBDA)],
    A1 = top_mu(A ++ Aoff, B),          %% score A-candidates against current B
    B1 = top_mu(B ++ Boff, A),          %% score B-candidates against current A
    Ca = lists:max(A1), Cb = lists:max(B1),
    %% Co-fitness = POPULATION-level mean win-prob of A vs B (smooth ~0.5 by symmetry,
    %% low variance). Champion-vs-champion is a bimodal high-variance estimator of the
    %% same 0.5 (DESIGN-gate note); population-level is the pre-committed measure.
    Rec = {G, (Ca + Cb) / 2, popcofit(A1, B1), Ca, Cb},
    gen_loop(G + 1, R, A1, B1, [Rec | Acc]).

popcofit(A, B) -> mean([fitness(X, B) || X <- A]).

%% Select the mu highest-fitness candidates; fitness = mean win-prob vs all opponents.
top_mu(Cands, Opp) ->
    Scored = [{fitness(X, Opp), X} || X <- Cands],
    [X || {_F, X} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), ?MU)].

fitness(X, Opp) -> mean([logistic((X - O) / ?TAU) || O <- Opp]).

pick(Pop) -> lists:nth(rand:uniform(length(Pop)), Pop).
mutate(X) -> X + ?SIGMA * rand:normal().

champx({_G, _M, _C, Ca, Cb}) -> max(Ca, Cb).

%% Benchmark ladder spanning x0 .. 2*final (anti-saturation), 20 references.
ladder(FinalX) ->
    Top = 2.0 * FinalX,
    [?X0 + (Top - ?X0) * I / 19 || I <- lists:seq(0, 19)].

%%%============================================================================
%%% Per-run metrics from a series.
%%%============================================================================
series_metrics(Series, Ladder) ->
    Gens = [G || {G, _, _, _, _} <- Series],
    Xs = [Mx || {_, Mx, _, _, _} <- Series],
    Cofs = [Cf || {_, _, Cf, _, _} <- Series],
    Champs = [Ca || {_, _, _, Ca, _} <- Series],
    Bench = [mean([logistic((Ca - Ref) / ?TAU) || Ref <- Ladder]) || Ca <- Champs],
    Unsat = length([1 || Bv <- Bench, Bv < 0.999]) / length(Bench),
    #{first_x => hd(Xs), last_x => lists:last(Xs),
      mean_cof => mean(Cofs), spear_gx => spearman(Gens, Xs),
      spear_gc => spearman(Gens, Cofs), unsat => Unsat,
      bench_mono => monotone(Bench)}.

%%%============================================================================
%%% Report + verdict
%%%============================================================================
report(Fd, R, Runs) ->
    FirstX = [maps:get(first_x, M) || M <- Runs],
    LastX = [maps:get(last_x, M) || M <- Runs],
    Cof = [maps:get(mean_cof, M) || M <- Runs],
    SGX = [maps:get(spear_gx, M) || M <- Runs],
    SGC = [maps:get(spear_gc, M) || M <- Runs],
    Unsat = [maps:get(unsat, M) || M <- Runs],
    Mono = lists:all(fun(M) -> maps:get(bench_mono, M) end, Runs),
    {FxLo, FxHi} = boot_ci(FirstX), {LxLo, LxHi} = boot_ci(LastX),
    {ScLo, ScHi} = boot_ci(SGC),
    MeanCof = mean(Cof),
    emit(Fd, "~n-- Results (n=~p, R=~p) --~n", [length(Runs), R]),
    emit(Fd, "champion x: first median=~.1f CI[~.1f,~.1f] -> last median=~.1f CI[~.1f,~.1f]~n",
         [median(FirstX), FxLo, FxHi, median(LastX), LxLo, LxHi]),
    emit(Fd, "escalation Spearman(gen,x): median=~.3f (min ~.3f)~n", [median(SGX), lists:min(SGX)]),
    emit(Fd, "co-fitness: mean=~.4f (across-run range [~.3f,~.3f])~n",
         [MeanCof, lists:min(Cof), lists:max(Cof)]),
    emit(Fd, "co-fitness trend Spearman(gen,cofit): median=~.3f CI[~.3f,~.3f]~n",
         [median(SGC), ScLo, ScHi]),
    emit(Fd, "benchmark smoke test: monotone-in-x all runs=~p; median unsaturated fraction=~.2f~n",
         [Mono, median(Unsat)]),
    ArmsRace = (LxLo > FxHi) andalso (median(SGX) > 0.9),
    CoFlat = (MeanCof >= 0.45) andalso (MeanCof =< 0.55) andalso (ScLo =< 0.0) andalso (ScHi >= 0.0),
    Valid = Mono,
    emit(Fd, "arms race (lastX>firstX disjoint & Spearman(gen,x)>0.9): ~p~n", [ArmsRace]),
    emit(Fd, "co-fitness flat (~~0.5 in [.45,.55] & trend CI spans 0): ~p~n", [CoFlat]),
    emit(Fd, "~s~n", [classify(Valid, ArmsRace, CoFlat)]).

classify(false, _, _) ->
    "RESULT=INVALID: benchmark smoke test not monotone in x -> runner bug; fix before reading.";
classify(true, false, _) ->
    "RESULT=NO ARMS RACE: trait x did not escalate -> operator too weak; retune, do not sign.";
classify(true, true, false) ->
    "RESULT=NOT A CLEAN RED QUEEN: x escalates but co-fitness is not flat ~0.5 -> broken symmetry "
    "or real asymmetry; investigate before rung 054.";
classify(true, true, true) ->
    "RESULT=RED QUEEN DEMONSTRATED: the champion trait x escalates unboundedly (real, observable "
    "progress) while co-fitness stays ~0.5 with no trend (blind to it) -> co-fitness misleads; the "
    "fixed-benchmark instrument earns its first real test at rung 054 (>=2D).".

%%%============================================================================
%%% Numerics + stats
%%%============================================================================
logistic(Z) when Z > 30.0 -> 1.0;
logistic(Z) when Z < -30.0 -> 0.0;
logistic(Z) -> 1.0 / (1.0 + math:exp(-Z)).

mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

median([]) -> 0.0;
median(L) ->
    S = lists:sort(L), N = length(S),
    median_pick(N rem 2, S, N).
median_pick(1, S, N) -> lists:nth(N div 2 + 1, S) * 1.0;
median_pick(0, S, N) -> (lists:nth(N div 2, S) + lists:nth(N div 2 + 1, S)) / 2.0.

monotone([_]) -> true;
monotone([A, B | T]) when B >= A -> monotone([B | T]);
monotone(_) -> false.

%% Spearman rank correlation.
spearman(Xs, Ys) -> pearson(ranks(Xs), ranks(Ys)).

ranks(L) ->
    Indexed = lists:zip(L, lists:seq(1, length(L))),
    Sorted = lists:keysort(1, Indexed),
    Ranked = lists:zip(Sorted, lists:seq(1, length(Sorted))),
    Back = [{OrigIdx, Rank} || {{_V, OrigIdx}, Rank} <- Ranked],
    [Rank || {_I, Rank} <- lists:keysort(1, Back)].

pearson(Xs, Ys) ->
    N = length(Xs), Mx = mean(Xs), My = mean(Ys),
    Cov = lists:sum([(X - Mx) * (Y - My) || {X, Y} <- lists:zip(Xs, Ys)]),
    Sx = math:sqrt(lists:sum([(X - Mx) * (X - Mx) || X <- Xs])),
    Sy = math:sqrt(lists:sum([(Y - My) * (Y - My) || Y <- Ys])),
    pearson_v(Cov, Sx, Sy, N).
pearson_v(_Cov, Sx, Sy, _N) when Sx == 0.0 orelse Sy == 0.0 -> 0.0;
pearson_v(Cov, Sx, Sy, _N) -> Cov / (Sx * Sy).

%% Bootstrap 95% percentile CI of the median.
boot_ci([]) -> {0.0, 0.0};
boot_ci(Vals) ->
    N = length(Vals),
    Reps = [median([lists:nth(rand:uniform(N), Vals) || _ <- lists:seq(1, N)])
            || _ <- lists:seq(1, ?BOOT)],
    S = lists:sort(Reps),
    {pctile(S, 0.025), pctile(S, 0.975)}.

pctile(S, P) ->
    N = length(S), I = max(1, min(N, round(P * N))),
    lists:nth(I, S) * 1.0.

emit(Fd, Fmt) -> emit(Fd, Fmt, []).
emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).
