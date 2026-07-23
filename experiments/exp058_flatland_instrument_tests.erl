%%%-------------------------------------------------------------------
%%% @doc EXP-058 — Flatland rung 1 (INSTRUMENT): kill gates.
%%%
%%% Pre-registration (DESIGN-gated): experiments/exp058_flatland_ecological_arms_race.md
%%% World engine: faber-tweann/src/flatland_sim.erl (pure, process-free).
%%% Nets: network_evaluator forward passes, process-free (the 057 path).
%%%
%%% This module implements ONLY the instrument kill gates the gate demanded run first:
%%%   0a -- the scape works: a hand-coded greedy-forager gains energy / eats plants,
%%%         a random agent does not; energy accounting + plant regrowth behave.
%%%   0b -- REPRESENTABILITY: a [5,6,4] net EVOLVES competent FORAGING (energy/plants
%%%         >> random, approaching the greedy-forager) AND competent HUNTING (capture
%%%         >> random). If it cannot, the front is INVALID at rung 1 (capacity limit).
%%%
%%% Sensing/geometry are IDENTICAL to 057 (9x9 torus, 4-way argmax, relative-position
%%% modality); the ONLY addition is the energy economy (plants + eating + death).
%%% NO coevolution / coupling claim here (that is exp059).
%%% @end
%%%-------------------------------------------------------------------
-module(exp058_flatland_instrument_tests).

-export([gate_0a/0, gate_0b/0, run/0]).

-define(W, 9).
-define(T, 40).
-define(HID, 6).
-define(NP, 5 * ?HID + ?HID + 4 * ?HID + 4).   %% [5,6,4] genome length = 64
-define(SIGMA, 0.2).

%% Energy economy knobs -- pinned by ARGUMENT (pre-reg), not tuned to an outcome:
%% density lets a competent forager sustain but a blind one starve; an episode with
%% no eating runs down E0 in ~E0/EM steps (< T), so foraging is load-bearing.
-define(NPLANTS, 8).
-define(E0, 20).
-define(EM, 1).      %% energy cost per step
-define(EP, 4).      %% energy gained per plant

%% Hunt-gate speed edge: the prey skips 1 move every M steps -> pursuer faster (as 057's
%% representability at a pursuer-favoured speed, so competent hunting is even POSSIBLE).
-define(HUNT_M, 2).

%%%============================================================================
%%% Starts (deterministic, as 057): avatar/plant layouts over many seeds
%%%============================================================================
cells() -> [{X, Y} || X <- lists:seq(0, ?W - 1), Y <- lists:seq(0, ?W - 1)].

%% A deterministic family of forage layouts: forager at {0,0}, NPLANTS plants placed
%% by a fixed stride so a probe faces a spread of configurations (no rand in the gate).
forage_starts() ->
    [plants_at(Off) || Off <- lists:seq(1, 12)].
plants_at(Off) ->
    All = [C || C <- cells(), C =/= {0, 0}],
    Step = max(1, length(All) div ?NPLANTS),
    Idx = [(Off + I * Step) rem length(All) || I <- lists:seq(0, ?NPLANTS - 1)],
    lists:usort([lists:nth(J + 1, All) || J <- Idx]).

%% Hunt starts: predator at {0,0}, prey at every cell beyond capture range (as 057).
hunt_starts() ->
    [{{0, 0}, {X, Y}} || X <- lists:seq(0, ?W - 1), Y <- lists:seq(0, ?W - 1),
                         flatland_sim:cheb({0, 0}, {X, Y}, ?W) > 1].

%%%============================================================================
%%% GATE 0a -- the scape works
%%%============================================================================
gate_0a() ->
    io:format("== EXP-058 gate 0a: the scape works (energy economy + plant regrowth) ==~n"),
    io:format("world ~px~p torus, plants=~p, E0=~p, Em=~p, Ep=~p, T=~p~n",
              [?W, ?W, ?NPLANTS, ?E0, ?EM, ?EP, ?T]),
    G = [forage(greedy_forage, Plants) || Plants <- forage_starts()],
    R = [forage(random, Plants) || Plants <- forage_starts()],
    io:format("greedy-forager: plants eaten mean=~.2f, final-energy mean=~.2f, survived ~p/~p~n",
              [mean([E || {_, E, _} <- G]), mean([En || {En, _, _} <- G]),
               length([1 || {_, _, S} <- G, S]), length(G)]),
    io:format("random agent  : plants eaten mean=~.2f, final-energy mean=~.2f, survived ~p/~p~n",
              [mean([E || {_, E, _} <- R]), mean([En || {En, _, _} <- R]),
               length([1 || {_, _, S} <- R, S]), length(R)]),
    Ok = mean([E || {_, E, _} <- G]) > 2.0 * max(0.1, mean([E || {_, E, _} <- R])),
    io:format("0a PASS (greedy eats >= 2x random): ~p~n", [Ok]),
    Ok.

%%%============================================================================
%%% GATE 0b -- representability: a net evolves foraging AND hunting
%%%============================================================================
gate_0b() ->
    io:format("~n== EXP-058 gate 0b: representability (net evolves foraging AND hunting) ==~n"),
    HandF = mean([E || {_, E, _} <- [forage(greedy_forage, P) || P <- forage_starts()]]),
    RandF = mean([E || {_, E, _} <- [forage(random, P) || P <- forage_starts()]]),
    NetF = evolve(forage, 80, 20),
    io:format("FORAGING plants-eaten: hand-coded greedy=~.2f, random=~.2f, evolved NET=~.2f~n",
              [HandF, RandF, NetF]),
    HandH = catch_rate(greedy_hunt),
    RandH = catch_rate(random),
    NetH = evolve(hunt, 40, 14),
    io:format("HUNTING  capture-rate: hand-coded greedy=~.3f, random=~.3f, evolved NET=~.3f~n",
              [HandH, RandH, NetH]),
    OkF = NetF > 0.6 * max(HandF, 0.1) andalso NetF > 1.5 * max(RandF, 0.1),
    OkH = NetH > 0.6 * max(HandH, 0.1) andalso NetH > 1.5 * max(RandH, 0.05),
    io:format("0b PASS (net reaches >=60% hand-coded and clearly beats random, both capabilities): "
              "forage=~p hunt=~p~n", [OkF, OkH]),
    OkF andalso OkH.

run() ->
    A = gate_0a(),
    B = gate_0b(),
    io:format("~n== EXP-058 rung-1 instrument kill gates: 0a=~p 0b=~p -> INSTRUMENT ~s ==~n",
              [A, B, case A andalso B of true -> "VALIDATED"; false -> "INVALID (fix before dynamics)" end]),
    A andalso B.

%%%============================================================================
%%% Evolution (mu+lambda, the 057 pattern) for a capability
%%%============================================================================
evolve(Cap, Gens, Mu) ->
    Pop = [rand_genome() || _ <- lists:seq(1, Mu)],
    best(Cap, Gens, Mu, Pop, 0.0).

best(_Cap, 0, _Mu, _Pop, B) -> B;
best(Cap, G, Mu, Pop, B) ->
    Off = [mutate(pick(Pop)) || _ <- lists:seq(1, Mu)],
    Scored = [{fit(Cap, Gm), Gm} || Gm <- Pop ++ Off],
    Ranked = lists:reverse(lists:keysort(1, Scored)),
    Top = [Gm || {_F, Gm} <- lists:sublist(Ranked, Mu)],
    best(Cap, G - 1, Mu, Top, max(B, element(1, hd(Ranked)))).

%% Foraging fitness = mean plants eaten over ALL layouts (smooth selection signal).
fit(forage, Gm) ->
    Net = mk_net(Gm),
    mean([E || {_, E, _} <- [forage({net, Net}, P) || P <- forage_starts()]]);
%% Hunting fitness = capture-rate of the net predator vs the flee prey (subset of starts).
fit(hunt, Gm) ->
    Net = mk_net(Gm),
    crate({net, Net}, rep(hunt_starts())).

rep(L) -> [X || {I, X} <- lists:zip(lists:seq(1, length(L)), L), I rem 3 =:= 0].

%%%============================================================================
%%% Forage episode (single avatar, no predator): returns {FinalEnergy, Eaten, Survived}
%%%============================================================================
forage(Policy, Plants0) ->
    forage_loop(Policy, Plants0, {0, 0}, ?E0, 0, ?T).

forage_loop(_P, _Plants, _Pos, En, Eaten, 0) -> {En, Eaten, En > 0};
forage_loop(_P, _Plants, _Pos, En, Eaten, _T) when En =< 0 -> {0, Eaten, false};
forage_loop(Policy, Plants, Pos, En, Eaten, T) ->
    S = flatland_sim:sense(?W, Pos, none, Plants, En, ?E0),
    Dir = decide(Policy, S, Pos, none, Plants),
    Pos2 = flatland_sim:move(Pos, Dir, ?W),
    {Plants2, Ate} = try_eat(Plants, Pos2),
    En2 = En - ?EM + case Ate of true -> ?EP; false -> 0 end,
    forage_loop(Policy, Plants2, Pos2, En2, Eaten + bit(Ate), T - 1).

%% Eat-on-contact: if a plant is on Pos, remove it and regrow one at a deterministic free cell.
try_eat(Plants, Pos) ->
    try_eat(lists:member(Pos, Plants), Plants, Pos).
try_eat(false, Plants, _Pos) -> {Plants, false};
try_eat(true, Plants, Pos) ->
    Rest = lists:delete(Pos, Plants),
    {[regrow(Rest, Pos) | Rest], true}.

%% Regrow at the first free cell in a fixed scan offset by the eaten position (no rand -> deterministic).
regrow(Plants, {X, Y}) ->
    Occupied = [{X, Y} | Plants],
    Scan = [C || C <- cells(), not lists:member(C, Occupied)],
    Base = (X * ?W + Y) rem max(1, length(Scan)),
    lists:nth(Base + 1, Scan).

%%%============================================================================
%%% Hunt episode (net/hand predator vs flee prey, pursuer speed edge M): capture?
%%%============================================================================
catch_rate(Policy) -> crate(Policy, hunt_starts()).
crate(Policy, Starts) ->
    R = [caught(hunt(Policy, flee, PP, PE, 0)) || {PP, PE} <- Starts],
    length([1 || true <- R]) / length(R).

hunt(PredPol, PreyPol, PP, PE, Step) ->
    hunt_loop(PredPol, PreyPol, PP, PE, Step, ?T).

hunt_loop(_PredPol, _PreyPol, PP, PE, _Step, 0) -> flatland_sim:cheb(PP, PE, ?W) =< 1;
hunt_loop(PredPol, PreyPol, PP, PE, Step, T) ->
    caught_or_step(flatland_sim:cheb(PP, PE, ?W) =< 1, PredPol, PreyPol, PP, PE, Step, T).

caught_or_step(true, _PredPol, _PreyPol, _PP, _PE, _Step, _T) -> true;
caught_or_step(false, PredPol, PreyPol, PP, PE, Step, T) ->
    Sp = flatland_sim:sense(?W, PP, PE, [], ?E0, ?E0),
    Se = flatland_sim:sense(?W, PE, PP, [], ?E0, ?E0),
    PP2 = flatland_sim:move(PP, decide(PredPol, Sp, PP, PE, []), ?W),
    %% prey skips 1 move every M steps -> the pursuer is faster (M=2 => 2x)
    PE2 = case skip(Step, ?HUNT_M) of
              true -> PE;
              false -> flatland_sim:move(PE, decide(PreyPol, Se, PE, PP, []), ?W)
          end,
    hunt_loop(PredPol, PreyPol, PP2, PE2, Step + 1, T - 1).

skip(Step, M) -> Step rem M =:= M - 1.
caught(C) -> C.

%%%============================================================================
%%% Policies
%%%============================================================================
%% Self, Opp, Plants give the world context; S is the sensor vector (nets use S).
decide({net, Net}, S, _Self, _Opp, _Plants) -> argmax(network_evaluator:evaluate(Net, S));
decide(greedy_forage, _S, Self, _Opp, Plants) ->
    case flatland_sim:nearest(Self, Plants, ?W) of
        none -> 0;
        P -> flatland_sim:toward(Self, P, ?W)
    end;
decide(greedy_hunt, _S, Self, Opp, _Plants) -> flatland_sim:toward(Self, Opp, ?W);
decide(flee, _S, Self, Opp, _Plants) -> flatland_sim:away(Self, Opp, ?W);
decide(random, _S, _Self, _Opp, _Plants) -> rand:uniform(4) - 1.

%%%============================================================================
%%% Net helpers (the 057 process-free path) + small stats
%%%============================================================================
mk_net(G) ->
    network_evaluator:set_weights(
        network_evaluator:create_feedforward(5, [?HID], 4, tanh, tanh), G).
rand_genome() -> [rand:normal() || _ <- lists:seq(1, ?NP)].
mutate(G) -> [X + ?SIGMA * rand:normal() || X <- G].
pick(Pop) -> lists:nth(rand:uniform(length(Pop)), Pop).

argmax([H | T]) -> argmax(T, H, 0, 1).
argmax([], _Best, BestI, _I) -> BestI;
argmax([H | T], Best, _BestI, I) when H > Best -> argmax(T, H, I, I + 1);
argmax([_H | T], Best, BestI, I) -> argmax(T, Best, BestI, I + 1).

bit(true) -> 1;
bit(false) -> 0.
mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).
