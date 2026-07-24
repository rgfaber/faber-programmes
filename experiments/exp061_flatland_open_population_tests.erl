%%%-------------------------------------------------------------------
%%% @doc EXP-061 — Flatland rung 3a (INSTRUMENT): open many-agent population dynamics.
%%%
%%% Pre-registration (DESIGN-gated, redesigned): exp061_flatland_open_population.md
%%% Engine: faber-tweann flatland_sim (pure torus geometry). No nets, no evolution in 3a --
%%% FIXED competent hand-coded behaviours isolate the ECOLOGY from evolution.
%%%
%%% Question: does the open population (prey + predators living and REPRODUCING in one shared
%%% world) sustain predator-prey COEXISTENCE over a long horizon, and produce population CYCLES
%%% with the Lotka-Volterra signature (predator abundance lagging prey abundance)?
%%%
%%% World state: #{plants => [Pos], preys => [{Pos,Energy}], preds => [{Pos,Energy}]}.
%%% Step: prey forage/flee + eat plants; predators hunt + eat adjacent prey; reproduce at an
%%% energy threshold (clone, split energy); die at energy 0; cull the LOWEST-energy over a cap
%%% (starvation-order, a SPECIFIED selection operator); regrow plants to constant density.
%%% @end
%%%-------------------------------------------------------------------
-module(exp061_flatland_open_population_tests).

-export([calibrate/0, run/0, run/1]).

-define(W, 40).
-define(NPLANTS, 150).
-define(N0_PREY, 110).
-define(N0_PRED, 22).
-define(DANGER, 4).
%% prey energetics -- establish fast and densely
-define(E0, 20).
-define(EM, 1).
-define(EP, 7).
-define(REPRO_PREY, 14).
-define(NMAX_PREY, 500).
%% predator energetics -- FEW, WEAK, heavily satiated: must not overshoot the prey to extinction
-define(E0P, 30).
-define(EMP, 1).
-define(EPRED, 14).
-define(REPRO_PRED, 36).
-define(NMAX_PRED, 120).
%% predator SPEED DISADVANTAGE: skips 1 move every M steps so fleeing prey can escape.
-define(PRED_SKIP_M, 5).
%% predator SATIATION (handling time / Rosenzweig-MacArthur functional response): after eating, a
%% predator digests for SATIATE steps -- wanders, cannot hunt or eat -- capping the predation rate.
%% This is the classic mechanism that stabilises predator-prey coexistence.
-define(SATIATE, 3).
%% LIMITED PERCEPTION: a predator only hunts prey within PERCEPT (else wanders); prey far from every
%% predator are in a spatial REFUGE. Finite perception is the spatial mechanism that lets prey persist
%% in patches the predators are not currently in -- without it (global nearest) predators wipe out all prey.
-define(PERCEPT, 6).
%% horizon + measurement
-define(H, 1500).
-define(BURN, 300).       %% skip the initial transient before measuring dynamics
-define(LMAX, 60).        %% max cross-correlation lag searched

%%%============================================================================
%%% World construction + one step
%%%============================================================================
rand_cell() -> {rand:uniform(?W) - 1, rand:uniform(?W) - 1}.

pred_moves(Step) -> Step rem ?PRED_SKIP_M =/= ?PRED_SKIP_M - 1.

%% prey: flee the nearest predator within DANGER, else forage the nearest plant; eat on contact.
move_prey(Preys, PredPos, Pl) ->
    lists:foldl(
      fun({Pos, En}, {Acc, PlAcc}) ->
              Move = prey_decide(Pos, PredPos, PlAcc),
              Pos2 = flatland_sim:move(Pos, Move, ?W),
              {Ate, PlAcc2} = eat_plant(Pos2, PlAcc),
              En2 = En - ?EM + case Ate of true -> ?EP; false -> 0 end,
              {[{Pos2, En2} | Acc], PlAcc2}
      end, {[], Pl}, Preys).

prey_decide(Pos, PredPos, Pl) ->
    case flatland_sim:nearest(Pos, PredPos, ?W) of
        NP when NP =/= none, PredPos =/= [] ->
            case flatland_sim:cheb(Pos, NP, ?W) =< ?DANGER of
                true -> flatland_sim:away(Pos, NP, ?W);
                false -> forage_move(Pos, Pl)
            end;
        _ -> forage_move(Pos, Pl)
    end.
forage_move(Pos, Pl) ->
    case flatland_sim:nearest(Pos, Pl, ?W) of none -> 0; T -> flatland_sim:toward(Pos, T, ?W) end.

eat_plant(Pos, Pl) ->
    case lists:member(Pos, Pl) of true -> {true, lists:delete(Pos, Pl)}; false -> {false, Pl} end.

%% predators {Pos,Energy,Cooldown}: if digesting (Cd>0) wander and cannot eat; else hunt the nearest prey
%% (unless skipping) and eat an adjacent prey (which dies), then digest for SATIATE steps.
move_preds(Preds, Preys, DoMove, Sat, Perc) ->
    lists:foldl(
      fun({Pos, En, Cd}, {Acc, PreyAcc}) when Cd > 0 ->
              Pos2 = flatland_sim:move(Pos, rand:uniform(4) - 1, ?W),
              {[{Pos2, En - ?EMP, Cd - 1} | Acc], PreyAcc};
         ({Pos, En, _Cd}, {Acc, PreyAcc}) ->
              Pos2 = case DoMove of
                         false -> Pos;
                         true -> hunt_or_wander(Pos, [P || {P, _} <- PreyAcc], Perc)
                     end,
              {Eaten, PreyAcc2} = eat_prey(Pos2, PreyAcc),
              {En2, Cd2} = case Eaten of true -> {En - ?EMP + ?EPRED, Sat}; false -> {En - ?EMP, 0} end,
              {[{Pos2, En2, Cd2} | Acc], PreyAcc2}
      end, {[], Preys}, Preds).

%% hunt the nearest prey only if within Perc; otherwise wander (no global vision -> spatial refuge).
hunt_or_wander(Pos, PreyPos, Perc) ->
    case flatland_sim:nearest(Pos, PreyPos, ?W) of
        none -> flatland_sim:move(Pos, rand:uniform(4) - 1, ?W);
        T ->
            case flatland_sim:cheb(Pos, T, ?W) =< Perc of
                true -> flatland_sim:move(Pos, flatland_sim:toward(Pos, T, ?W), ?W);
                false -> flatland_sim:move(Pos, rand:uniform(4) - 1, ?W)
            end
    end.

eat_prey(Pos, Preys) ->
    case [Py || {PyPos, _} = Py <- Preys, flatland_sim:cheb(Pos, PyPos, ?W) =< 1] of
        [] -> {false, Preys};
        [Victim | _] -> {true, lists:delete(Victim, Preys)}
    end.

%% reproduction: energy >= threshold -> parent + one clone offspring, energy split. Prey are {Pos,En};
%% predators {Pos,En,Cd} (offspring starts un-satiated).
reproduce(Agents, Thresh) ->
    lists:flatmap(
      fun({Pos, En}) when En >= Thresh ->
              C = En div 2, [{Pos, En - C}, {childpos(Pos), C}];
         ({Pos, En, Cd}) when En >= Thresh ->
              C = En div 2, [{Pos, En - C, Cd}, {childpos(Pos), C, 0}];
         (A) -> [A]
      end, Agents).
childpos(Pos) -> flatland_sim:move(Pos, rand:uniform(4) - 1, ?W).

alive(Agents) -> [A || A <- Agents, element(2, A) > 0].

%% cull the LOWEST-energy agents down to Nmax (starvation-order; favours high-energy agents).
cull(Agents, Nmax) ->
    case length(Agents) > Nmax of
        true -> lists:sublist(lists:reverse(lists:keysort(2, Agents)), Nmax);
        false -> Agents
    end.

regrow(Pl, N) when length(Pl) >= N -> Pl;
regrow(Pl, N) ->
    C = rand_cell(),
    regrow(case lists:member(C, Pl) of true -> Pl; false -> [C | Pl] end, N).

%%%============================================================================
%%% Trajectory + dynamics metrics
%%%============================================================================
trajectory(Seed) -> trajectory_cfg(Seed, ?NPLANTS, ?N0_PRED).

%% coexistence: neither role extinct at any post-burn step.
coexist(Traj) ->
    Post = lists:nthtail(min(?BURN, length(Traj)), Traj),
    lists:all(fun({Py, Pd}) -> Py > 0 andalso Pd > 0 end, Post).

%% LV signature: lag L (0..LMAX) maximising cross-covariance of prey(t) and pred(t+L); L>0 => predator
%% abundance LAGS prey abundance (the Lotka-Volterra phase). Also the predator coefficient of variation.
lv(Traj) ->
    Post = lists:nthtail(min(?BURN, length(Traj)), Traj),
    P = [float(A) || {A, _} <- Post], Q = [float(B) || {_, B} <- Post],
    Pm = mean(P), Qm = mean(Q),
    Pc = [X - Pm || X <- P], Qc = [X - Qm || X <- Q],
    Covs = [{L, xcov(Pc, Qc, L)} || L <- lists:seq(0, ?LMAX)],
    {BestL, _} = hd(lists:reverse(lists:keysort(2, Covs))),
    CV = case Qm > 0.0 of true -> std(Q, Qm) / Qm; false -> 0.0 end,
    {BestL, CV, Pm, Qm}.

%% cross-covariance of Pc[1..n-L] with Qc[1+L..n]
xcov(Pc, Qc, L) ->
    N = length(Pc),
    A = lists:sublist(Pc, 1, N - L),
    B = lists:sublist(Qc, 1 + L, N - L),
    mean([X * Y || {X, Y} <- lists:zip(A, B)]).

%%%============================================================================
%%% Calibration (one seed, verbose) + the study (seed split + knob band)
%%%============================================================================
calibrate() ->
    io:format("== EXP-061 calibration (seed 1): population trajectory sanity ==~n"),
    io:format("world ~px~p, plants=~p, init prey=~p pred=~p, H=~p~n",
              [?W, ?W, ?NPLANTS, ?N0_PREY, ?N0_PRED, ?H]),
    T = trajectory(1),
    Pys = [Py || {Py, _} <- T], Pds = [Pd || {_, Pd} <- T],
    io:format("prey  count: init=~p min=~p max=~p end=~p~n", [hd(Pys), lists:min(Pys), lists:max(Pys), lists:last(Pys)]),
    io:format("pred  count: init=~p min=~p max=~p end=~p~n", [hd(Pds), lists:min(Pds), lists:max(Pds), lists:last(Pds)]),
    io:format("coexist=~p ; ", [coexist(T)]),
    {L, CV, Pm, Qm} = lv(T),
    io:format("LV lag=~p (pred lags prey iff >0) predCV=~.3f meanPrey=~.1f meanPred=~.1f~n", [L, CV, Pm, Qm]),
    io:format("coarse trajectory (prey/pred every 150 steps): ~s~n",
              [lists:flatten([io_lib:format("~p/~p ", [Py, Pd]) || {I, {Py, Pd}} <- lists:zip(lists:seq(1, length(T)), T), I rem 150 =:= 0])]),
    ok.

run() -> run(#{seeds => lists:seq(101, 106)}).
run(#{seeds := Seeds}) ->
    {ok, Fd} = file:open("exp061_open_pop_feed.txt", [write]),
    emit(Fd, "== EXP-061 open-population dynamics: coexistence over knob grids (weak + STRONG stabilisers) ==~n"),
    emit(Fd, "world ~px~p, H=~p, ~p measurement seeds (calibration seeds 1-3 disjoint)~n", [?W, ?W, ?H, length(Seeds)]),
    NPs = [80, 150, 250], NPreds = [8, 15, 25, 40],
    %% GRID A: weak/default stabilisers (satiate=3, percept=6)
    emit(Fd, "~n-- GRID A: default stabilisers satiate=~p percept=~p (plant-density x initial-predators) --~n", [?SATIATE, ?PERCEPT]),
    grid(Fd, NPs, NPreds, ?SATIATE, ?PERCEPT, Seeds),
    %% GRID B: STRONG-stabiliser corner LV theory prefers -- long satiation + tiny perception (large refuge)
    emit(Fd, "~n-- GRID B: STRONG stabilisers satiate=12 percept=2 (the LV coexistence corner) --~n"),
    grid(Fd, NPs, NPreds, 12, 2, Seeds),
    BestA = maxcoex(NPs, NPreds, ?SATIATE, ?PERCEPT, Seeds),
    BestB = maxcoex(NPs, NPreds, 12, 2, Seeds),
    Best = max(BestA, BestB),
    %% time-to-extinction (does collapse precede the BURN=~p burn-in? -> the LV/cycle read is never exercised)
    Ttes = [tte(trajectory_cfg(S, Np, NPd, Sa, Pe))
            || {Sa, Pe} <- [{?SATIATE, ?PERCEPT}, {12, 2}], Np <- NPs, NPd <- NPreds, S <- Seeds],
    Fin = [X || X <- Ttes, X < ?H],
    emit(Fd, "~ntime-to-first-extinction across all ~p runs: median=~p (BURN-in=~p; collapse precedes burn-in => "
             "cycle-detection never exercised, coexistence criterion reduces to 'survived burn-in')~n",
         [length(Ttes), case Fin of [] -> na; _ -> med_int(Fin) end, ?BURN]),
    emit(Fd, "MAX coexistence fraction over BOTH grids = ~.2f (default corner ~.2f, strong corner ~.2f)~n", [Best, BestA, BestB]),
    emit(Fd, "~s~n", [verdict(Best)]),
    file:close(Fd),
    ok.

grid(Fd, NPs, NPreds, Sat, Perc, Seeds) ->
    emit(Fd, "               NPred: ~s~n", [row([io_lib:format("~5w", [X]) || X <- NPreds])]),
    [begin
         Cells = [coex_frac(Np, NPd, Sat, Perc, Seeds) || NPd <- NPreds],
         emit(Fd, "  plants=~4w:        ~s~n", [Np, row([io_lib:format("~5.2f", [C]) || C <- Cells])])
     end || Np <- NPs].

maxcoex(NPs, NPreds, Sat, Perc, Seeds) ->
    lists:max([coex_frac(Np, NPd, Sat, Perc, Seeds) || Np <- NPs, NPd <- NPreds]).

coex_frac(Np, NPred0, Sat, Perc, Seeds) ->
    Cs = [coexist(trajectory_cfg(S, Np, NPred0, Sat, Perc)) || S <- Seeds],
    length([1 || true <- Cs]) / length(Cs).

%% first step at which either role hits 0 (extinction), or H if both survive.
tte(Traj) -> tte(Traj, 1).
tte([], _) -> ?H;
tte([{Py, Pd} | _], S) when Py =:= 0; Pd =:= 0 -> S;
tte([_ | T], S) -> tte(T, S + 1).
med_int(L) -> S = lists:sort(L), lists:nth(length(S) div 2 + 1, S).

verdict(Best) when Best >= 0.5 ->
    "RESULT=COEXISTENCE REGIME FOUND (max coexistence fraction >= 0.5 over the grids incl. the strong-"
    "stabiliser corner) -- the current negative is FALSE as stated; characterise the LV cycles there.";
verdict(Best) when Best > 0.0 ->
    io_lib:format("RESULT=at best a KNIFE-EDGE (max coexistence fraction ~.2f, incl. the strong-stabiliser "
                  "corner) -- coexists on a minority of seeds; per the pre-registration a knife-edge is NOT "
                  "a robust coexistence regime. FIXED-GREEDY behaviours collapse (boom-bust to mutual "
                  "extinction) across density x predators AND the strong satiation+refuge corner. Whether "
                  "EVOLVED behaviours self-limit predation and coexist on this world is the open rung-3b "
                  "question; 3a does not foreclose it.", [Best]);
verdict(_) ->
    "RESULT=NO COEXISTENCE anywhere -- FIXED-GREEDY predator-prey behaviours collapse (boom-bust to mutual "
    "extinction) across the density x predator grid at DEFAULT stabilisers AND at the STRONG-stabiliser "
    "corner (satiate=12, percept=2 = large refuge) LV theory prefers. So the open-population/reproduction "
    "ingredient does NOT by itself yield a stable predator-prey ecology with these fixed behaviours. "
    "Whether EVOLVED behaviours self-limit predation and coexist on this same world is the open rung-3b "
    "question -- 3a does NOT foreclose it. SCOPE: a negative about fixed-greedy behaviours in THIS game, "
    "NOT that open populations cannot coexist in general, NOR that evolved behaviours cannot coexist here.".

%% trajectory with parameterised plant target Np and initial predator count NPred0 (the grid axes).
trajectory_cfg(Seed, Np, NPred0) -> trajectory_cfg(Seed, Np, NPred0, ?SATIATE, ?PERCEPT).
%% full config: plant target, initial predators, satiation (handling time), perception radius (refuge).
trajectory_cfg(Seed, Np, NPred0, Sat, Perc) ->
    _ = rand:seed(exsss, {Seed, Seed * 7 + 1, Seed * 13 + 3}),
    W0 = #{plants => [rand_cell() || _ <- lists:seq(1, Np)],
           preys => [{rand_cell(), ?E0} || _ <- lists:seq(1, ?N0_PREY)],
           preds => [{rand_cell(), ?E0P, 0} || _ <- lists:seq(1, NPred0)]},
    tnp_loop(W0, Np, Sat, Perc, ?H, 0, []).
tnp_loop(_W, _Np, _Sat, _Perc, 0, _Step, Acc) -> lists:reverse(Acc);
tnp_loop(World, Np, Sat, Perc, H, Step, Acc) ->
    #{preys := Py, preds := Pd} = World,
    tnp_loop(step_np(World, Np, Sat, Perc, Step), Np, Sat, Perc, H - 1, Step + 1, [{length(Py), length(Pd)} | Acc]).
%% step with parameterised plant target, satiation, perception, and a step counter (for the predator skip)
step_np(#{plants := Pl, preys := Preys, preds := Preds}, Np, Sat, Perc, Step) ->
    PredPos = [P || {P, _, _} <- Preds],
    {Preys1, Pl1} = move_prey(Preys, PredPos, Pl),
    {Preds1, Preys2} = move_preds(Preds, Preys1, pred_moves(Step), Sat, Perc),
    Preys3 = alive(reproduce(Preys2, ?REPRO_PREY)),
    Preds2 = alive(reproduce(Preds1, ?REPRO_PRED)),
    #{plants => regrow(Pl1, Np), preys => cull(Preys3, ?NMAX_PREY), preds => cull(Preds2, ?NMAX_PRED)}.

%%%============================================================================
%%% stats
%%%============================================================================
mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).
std(L, M) -> math:sqrt(mean([(X - M) * (X - M) || X <- L])).
row(Xs) -> lists:flatten(lists:join(" ", [lists:flatten(X) || X <- Xs])).
emit(Fd, F) -> emit(Fd, F, []).
emit(Fd, F, A) -> io:format(Fd, F, A), io:format(F, A).
