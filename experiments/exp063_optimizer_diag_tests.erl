%%%-------------------------------------------------------------------
%%% @doc EXP-063 (DIAGNOSTIC, UNSIGNED — its drafted insight was REFUSED at the CLAIM gate)
%%%
%%% Asks whether the Flatland rungs (058-062) were limited by a weak search algorithm. Runs the
%%% Flatland foraging fitness (plants eaten by a [5,6,4] net, dim 64) at a nominal 2000-evaluation
%%% budget under THREE optimizers, n=24 runs each, vs the hand-coded greedy (34.25):
%%%
%%%   1. `ea058/1'      -- exp058's `evolve/3' scheme: (mu+lambda) truncation, mu=lambda=20, FIXED
%%%                        sigma=0.2, uniform parent pick, elitist over Pop++Off. NOTE: 50 gens over
%%%                        8 layouts here, where exp058 gate_0b actually ran 80 gens over 12 -- so
%%%                        this is the scheme, NOT a faithful reproduction of 058's configuration.
%%%   2. `mu_lambda_es' -- the library self-adaptive (mu,lambda)-ES.
%%%   3. `sep_cma_es'   -- the library separable/diagonal CMA-ES (insight 028).
%%%
%%% RESULT AT 2000 EVALS: medians 28.94 / 29.00 / 29.00, no pair separated. But this budget is
%%% ~31 evaluations per dimension on a 64-dim problem, where sep_cma_es's covariance (learning rates
%%% O(1/N), 100 generations at N=64) has barely moved -- so a null here is NEAR-DEFINITIONAL and does
%%% NOT establish "the optimizer is not the lever". The CLAIM gate refused the insight drafted from
%%% this feed. Known defects, all to be fixed before re-gating: budget too small (needs a 20k cell);
%%% ea058 re-scores parents so it spends 1000 UNIQUE evals vs 2000 for the ESs; the 058 reproduction
%%% uses 50 gens / 8 layouts where 058 actually ran 80 gens / 12 layouts; medians on a 0.125-value
%%% grid collide by construction (use means + bootstrap CI + TOST); sep_cma_es starts at the ZERO
%%% vector (constant-move policy) while the others init N(0,1); no common random numbers across arms;
%%% per-run values are not persisted. See exp064_optimizer_strength_flatland.md for the full list.
%%%
%%% What IS earned from this feed: the n=8 read that sep_cma_es "removes mu+lambda's failure tail"
%%% is REFUTED -- all three arms retain failure runs at n=24 (minima 13.38 / 12.50 / 13.75).
%%% @end
%%%-------------------------------------------------------------------
-module(exp063_optimizer_diag_tests).

-export([run/0]).

-define(W, 9).
-define(T, 40).
-define(HID, 6).
-define(NP, 5 * ?HID + ?HID + 4 * ?HID + 4).   %% [5,6,4] = 64
-define(NPLANTS, 8).
-define(E0, 20).
-define(EM, 1).
-define(EP, 4).

cells() -> [{X, Y} || X <- lists:seq(0, ?W - 1), Y <- lists:seq(0, ?W - 1)].
plants_at(Off) ->
    All = [C || C <- cells(), C =/= {0, 0}],
    Step = max(1, length(All) div ?NPLANTS),
    lists:usort([lists:nth(((Off + I * Step) rem length(All)) + 1, All) || I <- lists:seq(0, ?NPLANTS - 1)]).
layouts() -> [plants_at(Off) || Off <- lists:seq(1, 8)].

%% foraging: plants eaten over T steps, no predator (the exp058 forage metric)
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
regrow(Pl, {X, Y}) -> Free = [C || C <- cells(), not lists:member(C, [{X, Y} | Pl])], lists:nth(((X * ?W + Y) rem max(1, length(Free))) + 1, Free).

decide({net, Net}, S, _Self, _Pl) -> argmax(network_evaluator:evaluate(Net, S));
decide(greedy, _S, Self, Pl) -> case flatland_sim:nearest(Self, Pl, ?W) of none -> 0; P -> flatland_sim:toward(Self, P, ?W) end;
decide(random, _S, _Self, _Pl) -> rand:uniform(4) - 1.

mk_net(W) -> network_evaluator:set_weights(network_evaluator:create_feedforward(5, [?HID], 4, tanh, tanh), W).
%% fitness for the optimizers: mean plants eaten by the net over the layouts (higher = better)
fit(W) -> mean([forage({net, mk_net(W)}, Pl) || Pl <- layouts()]).

%% The EA the Flatland rungs ACTUALLY ran (exp058 evolve/3, verbatim): (mu+lambda) truncation,
%% mu=lambda=20, FIXED sigma=0.2, uniform parent pick, elitist over Pop++Off. 40 evals/gen.
-define(SIGMA, 0.2).
ea058(Gens) ->
    Pop = [[rand:normal() || _ <- lists:seq(1, ?NP)] || _ <- lists:seq(1, 20)],
    ea058_loop(Gens, Pop, 0.0).
ea058_loop(0, _Pop, B) -> B;
ea058_loop(G, Pop, B) ->
    Off = [[X + ?SIGMA * rand:normal() || X <- lists:nth(rand:uniform(length(Pop)), Pop)] || _ <- lists:seq(1, 20)],
    Ranked = lists:reverse(lists:keysort(1, [{fit(Gm), Gm} || Gm <- Pop ++ Off])),
    ea058_loop(G - 1, [Gm || {_F, Gm} <- lists:sublist(Ranked, 20)], max(B, element(1, hd(Ranked)))).

run() ->
    N = 24,
    Greedy = mean([forage(greedy, Pl) || Pl <- layouts()]),
    io:format("== EXP-063 diagnostic: optimizer strength on Flatland foraging (dim=~p, n=~p runs each) ==~n", [?NP, N]),
    io:format("hand-coded greedy baseline = ~.2f plants~n", [Greedy]),
    Opts = #{lambda => 20, max_generations => 100, init_sigma => 1.0},
    EA = [ea058(50) || _ <- lists:seq(1, N)],   %% 50 gens x 40 evals = 2000, matched
    io:format("exp058 EA   : median=~.2f (min ~.2f, max ~.2f) = ~.1f%% of greedy   <-- the EA the rungs ran~n",
              [median(EA), lists:min(EA), lists:max(EA), 100.0 * median(EA) / Greedy]),
    ML = [maps:get(fitness, mu_lambda_es:evolve(fun fit/1, ?NP, Opts)) || _ <- lists:seq(1, N)],
    CM = [maps:get(fitness, sep_cma_es:evolve(fun fit/1, ?NP, Opts)) || _ <- lists:seq(1, N)],
    io:format("mu_lambda_es: median=~.2f (min ~.2f, max ~.2f) = ~.1f%% of greedy~n",
              [median(ML), lists:min(ML), lists:max(ML), 100.0 * median(ML) / Greedy]),
    io:format("sep_cma_es  : median=~.2f (min ~.2f, max ~.2f) = ~.1f%% of greedy~n",
              [median(CM), lists:min(CM), lists:max(CM), 100.0 * median(CM) / Greedy]),
    io:format("~n-- permutation tests on the median difference (10k shuffles, two-sided) --~n"),
    io:format("sep_cma   vs mu_lambda: diff=~.2f  p=~.4f~n", [median(CM) - median(ML), perm(CM, ML)]),
    io:format("mu_lambda vs exp058EA : diff=~.2f  p=~.4f~n", [median(ML) - median(EA), perm(ML, EA)]),
    io:format("sep_cma   vs exp058EA : diff=~.2f  p=~.4f~n", [median(CM) - median(EA), perm(CM, EA)]),
    io:format("best-of-run MAXIMA (what the rungs actually read): ea058=~.2f mu_lambda=~.2f sep_cma=~.2f (greedy=~.2f)~n",
              [lists:max(EA), lists:max(ML), lists:max(CM), Greedy]),
    ok.

%% two-sided permutation test on the difference of medians
perm(A, B) ->
    Obs = abs(median(A) - median(B)),
    All = A ++ B, Na = length(A), R = 10000,
    Hits = length([x || _ <- lists:seq(1, R),
                        begin
                            Sh = [E || {_, E} <- lists:sort([{rand:uniform(), E} || E <- All])],
                            abs(median(lists:sublist(Sh, Na)) - median(lists:nthtail(Na, Sh))) >= Obs
                        end]),
    Hits / R.
median(L) -> S = lists:sort(L), Nn = length(S), case Nn rem 2 of 1 -> lists:nth(Nn div 2 + 1, S) * 1.0; 0 -> (lists:nth(Nn div 2, S) + lists:nth(Nn div 2 + 1, S)) / 2.0 end.

argmax([H | T]) -> argmax(T, H, 0, 1).
argmax([], _B, BI, _I) -> BI;
argmax([H | T], B, _BI, I) when H > B -> argmax(T, H, I, I + 1);
argmax([_H | T], B, BI, I) -> argmax(T, B, BI, I + 1).
b(true) -> 1; b(false) -> 0.
mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).
