%%%-------------------------------------------------------------------
%%% @doc EXP-063 (DIAGNOSTIC, unsigned) — is the OPTIMIZER the Flatland bottleneck?
%%%
%%% Every Flatland rung (058-062) used a plain (mu+lambda) truncation EA that under-converged
%%% (foraging plateaued below the hand-coded greedy). P2 asks: does a STRONGER optimizer close
%%% the gap? Diagnostic: run the SAME Flatland foraging fitness (plants eaten by a [5,6,4] net)
%%% under mu_lambda_es vs sep_cma_es at a MATCHED evaluation budget, vs the hand-coded greedy (~34)
%%% and random (~2). If sep-CMA-ES reaches greedy where mu+lambda plateaus, the optimizer is the
%%% lever -> formalise as a signed P2 experiment. Unsigned scoping only.
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

run() ->
    N = 8,
    Greedy = mean([forage(greedy, Pl) || Pl <- layouts()]),
    io:format("== EXP-063 diagnostic: optimizer strength on Flatland foraging (dim=~p, n=~p runs each) ==~n", [?NP, N]),
    io:format("hand-coded greedy baseline = ~.2f plants~n", [Greedy]),
    Opts = #{lambda => 20, max_generations => 100, init_sigma => 1.0},
    ML = [maps:get(fitness, mu_lambda_es:evolve(fun fit/1, ?NP, Opts)) || _ <- lists:seq(1, N)],
    CM = [maps:get(fitness, sep_cma_es:evolve(fun fit/1, ?NP, Opts)) || _ <- lists:seq(1, N)],
    io:format("mu_lambda_es: median=~.2f (min ~.2f, max ~.2f) = ~.1f%% of greedy~n",
              [median(ML), lists:min(ML), lists:max(ML), 100.0 * median(ML) / Greedy]),
    io:format("sep_cma_es  : median=~.2f (min ~.2f, max ~.2f) = ~.1f%% of greedy~n",
              [median(CM), lists:min(CM), lists:max(CM), 100.0 * median(CM) / Greedy]),
    io:format("advantage (sep_cma - mu_lambda) median-diff = ~.2f plants~n", [median(CM) - median(ML)]),
    io:format("=> at 2000 evals, the STRONGER optimizer (sep-CMA-ES) reaches ~.1f%% vs ~.1f%% of greedy~n",
              [100.0 * median(CM) / Greedy, 100.0 * median(ML) / Greedy]),
    ok.
median(L) -> S = lists:sort(L), Nn = length(S), case Nn rem 2 of 1 -> lists:nth(Nn div 2 + 1, S) * 1.0; 0 -> (lists:nth(Nn div 2, S) + lists:nth(Nn div 2 + 1, S)) / 2.0 end.

argmax([H | T]) -> argmax(T, H, 0, 1).
argmax([], _B, BI, _I) -> BI;
argmax([H | T], B, _BI, I) when H > B -> argmax(T, H, I, I + 1);
argmax([_H | T], B, BI, I) -> argmax(T, B, BI, I + 1).
b(true) -> 1; b(false) -> 0.
mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).
