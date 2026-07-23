%%%-------------------------------------------------------------------
%%% @doc EXP-055 — P7 rung 3: does selecting on a MISALIGNED proxy decouple from
%%% true quality, and only under asymmetric improvement costs?
%%%
%%% Pre-registration (design-gated): experiments/exp055_coevolution_benchmark_alignment.md
%%% Run: erl -noshell -pa <ebin> -eval 'exp055_coevolution_benchmark_alignment_tests:run(), init:stop().'
%%%
%%% 2D coevolution; true quality q=min(x1,x2) (conjunctive). 2x2: selection proxy
%%% {aligned=min | proxy=mean} x cost regime {symmetric | asymmetric (x2 10x costlier)}.
%%% Aligned selection should reach high true min in both regimes; sum-proxy should be
%%% benign under symmetric costs but reach LOWER true min (lopsided) under asymmetric.
%%% Static 36-player min-vs-mean discordance = a runner UNIT TEST, not signed.
%%% Pure Erlang, no net/NIF.
%%% @end
%%%-------------------------------------------------------------------
-module(exp055_coevolution_benchmark_alignment_tests).

-export([run/0, run/1, validate/0]).

-define(MU, 30).
-define(LAMBDA, 30).
-define(SIG1, 0.3).       %% x1 mutation (cheap in both regimes)
-define(SIG2_SYM, 0.3).   %% x2 mutation, symmetric regime
-define(SIG2_ASYM, 0.03). %% x2 mutation, asymmetric regime (10x costlier)
-define(TAU, 0.3).
-define(X0, 50.0).
-define(BOOT, 2000).
-define(FEED, "exp055_feed.txt").

run() -> run(#{n => 30, r => 150}).
validate() -> run(#{n => 6, r => 60}).

run(#{n := N, r := R}) ->
    {ok, Fd} = file:open(?FEED, [write]),
    emit(Fd, "== EXP-055 misaligned selection proxy: does selecting on sum decouple from true min? ==~n"),
    emit(Fd, "config: mu=~p lambda=~p sig1=~.2f sig2(sym)=~.2f sig2(asym)=~.2f tau=~.2f x0=~.1f R=~p n=~p~n",
         [?MU, ?LAMBDA, ?SIG1, ?SIG2_SYM, ?SIG2_ASYM, ?TAU, ?X0, R, N]),
    unit_test(Fd),
    Cells = [{aligned, symmetric}, {proxy, symmetric}, {aligned, asymmetric}, {proxy, asymmetric}],
    Results = [{C, [one_run(C, R) || _ <- lists:seq(1, N)]} || C <- Cells],
    [report_cell(Fd, C, Rs) || {C, Rs} <- Results],
    verdict(Fd, Results),
    file:close(Fd),
    ok.

%% Runner unit test (NOT a finding): min and mean rank lopsided players discordantly.
unit_test(Fd) ->
    Panel = [{X1, X2} || X1 <- [10, 30, 50, 70, 90, 110], X2 <- [10, 30, 50, 70, 90, 110]],
    Disc = length([1 || A <- Panel, B <- Panel,
                        minv(A) < minv(B), meanv(A) > meanv(B)]),
    RankLop = meanv({110, 10}) > meanv({50, 50}) andalso minv({110, 10}) < minv({50, 50}),
    emit(Fd, "unit test (not signed): min-vs-mean discordant ordered pairs in 36-panel = ~p; "
             "mean ranks (110,10) above (50,50) while min ranks below = ~p~n", [Disc, RankLop]).

%%%============================================================================
%%% One coevolution run in a cell -> #{firstq, lastq, lop}
%%%============================================================================
one_run({Proxy, Regime}, R) ->
    Pop = [{?X0, ?X0} || _ <- lists:seq(1, ?MU)],
    Series = gen_loop(1, R, Pop, Pop, Proxy, Regime, []),
    {FirstQ, _} = hd(Series),
    {LastQ, LastLop} = lists:last(Series),
    #{firstq => FirstQ, lastq => LastQ, lopq => LastLop}.

gen_loop(G, R, _A, _B, _Proxy, _Regime, Acc) when G > R -> lists:reverse(Acc);
gen_loop(G, R, A, B, Proxy, Regime, Acc) ->
    A1 = top_mu(A ++ offspring(A, Regime), B, Proxy),
    B1 = top_mu(B ++ offspring(B, Regime), A, Proxy),
    TrueQ = max(max_min(A1), max_min(B1)),
    Lop = mean([lopv(P) || P <- A1 ++ B1]),
    gen_loop(G + 1, R, A1, B1, Proxy, Regime, [{TrueQ, Lop} | Acc]).

offspring(Pop, Regime) -> [mutate(pick(Pop), Regime) || _ <- lists:seq(1, ?LAMBDA)].

top_mu(Cands, Opp, Proxy) ->
    Scored = [{fitness(P, Opp, Proxy), P} || P <- Cands],
    [P || {_F, P} <- lists:sublist(lists:reverse(lists:keysort(1, Scored)), ?MU)].

fitness(P, Opp, aligned) -> mean([logistic((minv(P) - minv(O)) / ?TAU) || O <- Opp]);
fitness(P, Opp, proxy) -> mean([logistic((meanv(P) - meanv(O)) / ?TAU) || O <- Opp]).

pick(Pop) -> lists:nth(rand:uniform(length(Pop)), Pop).
mutate({X1, X2}, symmetric) -> {X1 + ?SIG1 * rand:normal(), X2 + ?SIG2_SYM * rand:normal()};
mutate({X1, X2}, asymmetric) -> {X1 + ?SIG1 * rand:normal(), X2 + ?SIG2_ASYM * rand:normal()}.

minv({X1, X2}) -> min(X1, X2).
meanv({X1, X2}) -> (X1 + X2) / 2.
lopv({X1, X2}) -> abs(X1 - X2).
max_min(Pop) -> lists:max([minv(P) || P <- Pop]).

%%%============================================================================
%%% Report + verdict
%%%============================================================================
report_cell(Fd, {Proxy, Regime}, Runs) ->
    FirstQ = [maps:get(firstq, M) || M <- Runs],
    LastQ = [maps:get(lastq, M) || M <- Runs],
    Lop = [maps:get(lopq, M) || M <- Runs],
    {QLo, QHi} = boot_ci(LastQ),
    emit(Fd, "cell ~p/~p: true min-quality first=~.1f -> last=~.1f CI[~.1f,~.1f]; lopsidedness=~.1f~n",
         [Proxy, Regime, median(FirstQ), median(LastQ), QLo, QHi, median(Lop)]).

verdict(Fd, Results) ->
    Q = fun(Proxy, Regime) ->
            {_, Rs} = lists:keyfind({Proxy, Regime}, 1, Results),
            [maps:get(lastq, M) || M <- Rs]
        end,
    L = fun(Proxy, Regime) ->
            {_, Rs} = lists:keyfind({Proxy, Regime}, 1, Results),
            [maps:get(lopq, M) || M <- Rs]
        end,
    First = fun(Proxy, Regime) ->
                {_, Rs} = lists:keyfind({Proxy, Regime}, 1, Results),
                [maps:get(firstq, M) || M <- Rs]
            end,
    {SaLo2, SpLo2} = {median(Q(aligned, symmetric)), median(Q(proxy, symmetric))},
    {AaLo, _} = boot_ci(Q(aligned, asymmetric)), {_, ApHi} = boot_ci(Q(proxy, asymmetric)),
    {AplLo, _} = boot_ci(L(proxy, asymmetric)), {_, AalHi} = boot_ci(L(aligned, asymmetric)),
    Escalates = (median(Q(aligned, symmetric)) > median(First(aligned, symmetric)))
                andalso (median(Q(aligned, asymmetric)) > median(First(aligned, asymmetric))),
    {SaLo, SaHi} = boot_ci(Q(aligned, symmetric)), {SpLo, SpHi} = boot_ci(Q(proxy, symmetric)),
    %% Direction-aware: "bite in symmetric" = aligned STRICTLY higher than proxy (aligned
    %% outperforms). A tiny disjoint gap with proxy higher is NOT a bite -- the proxy is benign
    %% (even marginally helpful). CI-overlap alone is direction-blind (the exploratory-run bug).
    SymAlignedHigher = SaLo > SpHi,
    AsymAlignedHigher = AaLo > ApHi,
    AsymProxyLopsided = AplLo > AalHi,
    emit(Fd, "~n-- Verdict (aligned vs proxy selection, per cost regime) --~n"),
    emit(Fd, "aligned escalates true min (both regimes): ~p~n", [Escalates]),
    emit(Fd, "SYMMETRIC true min: aligned med=~.1f [~.1f,~.1f] vs proxy med=~.1f [~.1f,~.1f] -> aligned strictly higher=~p~n",
         [SaLo2, SaLo, SaHi, SpLo2, SpLo, SpHi, SymAlignedHigher]),
    emit(Fd, "ASYMMETRIC true min: aligned CI-lo=~.1f > proxy CI-hi=~.1f -> aligned higher=~p~n",
         [AaLo, ApHi, AsymAlignedHigher]),
    emit(Fd, "ASYMMETRIC lopsided: proxy CI-lo=~.1f > aligned CI-hi=~.1f -> proxy more lopsided=~p~n",
         [AplLo, AalHi, AsymProxyLopsided]),
    emit(Fd, "~s~n", [classify(Escalates, SymAlignedHigher, AsymAlignedHigher, AsymProxyLopsided)]).

classify(false, _, _, _) ->
    "RESULT=INVALID: aligned selection did not escalate true min-quality -> operator/tau bug; fix first.";
classify(true, false, true, true) ->
    "RESULT=PROXY MISALIGNMENT BITES (asymmetric only): a sum-proxy is BENIGN under symmetric costs "
    "(aligned does not outperform it -- true min is comparable or the proxy is marginally better) but "
    "under asymmetric costs it reaches LOWER true min with far more lopsided champions -- selecting on "
    "a compensatory proxy decouples from conjunctive true quality when improvement costs are uneven. "
    "The graded aligned benchmark reveals the decoupling the proxy's own reading hides.";
classify(true, true, true, _) ->
    "RESULT=PROXY ALWAYS BITES: aligned selection reaches strictly higher true min than the sum-proxy "
    "in BOTH regimes -> the compensatory proxy decouples from conjunctive quality regardless of cost.";
classify(true, _, false, _) ->
    "RESULT=PROXY BENIGN: aligned selection does not outperform the sum-proxy on true min in the "
    "asymmetric regime -> on this task the compensatory proxy did not decouple; signed negative.";
classify(true, _, _, _) ->
    "RESULT=MIXED/INCONCLUSIVE: pattern does not match a clean cell; report descriptively.".

%%%============================================================================
%%% Numerics + stats
%%%============================================================================
logistic(Z) when Z > 30.0 -> 1.0;
logistic(Z) when Z < -30.0 -> 0.0;
logistic(Z) -> 1.0 / (1.0 + math:exp(-Z)).

mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

median([]) -> 0.0;
median(L) ->
    S = lists:sort(L), N = length(S),
    median_pick(N rem 2, S, N).
median_pick(1, S, N) -> lists:nth(N div 2 + 1, S) * 1.0;
median_pick(0, S, N) -> (lists:nth(N div 2, S) + lists:nth(N div 2 + 1, S)) / 2.0.

boot_ci([]) -> {0.0, 0.0};
boot_ci(Vals) ->
    N = length(Vals),
    Reps = [median([lists:nth(rand:uniform(N), Vals) || _ <- lists:seq(1, N)])
            || _ <- lists:seq(1, ?BOOT)],
    S = lists:sort(Reps),
    {pctile(S, 0.025), pctile(S, 0.975)}.
pctile(S, P) ->
    N = length(S), I = max(1, min(N, round(P * N))),
    lists:nth(I, S) * 1.0.

emit(Fd, Fmt) -> emit(Fd, Fmt, []).
emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).
