%%%-------------------------------------------------------------------
%%% @doc EXP-062 — Flatland rung 3b PRECONDITION, Part A: PERSISTENCE.
%%%
%%% Pre-registration (DESIGN-gated, redesigned): exp062_flatland_evolved_restraint.md
%%% Engine: faber-tweann flatland_sim. Extends the exp061 open-population sim with a fixed PRUDENT
%%% predator (prey-density THRESHOLD theta: hunt the nearest prey only if LOCAL prey count within
%%% perception >= theta, else wander -- sparing depleted patches; costless in abundance, does NOT
%%% self-starve). Adds a PREDATOR-GENERATIONS counter (cumulative births / mean standing count).
%%%
%%% Question: does any (theta, density) regime sustain coexistence for MANY predator generations
%%% (>= G_MIN), where fixed-GREEDY (061) collapsed in ~39 steps (0-1 generations)? If not, the open
%%% substrate admits no eco-evolutionary timescale -> signed negative, rung 3b stops.
%%% @end
%%%-------------------------------------------------------------------
-module(exp062_flatland_persistence_tests).

-export([calibrate/0, run/0, run/1]).

-define(W, 40).
-define(N0_PREY, 90).
-define(DANGER, 4).
-define(E0, 20).
-define(EM, 1).
-define(EP, 7).
-define(REPRO_PREY, 16).
-define(NMAX_PREY, 400).
-define(E0P, 30).
-define(EMP, 1).
-define(EPRED, 14).
-define(REPRO_PRED, 34).
-define(NMAX_PRED, 120).
-define(SATIATE, 4).
-define(PERCEPT, 5).          %% predator perception radius (also the "local patch" for the theta count)
-define(H, 4000).             %% long horizon so many predator generations can elapse
-define(GMIN, 20).            %% "persists" = coexists AND >= GMIN predator generations before extinction

rand_cell() -> {rand:uniform(?W) - 1, rand:uniform(?W) - 1}.
pred_moves(Step) -> Step rem 5 =/= 4.   %% predator ~0.8 speed (fixed)

%%%============================================================================
%%% One step: prey forage/flee + eat; PRUDENT predators hunt+eat+reproduce; returns pred births this step
%%%============================================================================
%% Pe = {ReproPred, Epred, Satiate, Percept}: predator energetics + stabilisers (swept for persistence,
%% incl. the 061 strong-stabiliser corner satiate=12/percept=2).
step(#{plants := Pl, preys := Preys, preds := Preds}, Np, Theta, Step, {RP, EPd, Sat, Perc}) ->
    PredPos = [P || {P, _, _} <- Preds],
    {Preys1, Pl1} = move_prey(Preys, PredPos, Pl),
    {Preds1, Preys2} = move_preds(Preds, Preys1, pred_moves(Step), Theta, EPd, Sat, Perc),
    {Preys3, _} = grow(reproduce_prey(Preys2, ?REPRO_PREY)),
    {Preds2, Births} = grow(reproduce_pred(Preds1, RP)),
    {#{plants => regrow(Pl1, Np), preys => cull(alive(Preys3), ?NMAX_PREY),
       preds => cull(alive(Preds2), ?NMAX_PRED)}, Births}.

move_prey(Preys, PredPos, Pl) ->
    lists:foldl(
      fun({Pos, En}, {Acc, PlAcc}) ->
              Pos2 = flatland_sim:move(Pos, prey_decide(Pos, PredPos, PlAcc), ?W),
              {Ate, PlAcc2} = eat_plant(Pos2, PlAcc),
              {[{Pos2, En - ?EM + case Ate of true -> ?EP; false -> 0 end} | Acc], PlAcc2}
      end, {[], Pl}, Preys).
prey_decide(Pos, PredPos, Pl) ->
    case flatland_sim:nearest(Pos, PredPos, ?W) of
        NP when NP =/= none, PredPos =/= [] ->
            case flatland_sim:cheb(Pos, NP, ?W) =< ?DANGER of
                true -> flatland_sim:away(Pos, NP, ?W);
                false -> forage(Pos, Pl)
            end;
        _ -> forage(Pos, Pl)
    end.
forage(Pos, Pl) -> case flatland_sim:nearest(Pos, Pl, ?W) of none -> 0; T -> flatland_sim:toward(Pos, T, ?W) end.
eat_plant(Pos, Pl) -> case lists:member(Pos, Pl) of true -> {true, lists:delete(Pos, Pl)}; false -> {false, Pl} end.

%% PRUDENT predator: hunt the nearest prey only if LOCAL prey count (within PERCEPT) >= Theta; else wander.
move_preds(Preds, Preys, DoMove, Theta, Epd, Sat, Perc) ->
    lists:foldl(
      fun({Pos, En, Cd}, {Acc, PreyAcc}) when Cd > 0 ->
              {[{flatland_sim:move(Pos, rand:uniform(4) - 1, ?W), En - ?EMP, Cd - 1} | Acc], PreyAcc};
         ({Pos, En, _Cd}, {Acc, PreyAcc}) ->
              PreyPos = [P || {P, _} <- PreyAcc],
              Local = length([1 || Q <- PreyPos, flatland_sim:cheb(Pos, Q, ?W) =< Perc]),
              Pos2 = case DoMove andalso Local >= Theta of
                         true -> flatland_sim:move(Pos, flatland_sim:toward(Pos, flatland_sim:nearest(Pos, PreyPos, ?W), ?W), ?W);
                         false -> flatland_sim:move(Pos, rand:uniform(4) - 1, ?W)
                     end,
              {Eaten, PreyAcc2} = eat_prey(Pos2, PreyAcc),
              {En2, Cd2} = case Eaten of true -> {En - ?EMP + Epd, Sat}; false -> {En - ?EMP, 0} end,
              {[{Pos2, En2, Cd2} | Acc], PreyAcc2}
      end, {[], Preys}, Preds).
eat_prey(Pos, Preys) ->
    case [Py || {PyPos, _} = Py <- Preys, flatland_sim:cheb(Pos, PyPos, ?W) =< 1] of
        [] -> {false, Preys};
        [V | _] -> {true, lists:delete(V, Preys)}
    end.

%% reproduce; the second list element of grow/1 is the number of BIRTHS (offspring) produced.
reproduce_prey(Agents, T) -> [repro2({Pos, En}, T) || {Pos, En} <- Agents].
reproduce_pred(Agents, T) -> [repro3({Pos, En, Cd}, T) || {Pos, En, Cd} <- Agents].
repro2({Pos, En}, T) when En >= T -> C = En div 2, {two, {Pos, En - C}, {childpos(Pos), C}};
repro2(A, _T) -> {one, A}.
repro3({Pos, En, Cd}, T) when En >= T -> C = En div 2, {two, {Pos, En - C, Cd}, {childpos(Pos), C, 0}};
repro3(A, _T) -> {one, A}.
childpos(Pos) -> flatland_sim:move(Pos, rand:uniform(4) - 1, ?W).
%% flatten the repro results into an agent list + count births
grow(Rs) -> lists:foldl(fun({one, A}, {L, B}) -> {[A | L], B};
                           ({two, P, Ch}, {L, B}) -> {[P, Ch | L], B + 1} end, {[], 0}, Rs).

alive(Agents) -> [A || A <- Agents, element(2, A) > 0].
cull(Agents, Nmax) ->
    case length(Agents) > Nmax of
        true -> lists:sublist(lists:reverse(lists:keysort(2, Agents)), Nmax);
        false -> Agents
    end.
regrow(Pl, N) when length(Pl) >= N -> Pl;
regrow(Pl, N) -> C = rand_cell(), regrow(case lists:member(C, Pl) of true -> Pl; false -> [C | Pl] end, N).

%%%============================================================================
%%% Trajectory: {prey, pred, cumulative-pred-births} per step; run until H or extinction
%%%============================================================================
run_world(Seed, Np, NPred0, Theta) -> run_world(Seed, Np, NPred0, Theta, {?REPRO_PRED, ?EPRED, ?SATIATE, ?PERCEPT}).
run_world(Seed, Np, NPred0, Theta, Pe) ->
    _ = rand:seed(exsss, {Seed, Seed * 7 + 1, Seed * 13 + 3}),
    W0 = #{plants => [rand_cell() || _ <- lists:seq(1, Np)],
           preys => [{rand_cell(), ?E0} || _ <- lists:seq(1, ?N0_PREY)],
           preds => [{rand_cell(), ?E0P, 0} || _ <- lists:seq(1, NPred0)]},
    loop(W0, Np, Theta, Pe, ?H, 0, 0, 0).
%% accumulate cumulative births + a running sum of pred counts (for mean standing count -> generations)
loop(_W, _Np, _Th, _Pe, 0, _Step, Births, SumPred) -> {survived, Births, SumPred, ?H};
loop(#{preys := Py, preds := Pd} = W, Np, Th, Pe, H, Step, Births, SumPred) ->
    case Py =:= [] orelse Pd =:= [] of
        true -> {extinct, Births, SumPred, Step};
        false ->
            {W2, B} = step(W, Np, Th, Step, Pe),
            loop(W2, Np, Th, Pe, H - 1, Step + 1, Births + B, SumPred + length(Pd))
    end.

%% predator generations elapsed = cumulative births / mean standing pred count
generations({_, Births, SumPred, Steps}) ->
    MeanPred = case Steps > 0 of true -> SumPred / Steps; false -> 1.0 end,
    case MeanPred > 0.0 of true -> Births / MeanPred; false -> 0.0 end.
persists(R) -> element(1, R) =:= survived andalso generations(R) >= ?GMIN.

%%%============================================================================
%%% Calibration + the persistence sweep
%%%============================================================================
calibrate() ->
    io:format("== EXP-062 calibrate: prudent predator, does it persist? (seed 1) ==~n"),
    [begin
         R = run_world(1, 150, 15, Th),
         io:format("theta=~p: ~p, pred-generations=~.1f, ended-at-step=~p, births=~p~n",
                   [Th, element(1, R), generations(R), element(4, R), element(2, R)])
     end || Th <- [1, 2, 3, 5, 8]],
    ok.

run() -> run(#{seeds => lists:seq(101, 106)}).
run(#{seeds := Seeds}) ->
    {ok, Fd} = file:open("exp062_persistence_feed.txt", [write]),
    emit(Fd, "== EXP-062 rung-3b PRECONDITION part A: PERSISTENCE (fixed prudent theta-predator) ==~n"),
    emit(Fd, "world ~px~p, H=~p, GMIN=~p predator-generations, ~p seeds; prudent = hunt only if local prey "
             ">= theta within percept ~p~n", [?W, ?W, ?H, ?GMIN, length(Seeds), ?PERCEPT]),
    emit(Fd, "cell = persistence fraction (coexist AND >=~p pred generations) | median generations~n", [?GMIN]),
    Thetas = [1, 2, 3, 5, 8], NPs = [100, 150, 220],
    %% GRID 1: default energetics, theta x density
    Pe0 = {?REPRO_PRED, ?EPRED, ?SATIATE, ?PERCEPT},
    emit(Fd, "~n-- GRID 1: default {reproPred=~p Epred=~p satiate=~p percept=~p}, theta x density --~n",
         [?REPRO_PRED, ?EPRED, ?SATIATE, ?PERCEPT]),
    grid(Fd, NPs, Thetas, Pe0, Seeds),
    %% GRID 2: predator ENERGETICS sweep (overshoot<->starve) at fixed theta=3, density=150
    emit(Fd, "~n-- GRID 2: predator energetics sweep {reproPred x Epred} at theta=3, plants=150 --~n"),
    RPs = [34, 55, 80], EPds = [8, 14, 22],
    emit(Fd, "               Epred: ~s~n", [row([io_lib:format("~7w", [E]) || E <- EPds])]),
    [begin
         Cs = [cell(150, 3, {RP, EP, ?SATIATE, ?PERCEPT}, Seeds) || EP <- EPds],
         emit(Fd, "  reproPred=~3w:       ~s~n", [RP, row([C || C <- Cs])])
     end || RP <- RPs],
    %% REQUIRED (CLAIM gate): the 061 STRONG-STABILISER corner (satiate=12, small percept=2 = big refuge),
    %% greedy theta=1 -- the most likely known persistence counterexample -- measured in GENERATIONS.
    emit(Fd, "~n-- 061 STRONG-STABILISER corner (theta=1 greedy, satiate=12, percept=2 = big refuge) --~n"),
    Corner = [run_world(S, 150, 15, 1, {34, 14, 12, 2}) || S <- Seeds],
    emit(Fd, "  persistence=~.2f | median pred-generations=~.1f (survived: ~p/~p)~n",
         [length([1 || R <- Corner, persists(R)]) / length(Corner), med([generations(R) || R <- Corner]),
          length([1 || R <- Corner, element(1, R) =:= survived]), length(Corner)]),
    BestA = lists:max([pfrac(Np, Th, Pe0, Seeds) || Np <- NPs, Th <- Thetas]),
    BestB = lists:max([pfrac(150, 3, {RP, EP, ?SATIATE, ?PERCEPT}, Seeds) || RP <- RPs, EP <- EPds]),
    BestC = length([1 || R <- Corner, persists(R)]) / length(Corner),
    Best = lists:max([BestA, BestB, BestC]),
    emit(Fd, "~nMAX persistence fraction = ~.2f (theta/density ~.2f, energetics ~.2f, 061 strong corner ~.2f); "
             "fixed-greedy 061 = ~~1 gen~n", [Best, BestA, BestB, BestC]),
    emit(Fd, "~s~n", [verdict(Best)]),
    file:close(Fd),
    ok.

grid(Fd, NPs, Thetas, Pe, Seeds) ->
    emit(Fd, "                theta: ~s~n", [row([io_lib:format("~7w", [T]) || T <- Thetas])]),
    [begin
         Cells = [cell(Np, Th, Pe, Seeds) || Th <- Thetas],
         emit(Fd, "  plants=~4w:         ~s~n", [Np, row([C || C <- Cells])])
     end || Np <- NPs].

cell(Np, Th, Pe, Seeds) ->
    Rs = [run_world(S, Np, 15, Th, Pe) || S <- Seeds],
    Pf = length([1 || R <- Rs, persists(R)]) / length(Rs),
    Mg = med([generations(R) || R <- Rs]),
    lists:flatten(io_lib:format("~.2f/~4.1f", [Pf, Mg])).
pfrac(Np, Th, Pe, Seeds) -> length([1 || R <- [run_world(S, Np, 15, Th, Pe) || S <- Seeds], persists(R)]) / length(Seeds).

verdict(Best) when Best >= 0.5 ->
    "RESULT=PERSISTENCE MET: a prudent-predator regime coexists for many predator generations across seeds "
    "-> the open substrate admits an eco-evolutionary timescale. PROCEED to Part B (open-population "
    "learnability: does a thrift trait evolve?) then rung 063 (evolved restraint under viscosity).";
verdict(Best) when Best > 0.0 ->
    io_lib:format("RESULT=MARGINAL persistence (max fraction ~.2f) -- persists on a minority of seeds; a "
                  "knife-edge is not a robust eco-evo timescale. Report the fragility; Part B/rung 063 need "
                  "a robust persistent regime.", [Best]);
verdict(_) ->
    "RESULT=NO PERSISTENT REGIME in the searched region (signed negative). A SQUEEZE: the non-starving "
    "extreme (theta=1, greedy) collapses by OVER-CONSUMPTION in ~1 predator generation, and any added "
    "restraint (theta>1 = decline-to-hunt) only accelerates extinction via STARVATION -- no COSTLESS "
    "restraint lever exists in this family, and that coupling is itself the finding. No regime coexists "
    ">= GMIN predator generations across theta x density, a predator-energetics sweep, AND the 061 strong-"
    "stabiliser corner (satiate=12/percept=2). So rung 3b (evolved restraint) is BLOCKED in this region: "
    "coexistence dies within ~1 predator generation everywhere searched, so no selection can act. World "
    "size, perception, prey reproduction, and plant energy were held FIXED -- whether a persistent regime "
    "exists ELSEWHERE in this substrate (larger world / stronger refugia / higher prey productivity) is "
    "UNTESTED; a substrate change is a HYPOTHESIS for the failure, not a demonstrated necessity. SCOPE: a "
    "negative about the searched region + the decline-to-hunt restraint family + these energetics, NOT that "
    "open ALife cannot persist/evolve in general.".

%%%============================================================================
%%% stats
%%%============================================================================
med([]) -> 0.0;
med(L) -> S = lists:sort(L), N = length(S), case N rem 2 of 1 -> lists:nth(N div 2 + 1, S) * 1.0; 0 -> (lists:nth(N div 2, S) + lists:nth(N div 2 + 1, S)) / 2.0 end.
row(Xs) -> lists:flatten(lists:join(" ", [lists:flatten(X) || X <- Xs])).
emit(Fd, F) -> emit(Fd, F, []).
emit(Fd, F, A) -> io:format(Fd, F, A), io:format(F, A).
