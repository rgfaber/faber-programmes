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

-export([calibrate/0, representability/1, representability/0, verify_benchmark/0, coevo_pilot/0, run/0, run/1]).

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
    R = [match(PolP, PolE, St, M) || St <- starts()],
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

%% A subset of starts for the (cheaper) representability EA fitness (every 5th start).
rep_starts() -> [St || {I, St} <- lists:zip(lists:seq(1, length(starts())), starts()), I rem 5 =:= 0].

%% pursuer role: catch-rate of the net pursuer vs the flee evader (want high).
role_fit(pursuer, G, M) ->
    Net = mk_net(G),
    mean([bit(match({net, Net}, flee, St, M)) || St <- rep_starts()]);
%% evader role: survival of the net evader vs the greedy pursuer (want high).
role_fit(evader, G, M) ->
    Net = mk_net(G),
    mean([bit(not match(greedy, {net, Net}, St, M)) || St <- rep_starts()]).

%%%============================================================================
%%% STEP 3a — Graded benchmark: a difficulty-tunable greedy/flee family (not a
%%% degenerate pilot HoF). p = probability of a RANDOM move; p=0.8 weak .. p=0.0 strong.
%%%============================================================================
bench_evaders() -> [{flee_p, P} || P <- [0.8, 0.6, 0.4, 0.2, 0.0]].
bench_pursuers() -> [{greedy_p, P} || P <- [0.8, 0.6, 0.4, 0.2, 0.0]].
bench_starts() -> [St || {I, St} <- lists:zip(lists:seq(1, length(starts())), starts()), I rem 6 =:= 0].
co_starts() -> [St || {I, St} <- lists:zip(lists:seq(1, length(starts())), starts()), I rem 10 =:= 0].

%% VERIFY the benchmark is difficulty-graded: a pure-greedy probe's catch-rate against the
%% flee rungs must be monotone and spread; a pure-flee probe's survival against the greedy rungs likewise.
verify_benchmark() ->
    M = ?SSTAR_M,
    io:format("== EXP-057 benchmark grading (s*=~.2f) ==~n", [?W / ?W * 1.083]),
    io:format("pure-greedy catch-rate vs flee rungs p=[0.8..0.0]:~n"),
    Pc = [{P, mean([bit(match(greedy, {flee_p, P}, St, M)) || St <- bench_starts()])} || {flee_p, P} <- bench_evaders()],
    [io:format("  flee p=~.1f: catch=~.3f~n", [P, C]) || {P, C} <- Pc],
    io:format("pure-flee survival vs greedy rungs p=[0.8..0.0]:~n"),
    Es = [{P, mean([bit(not match({greedy_p, P}, flee, St, M)) || St <- bench_starts()])} || {greedy_p, P} <- bench_pursuers()],
    [io:format("  greedy p=~.1f: survive=~.3f~n", [P, S]) || {P, S} <- Es],
    ok.

%% Champion benchmark readings (progress signals; stochastic rungs -> average over rungs x starts).
bench_pursuer(G, M) ->
    Net = mk_net(G),
    mean([bit(match({net, Net}, R, St, M)) || R <- bench_evaders(), St <- bench_starts()]).
bench_evader(G, M) ->
    Net = mk_net(G),
    mean([bit(not match(R, {net, Net}, St, M)) || R <- bench_pursuers(), St <- bench_starts()]).

%%%============================================================================
%%% STEP 3b — Coevolution at s*. Progress measured against the FIXED graded benchmark
%%% (NOT co-fitness). One PILOT run reports the trajectories + timing to set n.
%%%============================================================================
coevo_pilot() ->
    io:format("== EXP-057 coevolution pilot at s*=1.083 (m=~p), R=25 ==~n", [?SSTAR_M]),
    T0 = erlang:monotonic_time(millisecond),
    {Traj, _Saved} = coevo_run(?SSTAR_M, 25),
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

run(#{n := N, r := R}) ->
    {ok, Fd} = file:open("exp057_feed.txt", [write]),
    emit(Fd, "== EXP-057 embodied pursuit-evasion coevolution at s*=1.083 (m=~p) ==~n", [?SSTAR_M]),
    emit(Fd, "config: net=[2,6,4] mu=~p K=~p R=~p n=~p; benchmark = graded tunable greedy/flee family~n",
         [?CMU, ?CK, R, N]),
    Runs = [run_metrics(coevo_run(?SSTAR_M, R)) || _ <- lists:seq(1, N)],
    report_side(Fd, "PURSUER", [maps:get(p, M) || M <- Runs]),
    report_side(Fd, "EVADER ", [maps:get(e, M) || M <- Runs]),
    verdict(Fd, Runs),
    file:close(Fd),
    ok.

run_metrics({Traj, _Saved}) ->
    Ps = [Pp || {_, Pp, _} <- Traj], Es = [Ep || {_, _, Ep} <- Traj],
    #{p => side(Ps), e => side(Es)}.

side(Xs) -> #{start => hd(Xs), peak => lists:max(Xs), 'end' => lists:last(Xs)}.

report_side(Fd, Label, Sides) ->
    Starts = [maps:get(start, S) || S <- Sides],
    Peaks = [maps:get(peak, S) || S <- Sides],
    Ends = [maps:get('end', S) || S <- Sides],
    Prog = [maps:get(peak, S) - maps:get(start, S) || S <- Sides],     %% peak - start
    Ovf = [maps:get(peak, S) - maps:get('end', S) || S <- Sides],      %% peak - end (overfit drop)
    {PrLo, PrHi} = boot_ci(Prog), {OvLo, OvHi} = boot_ci(Ovf),
    emit(Fd, "~s benchmark: start=~.3f peak=~.3f end=~.3f | peak-progress median=~.3f CI[~.3f,~.3f] | "
             "overfit-drop(peak-end) median=~.3f CI[~.3f,~.3f]~n",
         [Label, median(Starts), median(Peaks), median(Ends), median(Prog), PrLo, PrHi,
          median(Ovf), OvLo, OvHi]).

verdict(Fd, Runs) ->
    PProg = [maps:get(peak, maps:get(p, M)) - maps:get(start, maps:get(p, M)) || M <- Runs],
    EProg = [maps:get(peak, maps:get(e, M)) - maps:get(start, maps:get(e, M)) || M <- Runs],
    POvf = [maps:get(peak, maps:get(p, M)) - maps:get('end', maps:get(p, M)) || M <- Runs],
    EOvf = [maps:get(peak, maps:get(e, M)) - maps:get('end', maps:get(e, M)) || M <- Runs],
    {PpLo, _} = boot_ci(PProg), {EpLo, _} = boot_ci(EProg),
    {PoLo, _} = boot_ci(POvf), {EoLo, _} = boot_ci(EOvf),
    PRises = PpLo > 0.03, ERises = EpLo > 0.03,          %% peak ever rose above start
    POverfits = PoLo > 0.03, EOverfits = EoLo > 0.03,    %% then fell back (peak >> end)
    %% SUSTAINED progress = rose AND held (did not overfit-collapse). An arms race needs both sustained.
    PSust = PRises andalso (not POverfits),
    ESust = ERises andalso (not EOverfits),
    emit(Fd, "~n-- Verdict --~n"),
    emit(Fd, "pursuer: rises=~p overfits=~p -> SUSTAINS=~p~n", [PRises, POverfits, PSust]),
    emit(Fd, "evader:  rises=~p overfits=~p -> SUSTAINS=~p~n", [ERises, EOverfits, ESust]),
    emit(Fd, "~s~n", [classify_embodied(PSust, ESust, POverfits, EOverfits)]).

classify_embodied(false, false, PO, EO) when PO orelse EO ->
    "RESULT=OVERFIT / DISENGAGEMENT: at the competent-play crossover s*, NEITHER side sustains progress "
    "against the fixed graded benchmark; both champions PEAK early then DECLINE (they overfit to the "
    "current coevolving opponent and lose general competence). No two-sided arms race. This is the "
    "honest embodied result -- neural pursuit-evasion does not sustain an arms race even at the balance "
    "where competent play is 50/50; a Flatland-scale world must ADD structure (space, resources, many "
    "agents) to escape it.";
classify_embodied(true, true, _, _) ->
    "RESULT=ARMS RACE: BOTH sides sustain benchmark progress at s* -- a two-sided gradient exists; "
    "sample densely around s* next.";
classify_embodied(true, false, _, _) ->
    "RESULT=DISENGAGEMENT toward PURSUER: only the pursuer sustains benchmark progress; the evader's "
    "gradient dies.";
classify_embodied(false, true, _, _) ->
    "RESULT=DISENGAGEMENT toward EVADER: only the evader sustains benchmark progress; the pursuer's "
    "gradient dies.";
classify_embodied(false, false, false, false) ->
    "RESULT=STASIS: neither side progresses nor overfits meaningfully; likely benchmark saturation or "
    "too-short R; investigate.".

coevo_run(M, R) ->
    PP = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    PE = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    co_loop(1, R, PP, PE, M, [], []).

co_loop(_G, R, _PP, _PE, _M, Traj, Saved) when length(Traj) >= R -> {lists:reverse(Traj), lists:reverse(Saved)};
co_loop(G, R, PP, PE, M, Traj, Saved) ->
    PP1 = sel(pursuer, PP ++ mut(PP), PE, M),
    PE1 = sel(evader, PE ++ mut(PE), PP, M),
    Frame = {G, bench_pursuer(hd(PP1), M), bench_evader(hd(PE1), M)},
    Saved1 = save_pop(G rem 5, {PP1, PE1}, Saved),
    co_loop(G + 1, R, PP1, PE1, M, [Frame | Traj], Saved1).

mut(Pop) -> [mutate(pick(Pop)) || _ <- lists:seq(1, ?CMU)].
save_pop(0, Pops, Saved) -> [Pops | Saved];
save_pop(_, _Pops, Saved) -> Saved.

%% Select top mu candidates by co-fitness vs K sampled opponents (opponent nets built once).
sel(Role, Cands, Opp, M) ->
    OppNets = [mk_net(pick(Opp)) || _ <- lists:seq(1, ?CK)],
    Scored = [{co_fit(Role, mk_net(G), OppNets, M), G} || G <- Cands],
    [G || {_F, G} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), ?CMU)].

co_fit(pursuer, Net, EvaderNets, M) ->
    mean([bit(match({net, Net}, {net, EN}, St, M)) || EN <- EvaderNets, St <- co_starts()]);
co_fit(evader, Net, PursuerNets, M) ->
    mean([bit(not match({net, PN}, {net, Net}, St, M)) || PN <- PursuerNets, St <- co_starts()]).

%%%============================================================================
%%% The game (one match). Returns whether the pursuer captures within T steps.
%%%============================================================================
match(PolP, PolE, {Pp0, Pe0}, M) -> play(PolP, PolE, Pp0, Pe0, ?T, M, 0).

play(_PolP, _PolE, Pp, Pe, 0, _M, _Step) -> cheb(Pp, Pe) =< 1;
play(PolP, PolE, Pp, Pe, T, M, Step) ->
    caught_or_step(cheb(Pp, Pe) =< 1, PolP, PolE, Pp, Pe, T, M, Step).

caught_or_step(true, _PolP, _PolE, _Pp, _Pe, _T, _M, _Step) -> true;
caught_or_step(false, PolP, PolE, Pp, Pe, T, M, Step) ->
    Pp2 = move(Pp, decide(PolP, Pp, Pe)),
    Pe2 = evader_move(skip(Step, M), Pe, decide(PolE, Pe, Pp)),
    play(PolP, PolE, Pp2, Pe2, T - 1, M, Step + 1).

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

emit(Fd, Fmt) -> emit(Fd, Fmt, []).
emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).
