%%%-------------------------------------------------------------------
%%% @doc EXP-065 — is `greedy' the CEILING, and is the Flatland "15% gap" a SHORTFALL or a MIXTURE?
%%%
%%% DESIGN-gated (REDESIGN accepted). The originally proposed representation-vs-search probe was
%%% killed by the gate: representability is already settled by persisted data (exp063's per-arm
%%% MAXIMA 34.50/35.00/35.00 EXCEED greedy 34.25), and `flatland_sim:sense/6' already performs the
%%% argmin and hands the net the nearest-plant delta, so the greedy policy is a trivially
%%% representable function of inputs 3 and 4. What is NOT settled, and what this runner measures:
%%%
%%%   1. INSTRUMENT CHECK (not a claim). Construct the greedy policy in weight space analytically
%%%      (a=1.0, c=1.0, eps=0.05; validity condition (1+eps)*tanh(0.75a) < tanh(a)) and verify it
%%%      EXHAUSTIVELY over all 81 (DX,DY) in [-4,4]^2 x energy {0.1,0.5,1.0} = 243 states. The
%%%      fitness is fully deterministic, so acceptance is EXACT (243/243), not a threshold.
%%%   2. PRIMARY -- IS GREEDY THE CEILING? Two arms at exp058's REAL config (80 gens, 12 layouts,
%%%      mu=lambda=20, sigma=0.2), n=20 runs, common random numbers by run index. Arm G seeds one
%%%      initial individual with the constructed greedy net; arm R initialises all 20 from N(0,1).
%%%      If arm G climbs >= 10% above greedy, then every "% of greedy" number in 058-064 is a ratio
%%%      to a reference that competent search beats, and "under-convergence" was mismeasured.
%%%   3. SECONDARY -- SHORTFALL OR MIXTURE? On arm R, success = final best >= 0.95 * greedy. Report
%%%      the success RATE with a bootstrap CI and the two sub-population medians SEPARATELY, never
%%%      pooled. A mixture means the remedy is restarts, not step size or parameterisation.
%%%   4. TERTIARY -- MECHANISM. Visitation-weighted exhaustive disagreement map of each arm-R
%%%      champion against `axis_move', to say whether the shortfall is a boundary/saturation effect
%%%      or a diffusely wrong policy.
%%%   5. FREE FINDING. In the FORAGE task `sense/6' is called with Opp=none, so inputs 1 and 2 are
%%%      identically zero in every state: 12 of the 64 weights are GLOBALLY dead (pure random-walk
%%%      directions for every optimizer). Reported exactly, by construction of the task.
%%%
%%% Pre-registration: exp065_representation_vs_search.md
%%% @end
%%%-------------------------------------------------------------------
-module(exp065_greedy_ceiling_and_mixture_tests).

-export([run/0]).

-define(W, 9).
-define(T, 40).
-define(HID, 6).
-define(NP, (5 * ?HID + ?HID + 4 * ?HID + 4)).   %% [5,6,4] = 64 (parenthesised: macro precedence)
-define(NPLANTS, 8).
-define(E0, 20).
-define(EM, 1).
-define(EP, 4).
-define(SIGMA, 0.2).      %% exp058's mutation step
-define(MU, 20).          %% exp058 gate_0b: evolve(forage, 80, 20)
-define(GENS, 80).        %% exp058 gate_0b: 80 generations (NOT the 50 exp063 used)
-define(NLAY, 12).        %% exp058 forage_starts/0: 12 layouts (NOT the 8 exp063 used)
-define(NRUNS, 20).
%% constructed-policy constants (pre-committed in the pre-reg)
-define(CA, 1.0).
-define(CC, 1.0).
-define(CEPS, 0.05).

%%%============================================================================
%%% World (identical geometry to exp058/exp063)
%%%============================================================================
cells() -> [{X, Y} || X <- lists:seq(0, ?W - 1), Y <- lists:seq(0, ?W - 1)].
plants_at(Off) ->
    All = [C || C <- cells(), C =/= {0, 0}],
    Step = max(1, length(All) div ?NPLANTS),
    lists:usort([lists:nth(((Off + I * Step) rem length(All)) + 1, All) || I <- lists:seq(0, ?NPLANTS - 1)]).
%% exp058's forage_starts/0: 12 layouts. This is the faithful set (exp063 wrongly used 8).
layouts() -> [plants_at(Off) || Off <- lists:seq(1, ?NLAY)].

forage(Policy, Plants0) -> floop(Policy, Plants0, {0, 0}, ?E0, 0, 0).
floop(_P, _Pl, _Pos, _En, Eaten, ?T) -> Eaten;
floop(_P, _Pl, _Pos, En, Eaten, _S) when En =< 0 -> Eaten;
floop(Policy, Pl, Pos, En, Eaten, S) ->
    Sn = flatland_sim:sense(?W, Pos, none, Pl, En, ?E0),
    Pos2 = flatland_sim:move(Pos, decide(Policy, Sn, Pos, Pl), ?W),
    {Pl2, Ate} = eat(Pl, Pos2),
    floop(Policy, Pl2, Pos2, En - ?EM + case Ate of true -> ?EP; false -> 0 end, Eaten + b(Ate), S + 1).
eat(Pl, Pos) ->
    case lists:member(Pos, Pl) of
        true -> Rest = lists:delete(Pos, Pl), {[regrow(Rest, Pos) | Rest], true};
        false -> {Pl, false}
    end.
regrow(Pl, {X, Y}) ->
    Free = [C || C <- cells(), not lists:member(C, [{X, Y} | Pl])],
    lists:nth(((X * ?W + Y) rem max(1, length(Free))) + 1, Free).

decide({net, Net}, S, _Self, _Pl) -> argmax(network_evaluator:evaluate(Net, S));
decide(greedy, _S, Self, Pl) ->
    case flatland_sim:nearest(Self, Pl, ?W) of
        none -> 0;
        P -> flatland_sim:toward(Self, P, ?W)
    end.

mk_net(W) -> network_evaluator:set_weights(network_evaluator:create_feedforward(5, [?HID], 4, tanh, tanh), W).
fit(W) -> mean([forage({net, mk_net(W)}, Pl) || Pl <- layouts()]).

%%%============================================================================
%%% (1) The CONSTRUCTED greedy policy, written not searched
%%%
%%% Flat layout of set_weights/2 (neuron-major, weights then biases, layer by layer):
%%%   1..30  hidden weights  (6 rows of 5)
%%%   31..36 hidden biases   (6)
%%%   37..60 output weights  (4 rows of 6)
%%%   61..64 output biases   (4)
%%% h1 = tanh(a*s3), h2 = tanh(a*s4); outputs indexed 0=North 1=East 2=South 3=West per move/3.
%%% o_N = -c*h2, o_E = c(1+eps)*h1, o_S = c*h2, o_W = -c(1+eps)*h1.
%%% tanh odd+strictly-monotone => |h1|>|h2| iff |DX|>|DY|; (1+eps) gives the x-axis priority on
%%% exact diagonal ties, matching axis_move's `abs(DX) >= abs(DY)' guard; all-zero input => all-zero
%%% outputs => argmax/1 (first-max-wins) returns 0 = North, matching axis_move(_,_) -> 0.
%%%============================================================================
constructed() ->
    CE = ?CC * (1 + ?CEPS),
    HiddenW = [0.0, 0.0, ?CA, 0.0, 0.0]      %% h1 reads s3 (PDX)
           ++ [0.0, 0.0, 0.0, ?CA, 0.0]      %% h2 reads s4 (PDY)
           ++ lists:duplicate(20, 0.0),      %% h3..h6 dead
    HiddenB = lists:duplicate(6, 0.0),
    OutW = [0.0, -?CC, 0.0, 0.0, 0.0, 0.0]   %% o0 North = -c*h2
        ++ [CE, 0.0, 0.0, 0.0, 0.0, 0.0]     %% o1 East  = c(1+eps)*h1
        ++ [0.0, ?CC, 0.0, 0.0, 0.0, 0.0]    %% o2 South = c*h2
        ++ [-CE, 0.0, 0.0, 0.0, 0.0, 0.0],   %% o3 West  = -c(1+eps)*h1
    OutB = lists:duplicate(4, 0.0),
    HiddenW ++ HiddenB ++ OutW ++ OutB.

%% Exhaustive instrument check: every (DX,DY) in [-4,4]^2 x energy {0.1,0.5,1.0}.
check_constructed() ->
    Valid = (1 + ?CEPS) * math:tanh(0.75 * ?CA) < math:tanh(?CA),
    Net = mk_net(constructed()),
    N = max(1, ?W div 2),
    States = [{DX, DY, E} || DX <- lists:seq(-4, 4), DY <- lists:seq(-4, 4), E <- [0.1, 0.5, 1.0]],
    Bad = [{DX, DY, E, Got, Want}
           || {DX, DY, E} <- States,
              begin
                  Got = argmax(network_evaluator:evaluate(Net, [0.0, 0.0, DX / N, DY / N, E])),
                  Want = axis_move_ref(DX, DY),
                  Got =/= Want
              end],
    {Valid, length(States) - length(Bad), length(States), Bad}.

%% axis_move/2 is not exported from flatland_sim; toward/3 is. Reference via toward/3 on a
%% position pair realising (DX,DY), so we compare against the SHIPPED function, not a copy.
axis_move_ref(0, 0) -> 0;
axis_move_ref(DX, DY) ->
    Self = {4, 4},
    Target = {flatland_sim:wrap(4 + DX, ?W), flatland_sim:wrap(4 + DY, ?W)},
    flatland_sim:toward(Self, Target, ?W).

%%%============================================================================
%%% (2) exp058's EA, at its REAL configuration, with an optional seeded individual
%%%============================================================================
ea(Gens, SeedInd) ->
    Pop0 = [[rand:normal() || _ <- lists:seq(1, ?NP)] || _ <- lists:seq(1, ?MU)],
    Pop = case SeedInd of
              none -> Pop0;
              W -> [W | tl(Pop0)]
          end,
    ea_loop(Gens, Pop, 0.0).
ea_loop(0, _Pop, B) -> B;
ea_loop(G, Pop, B) ->
    Off = [[X + ?SIGMA * rand:normal() || X <- lists:nth(rand:uniform(length(Pop)), Pop)]
           || _ <- lists:seq(1, ?MU)],
    Ranked = lists:reverse(lists:keysort(1, [{fit(Gm), Gm} || Gm <- Pop ++ Off])),
    ea_loop(G - 1, [Gm || {_F, Gm} <- lists:sublist(Ranked, ?MU)], max(B, element(1, hd(Ranked)))).

%% Same, but also returns the champion weights (for the tertiary mechanism map).
ea_champ(Gens) ->
    Pop = [[rand:normal() || _ <- lists:seq(1, ?NP)] || _ <- lists:seq(1, ?MU)],
    ea_champ_loop(Gens, Pop, {0.0, hd(Pop)}).
ea_champ_loop(0, _Pop, Best) -> Best;
ea_champ_loop(G, Pop, {BF, BW}) ->
    Off = [[X + ?SIGMA * rand:normal() || X <- lists:nth(rand:uniform(length(Pop)), Pop)]
           || _ <- lists:seq(1, ?MU)],
    Ranked = lists:reverse(lists:keysort(1, [{fit(Gm), Gm} || Gm <- Pop ++ Off])),
    {TF, TW} = hd(Ranked),
    Best2 = case TF > BF of true -> {TF, TW}; false -> {BF, BW} end,
    ea_champ_loop(G - 1, [Gm || {_F, Gm} <- lists:sublist(Ranked, ?MU)], Best2).

%%%============================================================================
%%% (4) Visitation-weighted disagreement map of a champion vs the greedy rule
%%%============================================================================
%% Roll the champion out over the 12 layouts; at each visited state record whether its action
%% matches axis_move on that state's (PDX,PDY). Returns {AgreeFrac, DiagOrFarMass, NDistinctBad}.
disagreement(W) ->
    Net = mk_net(W),
    Visits = lists:flatten([rollout_states(Net, Pl) || Pl <- layouts()]),
    Bad = [{DX, DY} || {DX, DY, Got} <- Visits, Got =/= axis_move_ref(DX, DY)],
    NB = length(Bad),
    Agree = case Visits of [] -> 1.0; _ -> 1.0 - NB / length(Visits) end,
    %% boundary/saturation states: the |DX|=|DY| diagonal, or far states max(|DX|,|DY|) >= 3
    Boundary = [1 || {DX, DY} <- Bad, abs(DX) =:= abs(DY) orelse max(abs(DX), abs(DY)) >= 3],
    Mass = case NB of 0 -> 0.0; _ -> length(Boundary) / NB end,
    {Agree, Mass, length(lists:usort(Bad))}.

rollout_states(Net, Plants0) -> rstates(Net, Plants0, {0, 0}, ?E0, 0, []).
rstates(_Net, _Pl, _Pos, _En, ?T, Acc) -> Acc;
rstates(_Net, _Pl, _Pos, En, _S, Acc) when En =< 0 -> Acc;
rstates(Net, Pl, Pos, En, S, Acc) ->
    Sn = [_, _, S3, S4, _] = flatland_sim:sense(?W, Pos, none, Pl, En, ?E0),
    N = max(1, ?W div 2),
    {DX, DY} = {round(S3 * N), round(S4 * N)},
    Act = argmax(network_evaluator:evaluate(Net, Sn)),
    Pos2 = flatland_sim:move(Pos, Act, ?W),
    {Pl2, Ate} = eat(Pl, Pos2),
    rstates(Net, Pl2, Pos2, En - ?EM + case Ate of true -> ?EP; false -> 0 end, S + 1,
            [{DX, DY, Act} | Acc]).

%%%============================================================================
%%% Runner
%%%============================================================================
run() ->
    io:format("== EXP-065: is greedy the CEILING, and is the gap a SHORTFALL or a MIXTURE? ==~n"),
    io:format("config: exp058-faithful (~p gens, ~p layouts, mu=lambda=~p, sigma=~p), n=~p runs/arm~n",
              [?GENS, ?NLAY, ?MU, ?SIGMA, ?NRUNS]),

    %% ---- free finding: dead coordinates in the FORAGE task ----
    io:format("~n-- FREE FINDING: dead search dimensions in FORAGE --~n"),
    io:format("sense/6 is called with Opp=none, so inputs 1,2 are identically 0 in EVERY forage state.~n"),
    io:format("Globally dead weights (input 1,2 -> each of ~p hidden units): ~p of ~p coordinates = ~.1f%%~n",
              [?HID, 2 * ?HID, ?NP, 100.0 * 2 * ?HID / ?NP]),
    io:format("flat indices: ~w~n", [lists:flatten([[1 + 5 * (H - 1), 2 + 5 * (H - 1)] || H <- lists:seq(1, ?HID)])]),

    %% ---- (1) instrument check ----
    Greedy = mean([forage(greedy, Pl) || Pl <- layouts()]),
    {Valid, Ok, Tot, Bad} = check_constructed(),
    CFit = fit(constructed()),
    io:format("~n-- (1) INSTRUMENT CHECK: constructed greedy policy (a=~.2f c=~.2f eps=~.2f) --~n",
              [?CA, ?CC, ?CEPS]),
    io:format("validity condition (1+eps)*tanh(0.75a) < tanh(a): ~p~n", [Valid]),
    io:format("exhaustive state agreement: ~p/~p~n", [Ok, Tot]),
    case Bad of [] -> ok; _ -> io:format("MISMATCHES: ~p~n", [lists:sublist(Bad, 10)]) end,
    io:format("constructed net return=~.4f  vs hand-coded greedy=~.4f  (must be EXACT)~n", [CFit, Greedy]),
    Constructed = (Valid andalso Ok =:= Tot andalso abs(CFit - Greedy) < 1.0e-9),
    io:format("INSTRUMENT ~s~n", [case Constructed of true -> "VALID"; false -> "INVALID -- fix before reading below" end]),

    %% ---- (2) primary: is greedy the ceiling? ----
    io:format("~n-- (2) PRIMARY: is greedy the CEILING? (common random numbers by run index) --~n"),
    Seed = constructed(),
    ArmG = [begin rand:seed(exsss, {1000 + I, 1000 + I, 1000 + I}), ea(?GENS, Seed) end || I <- lists:seq(1, ?NRUNS)],
    ArmR = [begin rand:seed(exsss, {1000 + I, 1000 + I, 1000 + I}), ea(?GENS, none) end || I <- lists:seq(1, ?NRUNS)],
    io:format("arm G (seeded with constructed greedy): median=~.4f min=~.4f max=~.4f~n",
              [median(ArmG), lists:min(ArmG), lists:max(ArmG)]),
    io:format("arm R (N(0,1) init)                   : median=~.4f min=~.4f max=~.4f~n",
              [median(ArmR), lists:min(ArmR), lists:max(ArmR)]),
    io:format("greedy reference = ~.4f ; 1.02x = ~.4f ; 1.10x = ~.4f~n",
              [Greedy, 1.02 * Greedy, 1.10 * Greedy]),
    MG = median(ArmG),
    Verdict = if MG >= 1.10 * Greedy -> "GREEDY IS NOT THE CEILING -- every '% of greedy' in 058-064 is mislabelled";
                 MG < 1.02 * Greedy  -> "GREEDY IS NEAR THE CEILING -- '% of greedy' is a fair yardstick";
                 true                -> "BETWEEN 1.02x and 1.10x -- report the number, make no framing claim"
              end,
    io:format("PRIMARY VERDICT: ~s~n", [Verdict]),

    %% ---- (3) secondary: shortfall or mixture? ----
    io:format("~n-- (3) SECONDARY: shortfall or MIXTURE? (arm R; success = >= 0.95 * greedy) --~n"),
    Thr = 0.95 * Greedy,
    Succ = [X || X <- ArmR, X >= Thr],
    Fail = [X || X <- ArmR, X < Thr],
    Rate = length(Succ) / length(ArmR),
    {Lo, Hi} = boot_ci(ArmR, Thr),
    io:format("success rate = ~.3f  (~p/~p)  bootstrap 95% CI [~.3f, ~.3f]~n",
              [Rate, length(Succ), length(ArmR), Lo, Hi]),
    io:format("successes: n=~p median=~s~n", [length(Succ), fmt(Succ)]),
    io:format("failures : n=~p median=~s~n", [length(Fail), fmt(Fail)]),
    IQR = iqr(ArmR),
    io:format("arm R IQR = [~.3f, ~.3f] = [~.3f, ~.3f] x greedy~n",
              [element(1, IQR), element(2, IQR), element(1, IQR) / Greedy, element(2, IQR) / Greedy]),
    SVerdict =
        case {Rate >= 0.4 andalso Rate =< 0.9 andalso Succ =/= [] andalso median(Succ) >= Greedy,
              Rate < 0.1 andalso element(1, IQR) / Greedy >= 0.8 andalso element(2, IQR) / Greedy =< 0.92} of
            {true, _} -> "MIXTURE -- the gap is a FAILURE RATE; remedy is restarts, not step size";
            {_, true} -> "UNIFORM SHORTFALL -- a landscape-geometry story is warranted";
            _         -> "NEITHER pre-declared pattern -- report the numbers, no mechanism claim"
        end,
    io:format("SECONDARY VERDICT: ~s~n", [SVerdict]),

    %% ---- (4) tertiary: mechanism ----
    io:format("~n-- (4) TERTIARY: champion disagreement vs the greedy rule (arm R) --~n"),
    Champs = [begin rand:seed(exsss, {2000 + I, 2000 + I, 2000 + I}), ea_champ(?GENS) end
              || I <- lists:seq(1, 10)],
    Maps = [{F, disagreement(W)} || {F, W} <- Champs],
    [io:format("champ fit=~.3f  action-agreement=~.3f  boundary/far mass=~.3f  distinct bad states=~p~n",
               [F, A, M, D]) || {F, {A, M, D}} <- Maps],
    Masses = [M || {_F, {_A, M, _D}} <- Maps],
    Dists = [D || {_F, {_A, _M, D}} <- Maps],
    io:format("median boundary/far mass=~.3f  median distinct bad states=~.1f~n", [median(Masses), median(Dists)]),
    TVerdict = case median(Masses) >= 0.5 of
                   true -> "BOUNDARY/SATURATION effect";
                   false -> case median(Dists) > 20 of
                                true -> "DIFFUSELY WRONG POLICY -- no boundary story licensed";
                                false -> "NEITHER pattern cleanly"
                            end
               end,
    io:format("TERTIARY VERDICT: ~s~n", [TVerdict]),

    %% ---- per-run persistence (the feed is the record) ----
    io:format("~n-- PER-RUN VALUES (the feed is the record) --~n"),
    io:format("armG_seeds=~w~n", [[1000 + I || I <- lists:seq(1, ?NRUNS)]]),
    io:format("armG=~s~n", [fmt_all(ArmG)]),
    io:format("armR=~s~n", [fmt_all(ArmR)]),
    io:format("champ_seeds=~w~n", [[2000 + I || I <- lists:seq(1, 10)]]),
    io:format("champ_fits=~s~n", [fmt_all([F || {F, _} <- Champs])]),
    io:format("evals_per_run=~p (~p gens x ~p scored per gen, parents re-scored as in exp058)~n",
              [?GENS * 2 * ?MU, ?GENS, 2 * ?MU]),
    ok.

%%%============================================================================
%%% Small stats
%%%============================================================================
fmt([]) -> "n/a";
fmt(L) -> lists:flatten(io_lib:format("~.3f", [median(L)])).
fmt_all(L) -> lists:flatten([io_lib:format("~.4f ", [X]) || X <- L]).

median(L) ->
    S = lists:sort(L), N = length(S),
    case N rem 2 of
        1 -> lists:nth(N div 2 + 1, S) * 1.0;
        0 -> (lists:nth(N div 2, S) + lists:nth(N div 2 + 1, S)) / 2.0
    end.

iqr(L) ->
    S = lists:sort(L), N = length(S),
    {lists:nth(max(1, N div 4), S), lists:nth(max(1, (3 * N) div 4), S)}.

%% bootstrap 95% CI on the success RATE
boot_ci(L, Thr) ->
    N = length(L), R = 10000,
    Rates = [begin
                 Samp = [lists:nth(rand:uniform(N), L) || _ <- lists:seq(1, N)],
                 length([X || X <- Samp, X >= Thr]) / N
             end || _ <- lists:seq(1, R)],
    S = lists:sort(Rates),
    {lists:nth(max(1, round(0.025 * R)), S), lists:nth(min(R, round(0.975 * R)), S)}.

argmax([H | T]) -> argmax(T, H, 0, 1).
argmax([], _B, BI, _I) -> BI;
argmax([H | T], B, _BI, I) when H > B -> argmax(T, H, I, I + 1);
argmax([_H | T], B, BI, I) -> argmax(T, B, BI, I + 1).
b(true) -> 1; b(false) -> 0.
mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).
