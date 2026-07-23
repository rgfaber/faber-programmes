%%%-------------------------------------------------------------------
%%% @doc EXP-059 — Flatland rung 2: the FORAGE/FLEE frontier.
%%%
%%% Pre-registration (DESIGN-gated, redesigned): exp059_flatland_energy_economy_coupling.md
%%% Engine: faber-tweann flatland_sim (pure world) + network_evaluator (process-free).
%%%
%%% Question (falsifiable, not foregone): is there a forage/flee FRONTIER (can a prey be
%%% maximal on BOTH the 058 foraging and fleeing axes, or does one cost the other?), and does
%%% PREDATOR PRESSURE move the prey along it (forage DOWN, flee UP)?
%%%
%%% A prey lives in the ecological episode (plants + energy + a predator); its co-fitness is
%%% ECOLOGICAL SURVIVAL (steps alive / T) -- forage to not starve, flee to not be caught. Under a
%%% LADDER of predator pressure (none -> weak-static -> coevo -> strong-static) the champion prey
%%% is FROZEN and read as a 2D point (forage-skill, flee-skill) on the validated 058 benchmark.
%%% Only the PREY side is claimed (pairwise, the predator's ecology is vacuous).
%%% @end
%%%-------------------------------------------------------------------
-module(exp059_flatland_forage_flee_frontier_tests).

-export([calibrate/0, verify_ranges/0, run_frontier/0, run_frontier/1, run/0, floor_flee/0]).

-define(W, 9).
-define(T, 40).
-define(HID, 6).
-define(NP, 5 * ?HID + ?HID + 4 * ?HID + 4).   %% [5,6,4] = 64
-define(SIGMA, 0.2).
-define(M, 13).                                 %% prey skips 1 move / 13 -> predator ~1.08x (057 crossover)
-define(E0, 20).
-define(EM, 1).
-define(EP, 4).
-define(NPLANTS, 8).
-define(DANGER, 3).                             %% hand-coded prey: flee if predator within this Chebyshev radius
-define(MU, 14).                                %% EA / coevo population
-define(CK, 3).                                 %% opponents sampled per coevo fitness eval

%%%============================================================================
%%% Layouts / starts
%%%============================================================================
cells() -> [{X, Y} || X <- lists:seq(0, ?W - 1), Y <- lists:seq(0, ?W - 1)].

plants_at(Off) ->
    All = [C || C <- cells(), C =/= {0, 0}],
    Step = max(1, length(All) div ?NPLANTS),
    lists:usort([lists:nth(((Off + I * Step) rem length(All)) + 1, All) || I <- lists:seq(0, ?NPLANTS - 1)]).

forage_layouts() -> [plants_at(Off) || Off <- lists:seq(1, 8)].

%% ecological starts: predator {0,0}, prey at a spread of far cells, each with a plant layout.
eco_starts() ->
    Preys = [{X, Y} || X <- [2, 5, 7], Y <- [2, 5, 7]],
    [{{0, 0}, PE, plants_at(I)} || {I, PE} <- lists:zip(lists:seq(1, length(Preys)), Preys)].

%% pursuit-evasion starts (plants OFF) for the flee-skill benchmark
hunt_starts() ->
    [{{0, 0}, {X, Y}} || X <- lists:seq(0, ?W - 1), Y <- lists:seq(0, ?W - 1),
                         flatland_sim:cheb({0, 0}, {X, Y}, ?W) > 1].
bench_starts() -> sub(hunt_starts(), 6).
sub(L, K) -> [X || {I, X} <- lists:zip(lists:seq(1, length(L)), L), I rem K =:= 0].

%%%============================================================================
%%% The ecological episode: prey survival fraction (forage to live, flee to live)
%%%============================================================================
%% PredPol = none (no predator) | a policy. Returns {PlantsEaten, Caught, Step-at-death}. The episode
%% ends on capture, starvation, or T. Prey fitness = PlantsEaten (rewards foraging AND staying alive to
%% keep foraging -> a caught/starved prey eats little); predator fitness = capture-speed from Caught/Step.
eco(PredPol, PreyPol, {PP0, PE0, Plants0}) ->
    eco_loop(PredPol, PreyPol, Plants0, PP0, PE0, ?E0, 0, 0).

eco_loop(_PredPol, _PreyPol, _Pl, _PP, _PE, _En, Eaten, ?T) -> {Eaten, false, ?T};
eco_loop(PredPol, PreyPol, Pl, PP, PE, En, Eaten, Step) ->
    Caught = PredPol =/= none andalso flatland_sim:cheb(PP, PE, ?W) =< 1,
    dead_or_step(Caught orelse En =< 0, Caught, PredPol, PreyPol, Pl, PP, PE, En, Eaten, Step).

dead_or_step(true, Caught, _PredPol, _PreyPol, _Pl, _PP, _PE, _En, Eaten, Step) -> {Eaten, Caught, Step};
dead_or_step(false, _Caught, PredPol, PreyPol, Pl, PP, PE, En, Eaten, Step) ->
    Se = flatland_sim:sense(?W, PE, pred_pos(PredPol, PP), Pl, En, ?E0),
    PE2 = case skip(Step, ?M) of
              true -> PE;
              false -> flatland_sim:move(PE, decide(PreyPol, Se, PE, PP, Pl), ?W)
          end,
    PP2 = pred_move(PredPol, PP, PE2),
    {Pl2, Ate} = try_eat(Pl, PE2),
    En2 = En - ?EM + case Ate of true -> ?EP; false -> 0 end,
    eco_loop(PredPol, PreyPol, Pl2, PP2, PE2, En2, Eaten + bit(Ate), Step + 1).

prey_eaten(R) -> element(1, R).
pred_speed({_Eaten, true, Step}) -> 1.0 - Step / ?T;
pred_speed({_Eaten, false, _Step}) -> 0.0.

pred_pos(none, _PP) -> none;
pred_pos(_PredPol, PP) -> PP.
pred_move(none, PP, _PE) -> PP;
pred_move(PredPol, PP, PE) ->
    Sp = flatland_sim:sense(?W, PP, PE, [], ?E0, ?E0),
    flatland_sim:move(PP, decide(PredPol, Sp, PP, PE, []), ?W).

skip(Step, M) -> Step rem M =:= M - 1.

try_eat(Pl, Pos) -> try_eat(lists:member(Pos, Pl), Pl, Pos).
try_eat(false, Pl, _Pos) -> {Pl, false};
try_eat(true, Pl, Pos) ->
    Rest = lists:delete(Pos, Pl),
    Free = [C || C <- cells(), not lists:member(C, [Pos | Rest])],
    {X, Y} = Pos,
    {[lists:nth(((X * ?W + Y) rem max(1, length(Free))) + 1, Free) | Rest], true}.

%%%============================================================================
%%% The 058 benchmark axes (the read): forage-skill + flee-skill
%%%============================================================================
%% FORAGE-skill: plants eaten over the forage layouts, no predator.
forage_skill(PreyNet) -> mean([plants_eaten({net, PreyNet}, Pl) || Pl <- forage_layouts()]).
plants_eaten(Policy, Plants0) -> pe_loop(Policy, Plants0, {0, 0}, ?E0, 0, 0).
pe_loop(_P, _Pl, _Pos, _En, Eaten, ?T) -> Eaten;
pe_loop(_P, _Pl, _Pos, En, Eaten, _Step) when En =< 0 -> Eaten;
pe_loop(P, Pl, Pos, En, Eaten, Step) ->
    S = flatland_sim:sense(?W, Pos, none, Pl, En, ?E0),
    Pos2 = flatland_sim:move(Pos, decide(P, S, Pos, none, Pl), ?W),
    {Pl2, Ate} = try_eat(Pl, Pos2),
    pe_loop(P, Pl2, Pos2, En - ?EM + case Ate of true -> ?EP; false -> 0 end, Eaten + bit(Ate), Step + 1).

%% FLEE-skill: escape-rate (fraction not caught) vs a frozen STRONG predator HoF, plants OFF.
flee_skill(PreyNet, Preds) ->
    mean([bit(not caught(match(Pred, {net, PreyNet}, St))) || Pred <- Preds, St <- bench_starts()]).

%% pure pursuit-evasion match (plants OFF) for flee-skill; returns {Caught, Step}
match(PredPol, PreyPol, {PP0, PE0}) -> play(PredPol, PreyPol, PP0, PE0, ?T, 0).
play(_PredPol, _PreyPol, PP, PE, 0, _Step) -> {flatland_sim:cheb(PP, PE, ?W) =< 1, 0};
play(PredPol, PreyPol, PP, PE, T, Step) ->
    pv_step(flatland_sim:cheb(PP, PE, ?W) =< 1, PredPol, PreyPol, PP, PE, T, Step).
pv_step(true, _PredPol, _PreyPol, _PP, _PE, _T, _Step) -> {true, 0};
pv_step(false, PredPol, PreyPol, PP, PE, T, Step) ->
    Sp = flatland_sim:sense(?W, PP, PE, [], ?E0, ?E0),
    Se = flatland_sim:sense(?W, PE, PP, [], ?E0, ?E0),
    PP2 = flatland_sim:move(PP, decide(PredPol, Sp, PP, PE, []), ?W),
    PE2 = case skip(Step, ?M) of true -> PE; false -> flatland_sim:move(PE, decide(PreyPol, Se, PE, PP, []), ?W) end,
    play(PredPol, PreyPol, PP2, PE2, T - 1, Step + 1).
caught({C, _}) -> C.

%%%============================================================================
%%% Policies
%%%============================================================================
decide({net, Net}, S, _Self, _Opp, _Pl) -> argmax(network_evaluator:evaluate(Net, S));
decide(greedy_hunt, _S, Self, Opp, _Pl) -> flatland_sim:toward(Self, Opp, ?W);
decide(greedy_forage, _S, Self, _Opp, Pl) ->
    case flatland_sim:nearest(Self, Pl, ?W) of none -> 0; P -> flatland_sim:toward(Self, P, ?W) end;
%% hand-coded prey: flee if the predator is within DANGER, else forage.
decide(forage_flee, _S, Self, Opp, Pl) ->
    case Opp =/= none andalso flatland_sim:cheb(Self, Opp, ?W) =< ?DANGER of
        true -> flatland_sim:away(Self, Opp, ?W);
        false -> case flatland_sim:nearest(Self, Pl, ?W) of none -> 0; P -> flatland_sim:toward(Self, P, ?W) end
    end;
decide(random, _S, _Self, _Opp, _Pl) -> rand:uniform(4) - 1.

%%%============================================================================
%%% Frozen strong-predator HoF (for the flee-skill benchmark) — seed-fixed
%%%============================================================================
strong_preds() ->
    _ = rand:seed(exsss, {59, 7, 2026}),
    [greedy_hunt | [{net, mk_net(evolve_pred(30))} || _ <- lists:seq(1, 2)]].

%% evolve a predator vs the hand-coded forage_flee prey (isolation fitness, capture-speed)
evolve_pred(Gens) -> element(2, evo(pred, Gens, [rand_genome() || _ <- lists:seq(1, ?MU)], {-1.0, none})).
%% evolve a prey vs a given predator condition (isolation fitness, ecological survival)
evolve_prey(PredPol, Gens) -> element(2, evo({prey, PredPol}, Gens, [rand_genome() || _ <- lists:seq(1, ?MU)], {-1.0, none})).
%% evolve a prey on flee-skill ALONE (escape vs greedy-hunt) -> the dedicated-fleer ceiling for the axis
evolve_flee(Gens) -> element(2, evo(flee, Gens, [rand_genome() || _ <- lists:seq(1, ?MU)], {-1.0, none})).

%% Absolute flee floor: gen-0 random nets + a dedicated fleer, on the 058 flee axis. Settles whether the
%% ~0.29 that every ecological condition shows is the do-nothing floor (reactive fleeing never learned).
floor_flee() ->
    Preds = strong_preds(),
    Rand = mean([flee_skill(mk_net(rand_genome()), Preds) || _ <- lists:seq(1, 20)]),
    Fleer = flee_skill(mk_net(evolve_flee(60)), Preds),
    io:format("flee-skill FLOOR: gen-0 random nets=~.3f | dedicated FLEER (evolved on flee only)=~.3f~n",
              [Rand, Fleer]),
    {Rand, Fleer}.

evo(_Spec, 0, Pop, {_F, none}) -> {0.0, hd(Pop)};
evo(_Spec, 0, _Pop, Best) -> Best;
evo(Spec, G, Pop, Best) ->
    Off = [mutate(pick(Pop)) || _ <- lists:seq(1, ?MU)],
    Ranked = lists:reverse(lists:keysort(1, [{isofit(Spec, Gm), Gm} || Gm <- Pop ++ Off])),
    {BF, BG} = hd(Ranked),
    evo(Spec, G - 1, [G0 || {_F, G0} <- lists:sublist(Ranked, ?MU)],
        pick_best(BF > element(1, Best), {BF, BG}, Best)).
pick_best(true, New, _Old) -> New;
pick_best(false, _New, Old) -> Old.

isofit(pred, Gm) ->
    Net = mk_net(Gm),
    mean([capspeed(match({net, Net}, forage_flee, {PP, PE})) || {PP, PE} <- sub(hunt_starts(), 5)]);
isofit({prey, PredPol}, Gm) ->
    Net = mk_net(Gm),
    mean([prey_eaten(eco(PredPol, {net, Net}, St)) || St <- eco_starts()]);
isofit(flee, Gm) ->
    Net = mk_net(Gm),
    mean([bit(not caught(match(greedy_hunt, {net, Net}, St))) || St <- sub(hunt_starts(), 5)]).
capspeed({true, S}) -> 1.0 - S / ?T;
capspeed({false, _}) -> 0.0.

%%%============================================================================
%%% Coevolution (prey + predator co-adapt); returns the final PREY champion genome
%%%============================================================================
coevo(Gens) ->
    Preys = [rand_genome() || _ <- lists:seq(1, ?MU)],
    Preds = [rand_genome() || _ <- lists:seq(1, ?MU)],
    co_loop(Gens, Preys, Preds).
co_loop(0, Preys, _Preds) -> hd(Preys);
co_loop(G, Preys, Preds) ->
    Preys1 = cosel(prey, Preys ++ mut(Preys), Preds),
    Preds1 = cosel(pred, Preds ++ mut(Preds), Preys),
    co_loop(G - 1, Preys1, Preds1).
mut(Pop) -> [mutate(pick(Pop)) || _ <- lists:seq(1, ?MU)].
cosel(Role, Cands, Opp) ->
    OppNets = [mk_net(pick(Opp)) || _ <- lists:seq(1, ?CK)],
    Scored = [{cofit(Role, mk_net(G), OppNets), G} || G <- Cands],
    [G || {_F, G} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), ?MU)].
cofit(prey, Net, PredNets) ->
    mean([prey_eaten(eco({net, PN}, {net, Net}, St)) || PN <- PredNets, St <- eco_starts()]);
cofit(pred, Net, PreyNets) ->
    mean([pred_speed(eco({net, Net}, {net, PN}, St)) || PN <- PreyNets, St <- eco_starts()]).

%%%============================================================================
%%% CALIBRATION + range check (kill gates)
%%%============================================================================
calibrate() ->
    io:format("== EXP-059 calibration: predator pressure in the ecology (m=~p) ==~n", [?M]),
    Cap = mean([bit(caught(eco_match(greedy_hunt, forage_flee, St))) || St <- eco_starts()]),
    io:format("greedy-hunt vs hand-coded forage-flee prey: per-episode CAPTURE prob=~.3f "
              "(want [0.4,0.7] = real but not overwhelming)~n", [Cap]),
    io:format("  balance OK: ~p~n", [Cap >= 0.4 andalso Cap =< 0.85]),
    Cap.
%% capture within an ecological episode (for calibration): did the predator catch before T/starve?
eco_match(PredPol, PreyPol, {PP0, PE0, Plants0}) ->
    em_loop(PredPol, PreyPol, Plants0, PP0, PE0, ?E0, 0).
em_loop(_PredPol, _PreyPol, _Pl, _PP, _PE, _En, ?T) -> {false, ?T};
em_loop(PredPol, PreyPol, Pl, PP, PE, En, Step) ->
    case flatland_sim:cheb(PP, PE, ?W) =< 1 of
        true -> {true, Step};
        false when En =< 0 -> {false, Step};
        false ->
            Se = flatland_sim:sense(?W, PE, PP, Pl, En, ?E0),
            PE2 = case skip(Step, ?M) of true -> PE; false -> flatland_sim:move(PE, decide(PreyPol, Se, PE, PP, Pl), ?W) end,
            PP2 = flatland_sim:move(PP, decide(PredPol, flatland_sim:sense(?W, PP, PE, [], ?E0, ?E0), PP, PE, []), ?W),
            {Pl2, Ate} = try_eat(Pl, PE2),
            em_loop(PredPol, PreyPol, Pl2, PP2, PE2, En - ?EM + case Ate of true -> ?EP; false -> 0 end, Step + 1)
    end.

verify_ranges() ->
    io:format("~n== EXP-059 dynamic-range gate: both benchmark axes un-saturated for ecology-trained prey ==~n"),
    Preds = strong_preds(),
    F0 = mk_net(evolve_prey(none, 60)),          %% pure forager
    Fs = mk_net(evolve_prey(greedy_hunt, 60)),   %% pressured prey
    io:format("pure-forager (no-pred trained):    forage=~.2f flee=~.3f~n", [forage_skill(F0), flee_skill(F0, Preds)]),
    io:format("pressured   (greedy-hunt trained): forage=~.2f flee=~.3f~n", [forage_skill(Fs), flee_skill(Fs, Preds)]),
    io:format("  (axes usable iff forage spans a real range AND flee is off floor for the pressured prey)~n"),
    ok.

%%%============================================================================
%%% The frontier study: 4 predator-pressure conditions x n runs -> (forage, flee) points
%%%============================================================================
run_frontier() -> run_frontier(#{n => 20, g => 50}).
run_frontier(#{n := N, g := Gens}) ->
    {ok, Fd} = file:open("exp059_frontier_feed.txt", [write]),
    Preds = strong_preds(),
    emit(Fd, "== EXP-059 forage/flee frontier: prey (forage-skill, flee-skill) by predator pressure "
             "(n=~p, gens=~p, m=~p) ==~n", [N, Gens, ?M]),
    Conds = [{"P0 no-predator ", none},
             {"WEAK-static    ", weak},
             {"COEVO          ", coevo},
             {"STRONG-static  ", greedy_hunt}],
    Rows = [{Lab, points(Cond, N, Gens, Preds)} || {Lab, Cond} <- Conds],
    [report_cond(Fd, Lab, Pts) || {Lab, Pts} <- Rows],
    frontier_verdict(Fd, Rows),
    file:close(Fd),
    ok.

%% n champion prey per condition -> list of {forage, flee}
points(Cond, N, Gens, Preds) ->
    [begin
         Prey = champion(Cond, Gens),
         {forage_skill(Prey), flee_skill(Prey, Preds)}
     end || _ <- lists:seq(1, N)].

champion(none, Gens) -> mk_net(evolve_prey(none, Gens));
champion(weak, Gens) ->
    Weak = {net, mk_net(rand_genome())},   %% frozen gen-0 (weak) predator
    mk_net(evolve_prey(Weak, Gens));
champion(greedy_hunt, Gens) -> mk_net(evolve_prey(greedy_hunt, Gens));
champion(coevo, Gens) -> mk_net(coevo(Gens)).

report_cond(Fd, Lab, Pts) ->
    Fo = [F || {F, _} <- Pts], Fl = [L || {_, L} <- Pts],
    {FoL, FoH} = boot_ci(Fo), {FlL, FlH} = boot_ci(Fl),
    emit(Fd, "~s forage=~.2f CI[~.2f,~.2f]  flee=~.3f CI[~.3f,~.3f]~n",
         [Lab, median(Fo), FoL, FoH, median(Fl), FlL, FlH]).

frontier_verdict(Fd, Rows) ->
    %% ladder order: P0, WEAK, COEVO, STRONG (increasing predator pressure)
    Fos = [median([F || {F, _} <- Pts]) || {_, Pts} <- Rows],
    Fls = [median([L || {_, L} <- Pts]) || {_, Pts} <- Rows],
    emit(Fd, "~n-- Frontier read --~n"),
    emit(Fd, "forage across ladder (P0->STRONG): ~s~n", [row(Fos)]),
    emit(Fd, "flee   across ladder (P0->STRONG): ~s~n", [row(Fls)]),
    Down = decreasing(Fos), Up = increasing(Fls),
    emit(Fd, "forage monotone DOWN with pressure: ~p ; flee monotone UP: ~p~n", [Down, Up]),
    %% COEVO vs WEAK-static axis differences (does a strengthening opponent move the prey further?)
    {_, WeakPts} = lists:nth(2, Rows), {_, CoevoPts} = lists:nth(3, Rows),
    {DfL, DfH} = boot_ci_diff([F || {F, _} <- CoevoPts], [F || {F, _} <- WeakPts]),
    {DlL, DlH} = boot_ci_diff([L || {_, L} <- CoevoPts], [L || {_, L} <- WeakPts]),
    emit(Fd, "COEVO-minus-WEAK forage-diff=~.2f CI[~.2f,~.2f] (want <0); flee-diff=~.3f CI[~.3f,~.3f] (want >0)~n",
         [median([F || {F, _} <- CoevoPts]) - median([F || {F, _} <- WeakPts]), DfL, DfH,
          median([L || {_, L} <- CoevoPts]) - median([L || {_, L} <- WeakPts]), DlL, DlH]),
    emit(Fd, "~s~n", [verdict_text(Down, Up)]).

verdict_text(true, true) ->
    "RESULT=FRONTIER + PRESSURE MOVES ALONG IT: forage falls and flee rises with predator pressure -- "
    "the energy economy forces a forage/flee trade-off and a stronger opponent pushes the prey down it. "
    "(Confirm mutual non-domination + reproduce the COEVO-vs-WEAK differences.)";
verdict_text(false, true) ->
    "RESULT=flee rises with pressure but forage does not monotonically fall -- partial/weak frontier; "
    "inspect the points (possible global gain on flee without a clean trade).";
verdict_text(true, false) ->
    "RESULT=forage falls with pressure but flee does not monotonically rise -- pressure degrades foraging "
    "without buying fleeing; inspect for global degradation vs a frontier.";
verdict_text(false, false) ->
    "RESULT=NO clean frontier movement -- either the net expresses both cheaply (no trade-off) or the "
    "signal is noise; inspect the (forage,flee) points and the Pareto structure.".

decreasing([_]) -> true;
decreasing([A, B | R]) -> A >= B andalso decreasing([B | R]).
increasing([_]) -> true;
increasing([A, B | R]) -> A =< B andalso increasing([B | R]).

run() ->
    calibrate(),
    verify_ranges(),
    run_frontier(),
    ok.

%%%============================================================================
%%% Net helpers + stats (self-contained, the 057 path)
%%%============================================================================
mk_net(G) -> network_evaluator:set_weights(network_evaluator:create_feedforward(5, [?HID], 4, tanh, tanh), G).
rand_genome() -> [rand:normal() || _ <- lists:seq(1, ?NP)].
mutate(G) -> [X + ?SIGMA * rand:normal() || X <- G].
pick(P) -> lists:nth(rand:uniform(length(P)), P).
argmax([H | T]) -> argmax(T, H, 0, 1).
argmax([], _B, BI, _I) -> BI;
argmax([H | T], B, _BI, I) when H > B -> argmax(T, H, I, I + 1);
argmax([_H | T], B, BI, I) -> argmax(T, B, BI, I + 1).
bit(true) -> 1; bit(false) -> 0.
mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).
median([]) -> 0.0;
median(L) -> S = lists:sort(L), N = length(S), mpick(N rem 2, S, N).
mpick(1, S, N) -> lists:nth(N div 2 + 1, S) * 1.0;
mpick(0, S, N) -> (lists:nth(N div 2, S) + lists:nth(N div 2 + 1, S)) / 2.0.
boot_ci([]) -> {0.0, 0.0};
boot_ci(V) ->
    N = length(V),
    R = [median([lists:nth(rand:uniform(N), V) || _ <- lists:seq(1, N)]) || _ <- lists:seq(1, 2000)],
    S = lists:sort(R), {pctile(S, 0.025), pctile(S, 0.975)}.
boot_ci_diff([], _) -> {0.0, 0.0};
boot_ci_diff(_, []) -> {0.0, 0.0};
boot_ci_diff(A, B) ->
    Na = length(A), Nb = length(B),
    R = [median([lists:nth(rand:uniform(Na), A) || _ <- lists:seq(1, Na)]) -
         median([lists:nth(rand:uniform(Nb), B) || _ <- lists:seq(1, Nb)]) || _ <- lists:seq(1, 2000)],
    S = lists:sort(R), {pctile(S, 0.025), pctile(S, 0.975)}.
pctile(S, P) -> N = length(S), lists:nth(max(1, min(N, round(P * N))), S) * 1.0.
row(Xs) -> lists:flatten(lists:join("  ", [lists:flatten(io_lib:format("~.3f", [X])) || X <- Xs])).
emit(Fd, F) -> emit(Fd, F, []).
emit(Fd, F, A) -> io:format(Fd, F, A), io:format(F, A).
