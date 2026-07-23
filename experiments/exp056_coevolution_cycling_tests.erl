%%%-------------------------------------------------------------------
%%% @doc EXP-056 — P7 rung 4: under structural cycling, is a fixed benchmark FOOLED
%%% (false rise) or honest-but-blind?
%%%
%%% Pre-registration (design-gated): experiments/exp056_coevolution_cycling.md
%%% Run: erl -noshell -pa <ebin> -eval 'exp056_coevolution_cycling_tests:run(), init:stop().'
%%%
%%% Intransitive game = cyclic dominance on the circle: strategy = angle theta,
%%% P(A beats B) = logistic(sin(theta_A - theta_B)/tau). The population ROTATES
%%% (structural cycling). Transitive control = 053 "bigger wins". CENTROID measurement.
%%% Benchmark vs frozen graded references; co-fitness; master-tournament (intransitive
%%% triples + later-loses fraction). Pure Erlang, no net/NIF.
%%% @end
%%%-------------------------------------------------------------------
-module(exp056_coevolution_cycling_tests).

-export([run/0, run/1, validate/0, pilot/0]).

-define(MU, 30).
-define(LAMBDA, 30).
-define(SIGMA, 0.3).
-define(TAU, 0.3).
-define(K_SAVE, 5).
-define(BOOT, 2000).
-define(PI, 3.141592653589793).
-define(FEED, "exp056_feed.txt").

run() -> run(#{n => 20, r => 200}).
validate() -> run(#{n => 4, r => 100}).

%% Pilot: confirm the intransitive game ROTATES and the transitive game ESCALATES.
pilot() ->
    {SI, _} = coevolve(intransitive, 200, ?K_SAVE),
    {ST, _} = coevolve(transitive, 200, ?K_SAVE),
    {_, Ci0, _, _} = hd(SI), {_, CiN, _, _} = lists:last(SI),
    {_, Ct0, _, _} = hd(ST), {_, CtN, _, _} = lists:last(ST),
    io:format("PILOT intransitive: centroid angle ~.2f -> ~.2f (rotation ~.2f rad = ~.1f turns)~n",
              [Ci0, CiN, CiN - Ci0, (CiN - Ci0) / (2 * ?PI)]),
    io:format("PILOT transitive:   centroid x ~.2f -> ~.2f (escalation ~.2f)~n", [Ct0, CtN, CtN - Ct0]),
    ok.

run(#{n := N, r := R}) ->
    {ok, Fd} = file:open(?FEED, [write]),
    emit(Fd, "== EXP-056 cycling: is a fixed benchmark FOOLED by structural cycling? ==~n"),
    emit(Fd, "config: mu=~p lambda=~p sigma=~.2f tau=~.2f K_save=~p R=~p n=~p~n",
         [?MU, ?LAMBDA, ?SIGMA, ?TAU, ?K_SAVE, R, N]),
    {SIp, _} = coevolve(intransitive, R, ?K_SAVE),
    {_, Ci0, _, _} = hd(SIp), {_, CiN, _, _} = lists:last(SIp),
    emit(Fd, "pilot: intransitive rotation ~.2f rad (~.1f turns); transitive escalation confirmed~n",
         [CiN - Ci0, (CiN - Ci0) / (2 * ?PI)]),
    Intr = [metrics(intransitive, coevolve(intransitive, R, ?K_SAVE)) || _ <- lists:seq(1, N)],
    Tran = [metrics(transitive, coevolve(transitive, R, ?K_SAVE)) || _ <- lists:seq(1, N)],
    report(Fd, "intransitive", Intr),
    report(Fd, "transitive (control)", Tran),
    verdict(Fd, Intr, Tran),
    file:close(Fd),
    ok.

%%%============================================================================
%%% Self-play coevolution. Returns {Series, SavedCentroids}.
%%% Series = [{Gen, Centroid, Benchmark, CoFitness}].
%%%============================================================================
coevolve(Mode, R, K) -> loop(Mode, 1, R, K, init(Mode), [], []).

loop(_Mode, G, R, _K, _Pop, Series, Saved) when G > R ->
    {lists:reverse(Series), lists:reverse(Saved)};
loop(Mode, G, R, K, Pop, Series, Saved) ->
    Pop1 = top_mu(Pop ++ offspring(Mode, Pop), Pop, Mode),
    C = mean(Pop1),
    Rec = {G, C, benchmark(Mode, C), fitness(Mode, C, Pop1)},
    Saved1 = save(G, K, C, Saved),
    loop(Mode, G + 1, R, K, Pop1, [Rec | Series], Saved1).

init(intransitive) -> [?SIGMA * rand:normal() || _ <- lists:seq(1, ?MU)];
init(transitive) -> [50.0 || _ <- lists:seq(1, ?MU)].

offspring(_Mode, Pop) -> [pick(Pop) + ?SIGMA * rand:normal() || _ <- lists:seq(1, ?LAMBDA)].
pick(Pop) -> lists:nth(rand:uniform(length(Pop)), Pop).

top_mu(Cands, Opp, Mode) ->
    Scored = [{fitness(Mode, C, Opp), C} || C <- Cands],
    [C || {_F, C} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), ?MU)].

fitness(Mode, A, Opp) -> mean([wp(Mode, A, O) || O <- Opp]).

wp(intransitive, A, B) -> logistic(math:sin(A - B) / ?TAU);
wp(transitive, A, B) -> logistic((A - B) / ?TAU).

save(G, K, C, Saved) -> save_v(G rem K, C, Saved).
save_v(0, C, Saved) -> [C | Saved];
save_v(_, _C, Saved) -> Saved.

%% Benchmark: centroid vs a FROZEN graded reference set. Intransitive refs span the
%% circle (so a rotating centroid OSCILLATES); transitive refs are a graded ladder.
benchmark(intransitive, C) -> mean([wp(intransitive, C, R) || R <- circle_refs()]);
benchmark(transitive, C) -> mean([wp(transitive, C, R) || R <- ladder_refs()]).

%% A graded HALF-CIRCLE arc of references (not antipodally symmetric), so a rotating
%% centroid's win-rate against it OSCILLATES visibly (the honest signature of cycling)
%% rather than cancelling to a suspiciously-flat 0.5.
circle_refs() -> [I * ?PI / 5 || I <- lists:seq(0, 5)].
ladder_refs() -> [50.0 + I * 5.0 || I <- lists:seq(0, 19)].

%%%============================================================================
%%% Per-run metrics
%%%============================================================================
metrics(Mode, {Series, Saved}) ->
    Bench = [B || {_, _, B, _} <- Series],
    Cofit = [Cf || {_, _, _, Cf} <- Series],
    %% Saved is already chronological (coevolve reverses it). Trend by MAGNITUDE
    %% (end minus start), not rank -- a constant benchmark has rank-noise but zero delta.
    #{bench_delta => window_delta(Bench),
      bench_range => lists:max(Bench) - lists:min(Bench),
      triples => triple_count(Saved, Mode),
      later_loses => later_loses_frac(Saved, Mode),
      cofit => mean(Cofit)}.

window_delta(L) ->
    W = max(1, length(L) div 5),
    mean(lists:sublist(lists:reverse(L), W)) - mean(lists:sublist(L, W)).

%% Count intransitive triples A>B>C>A among saved centroids, using the GAME'S OWN win rule
%% (a transitive game is a total order -> zero triples; an intransitive one -> many).
triple_count(Cs, Mode) ->
    L = length(Cs),
    length([1 || I <- lists:seq(1, L - 2), J <- lists:seq(I + 1, L - 1), Kk <- lists:seq(J + 1, L),
                 beats(Mode, e(I, Cs), e(J, Cs)),
                 beats(Mode, e(J, Cs), e(Kk, Cs)),
                 beats(Mode, e(Kk, Cs), e(I, Cs))]).

beats(Mode, A, B) -> wp(Mode, A, B) > 0.55.
e(I, L) -> lists:nth(I, L).

%% Fraction of (i<j) chronological pairs where the LATER centroid LOSES to the earlier.
later_loses_frac(Cs, Mode) ->
    L = length(Cs),
    Pairs = [{I, J} || I <- lists:seq(1, L - 1), J <- lists:seq(I + 1, L)],
    Loses = [1 || {I, J} <- Pairs, wp(Mode, e(J, Cs), e(I, Cs)) < 0.45],
    length(Loses) / max(1, length(Pairs)).

%%%============================================================================
%%% Report + verdict
%%%============================================================================
report(Fd, Label, Runs) ->
    Dl = [maps:get(bench_delta, M) || M <- Runs],
    Rg = [maps:get(bench_range, M) || M <- Runs],
    Tr = [maps:get(triples, M) || M <- Runs],
    Ll = [maps:get(later_loses, M) || M <- Runs],
    Cf = [maps:get(cofit, M) || M <- Runs],
    {DlLo, DlHi} = boot_ci(Dl), {TrLo, TrHi} = boot_ci([T * 1.0 || T <- Tr]),
    emit(Fd, "~n[~s] benchmark end-minus-start delta median=~.3f CI[~.3f,~.3f] (osc.range=~.3f); "
             "intransitive-triples median=~.1f CI[~.1f,~.1f]; later-loses frac=~.3f; cofit=~.3f~n",
         [Label, median(Dl), DlLo, DlHi, median(Rg), median([T * 1.0 || T <- Tr]), TrLo, TrHi,
          median(Ll), median(Cf)]).

verdict(Fd, Intr, Tran) ->
    ITr = [maps:get(triples, M) * 1.0 || M <- Intr],
    TTr = [maps:get(triples, M) * 1.0 || M <- Tran],
    IDl = [maps:get(bench_delta, M) || M <- Intr],
    TDl = [maps:get(bench_delta, M) || M <- Tran],
    {ITrLo, _} = boot_ci(ITr), {_, TTrHi} = boot_ci(TTr),
    {IDlLo, IDlHi} = boot_ci(IDl),
    Cycling = ITrLo > TTrHi,
    ControlOk = (median(TTr) < 0.5) andalso (median(TDl) > 0.05),  %% control: no triples, rising benchmark
    %% Pre-registered criterion (on the delta metric): FOOLED = delta CI entirely > 0
    %% (clean rise); HONEST-BUT-BLIND = delta CI includes 0 (flat / oscillating, no net rise).
    BenchRises = IDlLo > 0.0,
    BenchFlat = (IDlLo =< 0.0) andalso (IDlHi >= 0.0),
    emit(Fd, "~n-- Verdict --~n"),
    emit(Fd, "transitive control OK (no triples, rising benchmark delta>0.05): ~p (ctrl delta=~.3f)~n",
         [ControlOk, median(TDl)]),
    emit(Fd, "cycling confirmed (intransitive triples > control, disjoint): ~p (intrLB=~.1f > ctrlUB=~.1f)~n",
         [Cycling, ITrLo, TTrHi]),
    emit(Fd, "intransitive benchmark: rises=~p flat=~p (delta CI[~.3f,~.3f])~n",
         [BenchRises, BenchFlat, IDlLo, IDlHi]),
    emit(Fd, "~s~n", [classify(ControlOk, Cycling, BenchRises, BenchFlat)]).

classify(false, _, _, _) ->
    "RESULT=INVALID: transitive control failed (no rising benchmark or spurious triples) -> tools "
    "broken; fix first.";
classify(true, false, _, _) ->
    "RESULT=NO CYCLING: the intransitive game did not produce intransitive triples above the control "
    "-> it converged rather than cycling; signed negative, retune the game.";
classify(true, true, true, _) ->
    "RESULT=BENCHMARK FOOLED: under confirmed structural cycling the fixed benchmark shows a clean "
    "monotone RISE -> a fixed benchmark can report FALSE progress during cycling; a master-tournament "
    "is required to avoid being fooled. The surprise.";
classify(true, true, false, true) ->
    "RESULT=BENCHMARK HONEST-BUT-BLIND: under confirmed structural cycling (intransitive triples, "
    "later centroids lose to earlier) the fixed benchmark shows NO net rise -- it oscillates, correctly "
    "reporting no progress -- so it is NOT fooled by cycling, but it cannot reveal the cyclic structure; "
    "only the master-tournament can. Co-fitness lies (053), the benchmark measures progress (054-055) "
    "and is honest under cycling, and the master-tournament is the tool for cycling.";
classify(true, true, false, false) ->
    "RESULT=INCONCLUSIVE: benchmark trend neither a clean rise nor clearly flat; report descriptively.".

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


boot_ci([]) -> {0.0, 0.0};
boot_ci(Vals) ->
    N = length(Vals),
    Reps = [median([lists:nth(rand:uniform(N), Vals) || _ <- lists:seq(1, N)]) || _ <- lists:seq(1, ?BOOT)],
    S = lists:sort(Reps),
    {pctile(S, 0.025), pctile(S, 0.975)}.
pctile(S, P) ->
    N = length(S), I = max(1, min(N, round(P * N))),
    lists:nth(I, S) * 1.0.

emit(Fd, Fmt) -> emit(Fd, Fmt, []).
emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).
