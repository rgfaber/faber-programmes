%%%-------------------------------------------------------------------
%%% @doc EXP-057 — the embodied P7 rung: neural pursuit-evasion coevolution.
%%%
%%% Pre-registration (design-gated): experiments/exp057_embodied_pursuit_evasion.md
%%%
%%% BUILT INCREMENTALLY. This file currently implements the KILL GATES the gate
%%% demanded run first: (1) CALIBRATION -- hand-coded greedy pursuer vs optimal-flee
%%% evader across a fine speed grid, to find s* (the balance where competent play is
%%% nearest 50/50, the only place a two-sided gradient can live); (2) REPRESENTABILITY
%%% -- can a [2,6,4] net express competent pursuit / evasion (else INVALID, a capacity
%%% limit not dynamics). The coevolution at s* is added after these pass.
%%% Real engine: net moves are network_evaluator forward passes.
%%% @end
%%%-------------------------------------------------------------------
-module(exp057_embodied_pursuit_evasion_tests).

-export([calibrate/0, representability/1, representability/0, verify_benchmark/0, coevo_pilot/0,
         run/0, run/1, run_coupling/0, run_coupling/1, run_brackets/0, run_brackets/1]).

-define(W, 9).
-define(T, 40).
-define(HID, 6).
-define(NP, 6 * 2 + 6 + 4 * 6 + 4).     %% [2,6,4] genome length = 46
-define(SIGMA, 0.2).
-define(SSTAR_M, 13).                   %% s* = 1.083 (the competent-play crossover)
-define(CMU, 15).                       %% coevolution population size
-define(CK, 3).                         %% opponents sampled per fitness eval

%% Speed grid: evader skips 1 move every m steps -> pursuer speed factor s = m/(m-1).
%% Refined into the razor-thin transition zone near s=1.0 (calibration showed the crossover
%% between evader-wins and pursuer-wins is a knife-edge just above equal speed).
speed_grid() ->
    [{none, 1.0}, {40, 1.026}, {30, 1.034}, {24, 1.043}, {20, 1.053}, {16, 1.067},
     {15, 1.071}, {14, 1.077}, {13, 1.083}, {12, 1.091}, {11, 1.10}, {10, 1.111},
     {9, 1.125}, {8, 1.143}].

sstar() -> element(2, lists:keyfind(?SSTAR_M, 1, speed_grid())).

%% Starts: pursuer at {0,0} (torus is translation-invariant), evader at every cell not
%% already within capture range -> a fine, deterministic catch-rate for hand-coded policies.
starts() ->
    [{{0, 0}, {X, Y}} || X <- lists:seq(0, ?W - 1), Y <- lists:seq(0, ?W - 1), cheb({0, 0}, {X, Y}) > 1].

%%%============================================================================
%%% STEP 1 — Calibration: greedy pursuer vs optimal-flee evader across speeds.
%%%============================================================================
calibrate() ->
    io:format("== EXP-057 calibration: greedy pursuer vs optimal-flee evader ==~n"),
    io:format("grid ~p starts, T=~p, ~p speeds~n", [length(starts()), ?T, length(speed_grid())]),
    Rates = [{S, catch_rate(greedy, flee, M)} || {M, S} <- speed_grid()],
    [io:format("  s=~.2f (m=~p): greedy-vs-flee catch-rate = ~.3f~n", [S, M, R])
     || {{M, S}, {_, R}} <- lists:zip(speed_grid(), Rates)],
    {_, SStar} = lists:min([{abs(R - 0.5), S} || {S, R} <- Rates]),
    io:format("~ns* (catch-rate nearest 0.5) = ~.2f~n", [SStar]),
    io:format("interpretation: s<s* evader-favoured, s>s* pursuer-favoured; s* is where a "
              "two-sided gradient can exist~n"),
    SStar.

catch_rate(PolP, PolE, M) ->
    R = [caught(match(PolP, PolE, St, M)) || St <- starts()],
    length([1 || true <- R]) / length(R).

%%%============================================================================
%%% STEP 2 — Representability: can a [2,6,4] net express competent pursuit / evasion?
%%% Evolve a net pursuer vs the flee evader (and a net evader vs the greedy pursuer) with
%%% a quick (mu+lambda) EA; compare to the hand-coded policy's rate. Close => representable.
%%%============================================================================
representability() -> representability(1.5).

representability(S) ->
    M = m_for(S),
    io:format("~n== EXP-057 representability at s=~.2f (m=~p) ==~n", [S, M]),
    HandP = catch_rate(greedy, flee, M),
    HandE = 1.0 - catch_rate(greedy, flee, M),      %% flee's survival vs greedy
    NetP = evolve_net(pursuer, M, 30),              %% net pursuer vs flee -> catch-rate
    NetE = evolve_net(evader, M, 30),               %% net evader vs greedy -> survival
    io:format("  pursuit: hand-coded greedy catch-rate=~.3f ; evolved NET catch-rate=~.3f~n", [HandP, NetP]),
    io:format("  evasion: hand-coded flee survival=~.3f ; evolved NET survival=~.3f~n", [HandE, NetE]),
    Ok = (NetP > 0.6 * max(HandP, 0.1)) andalso (NetE > 0.6 * max(HandE, 0.1)),
    io:format("  representable (net reaches >=60% of hand-coded competence both roles): ~p~n", [Ok]),
    Ok.

%% Evolve a net for a role against the fixed hand-coded opponent; return its best rate.
evolve_net(Role, M, Gens) ->
    Pop = [rand_genome() || _ <- lists:seq(1, 14)],
    best_rate(Role, M, Gens, Pop, 0.0).

best_rate(_Role, _M, 0, _Pop, Best) -> Best;
best_rate(Role, M, G, Pop, Best) ->
    Off = [mutate(pick(Pop)) || _ <- lists:seq(1, 14)],
    Scored = [{role_fit(Role, Gm, M), Gm} || Gm <- Pop ++ Off],
    Top = [Gm || {_F, Gm} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), 14)],
    BestNow = lists:max([F || {F, _} <- Scored]),
    best_rate(Role, M, G - 1, Top, max(Best, BestNow)).

%% Like evolve_net but returns the CHAMPION GENOME (for harvesting frozen benchmark opponents).
evolve_genome(Role, M, Gens) ->
    Pop = [rand_genome() || _ <- lists:seq(1, 14)],
    best_genome(Role, M, Gens, Pop, {-1.0, hd(Pop)}).

best_genome(_Role, _M, 0, _Pop, {_F, G}) -> G;
best_genome(Role, M, Gn, Pop, Best) ->
    Off = [mutate(pick(Pop)) || _ <- lists:seq(1, 14)],
    Ranked = lists:reverse(lists:keysort(1, [{role_fit(Role, Gm, M), Gm} || Gm <- Pop ++ Off])),
    Top = [Gm || {_F, Gm} <- lists:sublist(Ranked, 14)],
    {BF, BG} = hd(Ranked),
    Best1 = pick_best(BF > element(1, Best), {BF, BG}, Best),
    best_genome(Role, M, Gn - 1, Top, Best1).

pick_best(true, New, _Old) -> New;
pick_best(false, _New, Old) -> Old.

%% A subset of starts for the (cheaper) representability EA fitness (every 5th start).
rep_starts() -> [St || {I, St} <- lists:zip(lists:seq(1, length(starts())), starts()), I rem 5 =:= 0].

%% pursuer role: catch-rate of the net pursuer vs the flee evader (want high).
role_fit(pursuer, G, M) ->
    Net = mk_net(G),
    mean([bit(caught(match({net, Net}, flee, St, M))) || St <- rep_starts()]);
%% evader role: survival of the net evader vs the greedy pursuer (want high).
role_fit(evader, G, M) ->
    Net = mk_net(G),
    mean([bit(not caught(match(greedy, {net, Net}, St, M))) || St <- rep_starts()]).

%%%============================================================================
%%% STEP 3a — Graded benchmark: a difficulty-tunable greedy/flee family (not a
%%% degenerate pilot HoF). p = probability of a RANDOM move; p=0.8 weak .. p=0.0 strong.
%%%============================================================================
bench_evaders() -> [{flee_p, P} || P <- [0.8, 0.6, 0.4, 0.2, 0.0]].
bench_starts() -> [St || {I, St} <- lists:zip(lists:seq(1, length(starts())), starts()), I rem 6 =:= 0].
co_starts() -> [St || {I, St} <- lists:zip(lists:seq(1, length(starts())), starts()), I rem 10 =:= 0].

%% VERIFY the benchmark is difficulty-graded AND that the CONTINUOUS metric de-saturates it.
%% Binary catch-rate saturates near the ceiling at s* (the 054 demon); capture-speed (pscore) does
%% not. Show both per rung, and the probe's aggregate on each -- the continuous aggregate must NOT
%% sit at a ceiling/floor (else no headroom to measure progress).
verify_benchmark() ->
    M = ?SSTAR_M,
    BM = build_benchmark(M),
    io:format("== EXP-057 benchmark grading (s*=~.3f, m=~p), FROZEN ladder ==~n", [sstar(), M]),
    io:format("pursuer benchmark: pure-greedy probe capture-speed (pscore) per evader rung "
              "(higher = easier rung):~n"),
    Pc = [{rung_label(R), mean([pscore(match(greedy, R, St, M)) || St <- bench_starts()])}
          || R <- maps:get(evaders, BM)],
    [io:format("  ~-14s pscore=~.3f~n", [L, Ps]) || {L, Ps} <- Pc],
    io:format("  AGG pursuer benchmark (mean pscore, must be OFF ceiling/floor): ~.3f~n",
              [mean([Ps || {_, Ps} <- Pc])]),
    io:format("evader benchmark: pure-flee probe ESCAPE-RATE (not-caught) per pursuer rung "
              "(higher = easier rung):~n"),
    Es = [{rung_label(R), mean([bit(not caught(match(R, flee, St, M))) || St <- bench_starts()])}
          || R <- maps:get(pursuers, BM)],
    [io:format("  ~-14s escape=~.3f~n", [L, Es2]) || {L, Es2} <- Es],
    io:format("  AGG evader benchmark (mean escape-rate, must be OFF ceiling/floor): ~.3f~n",
              [mean([Es2 || {_, Es2} <- Es])]),
    ok.

rung_label({flee_p, P}) -> lists:flatten(io_lib:format("flee p=~.1f", [P]));
rung_label({greedy_p, P}) -> lists:flatten(io_lib:format("greedy p=~.1f", [P]));
rung_label(greedy) -> "greedy(pure)";
rung_label({net, _}) -> "evolved-net".

%% FROZEN benchmark = the graded tunable family PLUS strong EVOLVED opponents, harvested ONCE
%% under a FIXED seed (reproducible, identical across all n runs of a study). The evolved rungs
%% de-saturate the side the hand-coded family is too weak to challenge: strong net pursuers give
%% the EVADER benchmark headroom (hand greedy is too weak at s*); strong net evaders harden the
%% top of the PURSUER benchmark. Continuous scores + a two-ended graded ladder = the 054 fix, both sides.
build_benchmark(M) ->
    _ = rand:seed(exsss, {101, 202, 303}),
    SP = [{net, mk_net(evolve_genome(pursuer, M, 40))} || _ <- lists:seq(1, 2)],
    SE = [{net, mk_net(evolve_genome(evader, M, 40))} || _ <- lists:seq(1, 2)],
    %% pursuer benchmark (capture-speed): FULL graded flee family + strong evolved evaders -- pscore
    %%   discriminates across the whole ladder, weak rungs included.
    %% evader benchmark (escape-rate): STRONG pursuers ONLY (pure greedy + evolved nets) -- weak
    %%   tunable pursuers catch nothing, so every evader escapes them and escape-rate loses its floor.
    #{evaders => bench_evaders() ++ SE, pursuers => [greedy | SP]}.

%% Champion benchmark readings over the FROZEN ladder, each role on its DISCRIMINATING axis.
%% At the catch-rate crossover s*, the game is asymmetric: capture happens LATE, so
%%   - the PURSUER's skill shows in capture SPEED (pscore) -- binary catch-rate saturates ~1.0;
%%   - the EVADER's skill shows in ESCAPE RATE (fraction not caught) -- survival-TIME saturates ~0.85
%%     (even a random evader survives most of the episode at s*).
%% Both are "competence vs the frozen graded benchmark", read on the axis with headroom for that role.
bench_pursuer(G, M, BM) ->
    Net = mk_net(G),
    mean([pscore(match({net, Net}, R, St, M)) || R <- maps:get(evaders, BM), St <- bench_starts()]).
bench_evader(G, M, BM) ->
    Net = mk_net(G),
    mean([bit(not caught(match(R, {net, Net}, St, M))) || R <- maps:get(pursuers, BM), St <- bench_starts()]).

%%%============================================================================
%%% STEP 3b — Coevolution at s*. Progress measured against the FIXED graded benchmark
%%% (NOT co-fitness). One PILOT run reports the trajectories + timing to set n.
%%%============================================================================
coevo_pilot() ->
    io:format("== EXP-057 coevolution pilot at s*=1.083 (m=~p), R=25 ==~n", [?SSTAR_M]),
    BM = build_benchmark(?SSTAR_M),
    T0 = erlang:monotonic_time(millisecond),
    {Traj, _Saved} = coevo_run(?SSTAR_M, 25, BM),
    Dt = erlang:monotonic_time(millisecond) - T0,
    io:format("gen / pursuer-benchmark / evader-benchmark:~n"),
    [io:format("  g~p  P=~.3f  E=~.3f~n", [G, Pp, Ep]) || {G, Pp, Ep} <- Traj],
    Ps = [Pp || {_, Pp, _} <- Traj], Es = [Ep || {_, _, Ep} <- Traj],
    io:format("~npursuer bench: start=~.3f peak=~.3f end=~.3f~n", [hd(Ps), lists:max(Ps), lists:last(Ps)]),
    io:format("evader  bench: start=~.3f peak=~.3f end=~.3f~n", [hd(Es), lists:max(Es), lists:last(Es)]),
    io:format("one run took ~p ms~n", [Dt]),
    ok.

%%%============================================================================
%%% STEP 3c — Full study: n coevolution runs at s*; benchmark trajectory (peak-vs-start
%%% progress) + overfit (end < peak) per side, aggregated with bootstrap CIs.
%%%============================================================================
run() -> run(#{n => 20, r => 30}).

%% Focused COUPLING study (the gate's stronger-baseline follow-up): compare coevolution's benchmark NET
%% against TWO static baselines -- a frozen RANDOM opponent and a frozen STRONG opponent (disjoint from
%% the benchmark) -- at larger n, both brackets. "Arms race / coupling" for a side is licensed iff coevo
%% NET exceeds the static NET (difference CI > 0). No tournament here (053-056 dynamics already signed).
run_coupling() -> run_coupling(#{n => 60, r => 30}).

run_coupling(#{n := N, r := R}) ->
    {ok, Fd} = file:open("exp057_coupling_feed.txt", [write]),
    emit(Fd, "== EXP-057 COUPLING: coevolution vs static baselines (RANDOM + STRONG), n=~p R=~p ==~n", [N, R]),
    emit(Fd, "coupling licensed for a side iff coevo NET EXCEEDS the static NET (coevo-minus-static CI > 0)~n"),
    [coupling_at(Fd, M, Tag, N, R) || {M, Tag} <- [{14, "EVADER-favoured (catch 0.389)"},
                                                   {13, "PURSUER-favoured (catch 0.667)"}]],
    file:close(Fd),
    ok.

coupling_at(Fd, M, Tag, N, R) ->
    emit(Fd, "~n#### m=~p  s=~.3f  [~s] ####~n", [M, m_speed(M), Tag]),
    BM = build_benchmark(M),
    {SFP, SFE} = build_strong_opponents(M),
    Coevo = [side_traj(element(1, coevo_run(M, R, BM))) || _ <- lists:seq(1, N)],
    Rand = [side_traj(control_run(M, R, BM)) || _ <- lists:seq(1, N)],
    Strong = [side_traj(control_vs(M, R, BM, SFP, SFE)) || _ <- lists:seq(1, N)],
    emit(Fd, "coevo NET median: pursuer=~.3f  evader=~.3f~n",
         [median(net_of(p, Coevo)), median(net_of(e, Coevo))]),
    couple2(Fd, "vs STATIC-RANDOM", Coevo, Rand),
    couple2(Fd, "vs STATIC-STRONG", Coevo, Strong).

couple2(Fd, Tag, Coevo, Static) ->
    emit(Fd, "  ~s (static NET | coevo-minus-static):~n", [Tag]),
    couple_side2(Fd, "pursuer", p, Coevo, Static),
    couple_side2(Fd, "evader ", e, Coevo, Static).

couple_side2(Fd, Label, Side, Coevo, Static) ->
    Co = net_of(Side, Coevo), St = net_of(Side, Static),
    {DLo, DHi} = boot_ci_diff(Co, St),
    emit(Fd, "    ~s: static=~.3f | diff=~.3f CI[~.3f,~.3f] -> ~s~n",
         [Label, median(St), median(Co) - median(St), DLo, DHi, coupling_verdict(DLo, DHi)]).

%% Run BOTH brackets of the coarse catch-rate crossover plateau: m=14 (s=1.077, catch 0.389,
%% evader-favoured) and m=13 (s=1.083, catch 0.667, pursuer-favoured). If the disengagement
%% direction is CONSISTENT across both, it is dynamics; if it FLIPS with the bracket, it is
%% calibration-placed and the direction must be dropped (only the no-sustained-race half survives).
run(#{n := N, r := R}) ->
    {ok, Fd} = file:open("exp057_feed.txt", [write]),
    emit(Fd, "== EXP-057 embodied pursuit-evasion coevolution -- BOTH crossover brackets ==~n"),
    emit(Fd, "config: net=[2,6,4] mu=~p K=~p R=~p n=~p; frozen seed-fixed graded HoF; pursuer=capture-speed, "
             "evader=escape-rate; master-tournament (intransitive triples) per run~n", [?CMU, ?CK, R, N]),
    Collected = [{M, run_at(Fd, M, Tag, N, R)}
                 || {M, Tag} <- [{14, "EVADER-favoured (catch 0.389)"},
                                 {13, "PURSUER-favoured (catch 0.667)"}]],
    cross_bracket(Fd, Collected),
    file:close(Fd),
    ok.

run_at(Fd, M, Tag, N, R) ->
    emit(Fd, "~n########## m=~p  s=~.3f  [~s] ##########~n", [M, m_speed(M), Tag]),
    BM = build_benchmark(M),
    Runs = [run_metrics(M, coevo_run(M, R, BM)) || _ <- lists:seq(1, N)],
    report_side(Fd, "PURSUER", [maps:get(p, X) || X <- Runs]),
    report_side(Fd, "EVADER ", [maps:get(e, X) || X <- Runs]),
    report_mt(Fd, [maps:get(mt, X) || X <- Runs]),
    verdict(Fd, Runs),
    Ctrl = [side_traj(control_run(M, R, BM)) || _ <- lists:seq(1, N)],
    report_coupling(Fd, Runs, Ctrl),
    Runs.

%% THREE-bracket trend (adds m=12, one speed-step MORE pursuer-favoured than m=13, to turn the
%% unresolved m=14-vs-m=13 evader difference into a trend). Coevolution + master-tournament only (the
%% coupling question is settled); focuses on whether the evader's marginal sustainment declines
%% monotonically as the pursuer's speed edge grows, with a resolvable m=14-vs-m=12 extreme pair.
run_brackets() -> run_brackets(#{n => 40, r => 30}).

run_brackets(#{n := N, r := R}) ->
    {ok, Fd} = file:open("exp057_brackets_feed.txt", [write]),
    emit(Fd, "== EXP-057 THREE brackets: evader-marginality trend (m=14, 13, 12) ==~n"),
    emit(Fd, "config: net=[2,6,4] mu=~p K=~p R=~p n=~p; frozen graded HoF; master-tournament per run~n",
         [?CMU, ?CK, R, N]),
    Collected = [{M, run_trend(Fd, M, Tag, N, R)}
                 || {M, Tag} <- [{14, "s=1.077 EVADER-favoured (catch 0.389)"},
                                  {13, "s=1.083 PURSUER-favoured (catch 0.667)"},
                                  {12, "s=1.091 PURSUER-favoured+ (catch 0.667, +1 step)"}]],
    cross_bracket(Fd, Collected),
    file:close(Fd),
    ok.

run_trend(Fd, M, Tag, N, R) ->
    emit(Fd, "~n#### m=~p  s=~.3f  [~s] ####~n", [M, m_speed(M), Tag]),
    BM = build_benchmark(M),
    Runs = [run_metrics(M, coevo_run(M, R, BM)) || _ <- lists:seq(1, N)],
    report_side(Fd, "PURSUER", [maps:get(p, X) || X <- Runs]),
    report_side(Fd, "EVADER ", [maps:get(e, X) || X <- Runs]),
    report_mt(Fd, [maps:get(mt, X) || X <- Runs]),
    verdict(Fd, Runs),
    Runs.

%%%============================================================================
%%% DECOUPLED CONTROL (earns/refuses "arms race"): evolve each side against a FROZEN gen-0 opponent
%%% (static target, no co-adaptation), measured on the SAME held-out graded benchmark. If coevolution's
%%% NET progress EXCEEDS the static control's, the co-adapting (moving) opponent drove extra progress =
%%% coevolutionary coupling. If not, agents improved merely from having any opponent gradient.
%%%============================================================================
control_run(M, R, BM) ->                          %% static baseline = frozen gen-0 RANDOM opponents
    FP = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    FE = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    control_vs(M, R, BM, FP, FE).

%% Train each side against a GIVEN fixed opponent set (FP fixed pursuers for the evader-in-training,
%% FE fixed evaders for the pursuer-in-training); measure on the held-out benchmark BM.
control_vs(M, R, BM, FP, FE) ->
    PP = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    PE = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    ctrl_loop(1, R, PP, PE, FP, FE, M, BM, []).

%% STRONG fixed opponents, harvested with a seed DISJOINT from the benchmark HoF (so training against
%% them is not teaching-to-the-test). A strong but NARROW static target: overfitting to it should
%% generalise worse to the graded benchmark than coevolution's varied curriculum -- IF coupling exists.
build_strong_opponents(M) ->
    _ = rand:seed(exsss, {202, 303, 404}),
    FP = [evolve_genome(pursuer, M, 30) || _ <- lists:seq(1, 5)],
    FE = [evolve_genome(evader, M, 30) || _ <- lists:seq(1, 5)],
    {FP, FE}.

ctrl_loop(_G, R, _PP, _PE, _FP, _FE, _M, _BM, Traj) when length(Traj) >= R -> lists:reverse(Traj);
ctrl_loop(G, R, PP, PE, FP, FE, M, BM, Traj) ->
    PP1 = sel(pursuer, PP ++ mut(PP), FE, M),   %% pursuers evolve vs FROZEN evaders (static)
    PE1 = sel(evader, PE ++ mut(PE), FP, M),    %% evaders evolve vs FROZEN pursuers (static)
    Frame = {G, bench_pursuer(hd(PP1), M, BM), bench_evader(hd(PE1), M, BM)},
    ctrl_loop(G + 1, R, PP1, PE1, FP, FE, M, BM, [Frame | Traj]).

side_traj(Traj) ->
    Ps = [Pp || {_, Pp, _} <- Traj], Es = [Ep || {_, _, Ep} <- Traj],
    #{p => side(Ps), e => side(Es)}.

report_coupling(Fd, Coevo, Ctrl) ->
    emit(Fd, "~n-- Coupling control (coevolution vs FROZEN static opponent, same benchmark, matched n) --~n"),
    couple_side(Fd, "PURSUER", p, Coevo, Ctrl),
    couple_side(Fd, "EVADER ", e, Coevo, Ctrl),
    emit(Fd, "=> 'coevolutionary coupling / arms race' licensed for a side iff its coevo NET EXCEEDS its "
             "static-control NET (difference CI > 0).~n").

couple_side(Fd, Label, Side, Coevo, Ctrl) ->
    Co = net_of(Side, Coevo), St = net_of(Side, Ctrl),
    {DLo, DHi} = boot_ci_diff(Co, St),
    emit(Fd, "~s NET: coevo median=~.3f vs static median=~.3f | coevo-minus-static=~.3f CI[~.3f,~.3f] -> ~s~n",
         [Label, median(Co), median(St), median(Co) - median(St), DLo, DHi,
          coupling_verdict(DLo, DHi)]).

coupling_verdict(Lo, _Hi) when Lo > 0.0 -> "COUPLED (coevo > static)";
coupling_verdict(_Lo, Hi) when Hi < 0.0 -> "ANTI (static > coevo)";
coupling_verdict(_, _) -> "UNRESOLVED (CI includes 0)".

%% The gate's REQUIRED test: is the between-bracket difference in each side's NET-sustained progress
%% actually resolved, or do the per-bracket CIs merely straddle the threshold? With 3+ brackets this
%% becomes a TREND: report each side's NET median per bracket and the extreme-pair difference CI (the
%% widest, most resolvable). "Balance-contingent evader sustainment" needs a monotone decline AND a
%% resolved extreme-pair difference. Handles any N>=2 brackets.
cross_bracket(Fd, Collected) ->
    Ms = [M || {M, _} <- Collected],
    PMeds = [median(net_of(p, Rs)) || {_, Rs} <- Collected],
    EMeds = [median(net_of(e, Rs)) || {_, Rs} <- Collected],
    emit(Fd, "~n-- Cross-bracket trend (NET-sustained medians by bracket) --~n"),
    emit(Fd, "  m:           ~s~n", [row(Ms, fun(M) -> io_lib:format("m=~p", [M]) end)]),
    emit(Fd, "  pursuer NET: ~s~n", [row(PMeds, fun(X) -> io_lib:format("~.3f", [X]) end)]),
    emit(Fd, "  evader  NET: ~s~n", [row(EMeds, fun(X) -> io_lib:format("~.3f", [X]) end)]),
    {M1, R1} = hd(Collected), {Mn, Rn} = lists:last(Collected),
    {EdLo, EdHi} = boot_ci_diff(net_of(e, R1), net_of(e, Rn)),
    {PdLo, PdHi} = boot_ci_diff(net_of(p, R1), net_of(p, Rn)),
    emit(Fd, "  EVADER  extreme-pair NET (m=~p minus m=~p): ~.3f CI[~.3f,~.3f] -> ~s~n",
         [M1, Mn, median(net_of(e, R1)) - median(net_of(e, Rn)), EdLo, EdHi, resolved(EdLo, EdHi)]),
    emit(Fd, "  PURSUER extreme-pair NET (m=~p minus m=~p): ~.3f CI[~.3f,~.3f] -> ~s~n",
         [M1, Mn, median(net_of(p, R1)) - median(net_of(p, Rn)), PdLo, PdHi, resolved(PdLo, PdHi)]),
    emit(Fd, "  => balance-contingent evader sustainment needs a monotone evader decline AND a "
             "resolved extreme-pair difference.~n").

row(Xs, F) -> lists:flatten(lists:join("  ", [lists:flatten(F(X)) || X <- Xs])).

net_of(Side, Runs) ->
    [maps:get('end', maps:get(Side, X)) - maps:get(start, maps:get(Side, X)) || X <- Runs].

resolved(Lo, Hi) when Lo > 0.0; Hi < 0.0 -> "RESOLVED (excludes 0)";
resolved(_, _) -> "NOT resolved (includes 0)".


m_speed(M) -> element(2, lists:keyfind(M, 1, speed_grid())).

run_metrics(M, {Traj, Saved}) ->
    Ps = [Pp || {_, Pp, _} <- Traj], Es = [Ep || {_, _, Ep} <- Traj],
    #{p => side(Ps), e => side(Es), mt => master_tournament(Saved, M)}.

%%%============================================================================
%%% Master-tournament (pre-registered): distinguishes DISENGAGEMENT (monotone cross-generation
%%% dominance, ~0 intransitive triples) from CYCLING (intransitive triples above a noise band).
%%% Generation i "dominates" j iff i's pursuers catch j's evaders MORE than j's pursuers catch
%%% i's evaders, by more than a noise band. A cyclic triple A>B>C>A is structural cycling.
%%%============================================================================
master_tournament([], _M) -> #{n => 0, triples => 0, pairs => 0, later => 0, earlier => 0};
master_tournament(Saved, M) ->
    G = list_to_tuple(Saved),
    N = tuple_size(G),
    Idx = lists:seq(1, N),
    %% Precompute the N x N cross-generation capture matrix ONCE (Score(i,j) = P_i vs E_j), then all
    %% dominance/triple tests are pure lookups -- else Beats would re-simulate on every call.
    Cell = fun(I, J) ->
        {PPi, _} = element(I, G), {_, PEj} = element(J, G),
        mean([bit(caught(match({net, mk_net(P)}, {net, mk_net(E)}, St, M)))
              || P <- lists:sublist(PPi, 3), E <- lists:sublist(PEj, 3), St <- co_starts()])
    end,
    Mtx = maps:from_list([{{I, J}, Cell(I, J)} || I <- Idx, J <- Idx]),
    Mg = fun(I, J) -> maps:get({I, J}, Mtx) - maps:get({J, I}, Mtx) end,   %% net dominance margin
    Pairs = [{I, J} || I <- Idx, J <- Idx, I < J],
    %% Band SWEEP: is "no cycling" robust to the noise band, and are edges decisive (not band-swallowed)?
    Trip = fun(B) -> length([1 || A <- Idx, X <- Idx, C <- Idx, A < X, A =/= C, X =/= C,
                                  Mg(A, X) > B, Mg(X, C) > B, Mg(C, A) > B]) end,
    Dec = fun(B) -> length([1 || {I, J} <- Pairs, abs(Mg(I, J)) > B]) end,
    Later = length([1 || {I, J} <- Pairs, Mg(J, I) > 0.15]),
    Earlier = length([1 || {I, J} <- Pairs, Mg(I, J) > 0.15]),
    #{n => N, pairs => length(Pairs),
      triples => #{5 => Trip(0.05), 10 => Trip(0.10), 15 => Trip(0.15)},
      decisive => #{5 => Dec(0.05), 10 => Dec(0.10), 15 => Dec(0.15)},
      later => Later, earlier => Earlier}.

report_mt(Fd, Mts) ->
    NP = maps:get(pairs, hd(Mts)),
    T = fun(B) -> median([float(maps:get(B, maps:get(triples, X))) || X <- Mts]) end,
    D = fun(B) -> median([float(maps:get(B, maps:get(decisive, X))) || X <- Mts]) end,
    emit(Fd, "master-tournament (~p saved gens, ~p pairs/run):~n", [maps:get(n, hd(Mts)), NP]),
    emit(Fd, "  intransitive-triples median @band 0.05/0.10/0.15 = ~.1f / ~.1f / ~.1f  "
             "(0 => no cycling above that band)~n", [T(5), T(10), T(15)]),
    emit(Fd, "  decisive-edges median @band 0.05/0.10/0.15 = ~.1f / ~.1f / ~.1f of ~p  "
             "(band not swallowing edges)~n", [D(5), D(10), D(15), NP]),
    emit(Fd, "  later-dominates-earlier median=~.1f vs earlier-dominates-later median=~.1f (@0.15) => "
             "monotone directional progress~n",
         [median([float(maps:get(later, X)) || X <- Mts]),
          median([float(maps:get(earlier, X)) || X <- Mts])]).

side(Xs) -> #{start => hd(Xs), peak => lists:max(Xs), 'end' => lists:last(Xs)}.

report_side(Fd, Label, Sides) ->
    Starts = [maps:get(start, S) || S <- Sides],
    Peaks = [maps:get(peak, S) || S <- Sides],
    Ends = [maps:get('end', S) || S <- Sides],
    Prog = [maps:get(peak, S) - maps:get(start, S) || S <- Sides],     %% peak - start (ever rose)
    Ovf = [maps:get(peak, S) - maps:get('end', S) || S <- Sides],      %% peak - end (gave back)
    Net = [maps:get('end', S) - maps:get(start, S) || S <- Sides],     %% end - start (SUSTAINED)
    {PrLo, PrHi} = boot_ci(Prog), {OvLo, OvHi} = boot_ci(Ovf), {NtLo, NtHi} = boot_ci(Net),
    emit(Fd, "~s benchmark: start=~.3f peak=~.3f end=~.3f~n"
             "  rise(peak-start) med=~.3f CI[~.3f,~.3f] | gave-back(peak-end) med=~.3f CI[~.3f,~.3f] | "
             "NET-sustained(end-start) med=~.3f CI[~.3f,~.3f]~n",
         [Label, median(Starts), median(Peaks), median(Ends),
          median(Prog), PrLo, PrHi, median(Ovf), OvLo, OvHi, median(Net), NtLo, NtHi]).

verdict(Fd, Runs) ->
    PProg = [maps:get(peak, maps:get(p, M)) - maps:get(start, maps:get(p, M)) || M <- Runs],
    EProg = [maps:get(peak, maps:get(e, M)) - maps:get(start, maps:get(e, M)) || M <- Runs],
    PNet = [maps:get('end', maps:get(p, M)) - maps:get(start, maps:get(p, M)) || M <- Runs],
    ENet = [maps:get('end', maps:get(e, M)) - maps:get(start, maps:get(e, M)) || M <- Runs],
    {PpLo, _} = boot_ci(PProg), {EpLo, _} = boot_ci(EProg),
    {PnLo, _} = boot_ci(PNet), {EnLo, _} = boot_ci(ENet),
    PRises = PpLo > 0.03, ERises = EpLo > 0.03,          %% peak ever rose above start
    %% SUSTAINED = the END is clearly above the START (retained progress after any overfit give-back).
    %% This is the arms-race test: a transient peak that collapses back to start is NOT sustained.
    PSust = PnLo > 0.03, ESust = EnLo > 0.03,
    emit(Fd, "~n-- Verdict (POST-HOC lens: rise = peak-progress [pre-registered]; SUSTAINED = end-vs-start "
             "CI-lb > 0.03, introduced after the n=20 exploratory look; read WITH the master-tournament above) --~n"),
    emit(Fd, "pursuer: rises(peak-progress)=~p  net-sustained=~p~n", [PRises, PSust]),
    emit(Fd, "evader:  rises(peak-progress)=~p  net-sustained=~p~n", [ERises, ESust]),
    emit(Fd, "both-rise (pre-registered BRIEF-ARMS-RACE cell): ~p~n", [PRises andalso ERises]),
    emit(Fd, "~s~n", [classify_embodied(PSust, ESust, PRises, ERises)]).

%% Args: (PursuerSustains, EvaderSustains, PursuerRose, EvaderRose). SUSTAINS = end clearly > start.
classify_embodied(true, true, _, _) ->
    "RESULT=SUSTAINED TWO-SIDED PROGRESS: BOTH sides end clearly above start on their own axis (within-"
    "side; the two axes are incommensurable). Two-sided PROGRESS under coevolution, NOT a proven arms "
    "race -- reciprocal driving needs a decoupled solo control. Confirm monotone dominance (triples ~0) "
    "in the master-tournament above.";
classify_embodied(true, false, _, ER) ->
    "RESULT=PURSUER SUSTAINS, EVADER MARGINAL: both sides' peak-progress is disjoint from 0 (a brief two-"
    "sided rise), but only the PURSUER retains NET progress (end above start); the EVADER " ++ rose_text(ER) ++
    " then falls back to statistical indistinguishability from its start. No SUSTAINED two-sided progress "
    "at this bracket. Read WITH the master-tournament (monotone => progress not cycling) and the cross-"
    "bracket difference (is the evader's between-bracket gap actually resolved?).";
classify_embodied(false, true, PR, _) ->
    "RESULT=EVADER SUSTAINS, PURSUER MARGINAL: only the EVADER retains net progress; the PURSUER " ++
    rose_text(PR) ++ " then falls back to indistinguishability from its start.";
classify_embodied(false, false, PR, ER) when PR orelse ER ->
    "RESULT=OVERFIT / MUTUAL DISENGAGEMENT: at this bracket, NEITHER side ends above its start on the "
    "verified-graded benchmark; each champion PEAKS then DECLINES back to start (overfitting the current "
    "coevolving opponent, losing general competence). No sustained arms race -- neural pursuit-evasion "
    "does not arms-race at this near-crossover balance; a Flatland-scale world must ADD structure to escape it.";
classify_embodied(false, false, false, false) ->
    "RESULT=STASIS: neither side rises nor sustains; likely benchmark saturation or too-short R; investigate.".

rose_text(true) -> "rises to a transient peak";
rose_text(false) -> "does not rise".

coevo_run(M, R, BM) ->
    PP = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    PE = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    co_loop(1, R, PP, PE, M, BM, [], []).

co_loop(_G, R, _PP, _PE, _M, _BM, Traj, Saved) when length(Traj) >= R -> {lists:reverse(Traj), lists:reverse(Saved)};
co_loop(G, R, PP, PE, M, BM, Traj, Saved) ->
    PP1 = sel(pursuer, PP ++ mut(PP), PE, M),
    PE1 = sel(evader, PE ++ mut(PE), PP, M),
    Frame = {G, bench_pursuer(hd(PP1), M, BM), bench_evader(hd(PE1), M, BM)},
    Saved1 = save_pop(G rem 3, {PP1, PE1}, Saved),
    co_loop(G + 1, R, PP1, PE1, M, BM, [Frame | Traj], Saved1).

mut(Pop) -> [mutate(pick(Pop)) || _ <- lists:seq(1, ?CMU)].
save_pop(0, Pops, Saved) -> [Pops | Saved];
save_pop(_, _Pops, Saved) -> Saved.

%% Select top mu candidates by co-fitness vs K sampled opponents (opponent nets built once).
sel(Role, Cands, Opp, M) ->
    OppNets = [mk_net(pick(Opp)) || _ <- lists:seq(1, ?CK)],
    Scored = [{co_fit(Role, mk_net(G), OppNets, M), G} || G <- Cands],
    [G || {_F, G} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), ?CMU)].

%% Co-fitness uses the SAME continuous scores as the benchmark -> a smoother selection gradient
%% (fast-capture / long-survival) than binary win/loss over a handful of sampled opponents.
co_fit(pursuer, Net, EvaderNets, M) ->
    mean([pscore(match({net, Net}, {net, EN}, St, M)) || EN <- EvaderNets, St <- co_starts()]);
co_fit(evader, Net, PursuerNets, M) ->
    mean([escore(match({net, PN}, {net, Net}, St, M)) || PN <- PursuerNets, St <- co_starts()]).

%%%============================================================================
%%% The game (one match). Returns whether the pursuer captures within T steps.
%%%============================================================================
%% Returns {Caught, Step} -- Step = when captured (0..T), or T if survived. Enables a
%% CONTINUOUS metric (capture speed / survival time) that does not saturate like catch-rate.
match(PolP, PolE, {Pp0, Pe0}, M) -> play(PolP, PolE, Pp0, Pe0, ?T, M, 0).

play(_PolP, _PolE, Pp, Pe, 0, _M, Step) -> {cheb(Pp, Pe) =< 1, Step};
play(PolP, PolE, Pp, Pe, T, M, Step) ->
    caught_or_step(cheb(Pp, Pe) =< 1, PolP, PolE, Pp, Pe, T, M, Step).

caught_or_step(true, _PolP, _PolE, _Pp, _Pe, _T, _M, Step) -> {true, Step};
caught_or_step(false, PolP, PolE, Pp, Pe, T, M, Step) ->
    Pp2 = move(Pp, decide(PolP, Pp, Pe)),
    Pe2 = evader_move(skip(Step, M), Pe, decide(PolE, Pe, Pp)),
    play(PolP, PolE, Pp2, Pe2, T - 1, M, Step + 1).

caught({C, _Step}) -> C.
%% pursuit score: 1.0 for an instant capture -> 0.0 for none; a fast capture beats a slow one.
pscore({true, Step}) -> 1.0 - Step / ?T;
pscore({false, _Step}) -> 0.0.
%% survival score: 1.0 for surviving all T -> 0.0 for an instant capture.
escore({true, Step}) -> Step / ?T;
escore({false, _Step}) -> 1.0.

evader_move(true, Pe, _Dir) -> Pe;             %% skipped this step (pursuer is faster)
evader_move(false, Pe, Dir) -> move(Pe, Dir).

skip(_Step, none) -> false;
skip(Step, M) -> Step rem M =:= M - 1.

%% Policies decide a direction (0=N 1=E 2=S 3=W) from self + opponent positions.
decide({net, Net}, Self, Opp) -> argmax(network_evaluator:evaluate(Net, sense(Self, Opp)));
decide(greedy, Self, Opp) -> toward(delta(Self, Opp));    %% pursuer: close the distance
decide(flee, Self, Opp) -> away(delta(Self, Opp));        %% evader: open the distance
decide({greedy_p, P}, Self, Opp) -> rnd_or(P, toward(delta(Self, Opp)));  %% tunable-competence pursuer
decide({flee_p, P}, Self, Opp) -> rnd_or(P, away(delta(Self, Opp))).      %% tunable-competence evader

rnd_or(P, Dir) -> rnd_or_v(rand:uniform() < P, Dir).
rnd_or_v(true, _Dir) -> rand:uniform(4) - 1;
rnd_or_v(false, Dir) -> Dir.

toward({Dx, Dy}) -> toward_axis(abs(Dx) >= abs(Dy), Dx, Dy).
toward_axis(true, Dx, _Dy) when Dx > 0 -> 1;   %% E
toward_axis(true, _Dx, _Dy) -> 3;              %% W
toward_axis(false, _Dx, Dy) when Dy > 0 -> 0;  %% N
toward_axis(false, _Dx, _Dy) -> 2.             %% S

away({Dx, Dy}) -> away_axis(abs(Dx) >= abs(Dy), Dx, Dy).
away_axis(true, Dx, _Dy) when Dx > 0 -> 3;     %% opp east -> flee W
away_axis(true, _Dx, _Dy) -> 1;                %% flee E
away_axis(false, _Dx, Dy) when Dy > 0 -> 2;    %% opp north -> flee S
away_axis(false, _Dx, _Dy) -> 0.               %% flee N

%% opponent relative position (shortest wrap-around signed), for greedy/flee + sensing.
delta({Sx, Sy}, {Ox, Oy}) -> {wrap(Ox - Sx), wrap(Oy - Sy)}.
sense(Self, Opp) -> {Dx, Dy} = delta(Self, Opp), [Dx / (?W / 2), Dy / (?W / 2)].

wrap(D) -> over(((D rem ?W) + ?W) rem ?W).
over(M) when M > ?W div 2 -> M - ?W;
over(M) -> M.

move({X, Y}, 0) -> {X, mod(Y + 1)};
move({X, Y}, 1) -> {mod(X + 1), Y};
move({X, Y}, 2) -> {X, mod(Y - 1)};
move({X, Y}, 3) -> {mod(X - 1), Y}.
mod(V) -> ((V rem ?W) + ?W) rem ?W.

cheb({X1, Y1}, {X2, Y2}) -> max(td(X1, X2), td(Y1, Y2)).
td(A, B) -> min(mod(A - B), mod(B - A)).

m_for(S) -> {_, M} = lists:min([{abs(Sg - S), M} || {M, Sg} <- speed_grid()]), M.

argmax([H | T]) -> argmax(T, 1, H, 0).
argmax([], _I, _Best, BestI) -> BestI;
argmax([H | T], I, Best, _BestI) when H > Best -> argmax(T, I + 1, H, I);
argmax([_H | T], I, Best, BestI) -> argmax(T, I + 1, Best, BestI).

mk_net(G) -> network_evaluator:set_weights(network_evaluator:create_feedforward(2, [?HID], 4, tanh, tanh), G).
rand_genome() -> [rand:normal() || _ <- lists:seq(1, ?NP)].
mutate(G) -> [X + ?SIGMA * rand:normal() || X <- G].
pick(Pop) -> lists:nth(rand:uniform(length(Pop)), Pop).

bit(true) -> 1.0;
bit(false) -> 0.0.
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
    Reps = [median([lists:nth(rand:uniform(N), Vals) || _ <- lists:seq(1, N)]) || _ <- lists:seq(1, 2000)],
    S = lists:sort(Reps),
    {pctile(S, 0.025), pctile(S, 0.975)}.
pctile(S, P) ->
    N = length(S), I = max(1, min(N, round(P * N))),
    lists:nth(I, S) * 1.0.

%% Two-sample (independent) bootstrap CI of median(A) - median(B). If it excludes 0, the two
%% groups' medians differ; if it includes 0, the between-group difference is NOT resolved.
boot_ci_diff([], _) -> {0.0, 0.0};
boot_ci_diff(_, []) -> {0.0, 0.0};
boot_ci_diff(A, B) ->
    Na = length(A), Nb = length(B),
    Reps = [median([lists:nth(rand:uniform(Na), A) || _ <- lists:seq(1, Na)]) -
            median([lists:nth(rand:uniform(Nb), B) || _ <- lists:seq(1, Nb)]) || _ <- lists:seq(1, 2000)],
    S = lists:sort(Reps),
    {pctile(S, 0.025), pctile(S, 0.975)}.

emit(Fd, Fmt) -> emit(Fd, Fmt, []).
emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).
