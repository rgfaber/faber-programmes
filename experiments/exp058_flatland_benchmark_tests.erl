%%%-------------------------------------------------------------------
%%% @doc EXP-058 — Flatland rung 1, deliverable 3: the DECOMPOSED graded benchmark
%%% and the RE-BASELINE of 057's decoupled coupling control on it.
%%%
%%% Pre-registration (DESIGN-gated): experiments/exp058_flatland_ecological_arms_race.md
%%% Engine: faber-tweann flatland_sim (pure world) + network_evaluator (process-free).
%%%
%%% The DESIGN gate's core requirement: read each capability ORTHOGONALLY so a later
%%% coupling verdict cannot be foraging drift wearing an arms-race label.
%%%   - prey FLEEING-skill:  survival vs a frozen graded PREDATOR HoF (plants OFF -> pure fleeing)
%%%   - prey FORAGING-skill: plants eaten vs plants, NO predator
%%%   - predator CAPTURE-skill: capture-speed vs a frozen graded PREY HoF
%%% verify_decomposition/0 shows each sub-metric is difficulty-GRADED + un-saturated AND
%%% that foraging and fleeing are DISTINCT axes (a pure forager is not a good fleer, & vice versa).
%%%
%%% rebaseline_057/1 re-runs 057's decoupled coupling control (coevolution vs a frozen static
%%% opponent) on PURE pursuit-evasion in the Flatland engine (plants OFF), at 057's crossover
%%% speed, measured on the capture/flee sub-metrics -- confirming 057's "no coupling" refusal
%%% REPRODUCES on the new graded instrument (ruling out that it was binary-capture saturation).
%%% No ecology claim here; that is exp059 (rung 2).
%%% @end
%%%-------------------------------------------------------------------
-module(exp058_flatland_benchmark_tests).

-export([verify_decomposition/0, rebaseline_057/0, rebaseline_057/1, run/0]).

-define(W, 9).
-define(T, 40).
-define(HID, 6).
-define(NP, 5 * ?HID + ?HID + 4 * ?HID + 4).   %% [5,6,4] = 64
-define(SIGMA, 0.2).
-define(SSTAR_M, 13).                           %% 057 crossover speed (identical geometry)
-define(E0, 20).
-define(NPLANTS, 8).
-define(CMU, 15).
-define(CK, 3).

%%%============================================================================
%%% Starts
%%%============================================================================
cells() -> [{X, Y} || X <- lists:seq(0, ?W - 1), Y <- lists:seq(0, ?W - 1)].
hunt_starts() ->
    [{{0, 0}, {X, Y}} || X <- lists:seq(0, ?W - 1), Y <- lists:seq(0, ?W - 1),
                         flatland_sim:cheb({0, 0}, {X, Y}, ?W) > 1].
bench_starts() -> sub(hunt_starts(), 6).
co_starts() -> sub(hunt_starts(), 10).
sub(L, K) -> [X || {I, X} <- lists:zip(lists:seq(1, length(L)), L), I rem K =:= 0].

forage_layouts() -> [plants_at(Off) || Off <- lists:seq(1, 8)].
plants_at(Off) ->
    All = [C || C <- cells(), C =/= {0, 0}],
    Step = max(1, length(All) div ?NPLANTS),
    lists:usort([lists:nth(((Off + I * Step) rem length(All)) + 1, All) || I <- lists:seq(0, ?NPLANTS - 1)]).

%%%============================================================================
%%% Pursuit-evasion match (plants OFF) at speed M; returns {Caught, Step}
%%%============================================================================
match(PredPol, PreyPol, {PP0, PE0}, M) -> play(PredPol, PreyPol, PP0, PE0, ?T, M, 0).

play(_PredPol, _PreyPol, PP, PE, 0, _M, Step) -> {flatland_sim:cheb(PP, PE, ?W) =< 1, Step};
play(PredPol, PreyPol, PP, PE, T, M, Step) ->
    step_or_catch(flatland_sim:cheb(PP, PE, ?W) =< 1, PredPol, PreyPol, PP, PE, T, M, Step).

step_or_catch(true, _PredPol, _PreyPol, _PP, _PE, _T, _M, Step) -> {true, Step};
step_or_catch(false, PredPol, PreyPol, PP, PE, T, M, Step) ->
    Sp = flatland_sim:sense(?W, PP, PE, [], ?E0, ?E0),
    Se = flatland_sim:sense(?W, PE, PP, [], ?E0, ?E0),
    PP2 = flatland_sim:move(PP, decide(PredPol, Sp, PP, PE, []), ?W),
    PE2 = case skip(Step, M) of
              true -> PE;
              false -> flatland_sim:move(PE, decide(PreyPol, Se, PE, PP, []), ?W)
          end,
    play(PredPol, PreyPol, PP2, PE2, T - 1, M, Step + 1).

skip(Step, M) -> Step rem M =:= M - 1.
caught({C, _}) -> C.
%% predator capture-speed: 1.0 for an instant catch -> 0 for none (the 057 continuous metric).
pscore({true, Step}) -> 1.0 - Step / ?T;
pscore({false, _}) -> 0.0.

%%%============================================================================
%%% Forage episode (plants ON, no predator): plants eaten
%%%============================================================================
-define(EM, 1).
-define(EP, 4).
forage(Policy, Plants0) -> forage_loop(Policy, Plants0, {0, 0}, ?E0, 0, ?T).
forage_loop(_P, _Pl, _Pos, _En, Eaten, 0) -> Eaten;
forage_loop(_P, _Pl, _Pos, En, Eaten, _T) when En =< 0 -> Eaten;
forage_loop(Policy, Pl, Pos, En, Eaten, T) ->
    S = flatland_sim:sense(?W, Pos, none, Pl, En, ?E0),
    Pos2 = flatland_sim:move(Pos, decide(Policy, S, Pos, none, Pl), ?W),
    {Pl2, Ate} = try_eat(Pl, Pos2),
    forage_loop(Policy, Pl2, Pos2, En - ?EM + case Ate of true -> ?EP; false -> 0 end,
                Eaten + bit(Ate), T - 1).
try_eat(Pl, Pos) -> try_eat(lists:member(Pos, Pl), Pl, Pos).
try_eat(false, Pl, _Pos) -> {Pl, false};
try_eat(true, Pl, Pos) ->
    Rest = lists:delete(Pos, Pl),
    Free = [C || C <- cells(), not lists:member(C, [Pos | Rest])],
    {X, Y} = Pos,
    {[lists:nth(((X * ?W + Y) rem max(1, length(Free))) + 1, Free) | Rest], true}.

%%%============================================================================
%%% Policies
%%%============================================================================
decide({net, Net}, S, _Self, _Opp, _Pl) -> argmax(network_evaluator:evaluate(Net, S));
decide(greedy_hunt, _S, Self, Opp, _Pl) -> flatland_sim:toward(Self, Opp, ?W);
decide(flee, _S, Self, Opp, _Pl) -> flatland_sim:away(Self, Opp, ?W);
decide(greedy_forage, _S, Self, _Opp, Pl) ->
    case flatland_sim:nearest(Self, Pl, ?W) of none -> 0; P -> flatland_sim:toward(Self, P, ?W) end;
decide({hunt_p, P}, _S, Self, Opp, _Pl) -> rnd_or(P, flatland_sim:toward(Self, Opp, ?W));
decide({flee_p, P}, _S, Self, Opp, _Pl) -> rnd_or(P, flatland_sim:away(Self, Opp, ?W));
decide(random, _S, _Self, _Opp, _Pl) -> rand:uniform(4) - 1.
rnd_or(P, Dir) -> case rand:uniform() < P of true -> rand:uniform(4) - 1; false -> Dir end.

%%%============================================================================
%%% Frozen graded benchmark HoF (seed-fixed): tunable families + strong evolved opponents
%%%============================================================================
build_hof(M) ->
    _ = rand:seed(exsss, {58, 12, 2026}),
    SPred = [{net, mk_net(evolve(capture, M, 30))} || _ <- lists:seq(1, 2)],
    SPrey = [{net, mk_net(evolve(flee, M, 30))} || _ <- lists:seq(1, 2)],
    #{preys => [{flee_p, P} || P <- [0.8, 0.6, 0.4, 0.2, 0.0]] ++ SPrey,   %% opponents for a PREDATOR
      preds => [greedy_hunt | SPred]}.                                     %% opponents for a PREY (strong only)

%% predator CAPTURE-skill: continuous capture-speed vs the frozen prey HoF.
capture_skill(PredNet, M, HoF) ->
    mean([pscore(match({net, PredNet}, Prey, St, M)) || Prey <- maps:get(preys, HoF), St <- bench_starts()]).
%% prey FLEEING-skill: escape-rate (fraction not caught) vs the frozen STRONG predator HoF.
flee_skill(PreyNet, M, HoF) ->
    mean([bit(not caught(match(Pred, {net, PreyNet}, St, M))) || Pred <- maps:get(preds, HoF), St <- bench_starts()]).
%% prey FORAGING-skill: plants eaten vs plants, NO predator.
forage_skill(PreyNet) ->
    mean([forage({net, PreyNet}, Pl) || Pl <- forage_layouts()]).

%%%============================================================================
%%% Evolve a capability in isolation (mu+lambda); returns champion genome
%%%============================================================================
evolve(Cap, M, Gens) ->
    Pop = [rand_genome() || _ <- lists:seq(1, 14)],
    best(Cap, M, Gens, Pop, {-1.0, hd(Pop)}).
best(_Cap, _M, 0, _Pop, {_F, G}) -> G;
best(Cap, M, Gn, Pop, Best) ->
    Off = [mutate(pick(Pop)) || _ <- lists:seq(1, 14)],
    Ranked = lists:reverse(lists:keysort(1, [{isofit(Cap, Gm, M), Gm} || Gm <- Pop ++ Off])),
    {BF, BG} = hd(Ranked),
    best(Cap, M, Gn - 1, [G || {_F, G} <- lists:sublist(Ranked, 14)],
         pick_best(BF > element(1, Best), {BF, BG}, Best)).
pick_best(true, New, _Old) -> New;
pick_best(false, _New, Old) -> Old.

%% Isolation fitness against a FIXED hand-coded opponent (no HoF -> no circularity).
isofit(capture, Gm, M) -> mean([pscore(match({net, mk_net(Gm)}, flee, St, M)) || St <- sub(hunt_starts(), 5)]);
isofit(flee, Gm, M) -> mean([bit(not caught(match(greedy_hunt, {net, mk_net(Gm)}, St, M))) || St <- sub(hunt_starts(), 5)]);
isofit(forage, Gm, _M) -> forage_skill(mk_net(Gm)).

%%%============================================================================
%%% verify_decomposition -- grading (un-saturated) + separation (distinct axes)
%%%============================================================================
verify_decomposition() ->
    M = ?SSTAR_M,
    HoF = build_hof(M),
    io:format("== EXP-058 decomposed benchmark: grading + separation (m=~p) ==~n", [M]),
    io:format("PREDATOR capture-skill probe (greedy-hunt capture-speed vs prey rungs; want spread, off ceiling):~n"),
    Pc = [{lab(Prey), mean([pscore(match(greedy_hunt, Prey, St, M)) || St <- bench_starts()])}
          || Prey <- maps:get(preys, HoF)],
    [io:format("  ~-14s pscore=~.3f~n", [L, V]) || {L, V} <- Pc],
    io:format("  AGG=~.3f~n", [mean([V || {_, V} <- Pc])]),
    io:format("PREY fleeing-skill probe (optimal-flee escape-rate vs predator rungs; want spread, off floor):~n"),
    Fc = [{lab(Pred), mean([bit(not caught(match(Pred, flee, St, M))) || St <- bench_starts()])}
          || Pred <- maps:get(preds, HoF)],
    [io:format("  ~-14s escape=~.3f~n", [L, V]) || {L, V} <- Fc],
    io:format("  AGG=~.3f~n", [mean([V || {_, V} <- Fc])]),
    %% SEPARATION: evolve a pure forager and a pure fleer; foraging and fleeing must be DISTINCT axes.
    io:format("SEPARATION (foraging vs fleeing are orthogonal capabilities):~n"),
    Forager = mk_net(evolve(forage, M, 60)),
    Fleer = mk_net(evolve(flee, M, 40)),
    io:format("  pure-FORAGER: forage-skill=~.2f  flee-skill=~.3f~n",
              [forage_skill(Forager), flee_skill(Forager, M, HoF)]),
    io:format("  pure-FLEER  : forage-skill=~.2f  flee-skill=~.3f~n",
              [forage_skill(Fleer), flee_skill(Fleer, M, HoF)]),
    io:format("  => distinct iff the forager out-forages the fleer AND the fleer out-flees the forager~n"),
    ok.

lab({flee_p, P}) -> lists:flatten(io_lib:format("flee p=~.1f", [P]));
lab(greedy_hunt) -> "greedy-hunt";
lab({net, _}) -> "evolved-net".

%%%============================================================================
%%% RE-BASELINE 057: coupling control on PURE pursuit-evasion (plants OFF), crossover M
%%%============================================================================
rebaseline_057() -> rebaseline_057(#{n => 40, r => 30}).
rebaseline_057(#{n := N, r := R}) ->
    M = ?SSTAR_M,
    HoF = build_hof(M),
    io:format("~n== EXP-058 re-baseline 057: coupling control on PURE pursuit-evasion (plants OFF), "
              "m=~p, n=~p R=~p ==~n", [M, N, R]),
    Coevo = [side(coevo_run(M, R, HoF)) || _ <- lists:seq(1, N)],
    Ctrl = [side(control_run(M, R, HoF)) || _ <- lists:seq(1, N)],
    couple("PREDATOR (capture-skill)", p, Coevo, Ctrl),
    couple("PREY     (flee-skill)   ", e, Coevo, Ctrl),
    io:format("=> 057 refusal REPRODUCES on the graded instrument iff NEITHER side's coupling is resolved "
              "(coevo NET does not exceed static NET).~n"),
    ok.

couple(Label, Side, Coevo, Ctrl) ->
    Co = [maps:get(Side, X) || X <- Coevo], St = [maps:get(Side, X) || X <- Ctrl],
    {DLo, DHi} = boot_ci_diff(Co, St),
    io:format("  ~s: coevo NET=~.3f static NET=~.3f | coevo-minus-static=~.3f CI[~.3f,~.3f] -> ~s~n",
              [Label, median(Co), median(St), median(Co) - median(St), DLo, DHi,
               case DLo > 0.0 of true -> "COUPLED"; false -> "no coupling (CI includes 0)" end]).

%% Coevolution: both populations co-adapt. Returns #{p => predator NET, e => prey NET} on the benchmark.
coevo_run(M, R, HoF) ->
    PP = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    PE = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    co_loop(1, R, PP, PE, M, HoF, [], []).
co_loop(_G, R, _PP, _PE, _M, _HoF, Ps, Es) when length(Ps) >= R -> traj(Ps, Es);
co_loop(G, R, PP, PE, M, HoF, Ps, Es) ->
    PP1 = sel(pred, PP ++ mut(PP), PE, M),
    PE1 = sel(prey, PE ++ mut(PE), PP, M),
    co_loop(G + 1, R, PP1, PE1, M, HoF, [capture_skill(mk_net(hd(PP1)), M, HoF) | Ps],
            [flee_skill(mk_net(hd(PE1)), M, HoF) | Es]).

%% Control: each side vs a FROZEN gen-0 static opponent (no co-adaptation).
control_run(M, R, HoF) ->
    PP = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    PE = [rand_genome() || _ <- lists:seq(1, ?CMU)],
    ctrl_loop(1, R, PP, PE, PP, PE, M, HoF, [], []).
ctrl_loop(_G, R, _PP, _PE, _FP, _FE, _M, _HoF, Ps, Es) when length(Ps) >= R -> traj(Ps, Es);
ctrl_loop(G, R, PP, PE, FP, FE, M, HoF, Ps, Es) ->
    PP1 = sel(pred, PP ++ mut(PP), FE, M),
    PE1 = sel(prey, PE ++ mut(PE), FP, M),
    ctrl_loop(G + 1, R, PP1, PE1, FP, FE, M, HoF, [capture_skill(mk_net(hd(PP1)), M, HoF) | Ps],
              [flee_skill(mk_net(hd(PE1)), M, HoF) | Es]).

traj(Ps, Es) -> {lists:reverse(Ps), lists:reverse(Es)}.
side({Ps, Es}) -> #{p => lists:last(Ps) - hd(Ps), e => lists:last(Es) - hd(Es)}.   %% NET = end - start

mut(Pop) -> [mutate(pick(Pop)) || _ <- lists:seq(1, ?CMU)].
sel(Role, Cands, Opp, M) ->
    OppNets = [mk_net(pick(Opp)) || _ <- lists:seq(1, ?CK)],
    Scored = [{cofit(Role, mk_net(G), OppNets, M), G} || G <- Cands],
    [G || {_F, G} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), ?CMU)].
cofit(pred, Net, PreyNets, M) ->
    mean([pscore(match({net, Net}, {net, PN}, St, M)) || PN <- PreyNets, St <- co_starts()]);
cofit(prey, Net, PredNets, M) ->
    mean([bit(not caught(match({net, PN}, {net, Net}, St, M))) || PN <- PredNets, St <- co_starts()]).

run() ->
    verify_decomposition(),
    rebaseline_057(),
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
boot_ci_diff([], _) -> {0.0, 0.0};
boot_ci_diff(_, []) -> {0.0, 0.0};
boot_ci_diff(A, B) ->
    Na = length(A), Nb = length(B),
    Reps = [median([lists:nth(rand:uniform(Na), A) || _ <- lists:seq(1, Na)]) -
            median([lists:nth(rand:uniform(Nb), B) || _ <- lists:seq(1, Nb)]) || _ <- lists:seq(1, 2000)],
    S = lists:sort(Reps),
    {pctile(S, 0.025), pctile(S, 0.975)}.
pctile(S, P) -> N = length(S), lists:nth(max(1, min(N, round(P * N))), S) * 1.0.
