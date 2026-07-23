%%%-------------------------------------------------------------------
%%% @doc EXP-060 — Flatland rung 2b: interventional AVOIDANCE probe.
%%%
%%% Pre-registration (DESIGN-gated, redesigned): exp060_flatland_avoidance.md
%%% Engine: faber-tweann flatland_sim + network_evaluator (process-free).
%%%
%%% Adjudicates the 059 foraging collapse: AVOIDANCE (adaptive positional distance-keeping /
%%% abandoning plants near the predator) vs DEGRADATION (non-adaptive). The DESIGN gate killed an
%%% observational NEAR/FAR read (NEAR is a COLLIDER -> foregone). This is the interventional read:
%%% ASSIGN the predator distance d, hold foraging opportunity fixed (one plant at a fixed offset),
%%% and read the prey's single-step policy choice.
%%%   avoid(d)           = P(move increases predator distance)                 [plant-independent]
%%%   forage_conflict(d) = P(move toward plant | plant is 1 step TOWARD predator)  [forage vs avoid oppose]
%%%   forage_aligned(d)  = P(move toward plant | plant 1 step AWAY from predator)  [sanity: high & flat]
%%% Three champions: NAIVE (P0, no predator in training), PROXIMITY (predator sensed, capture DISABLED
%%% -> sensor exposure, no avoidance incentive), PRESSURED (greedy-hunt, capture enabled). PRESSURED
%%% minus PROXIMITY isolates avoidance from sensor-channel exposure.
%%% @end
%%%-------------------------------------------------------------------
-module(exp060_flatland_avoidance_tests).

-export([sanity/0, run/0, run/1]).

-define(W, 9).
-define(T, 40).
-define(HID, 6).
-define(NP, 5 * ?HID + ?HID + 4 * ?HID + 4).
-define(SIGMA, 0.2).
-define(M, 13).
-define(E0, 20).
-define(EM, 1).
-define(EP, 4).
-define(NPLANTS, 8).
-define(MU, 14).
%% On a 9x9 torus the MAX Chebyshev distance is 4 (W div 2); distances beyond wrap back. So the real
%% near/far contrast is d=2 (near) vs d=4 (max separation). d=1 is skipped for conflict (plant would
%% coincide with the predator).
-define(DNEAR, 2).
-define(DFAR, 4).
-define(DS, [2, 3, 4]).

%%%============================================================================
%%% Training the three prey (ecological survival; capture kills or not)
%%%============================================================================
cells() -> [{X, Y} || X <- lists:seq(0, ?W - 1), Y <- lists:seq(0, ?W - 1)].
plants_at(Off) ->
    All = [C || C <- cells(), C =/= {0, 0}],
    Step = max(1, length(All) div ?NPLANTS),
    lists:usort([lists:nth(((Off + I * Step) rem length(All)) + 1, All) || I <- lists:seq(0, ?NPLANTS - 1)]).
eco_starts() ->
    Preys = [{X, Y} || X <- [2, 5, 7], Y <- [2, 5, 7]],
    [{{0, 0}, PE, plants_at(I)} || {I, PE} <- lists:zip(lists:seq(1, length(Preys)), Preys)].

%% eco episode returning plants eaten before death. CapKills=false -> capture is harmless (proximity-control).
eco(PredPol, PreyPol, {PP0, PE0, Pl0}, CapKills) -> eco_loop(PredPol, PreyPol, Pl0, PP0, PE0, ?E0, 0, 0, CapKills).
eco_loop(_Pr, _Py, _Pl, _PP, _PE, _En, Eaten, ?T, _CK) -> Eaten;
eco_loop(PredPol, PreyPol, Pl, PP, PE, En, Eaten, Step, CK) ->
    Caught = PredPol =/= none andalso flatland_sim:cheb(PP, PE, ?W) =< 1,
    Dead = (Caught andalso CK) orelse En =< 0,
    eco_next(Dead, PredPol, PreyPol, Pl, PP, PE, En, Eaten, Step, CK).
eco_next(true, _Pr, _Py, _Pl, _PP, _PE, _En, Eaten, _Step, _CK) -> Eaten;
eco_next(false, PredPol, PreyPol, Pl, PP, PE, En, Eaten, Step, CK) ->
    Se = flatland_sim:sense(?W, PE, pp(PredPol, PP), Pl, En, ?E0),
    PE2 = case skip(Step, ?M) of true -> PE; false -> flatland_sim:move(PE, decide(PreyPol, Se, PE, PP, Pl), ?W) end,
    PP2 = pmove(PredPol, PP, PE2),
    {Pl2, Ate} = try_eat(Pl, PE2),
    eco_loop(PredPol, PreyPol, Pl2, PP2, PE2, En - ?EM + case Ate of true -> ?EP; false -> 0 end,
             Eaten + bit(Ate), Step + 1, CK).
pp(none, _) -> none; pp(_, PP) -> PP.
pmove(none, PP, _) -> PP;
pmove(PredPol, PP, PE) -> flatland_sim:move(PP, decide(PredPol, flatland_sim:sense(?W, PP, PE, [], ?E0, ?E0), PP, PE, []), ?W).
skip(Step, M) -> Step rem M =:= M - 1.
try_eat(Pl, Pos) -> try_eat(lists:member(Pos, Pl), Pl, Pos).
try_eat(false, Pl, _Pos) -> {Pl, false};
try_eat(true, Pl, Pos) ->
    Rest = lists:delete(Pos, Pl),
    Free = [C || C <- cells(), not lists:member(C, [Pos | Rest])],
    {X, Y} = Pos,
    {[lists:nth(((X * ?W + Y) rem max(1, length(Free))) + 1, Free) | Rest], true}.

decide({net, Net}, S, _Self, _Opp, _Pl) -> argmax(network_evaluator:evaluate(Net, S));
decide(greedy_hunt, _S, Self, Opp, _Pl) -> flatland_sim:toward(Self, Opp, ?W);
decide(greedy_forage, _S, Self, _Opp, Pl) ->
    case flatland_sim:nearest(Self, Pl, ?W) of none -> 0; P -> flatland_sim:toward(Self, P, ?W) end.

%% Train a champion prey of each type (isolation fitness = plants eaten in the ecological episode).
champion(naive, G) -> {net, mk_net(evo(none, true, G))};       %% no predator
champion(proximity, G) -> {net, mk_net(evo(greedy_hunt, false, G))};  %% predator sensed, capture harmless
champion(pressured, G) -> {net, mk_net(evo(greedy_hunt, true, G))}.   %% predator, capture kills

evo(PredPol, CK, Gens) ->
    Pop = [rand_genome() || _ <- lists:seq(1, ?MU)],
    element(2, best(PredPol, CK, Gens, Pop, {-1.0, hd(Pop)})).
best(_Pr, _CK, 0, _Pop, B) -> B;
best(PredPol, CK, G, Pop, B) ->
    Off = [mutate(pick(Pop)) || _ <- lists:seq(1, ?MU)],
    Ranked = lists:reverse(lists:keysort(1, [{fit(PredPol, CK, Gm), Gm} || Gm <- Pop ++ Off])),
    {BF, BG} = hd(Ranked),
    best(PredPol, CK, G - 1, [G0 || {_F, G0} <- lists:sublist(Ranked, ?MU)],
         case BF > element(1, B) of true -> {BF, BG}; false -> B end).
fit(PredPol, CK, Gm) ->
    Net = mk_net(Gm),
    mean([eco(PredPol, {net, Net}, St, CK) || St <- eco_starts()]).

%%%============================================================================
%%% The interventional probe (assigned distance, fixed opportunity, single-step read)
%%%============================================================================
probe_positions() -> [{2, 2}, {2, 5}, {5, 2}, {5, 5}, {7, 7}, {3, 6}, {6, 3}].
dir_vec(0) -> {0, -1}; dir_vec(1) -> {1, 0}; dir_vec(2) -> {0, 1}; dir_vec(3) -> {-1, 0}.
addk({X, Y}, {Dx, Dy}, K) -> {flatland_sim:wrap(X + K * Dx, ?W), flatland_sim:wrap(Y + K * Dy, ?W)}.

%% avoid(d): P(move increases predator distance) with NO plant present (predator-only -> plant-independent,
%% no foraging confound). Only meaningful for d < W/2 (at the torus max you cannot get further).
avoid_rate(Pol, D) ->
    Cs = [begin
              E = dir_vec(Di), Q = addk(P, E, D),
              S = flatland_sim:sense(?W, P, Q, [], ?E0, ?E0),
              P2 = flatland_sim:move(P, decide(Pol, S, P, Q, []), ?W),
              flatland_sim:cheb(P2, Q, ?W) > flatland_sim:cheb(P, Q, ?W)
          end || P <- probe_positions(), Di <- [0, 1, 2, 3]],
    mean([bit(A) || A <- Cs]).

%% forage(d) under a geometry: P(move toward plant). conflict -> plant 1 step TOWARD predator.
forage_rate(Pol, D, Geom) ->
    K = case Geom of conflict -> 1; aligned -> -1 end,
    Cs = [begin
              E = dir_vec(Di), Q = addk(P, E, D), Plant = addk(P, E, K),
              move_metrics(Pol, P, Q, Plant)
          end || P <- probe_positions(), Di <- [0, 1, 2, 3]],
    mean([bit(F) || {_A, F} <- Cs]).

move_metrics(Pol, P, Q, Plant) ->
    S = flatland_sim:sense(?W, P, Q, [Plant], ?E0, ?E0),
    P2 = flatland_sim:move(P, decide(Pol, S, P, Q, [Plant]), ?W),
    {flatland_sim:cheb(P2, Q, ?W) > flatland_sim:cheb(P, Q, ?W),        %% avoid: moved away from predator
     flatland_sim:cheb(P2, Plant, ?W) < flatland_sim:cheb(P, Plant, ?W)}. %% forage: moved toward plant

%% per champion -> the scalars the decision needs (Pol = {net, Net})
champ_scalars(Pol) ->
    #{avoid_near => avoid_rate(Pol, ?DNEAR),                       %% P(step away from a near predator)
      fc_near => forage_rate(Pol, ?DNEAR, conflict),
      fc_far => forage_rate(Pol, ?DFAR, conflict),
      fa => mean([forage_rate(Pol, D, aligned) || D <- ?DS])}.

%%%============================================================================
%%% Probe geometry sanity gate
%%%============================================================================
sanity() ->
    io:format("== EXP-060 probe sanity ==~n"),
    io:format("hand-coded greedy-forage (MUST forage-aligned approx 1.0, avoid-on-aligned approx 1.0):~n"),
    [io:format("  d=~p: avoid=~.3f  forage_conflict=~.3f  forage_aligned=~.3f~n",
               [D, avoid_rate(greedy_forage, D), forage_rate(greedy_forage, D, conflict), forage_rate(greedy_forage, D, aligned)]) || D <- ?DS],
    io:format("NAIVE net forager (one champion, informational):~n"),
    Net = champion(naive, 50),
    [io:format("  d=~p: avoid=~.3f  forage_conflict=~.3f  forage_aligned=~.3f~n",
               [D, avoid_rate(Net, D), forage_rate(Net, D, conflict), forage_rate(Net, D, aligned)]) || D <- ?DS],
    ok.

%%%============================================================================
%%% The study
%%%============================================================================
run() -> run(#{n => 12, g => 50}).
run(#{n := N, g := Gens}) ->
    {ok, Fd} = file:open("exp060_avoidance_feed.txt", [write]),
    emit(Fd, "== EXP-060 interventional avoidance probe (n=~p champions/type, g=~p, near d=~p far d=~p) ==~n",
         [N, Gens, ?DNEAR, ?DFAR]),
    Types = [{"NAIVE     ", naive}, {"PROXIMITY ", proximity}, {"PRESSURED ", pressured}],
    Rows = [{Lab, [champ_scalars(champion(T, Gens)) || _ <- lists:seq(1, N)]} || {Lab, T} <- Types],
    [report_type(Fd, Lab, Ss) || {Lab, Ss} <- Rows],
    contrasts(Fd, Rows),
    file:close(Fd),
    ok.

report_type(Fd, Lab, Ss) ->
    An = [maps:get(avoid_near, S) || S <- Ss],
    Fn = [maps:get(fc_near, S) || S <- Ss], Ff = [maps:get(fc_far, S) || S <- Ss],
    Fa = [maps:get(fa, S) || S <- Ss],
    emit(Fd, "~s avoid_near med=~.3f | forage_conflict near=~.3f far=~.3f | forage_aligned med=~.3f "
             "(SANITY: naive must be high; if ~~chance the forage readouts are INVALID)~n",
         [Lab, median(An), median(Fn), median(Ff), median(Fa)]),
    emit(Fd, "    raw avoid_near (sorted): ~s~n",
         [lists:flatten(lists:join(" ", [lists:flatten(io_lib:format("~.3f", [X])) || X <- lists:sort(An)]))]).

contrasts(Fd, Rows) ->
    [{_, Naive}, {_, Prox}, {_, Press}] = Rows,
    emit(Fd, "~n-- Contrasts (avoidance signatures; PRESSURED must exceed PROXIMITY, not just NAIVE) --~n"),
    signature(Fd, "avoid_near (step away from near predator)", fun(S) -> maps:get(avoid_near, S) end, Naive, Prox, Press),
    signature(Fd, "fc-drop (fc_far - fc_near)               ", fun(S) -> maps:get(fc_far, S) - maps:get(fc_near, S) end, Naive, Prox, Press),
    emit(Fd, "~s~n", [verdict(Naive, Prox, Press)]).

signature(Fd, Name, F, Naive, Prox, Press) ->
    Vn = [F(S) || S <- Naive], Vx = [F(S) || S <- Prox], Vp = [F(S) || S <- Press],
    {PxLo, PxHi} = boot_ci_diff(Vp, Vx),
    emit(Fd, "  ~s: naive=~.3f prox=~.3f pressured=~.3f | PRESSURED-minus-PROX=~.3f CI[~.3f,~.3f] -> ~s~n",
         [Name, median(Vn), median(Vx), median(Vp), median(Vp) - median(Vx), PxLo, PxHi,
          case PxLo > 0.0 of true -> "RESOLVED (avoidance)"; false -> "unresolved" end]).

%% Verdict on avoid_near ONLY (the plant-independent readout). The forage_conflict/aligned readouts are
%% INVALID whenever the naive forager's forage_aligned is ~chance (pre-registered sanity gate) -- so they
%% do NOT enter the verdict.
verdict(Naive, Prox, Press) ->
    Av = fun(S) -> maps:get(avoid_near, S) end,
    {AvLo, _} = boot_ci_diff([Av(S) || S <- Press], [Av(S) || S <- Prox]),
    ForageValid = median([maps:get(fa, S) || S <- Naive]) > 0.6,
    verdict_text(AvLo > 0.0, ForageValid).
verdict_text(true, ForageValid) ->
    "RESULT=NEAR-PREDATOR REPULSION above chance: the PRESSURED prey steps AWAY from a near (d=2) predator "
    "beyond the proximity-control (which has predator-sensor exposure but no avoidance incentive) -- so the "
    "059 foraging collapse is AT LEAST PARTLY adaptive avoidance, not pure degradation. This is single-step "
    "static-probe repulsion, NOT whole-episode reactive fleeing (059's flee-skill, never learned). Forage "
    "readouts " ++ forage_note(ForageValid) ++ ".";
verdict_text(false, _) ->
    "RESULT=NO resolved near-predator repulsion beyond the proximity-control -- consistent with degradation "
    "at this EA budget.".
forage_note(true) -> "valid (naive forages above chance)";
forage_note(false) -> "INVALID and dropped (naive forage_aligned ~chance -- the pre-registered sanity gate)".

%%%============================================================================
%%% Net helpers + stats
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
    R = [median([lists:nth(rand:uniform(Na), A) || _ <- lists:seq(1, Na)]) -
         median([lists:nth(rand:uniform(Nb), B) || _ <- lists:seq(1, Nb)]) || _ <- lists:seq(1, 2000)],
    S = lists:sort(R), {pctile(S, 0.025), pctile(S, 0.975)}.
pctile(S, P) -> N = length(S), lists:nth(max(1, min(N, round(P * N))), S) * 1.0.
emit(Fd, F) -> emit(Fd, F, []).
emit(Fd, F, A) -> io:format(Fd, F, A), io:format(F, A).
