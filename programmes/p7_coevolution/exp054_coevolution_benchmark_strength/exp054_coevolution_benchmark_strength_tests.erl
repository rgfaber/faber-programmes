%%%-------------------------------------------------------------------
%%% @doc EXP-054 — P7 rung 2: even a FIXED benchmark goes blind if too weak.
%%%
%%% Pre-registration (design-gated): experiments/exp054_coevolution_benchmark_strength.md
%%% Run: erl -noshell -pa <ebin> -eval 'exp054_coevolution_benchmark_strength_tests:run(), init:stop().'
%%%
%%% Same 1D stochastic transitive game as 053 (arms race; true progress = champion x,
%%% directly observable). Two FROZEN benchmarks: GRADED (spans x0..2x final) stays
%%% unsaturated and tracks x; WEAK (references clustered low, x0..x0+5) saturates early
%%% and goes blind. Metric is the LATE window (2nd half), not a full-run time-correlation
%%% (which is tautological). Pure Erlang, no net/NIF.
%%% @end
%%%-------------------------------------------------------------------
-module(exp054_coevolution_benchmark_strength_tests).

-export([run/0, run/1, validate/0]).

-define(MU, 30).
-define(LAMBDA, 30).
-define(SIGMA, 0.3).
-define(TAU, 0.3).
-define(X0, 50.0).
-define(BOOT, 2000).
-define(FEED, "exp054_feed.txt").

run() -> run(#{n => 30, r => 150}).
validate() -> run(#{n => 5, r => 60}).

run(#{n := N, r := R}) ->
    {ok, Fd} = file:open(?FEED, [write]),
    emit(Fd, "== EXP-054 benchmark strength: a fixed-but-weak benchmark goes blind ==~n"),
    emit(Fd, "config: mu=~p lambda=~p sigma=~.2f tau=~.2f x0=~.1f R=~p n=~p~n",
         [?MU, ?LAMBDA, ?SIGMA, ?TAU, ?X0, R, N]),
    %% Pilot: size the graded ladder (>=2x final x); weak ladder is fixed low.
    FinalX = lists:last(coevolve(R)),
    Graded = ladder(?X0, 2.0 * FinalX, 20),
    Weak = ladder(?X0, ?X0 + 5.0, 20),
    emit(Fd, "pilot final champion x=~.1f -> graded ladder [~.1f..~.1f], weak ladder [~.1f..~.1f]~n",
         [FinalX, hd(Graded), lists:last(Graded), hd(Weak), lists:last(Weak)]),
    Runs = [series_metrics(with_gens(coevolve(R)), Graded, Weak) || _ <- lists:seq(1, N)],
    report(Fd, R, Runs),
    file:close(Fd),
    ok.

%% Coevolve two 1D populations; return the per-generation champion x (max over both pops).
coevolve(R) -> gen_loop(1, R, init(), init(), []).
init() -> [?X0 || _ <- lists:seq(1, ?MU)].

gen_loop(G, R, _A, _B, Acc) when G > R -> lists:reverse(Acc);
gen_loop(G, R, A, B, Acc) ->
    A1 = top_mu(A ++ offspring(A), B),
    B1 = top_mu(B ++ offspring(B), A),
    ChampX = max(lists:max(A1), lists:max(B1)),
    gen_loop(G + 1, R, A1, B1, [ChampX | Acc]).

offspring(Pop) -> [mutate(pick(Pop)) || _ <- lists:seq(1, ?LAMBDA)].
top_mu(Cands, Opp) ->
    Scored = [{fitness(X, Opp), X} || X <- Cands],
    [X || {_F, X} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), ?MU)].
fitness(X, Opp) -> mean([logistic((X - O) / ?TAU) || O <- Opp]).
pick(Pop) -> lists:nth(rand:uniform(length(Pop)), Pop).
mutate(X) -> X + ?SIGMA * rand:normal().

with_gens(Xs) -> lists:zip(lists:seq(1, length(Xs)), Xs).
ladder(Lo, Hi, K) -> [Lo + (Hi - Lo) * I / (K - 1) || I <- lists:seq(0, K - 1)].

%% Benchmark reading = champion's mean win-prob against the frozen reference set.
bench(X, Ladder) -> mean([logistic((X - Ref) / ?TAU) || Ref <- Ladder]).

%%%============================================================================
%%% Per-run metrics: unsaturated fraction + late-window tracking of true x.
%%%============================================================================
series_metrics(Series, Graded, Weak) ->
    Xs = [X || {_G, X} <- Series],
    GB = [bench(X, Graded) || X <- Xs],
    WB = [bench(X, Weak) || X <- Xs],
    Half = length(Xs) div 2,
    {_, LateGB} = lists:split(Half, GB),
    {_, LateWB} = lists:split(Half, WB),
    %% Late-window RANGE (magnitude the reading moves), NOT Spearman: a saturated
    %% benchmark creeps up infinitesimally (0.999->0.9999), so its rank order still
    %% rises and Spearman reads 1.0 despite being flat and blind. Range catches it.
    #{g_unsat => frac_below(GB, 0.99),
      w_unsat => frac_below(WB, 0.99),
      g_range => range(LateGB),
      w_range => range(LateWB),
      blind_gap => blindness_gap(Xs, WB)}.

range(L) -> lists:max(L) - lists:min(L).
frac_below(L, Thr) -> length([1 || V <- L, V < Thr]) / length(L).

%% How much true progress happened AFTER the weak benchmark first saturated.
blindness_gap(Xs, WB) ->
    SatIdx = first_ge_index(WB, 0.99),
    blind_gap_v(SatIdx, Xs).
blind_gap_v(none, _Xs) -> 0.0;
blind_gap_v(I, Xs) -> lists:last(Xs) - lists:nth(I, Xs).

first_ge_index(L, Thr) -> first_ge_index(L, Thr, 1).
first_ge_index([], _Thr, _I) -> none;
first_ge_index([V | _T], Thr, I) when V >= Thr -> I;
first_ge_index([_V | T], Thr, I) -> first_ge_index(T, Thr, I + 1).

%%%============================================================================
%%% Report + verdict
%%%============================================================================
report(Fd, R, Runs) ->
    GRange = [maps:get(g_range, M) || M <- Runs],
    WRange = [maps:get(w_range, M) || M <- Runs],
    GUns = [maps:get(g_unsat, M) || M <- Runs],
    WUns = [maps:get(w_unsat, M) || M <- Runs],
    Blind = [maps:get(blind_gap, M) || M <- Runs],
    {GrLo, GrHi} = boot_ci(GRange), {WrLo, WrHi} = boot_ci(WRange),
    emit(Fd, "~n-- Results (n=~p, R=~p; late window = 2nd half) --~n", [length(Runs), R]),
    emit(Fd, "GRADED benchmark: unsaturated frac median=~.2f; late-window reading RANGE median=~.4f CI[~.4f,~.4f]~n",
         [median(GUns), median(GRange), GrLo, GrHi]),
    emit(Fd, "WEAK   benchmark: unsaturated frac median=~.2f; late-window reading RANGE median=~.4f CI[~.4f,~.4f]~n",
         [median(WUns), median(WRange), WrLo, WrHi]),
    emit(Fd, "blindness gap (true x climbed AFTER the weak benchmark saturated): median=~.1f~n",
         [median(Blind)]),
    GradedTracks = (median(GRange) > 0.03) andalso (median(GUns) > 0.9),
    WeakBlind = (median(WRange) < 0.01) andalso (median(WUns) < 0.3),
    Disjoint = GrLo > WrHi,
    emit(Fd, "graded resolves progress (late range>0.03 & unsat>0.9): ~p~n", [GradedTracks]),
    emit(Fd, "weak blind (late range<0.01 & unsat<0.3): ~p~n", [WeakBlind]),
    emit(Fd, "graded>weak late-range disjoint CIs: ~p~n", [Disjoint]),
    emit(Fd, "~s~n", [classify(GradedTracks, WeakBlind, Disjoint)]).

classify(true, true, true) ->
    "RESULT=STRENGTH MATTERS: a fixed-but-too-weak benchmark saturates early and reports NO progress "
    "during a large ongoing arms race (late-window tracking collapses to ~0), while a graded benchmark "
    "of adequate range keeps tracking. 'Fixed' is not enough; the benchmark must be graded. This is the "
    "fix the deferred pursuit-evasion rung needs.";
classify(true, false, _) ->
    "RESULT=NO STRENGTH EFFECT: the weak ladder did not saturate/go blind within R -> narrow it or "
    "lengthen R before concluding; signed note.";
classify(false, _, _) ->
    "RESULT=INVALID: the graded benchmark did not track a real arms race (operator too weak or a bug) "
    "-> fix before interpreting.".

%%%============================================================================
%%% Numerics + stats (as 053)
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
