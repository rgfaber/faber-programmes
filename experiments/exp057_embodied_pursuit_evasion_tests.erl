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

-export([calibrate/0, representability/1, representability/0]).

-define(W, 9).
-define(T, 40).
-define(HID, 6).
-define(NP, 6 * 2 + 6 + 4 * 6 + 4).     %% [2,6,4] genome length = 46
-define(SIGMA, 0.2).

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
decide(flee, Self, Opp) -> away(delta(Self, Opp)).        %% evader: open the distance

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
