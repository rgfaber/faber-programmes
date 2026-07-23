%%%-------------------------------------------------------------------
%%% @doc EXP-048 — integration depth (047 follow-up).
%%%
%%% Pre-registration: experiments/exp048_integration_depth.md
%%% Run: erl -noshell -pa <ebins> -eval 'exp048_integration_depth_tests:run(), init:stop().'
%%%
%%% Is 047's good-arm tracking genuine multi-trial INTEGRATION, or a short reactive
%%% window (holding the last few reward/action pairs)? Decode the good arm from a
%%% k-step sensor-history window (k in {1,3,5,10}) and compare to the state AUC.
%%% The k at which the window matches the state is the substrate's memory depth.
%%%
%%% Replay-only: consumes the PERSISTED 047 champions, no re-evolution. Self-contained
%%% (reuses the 047 harness verbatim; runners are standalone records). Accessors only.
%%% @end
%%%-------------------------------------------------------------------
-module(exp048_integration_depth_tests).

-export([run/0, run/1]).

-define(INPUTS, 3).
-define(HIDDEN, 10).
-define(OUTPUTS, 1).
-define(LIFETIME, 60).
-define(REVERSAL_AT, 30).
-define(PHI, 0.8).
-define(ARMS, [fixed, cfc, nm_global, nm_pc]).
-define(ADAPTIVE, [cfc, nm_global, nm_pc]).
-define(KS, [1, 3, 5, 10]).
-define(LOGREG_ITERS, 1200).   %% raised from 400: the 20-30 dim windows must not be undertrained
-define(LOGREG_LR, 0.5).
-define(FEED, "exp048_feed.txt").
-define(CHAMPS,
        "programmes/p3_meta_learning/exp047_lifetime_mechanism_probe/exp047_champions.eterm").

holdout_instances() ->
    [{G, ?REVERSAL_AT, ?LIFETIME, Fs, ?PHI}
     || {G, Fs} <- [{0, 901}, {1, 902}, {0, 903}, {1, 904}, {0, 905}, {1, 906},
                    {0, 907}, {1, 908}, {0, 909}, {1, 910}, {0, 911}, {1, 912},
                    {0, 913}, {1, 914}, {0, 915}, {1, 916}]].

%%%============================================================================
%%% Entry
%%%============================================================================
run() -> run(?CHAMPS).

run(ChampsFile) ->
    {ok, Bin} = file:read_file(ChampsFile),
    Champions = binary_to_term(Bin),
    {ok, Fd} = file:open(?FEED, [write]),
    emit(Fd, "== EXP-048 integration depth (047 follow-up, replay-only) ==~n", []),
    emit(Fd, "champions: ~s~n", [ChampsFile]),
    emit(Fd, "decode good-arm from a k-step [reward,action] window vs the internal state~n"),
    emit(Fd, "k=1 is the one-step reactive baseline; the k that matches state = memory depth~n~n"),
    Rows = [depth_row(Fd, Arm, Champs) || {Arm, Champs} <- Champions],
    verdict(Fd, Rows),
    file:close(Fd),
    ok.

depth_row(Fd, Arm, Champs) ->
    PC = [champion_aucs(Arm, maps:get(genome, C)) || C <- Champs],
    States = [S || {S, _, _} <- PC],
    Raw = fun(K) -> mean([getk(K, R) || {_, R, _} <- PC]) end,
    Aug = fun(K) -> mean([getk(K, A) || {_, _, A} <- PC]) end,
    %% Paired, per champion: does the state beat the INTERACTION-augmented 10-window?
    %% (the per-step bandit evidence is r*a, which a raw-[r,a] linear decoder cannot form.)
    Diffs = [S - getk(10, A) || {S, _, A} <- PC],
    Pos = length([D || D <- Diffs, D > 0]),
    State = mean(States),
    emit(Fd, "EXP048 arm=~p state=~.3f(sd~.3f)~n", [Arm, State, sd_of(States)]),
    emit(Fd, "  raw window (last k [r,a]):          w1=~.3f w3=~.3f w5=~.3f w10=~.3f~n",
         [Raw(1), Raw(3), Raw(5), Raw(10)]),
    emit(Fd, "  interaction window (+ r*a / step):  w1=~.3f w3=~.3f w5=~.3f w10=~.3f~n",
         [Aug(1), Aug(3), Aug(5), Aug(10)]),
    emit(Fd, "  state - interaction_w10 (paired):   mean=~.3f sd=~.3f positive=~p/~p~n",
         [mean(Diffs), sd_of(Diffs), Pos, length(Diffs)]),
    {Arm, State, Aug(5), mean(Diffs), Pos}.

getk(K, KVs) -> element(2, lists:keyfind(K, 1, KVs)).

%% Per champion: {StateAuc, [{K,RawWinAuc}], [{K,AugWinAuc}]}. One replay, reused.
champion_aucs(Arm, G) ->
    R = replay(Arm, G),
    {decode(state_feats(R)),
     [{K, decode(window_feats(K, R))} || K <- ?KS],
     [{K, decode(aug_window_feats(K, R))} || K <- ?KS]}.

%%%============================================================================
%%% Verdict: the INTERACTION-augmented window is the fair DEEP test. The per-step
%%% bandit evidence is the product r*a (which arm the last trial implicates); a raw
%%% [r,a] linear decoder cannot form it, so state-beats-raw-window would confound
%%% depth with decoder expressiveness. DEEP must beat the interaction window.
%%%============================================================================
verdict(Fd, Rows) ->
    emit(Fd, "~n-- Verdict (interaction-window controlled, paired) --~n"),
    [emit(Fd, "~p: ~s~n", [Arm, classify(State, AugW5, Diff, Pos)])
     || {Arm, State, AugW5, Diff, Pos} <- Rows, lists:member(Arm, ?ADAPTIVE)],
    {_, FS, _, _, _} = lists:keyfind(fixed, 1, Rows),
    emit(Fd, "fixed sentinel (state should be ~~0.5): state=~.3f~n", [FS]).

%% SHALLOW if a <=5-step interaction window matches the state. DEEP only if the state
%% beats the interaction 10-window by a paired mean > 0.02 with a consistent sign.
classify(State, AugW5, _Diff, _Pos) when AugW5 >= State - 0.02 ->
    "SHALLOW: a <=5-step interaction window matches the state; short reactive window, "
    "not deep integration.";
classify(_State, _AugW5, Diff, Pos) when Diff > 0.02, Pos >= 8 ->
    "DEEP: state beats even the interaction 10-window (paired mean > 0.02, >=8/10 champions); "
    "genuine integration beyond a 10-step window a linear interaction decoder cannot match.";
classify(_State, _AugW5, _Diff, _Pos) ->
    "INTERMEDIATE / not-deep: state does not robustly beat the interaction 10-window.".

%%%============================================================================
%%% Feature extraction: state rows and window rows -> [{Feat, Y, Idx, T}]
%%%============================================================================
state_feats(Replay) ->
    [{St, Y, Idx, T} || {St, _Se, Y, Idx, T} <- Replay].

%% Window feature at each trial = the last K observed [reward,action] pairs, built on
%% the FULL per-instance sequence (transition trials count as history), padded with
%% [0,0] before the episode start.
window_feats(K, Replay) -> wfeats(K, Replay, fun raw_pair/1).
aug_window_feats(K, Replay) -> wfeats(K, Replay, fun aug_pair/1).

wfeats(K, Replay, F) ->
    lists:append([wf_instance(K, Rows, F) || {_Idx, Rows} <- group_by_idx(Replay)]).

wf_instance(K, Rows, F) ->
    Sorted = lists:sort(fun({_, _, _, _, Ta}, {_, _, _, _, Tb}) -> Ta =< Tb end, Rows),
    Sensors = [Se || {_, Se, _, _, _} <- Sorted],
    [{wf(K, Sensors, I, F), Y, Idx, T}
     || {I, {_St, _Se, Y, Idx, T}} <- lists:zip(lists:seq(1, length(Sorted)), Sorted)].

wf(K, Sensors, I, F) ->
    lists:append([F(sensor_at(Sensors, J)) || J <- lists:seq(I - K + 1, I)]).

sensor_at(_S, J) when J < 1 -> [0.0, 0.0];
sensor_at(S, J) -> lists:nth(J, S).

%% Raw pair vs interaction-augmented pair. r*a is the per-trial evidence of which arm
%% is currently good (action +1/-1 for arm0/arm1, reward +1/-1): a linear decoder needs
%% the product to read it, which raw [r,a] cannot supply.
raw_pair([R, A]) -> [R, A].
aug_pair([R, A]) -> [R, A, R * A].

group_by_idx(Rows) ->
    Map = lists:foldl(fun({_, _, _, Idx, _} = R, Acc) ->
                          maps:update_with(Idx, fun(L) -> [R | L] end, [R], Acc)
                      end, #{}, Rows),
    maps:to_list(Map).

%%%============================================================================
%%% Decode a set of {Feat, Y, Idx, T} rows -> test AUC (047's split + filter + logreg)
%%%============================================================================
decode(FeatRows) ->
    Keep = [R || {_, _, _, T} = R <- FeatRows,
                 T < ?REVERSAL_AT orelse T > ?REVERSAL_AT + 2],
    {Train, Test} = lists:partition(fun({_, _, Idx, _}) -> Idx =< 8 end, Keep),
    {Mu, Sd} = standardiser([F || {F, _, _, _} <- Train]),
    Model = train_logreg([standardise(F, Mu, Sd) || {F, _, _, _} <- Train],
                         [Y || {_, Y, _, _} <- Train]),
    auc([predict(Model, standardise(F, Mu, Sd)) || {F, _, _, _} <- Test],
        [Y || {_, Y, _, _} <- Test]).

%%%============================================================================
%%% Replay (verbatim from 047) -> [{StateVec, SensorVec, GoodArm, Idx, Trial}]
%%%============================================================================
replay(Arm, Genome) ->
    Instances = holdout_instances(),
    Indexed = lists:zip(lists:seq(1, length(Instances)), Instances),
    lists:append([replay_instance(Arm, Genome, Idx, I) || {Idx, I} <- Indexed]).

replay_instance(Arm, Genome, Idx, {GoodArm, RevAt, _Life, _Fs, _Phi} = Instance) ->
    Net = build_net(Arm, Genome),
    S0 = prob_reversal_bandit_sim:init(tuple_to_list(Instance)),
    replay_loop(Net, S0, GoodArm, RevAt, Idx, 0, []).

replay_loop(Net, S, GoodArm, RevAt, Idx, Trial, Acc) ->
    {Inputs, S1} = prob_reversal_bandit_sim:sense(sensor, [], S),
    {Output, Net1} = step(Net, Inputs),
    {_Reward, Done, S2} = prob_reversal_bandit_sim:act(actuator, [], Output, S1),
    Row = {state_vec(Net1), sensor_vec(Inputs), good_at(Trial, RevAt, GoodArm), Idx, Trial},
    replay_continue(Done, Net1, S2, GoodArm, RevAt, Idx, Trial + 1, [Row | Acc]).

replay_continue(done, _Net, _S, _GA, _R, _Idx, _Trial, Acc) -> lists:reverse(Acc);
replay_continue(_, Net, S, GA, R, Idx, Trial, Acc) ->
    replay_loop(Net, S, GA, R, Idx, Trial, Acc).

sensor_vec([LastReward, LastAction, _Bias]) -> [LastReward, LastAction].

good_at(Trial, RevAt, GoodArm) when Trial < RevAt -> GoodArm;
good_at(_Trial, _RevAt, GoodArm) -> 1 - GoodArm.

%%%============================================================================
%%% Network construction + step + state (verbatim from 047; accessors only)
%%%============================================================================
net_params() -> ?HIDDEN * ?INPUTS + ?HIDDEN + ?OUTPUTS * ?HIDDEN + ?OUTPUTS.
n_synapses() -> ?HIDDEN * ?INPUTS + ?OUTPUTS * ?HIDDEN.

build_net(fixed, G) ->
    Base = network_evaluator:create_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, []} = lists:split(net_params(), G),
    {fixed, network_evaluator:set_weights(Base, W)};
build_net(cfc, G) ->
    Base = network_evaluator:create_cfc_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, Taus} = lists:split(net_params(), G),
    Net1 = network_evaluator:set_weights(Base, W),
    Meta = network_evaluator:get_neuron_meta(Net1),
    Net2 = network_evaluator:set_neuron_meta(Net1, set_taus(Meta, Taus)),
    {cfc, network_evaluator:reset_internal_state(Net2)};
build_net(nm_global, G) ->
    Base = network_evaluator:create_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, [A, B, C, D, Eta]} = lists:split(net_params(), G),
    {nm_global, {network_evaluator:set_weights(Base, W), {A, B, C, D, Eta}}};
build_net(nm_pc, G) ->
    Base = network_evaluator:create_feedforward(?INPUTS, [?HIDDEN], ?OUTPUTS, tanh, tanh),
    {W, Rest} = lists:split(net_params(), G),
    {Coeffs, [Eta]} = lists:split(4 * n_synapses(), Rest),
    {nm_pc, {network_evaluator:set_weights(Base, W), {pc, build_pc_coeffs(Coeffs), Eta}}}.

set_taus([HiddenMeta, OutputMeta], Taus) ->
    NewHidden = [M#{tau => clamp_tau(T)} || {M, T} <- lists:zip(HiddenMeta, Taus)],
    [NewHidden, OutputMeta].

clamp_tau(T) -> max(0.1, min(2.0, 0.1 + abs(T))).

build_pc_coeffs(Coeffs) ->
    {L1Flat, L2Flat} = lists:split(4 * ?HIDDEN * ?INPUTS, Coeffs),
    L1 = [tuples4(neuron_slice(L1Flat, N, ?INPUTS)) || N <- lists:seq(0, ?HIDDEN - 1)],
    [L1, [tuples4(L2Flat)]].

neuron_slice(Flat, N, Inputs) -> lists:sublist(Flat, N * Inputs * 4 + 1, Inputs * 4).

tuples4([A, B, C, D | Rest]) -> [{A, B, C, D} | tuples4(Rest)];
tuples4([]) -> [].

step({fixed, Net}, Inputs) ->
    {network_evaluator:evaluate(Net, Inputs), {fixed, Net}};
step({cfc, Net}, Inputs) ->
    {Out, Net1} = network_evaluator:evaluate_with_state(Net, Inputs),
    {Out, {cfc, Net1}};
step({nm_global, {Net, Rule}}, Inputs) ->
    {Out, Net1} = network_evaluator:evaluate_with_neuromod(Net, Inputs, Rule, hd(Inputs)),
    {Out, {nm_global, {Net1, Rule}}};
step({nm_pc, {Net, Rule}}, Inputs) ->
    {Out, Net1} = network_evaluator:evaluate_with_neuromod(Net, Inputs, Rule, hd(Inputs)),
    {Out, {nm_pc, {Net1, Rule}}}.

state_vec({fixed, Net}) -> network_evaluator:get_weights(Net);
state_vec({cfc, Net}) -> lists:flatten(network_evaluator:get_internal_state(Net));
state_vec({nm_global, {Net, _}}) -> network_evaluator:get_weights(Net);
state_vec({nm_pc, {Net, _}}) -> network_evaluator:get_weights(Net).

%%%============================================================================
%%% Logistic regression + AUC (verbatim from 047)
%%%============================================================================
standardiser(X) ->
    D = length(hd(X)),
    N = length(X),
    Cols = [[lists:nth(J, Xi) || Xi <- X] || J <- lists:seq(1, D)],
    Mu = [lists:sum(C) / N || C <- Cols],
    Sd = [col_sd(C, M, N) || {C, M} <- lists:zip(Cols, Mu)],
    {Mu, Sd}.

col_sd(C, M, N) -> guard_sd(math:sqrt(lists:sum([(X - M) * (X - M) || X <- C]) / N)).

guard_sd(S) when S < 1.0e-9 -> 1.0;
guard_sd(S) -> S.

standardise(X, Mu, Sd) -> [(Xi - M) / S || {Xi, M, S} <- lists:zip3(X, Mu, Sd)].

train_logreg(X, Y) ->
    D = length(hd(X)),
    Init = {lists:duplicate(D, 0.0), 0.0},
    lists:foldl(fun(_, Model) -> gd_step(X, Y, Model) end, Init, lists:seq(1, ?LOGREG_ITERS)).

gd_step(X, Y, {W, B}) ->
    N = length(X),
    {GW, GB} = lists:foldl(step_grad(W, B), {lists:duplicate(length(W), 0.0), 0.0},
                           lists:zip(X, Y)),
    {vsub(W, vscale(?LOGREG_LR / N, GW)), B - ?LOGREG_LR * GB / N}.

step_grad(W, B) ->
    fun({Xi, Yi}, {AccW, AccB}) ->
        E = sigmoid(dot(W, Xi) + B) - Yi,
        {vadd(AccW, vscale(E, Xi)), AccB + E}
    end.

predict({W, B}, X) -> sigmoid(dot(W, X) + B).

auc(Scores, Labels) ->
    Pairs = lists:zip(Scores, Labels),
    auc_ranked([S || {S, 1} <- Pairs], [S || {S, 0} <- Pairs]).

auc_ranked([], _) -> 0.5;
auc_ranked(_, []) -> 0.5;
auc_ranked(Pos, Neg) ->
    C = lists:sum([lists:sum([pair_score(P, Nv) || Nv <- Neg]) || P <- Pos]),
    C / (length(Pos) * length(Neg)).

pair_score(P, N) when P > N -> 1.0;
pair_score(P, N) when P == N -> 0.5;
pair_score(_, _) -> 0.0.

sigmoid(Z) when Z < -30.0 -> 0.0;
sigmoid(Z) when Z > 30.0 -> 1.0;
sigmoid(Z) -> 1.0 / (1.0 + math:exp(-Z)).

dot(A, B) -> lists:sum([X * Y || {X, Y} <- lists:zip(A, B)]).
vadd(A, B) -> [X + Y || {X, Y} <- lists:zip(A, B)].
vsub(A, B) -> [X - Y || {X, Y} <- lists:zip(A, B)].
vscale(S, A) -> [S * X || X <- A].

mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

sd_of([]) -> 0.0;
sd_of(L) ->
    M = mean(L),
    math:sqrt(mean([(X - M) * (X - M) || X <- L])).

emit(Fd, Fmt) -> emit(Fd, Fmt, []).
emit(Fd, Fmt, Args) ->
    io:format(Fd, Fmt, Args),
    io:format(Fmt, Args).
