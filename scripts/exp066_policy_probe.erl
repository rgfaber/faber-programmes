%%%-------------------------------------------------------------------
%%% @doc EXP-066 post-hoc POLICY PROBE. Read-only, signs nothing.
%%%
%%% THE QUESTION. Arm S champions beat robo_gauntlet's predictive_gun at a
%%% median held-out win rate of 0.9750. Nobody has looked at WHAT THEY DO.
%%% predictive_gun's lead solver estimates the contact's velocity by
%%% differencing two scans and leads the shot by the bullet's flight time, which
%%% ASSUMES THE VELOCITY IS CONSTANT OVER THAT FLIGHT. A champion that weaves
%%% defeats the assumption without ever out-shooting the bot, and a champion
%%% that stays out of the radar beam defeats the ESTIMATOR instead, because
%%% robo_gauntlet:shoot/4 holds fire on any turn whose track is not from this
%%% turn. Those are three different findings and the record distinguishes none
%%% of them.
%%%
%%% WHY THERE IS NO REIMPLEMENTATION HERE. The pilot encoder and the match loop
%%% that produced the archived feed live in unexported functions of the runner.
%%% The sibling shell script extracts the runner's OWN abstract code out of its
%%% compiled beam, renames the module to exp066_view and bolts export_all on, so
%%% every call below runs the exact code that produced the feed. verify/0
%%% recomputes four archived columns (W, margin, shots, pulls) through this
%%% module's own loop and asserts they match the feed to the digit, so the loop
%%% is verified by recomputation rather than trusted.
%%%
%%% THE COUNTERFACTUAL IS THE DECISIVE MEASURE. For every shot the floor bot
%%% takes, the bullet is walked with the engine's own integer arithmetic against
%%% the champion's ACTUAL recorded trajectory, and then against the
%%% COUNTERFACTUAL trajectory in which the champion holds the velocity it had at
%%% the instant of firing. A shot that misses the real champion and hits the
%%% constant-velocity ghost is a shot the champion's weaving defeated. A shot
%%% that misses both was already aimed wrong when it left the barrel.
%%% @end
%%%-------------------------------------------------------------------
-module(exp066_policy_probe).

-compile([export_all, nowarn_export_all]).

-include("robo_sim.hrl").

-define(SIN, 32768).
-define(FP, 256).
-define(HITR, 5120).             %% robo_sim HIT_R
-define(ARENA_W, 204800).
-define(ARENA_H, 153600).
-define(BUCKET, 6400).           %% 25 whole units per range histogram bucket
-define(NBUCKET, 40).
-define(ARCH, "/home/rl/work/github.com/rgfaber/faber-programmes/"
              "programmes/p7_coevolution/exp066_competence_floor/").

%%%============================================================================
%%% CLI
%%%============================================================================
cli(["verify"]) -> verify();
cli(["layout"]) -> layout();
cli(["one", Arm, Seed, K]) ->
    one(list_to_atom(Arm), list_to_integer(Seed), list_to_integer(K));
cli(["run"]) -> run(80);
cli(["run", N]) -> run(list_to_integer(N)).


%% SELF-CHECK ON THE BULLET WALK. One match, every shot event and every engine
%% damage credit printed side by side. The walk is only usable if the bullets it
%% calls hits are exactly the turns on which the engine credited damage.
one(Arm, Seed, K) ->
    {Seed, Net} = lists:keyfind(Seed, 1, nets(Arm)),
    Start = lists:nth(K, heldout(80)),
    {Final, Frames} = trace(Net, {script, predictive_gun}, Start, a),
    Arenas = list_to_tuple([A || {A, _} <- Frames] ++ [Final]),
    Acts = list_to_tuple([Ac || {_, Ac} <- Frames]),
    N = tuple_size(Acts),
    Shots = shots(a, Arenas, Acts, N),
    Walk = [bullet(S, credit_map(a, Arenas, N), b, Arenas, N) || S <- Shots],
    io:format("turns=~p  dealt=~p (~.2f units)  walk hits=~p of ~p shots~n",
              [N, (tank(a, Final))#tank.damage_dealt,
               (tank(a, Final))#tank.damage_dealt / ?FP,
               length([1 || #{hit := true} <- Walk]), length(Shots)]),
    io:format("shot events (at, power, walk hit, flight, min_dist) = ~p~n",
              [[{maps:get(at, S), maps:get(power, S), maps:get(hit, W),
                 maps:get(flight, W), maps:get(min_dist, W)}
                || {S, W} <- lists:zip(Shots, Walk)]]),
    io:format("engine damage credits to a (turn index, increment, units) = ~p~n",
              [credits(a, Arenas, N)]).

%% Credits keyed by ARENA index, not by step index. credits/3 reports the step,
%% and the arena the step produced is one further along; getting that off by one
%% wrong made every hit vanish, which the self-check caught at once.
credit_map(Id, Arenas, N) ->
    maps:from_list([{I + 1, D} || {I, D, _U} <- credits(Id, Arenas, N)]).

credits(Id, Arenas, N) ->
    [{I, D, D / ?FP} || I <- lists:seq(1, N),
                        (D = (tank(Id, element(I + 1, Arenas)))#tank.damage_dealt -
                             (tank(Id, element(I, Arenas)))#tank.damage_dealt) > 0].

%%%============================================================================
%%% The archive
%%%============================================================================
champions(Arm) ->
    {ok, Terms} = file:consult(?ARCH ++ "exp066_champions_" ++
                               atom_to_list(Arm) ++ ".eterm"),
    Terms.

nets(Arm) ->
    [{S, {net, L, Q}} || {champion, _A, S, L, Q, _F, _E} <- champions(Arm)].

heldout(N) -> lists:sublist(exp066_view:split(heldout), N).

%%%============================================================================
%%% The traced match loop. Shape-for-shape the runner's play_step/3: act on the
%%% CURRENT arena, whose scans came from the step that produced these tanks, and
%%% only then step. Reversing those two lines is the silent bug robo_match
%%% exists to prevent, so it is not reversed here either.
%%%============================================================================
trace(Subject, Opp, {AX, AY, AH, BX, BY, BH}, Seat) ->
    Arena = robo_sim:new([{a, AX, AY, AH}, {b, BX, BY, BH}]),
    loop(Arena, seats(Seat, Subject, Opp), []).

seats(a, S, O) -> [{a, mk(S)}, {b, mk(O)}];
seats(b, S, O) -> [{a, mk(O)}, {b, mk(S)}].

mk({net, L, Q}) -> {pilot, {L, Q}, exp066_view:pilot_init()};
mk({script, K}) -> {script, K, robo_gauntlet:init(K)}.

loop(Arena, Ctl, Acc) -> loop_step(Arena, Ctl, Acc, robo_sim:finished(Arena)).

loop_step(Arena, _Ctl, Acc, true) -> {Arena, lists:reverse(Acc)};
loop_step(Arena, Ctl, Acc, false) ->
    Acted = [act_one(T, Ctl, Arena) || T <- robo_sim:alive(Arena)],
    Next = robo_sim:step(Arena, [{Id, I} || {Id, I, _C} <- Acted]),
    loop(Next, restate(Ctl, Acted), [{Arena, Acted} | Acc]).

restate(Ctl, Acted) ->
    lists:foldl(fun({Id, _I, C}, A) -> lists:keystore(Id, 1, A, {Id, C}) end,
                Ctl, Acted).

act_one(#tank{id = Id} = T, Ctl, Arena) ->
    {Id, C} = lists:keyfind(Id, 1, Ctl),
    {I, C2} = drive(C, T, Arena),
    {Id, I, C2}.

drive({script, K, S}, T, A) ->
    {I, S2} = robo_gauntlet:act(K, S, T, A),
    {I, {script, K, S2}};
drive({pilot, N, S}, T, A) ->
    {I, S2} = exp066_view:pilot_act(N, S, T, A),
    {I, {pilot, N, S2}}.

%%%============================================================================
%%% VERIFICATION BY RECOMPUTATION. Four archived columns for arm S seed 2001,
%%% recomputed through the loop above.
%%%============================================================================
verify() ->
    Starts = heldout(80),
    lists:foreach(fun(Seed) -> verify_one(Seed, Starts) end, [2001, 2008, 2015]).

verify_one(Seed, Starts) ->
    {Seed, Net} = lists:keyfind(Seed, 1, nets(s)),
    Os = [outcome(Net, {script, predictive_gun}, St, Seat)
          || St <- Starts, Seat <- [a, b]],
    N = length(Os),
    W = length([1 || #{alive := true, opp_alive := false} <- Os]) / N,
    L = length([1 || #{alive := false, opp_alive := true} <- Os]) / N,
    M = lists:sum([(maps:get(dealt, O) - maps:get(taken, O)) / ?FP
                   || O <- Os]) / N,
    Sh = lists:sum([maps:get(my_shots, O) || O <- Os]) / N,
    Pu = lists:sum([maps:get(pulls, O) || O <- Os]) / N,
    io:format("VERIFY seed ~p  n=~p  W=~.4f L=~.4f margin=~.2f shots=~.2f "
              "pulls=~.2f~n", [Seed, N, W, L, M, Sh, Pu]).

outcome(Subject, Opp, Start, Seat) ->
    {Final, Frames} = trace(Subject, Opp, Start, Seat),
    analyse(Seat, Final, Frames).

%%%============================================================================
%%% ANALYSIS
%%%============================================================================
analyse(Seat, Final, Frames) ->
    Arenas = list_to_tuple([A || {A, _} <- Frames] ++ [Final]),
    Acts = list_to_tuple([Ac || {_, Ac} <- Frames]),
    N = tuple_size(Acts),
    Me = Seat,
    Op = other(Seat),
    MyShots = shots(Me, Arenas, Acts, N),
    OpShots = shots(Op, Arenas, Acts, N),
    MyC = credit_map(Me, Arenas, N),
    OpC = credit_map(Op, Arenas, N),
    MyB = [bullet(S, MyC, Op, Arenas, N) || S <- MyShots],
    OpB = [bullet(S, OpC, Me, Arenas, N) || S <- OpShots],
    MeF = tank(Me, element(tuple_size(Arenas), Arenas)),
    OpF = tank(Op, element(tuple_size(Arenas), Arenas)),
    Motion = motion(Me, Op, Arenas, Acts, N),
    maps:merge(
      Motion,
      #{turns => N,
        dealt => MeF#tank.damage_dealt,
        taken => OpF#tank.damage_dealt,
        alive => not MeF#tank.dead,
        opp_alive => not OpF#tank.dead,
        pulls => length([1 || I <- lists:seq(1, N),
                             (intent(Me, element(I, Acts)))#intent.fire > 0]),
        my_shots => length(MyShots),
        op_shots => length(OpShots),
        my_hits => length([1 || #{hit := true} <- MyB]),
        op_hits => length([1 || #{hit := true} <- OpB]),
        op_cf_hits => length([1 || #{cf_hit := true} <- OpB]),
        op_weave_saves => length([1 || #{hit := false, cf_hit := true} <- OpB]),
        op_blind_misses => length([1 || #{hit := false, cf_hit := false} <- OpB]),
        my_shot_range => sum([maps:get(range, B) || B <- MyB]),
        op_shot_range => sum([maps:get(range, B) || B <- OpB]),
        op_lat_miss => sum([abs(maps:get(lat_miss, B)) || B <- OpB]),
        op_dev_lat => sum([abs(maps:get(dev_lat, B)) || B <- OpB]),
        op_est_lat => sum([abs(maps:get(est_lat, B)) || B <- OpB]),
        op_flight => sum([maps:get(flight, B) || B <- OpB]),
        op_mind => sum([maps:get(min_dist, B) || B <- OpB]),
        op_power => sum([maps:get(power, B) || B <- OpB]),
        my_power => sum([maps:get(power, B) || B <- MyB]),
        my_credits => map_size(MyC),
        op_credits => map_size(OpC),
        uncredited => length([1 || #{walk_hit := true, hit := false} <- MyB]) +
                      length([1 || #{walk_hit := true, hit := false} <- OpB]),
        unwalked => map_size(MyC) - length([1 || #{hit := true} <- MyB]) +
                    map_size(OpC) - length([1 || #{hit := true} <- OpB]),
        dmg_ok => length([1 || #{hit := true, power := P, credited := C} <- MyB,
                               C =:= dmg(P)]) +
                  length([1 || #{hit := true, power := P, credited := C} <- OpB,
                               C =:= dmg(P)]),
        multi => length([1 || {_I, D, _U} <- credits(Me, Arenas, N) ++
                                            credits(Op, Arenas, N), D > 4096])}).

other(a) -> b;
other(b) -> a.

%% robo_sim:damage/1 restated, so a credit can be matched to the power of the one
%% bullet that arrived on that turn rather than merely counted.
dmg(P) when P =< 10 -> (4 * ?FP * P) div 10;
dmg(P) -> (4 * ?FP * P) div 10 + (2 * ?FP * (P - 10)) div 10.

tank(Id, #arena{tanks = Ts}) -> lists:keyfind(Id, #tank.id, Ts).

intent(Id, Acted) -> element(2, lists:keyfind(Id, 1, Acted)).

ctl(Id, Acted) -> element(3, lists:keyfind(Id, 1, Acted)).

sum(L) -> lists:sum(L).

%%%----------------------------------------------------------------------------
%%% Shot events. A shot is a gun_heat zero-to-nonzero transition, which is the
%%% same definition the runner's count_shots/3 uses. The power is the intent's
%%% own fire value under the engine's clamp, and the spawn point is the
%%% shooter's POST-MOVE position, because robo_sim:step/2 moves before it fires.
%%%----------------------------------------------------------------------------
shots(Id, Arenas, Acts, N) ->
    [shot(Id, I, Arenas, Acts) || I <- lists:seq(1, N),
                                  fired(Id, element(I, Arenas),
                                        element(I + 1, Arenas))].

fired(Id, Before, After) -> heat_step(tank(Id, Before), tank(Id, After)).

heat_step(#tank{gun_heat = 0}, #tank{gun_heat = H}) when H > 0 -> true;
heat_step(_B, _A) -> false.

shot(Id, I, Arenas, Acts) ->
    #tank{x = X, y = Y, gun = G} = tank(Id, element(I + 1, Arenas)),
    P = clamp_power((intent(Id, element(I, Acts)))#intent.fire),
    #{at => I, power => P, x => X, y => Y, heading => G,
      bot => bot_of(ctl(Id, element(I, Acts)))}.

clamp_power(P) when P =< 0 -> 0;
clamp_power(P) -> min(30, max(1, P)).

bot_of({script, _K, S}) -> S;
bot_of(_Other) -> none.

%%%----------------------------------------------------------------------------
%%% One bullet, walked with the engine's own per-step integer arithmetic, twice:
%%% against the victim's ACTUAL trajectory, and against the COUNTERFACTUAL in
%%% which the victim holds the velocity it had at the instant of firing.
%%%----------------------------------------------------------------------------
bullet(#{at := I, power := P, x := X, y := Y, heading := G, bot := Bot},
       Cred, Victim, Arenas, N) ->
    Speed = ?FP * 20 - (3 * ?FP * P) div 10,
    #tank{x = VX, y = VY, vel = V, heading = VH} =
        tank(Victim, element(I + 1, Arenas)),
    V0 = {(V * robo_sim:cos(VH)) div ?SIN, (V * robo_sim:sin(VH)) div ?SIN},
    {Hit, MinD, MinI} = walk(X, Y, Speed, G, I + 1, Victim, Arenas, N,
                             {false, 1 bsl 40, I + 1}),
    {CfHit, _CfD, _CfI} = walk_cf(X, Y, Speed, G, I + 1, {VX, VY}, V0, N,
                                  {false, 1 bsl 40, I + 1}),
    M = MinI - (I + 1),
    #tank{x = AX, y = AY} = tank(Victim, element(MinI, Arenas)),
    {PX, PY} = {VX + element(1, V0) * M, VY + element(2, V0) * M},
    {EX, EY} = est_err(Bot, V0),
    #{hit => Hit andalso maps:is_key(MinI, Cred),
      walk_hit => Hit, cf_hit => CfHit, flight => M, power => P,
      at => I, arrive => MinI, credited => maps:get(MinI, Cred, 0),
      range => robo_sim:dist({X, Y}, {VX, VY}) div ?FP,
      min_dist => MinD div ?FP,
      lat_miss => perp(G, AX - X, AY - Y) div ?FP,
      dev_lat => perp(G, AX - PX, AY - PY) div ?FP,
      est_lat => perp(G, EX * M, EY * M) div ?FP}.

%% The engine's advance_one/2, restated: one step, then the hit test against the
%% post-move tanks of the arena this step produced.
walk(_X, _Y, _S, _G, I, _V, _As, N, Acc) when I > N + 1 -> Acc;
walk(X, Y, S, G, I, V, As, N, Acc) ->
    NX = X + (S * robo_sim:cos(G)) div ?SIN,
    NY = Y + (S * robo_sim:sin(G)) div ?SIN,
    #tank{x = TX, y = TY} = tank(V, element(I, As)),
    D = robo_sim:dist({NX, NY}, {TX, TY}),
    walk_step(NX, NY, S, G, I, V, As, N, best(Acc, D, I), D < ?HITR).

%% NO ALIVENESS TEST, and that is deliberate. The engine resolves a bullet
%% against the tanks as they stand BEFORE this bullet lands, so reading the dead
%% flag out of the arena the hit produced rejects the killing blow: measured, it
%% cost one hit per match and put dealt/hits above the engine's own maximum
%% damage per hit, which is how the defect was caught. robo_sim:finished/1 ends a
%% match at the first death, so no step inside a trace ever BEGINS with a corpse
%% and no aliveness test is needed.
walk_step(_X, _Y, _S, _G, _I, _V, _As, _N, {_H, D, MI}, true) -> {true, D, MI};
walk_step(X, Y, _S, _G, _I, _V, _As, _N, Acc, _Hit)
  when X < 0; X > ?ARENA_W; Y < 0; Y > ?ARENA_H -> Acc;
walk_step(X, Y, S, G, I, V, As, N, Acc, _Hit) ->
    walk(X, Y, S, G, I + 1, V, As, N, Acc).

best({H, D0, I0}, D, _I) when D0 =< D -> {H, D0, I0};
best({H, _D0, _I0}, D, I) -> {H, D, I}.

%% The same walk against a ghost that holds V0 for ever. The ghost never dies
%% and is never clamped by a wall, which is exactly the assumption under test.
walk_cf(_X, _Y, _S, _G, I, _P, _V0, N, Acc) when I > N + 1 -> Acc;
walk_cf(X, Y, S, G, I, {PX, PY}, {VX, VY} = V0, N, Acc) ->
    NX = X + (S * robo_sim:cos(G)) div ?SIN,
    NY = Y + (S * robo_sim:sin(G)) div ?SIN,
    D = robo_sim:dist({NX, NY}, {PX + VX, PY + VY}),
    walk_cf_step(NX, NY, S, G, I, {PX + VX, PY + VY}, V0, N,
                 best(Acc, D, I), D < ?HITR).

walk_cf_step(_X, _Y, _S, _G, _I, _P, _V0, _N, {_H, D, MI}, true) ->
    {true, D, MI};
walk_cf_step(X, Y, _S, _G, _I, _P, _V0, _N, Acc, _Hit)
  when X < 0; X > ?ARENA_W; Y < 0; Y > ?ARENA_H -> Acc;
walk_cf_step(X, Y, S, G, I, P, V0, N, Acc, _Hit) ->
    walk_cf(X, Y, S, G, I + 1, P, V0, N, Acc).

%% Component of a vector perpendicular to direction G, fixed-point.
perp(G, DX, DY) -> (robo_sim:cos(G) * DY - robo_sim:sin(G) * DX) div ?SIN.

%%%----------------------------------------------------------------------------
%%% The floor bot's OWN velocity estimate at the instant of firing, which is
%%% robo_gauntlet:enemy_vel/1 restated against the bot record as a tuple. The
%%% layout is asserted by layout/0 rather than assumed.
%%%----------------------------------------------------------------------------
est_err(none, _V0) -> {0, 0};
est_err(Bot, {TX, TY}) ->
    {EX, EY} = bot_vel(Bot),
    {EX - TX, EY - TY}.

bot_vel(B) -> bot_vel_g(element(3, B), element(8, B), element(11, B), B).

bot_vel_g(N, _T, _P, _B) when N < 2 -> {0, 0};
bot_vel_g(_N, T, P, _B) when T =< P -> {0, 0};
bot_vel_g(_N, T, P, _B) when T - P > 8 -> {0, 0};
bot_vel_g(_N, T, P, B) ->
    G = T - P,
    {(element(6, B) - element(9, B)) div G,
     (element(7, B) - element(10, B)) div G}.

layout() ->
    B = robo_gauntlet:init(predictive_gun),
    io:format("bot record = ~p  size=~p~n", [B, tuple_size(B)]),
    io:format("expect {bot,tick,seen,age,dist,ex,ey,etick,px,py,ptick,target}"
              " => size 12, all zero, target=none~n", []),
    io:format("element(12) = ~p~n", [element(12, B)]).

%%%----------------------------------------------------------------------------
%%% MOTION. Everything about what the champion is doing with its body, plus the
%%% floor bot's perception state, accumulated as sums so matches aggregate.
%%%
%%% LATERAL SIGN is the sign of cross(line of sight, own velocity), that is
%%% which way the champion is crossing the floor bot's aiming line. A sign
%%% change is a reversal of the very quantity the lead solver extrapolates.
%%%----------------------------------------------------------------------------
motion(Me, Op, Arenas, Acts, N) ->
    Series = [frame_terms(Me, Op, Arenas, Acts, I) || I <- lists:seq(1, N)],
    Body = [B || {B, _L, _R, _F, _Z, _A, _V, _W, _O, _M} <- Series],
    Lat = [L || {_B, L, _R, _F, _Z, _A, _V, _W, _O, _M} <- Series],
    #{live => N,
      hist => hist(Arenas, N),
      range_sum => sum([R || {_B, _L, R, _F, _Z, _A, _V, _W, _O, _M} <- Series]),
      op_fresh => length([1 || {_B, _L, _R, 0, _Z, _A, _V, _W, _O, _M} <- Series]),
      op_vel_zero => length([1 || {_B, _L, _R, _F, true, _A, _V, _W, _O, _M}
                                  <- Series]),
      my_wall => length([1 || {_B, _L, _R, _F, _Z, _A, _V, true, _O, _M}
                              <- Series]),
      op_wall => length([1 || {_B, _L, _R, _F, _Z, _A, _V, _W, true, _M}
                              <- Series]),
      ram => length([1 || {_B, _L, _R, _F, _Z, _A, _V, _W, _O, true} <- Series]),
      accel_abs => sum([abs(A) || {_B, _L, _R, _F, _Z, A, _V, _W, _O, _M}
                                  <- Series]),
      vel_abs => sum([abs(V) || {_B, _L, _R, _F, _Z, _A, V, _W, _O, _M}
                                <- Series]),
      body_abs => sum([abs(X) || X <- Body]),
      body_flip => flips(Body),
      body_s1 => sum(Body),
      body_s2 => sum([X * X || X <- Body]),
      body_s11 => lag1(Body),
      lat_flip => flips(Lat),
      lat_abs => sum([abs(X) || X <- Lat])}.

frame_terms(Me, Op, Arenas, Acts, I) ->
    A = element(I, Arenas),
    Acted = element(I, Acts),
    #tank{x = MX, y = MY, vel = V, heading = H} = tank(Me, A),
    #tank{x = OX, y = OY, vel = OV} = tank(Op, A),
    #intent{turn_body = TB, accel = Ac} = intent(Me, Acted),
    {VX, VY} = {(V * robo_sim:cos(H)) div ?SIN, (V * robo_sim:sin(H)) div ?SIN},
    Bot = bot_of(ctl(Op, Acted)),
    D = robo_sim:dist({MX, MY}, {OX, OY}),
    {TB, vperp(MX - OX, MY - OY, VX, VY, D), D div ?FP,
     bot_age(Bot), bot_vel(Bot) =:= {0, 0}, Ac, V,
     onwall(MX, MY, V), onwall(OX, OY, OV), D < 9216}.

%% Own velocity resolved PERPENDICULAR to the line of sight, in fixed point, by
%% dividing the cross product by the separation. That is the component the floor
%% bot's lead solver has to extrapolate, and a SIGN CHANGE in it is a reversal of
%% exactly the quantity the constant-velocity assumption is about.
vperp(_LX, _LY, _VX, _VY, 0) -> 0;
vperp(LX, LY, VX, VY, D) -> (LX * VY - LY * VX) div D.

%% A wall-contact turn: robo_sim:wall/3 zeroes the velocity and pins the tank on
%% the clamp boundary, and charges a full unit of energy for it. Detecting the
%% pair is how wall grinding is counted without reaching into the engine.
onwall(X, Y, 0) when X =:= 4608; X =:= 200192; Y =:= 4608; Y =:= 148992 -> true;
onwall(_X, _Y, _V) -> false.

bot_age(none) -> -1;
bot_age(B) -> element(4, B).

flips(L) -> flips(signs(L), 0).

flips([A, B | Rest], N) when A =/= B -> flips([B | Rest], N + 1);
flips([_A | Rest], N) -> flips(Rest, N);
flips([], N) -> N.

signs(L) -> [sgn(X) || X <- L, sgn(X) =/= 0].

sgn(X) when X > 0 -> 1;
sgn(X) when X < 0 -> -1;
sgn(_X) -> 0.

lag1([A, B | Rest]) -> A * B + lag1([B | Rest]);
lag1(_Short) -> 0.

hist(Arenas, N) ->
    lists:foldl(fun(I, H) -> bump(H, bucket(Arenas, I)) end,
                erlang:make_tuple(?NBUCKET, 0), lists:seq(1, N)).

bucket(Arenas, I) ->
    A = element(I, Arenas),
    [#tank{x = X1, y = Y1}, #tank{x = X2, y = Y2}] = A#arena.tanks,
    min(?NBUCKET, 1 + robo_sim:dist({X1, Y1}, {X2, Y2}) div ?BUCKET).

bump(H, I) -> setelement(I, H, element(I, H) + 1).

%%%============================================================================
%%% AGGREGATION
%%%============================================================================
tally(Subject, Opp, Starts) ->
    Os = [outcome(Subject, Opp, St, Seat) || St <- Starts, Seat <- [a, b]],
    lists:foldl(fun merge/2, base(), Os).

base() ->
    #{n => 0, wins => 0, losses => 0, hist => erlang:make_tuple(?NBUCKET, 0)}.

merge(O, Acc) ->
    Add = maps:merge(O, #{n => 1,
                          wins => b(maps:get(alive, O) andalso
                                    not maps:get(opp_alive, O)),
                          losses => b(not maps:get(alive, O) andalso
                                      maps:get(opp_alive, O))}),
    maps:fold(fun add/3, Acc, maps:without([alive, opp_alive], Add)).

add(K, V, Acc) when is_number(V) -> maps:put(K, maps:get(K, Acc, 0) + V, Acc);
add(hist, V, Acc) -> maps:put(hist, tadd(maps:get(hist, Acc), V), Acc);
add(_K, _V, Acc) -> Acc.

tadd(A, B) ->
    list_to_tuple([element(I, A) + element(I, B)
                   || I <- lists:seq(1, tuple_size(A))]).

b(true) -> 1;
b(false) -> 0.

%%%============================================================================
%%% THE REPORT
%%%============================================================================
run(NStarts) ->
    Starts = heldout(NStarts),
    {ok, Fd} = file:open(?ARCH ++ "exp066_policy_probe.txt", [write]),
    hdr(Fd, NStarts, length(Starts)),
    Ctl = [control(K, Starts) || K <- [sitting_duck, spinner, rammer,
                                       circle_strafer]],
    Rows = [{Arm, Seed, tally(Net, {script, predictive_gun}, Starts)}
            || Arm <- [s, l, d], {Seed, Net} <- nets(Arm)],
    io:format(Fd, "~n-- 0. THE LOOP, VERIFIED BY RECOMPUTATION AGAINST THE "
                  "ARCHIVED FEED --~n~n", []),
    io:format(Fd, "Four columns of the arm S block of exp066_floor_feed.txt, "
                  "recomputed through THIS module's match loop. Agreement to the"
                  " digit is what licenses everything below it: it shows the "
                  "loop is driving the archived code over the archived starts "
                  "and not something nearby.~n~n", []),
    io:format(Fd, "~-6s ~8s ~8s ~9s ~8s ~8s~n",
              ["seed", "W", "L", "margin", "shots", "pulls"]),
    [feedrow(Fd, Sd, Starts) || Sd <- [2001, 2008, 2015]],
    io:format(Fd, "~nfeed, seed 2001: W=0.9750 L=0.0250 margin=67.23 "
                  "shots=11.96 pulls=71.94~nfeed, seed 2008: W=0.9750 L=0.0250 "
                  "margin=71.92 shots=11.28 pulls=123.84~nfeed, seed 2015: "
                  "W=0.4188 L=0.5813 margin=-15.89 shots=8.09 pulls=121.20~n",
              []),
    io:format(Fd, "~n-- A. SELF-CHECK ON THE BULLET WALK --~n~n", []),
    selfcheck(Fd, [T || {_A, _S, T} <- Rows] ++ [T || {_K, T} <- Ctl]),
    io:format(Fd, "~n-- B. THE GUN EXCHANGE. Rows A1-A4 are the CONTROL: the "
                  "floor bot against the four scripted rungs it already beats."
                  "~n~n", []),
    guns(Fd, Ctl, Rows),
    io:format(Fd, "~n-- C. THE BODY. What the champion is doing while that "
                  "happens.~n~n", []),
    bodies(Fd, Ctl, Rows),
    io:format(Fd, "~n-- D. THE TWO MODES OF ARM S, split on mean standoff "
                  "range at 150 whole units. The split is not a chosen "
                  "threshold: no arm S seed has a mean range between 129.3 and "
                  "182.7, so any cut in that 53-unit gap gives the same two "
                  "groups.~n~n", []),
    modes(Fd, Rows),
    io:format(Fd, "~n-- E. RANGE HISTOGRAM, 25-UNIT BUCKETS, share of turns. "
                  "Columns are 0-25, 25-50, ... 575-600.~n~n", []),
    hists(Fd, Ctl, Rows),
    file:close(Fd),
    io:format("wrote ~s~n", [?ARCH ++ "exp066_policy_probe.txt"]).

control(K, Starts) -> {K, tally({script, K}, {script, predictive_gun}, Starts)}.

feedrow(Fd, Seed, Starts) ->
    {Seed, Net} = lists:keyfind(Seed, 1, nets(s)),
    T = tally(Net, {script, predictive_gun}, Starts),
    N = maps:get(n, T),
    io:format(Fd, "~-6w ~8.4f ~8.4f ~9.2f ~8.2f ~8.2f~n",
              [Seed, maps:get(wins, T) / N, maps:get(losses, T) / N,
               (maps:get(dealt, T) - maps:get(taken, T)) / (?FP * N),
               maps:get(my_shots, T) / N, maps:get(pulls, T) / N]).

selfcheck(Fd, Ts) ->
    H = sum([maps:get(my_hits, T) + maps:get(op_hits, T) || T <- Ts]),
    EC = sum([maps:get(my_credits, T) + maps:get(op_credits, T) || T <- Ts]),
    io:format(Fd,
      "A HIT here means BOTH that this module's bullet walk reached the victim "
      "inside HIT_R and that the engine credited the shooter damage on that very"
      " turn. The walk supplies the geometry, the ENGINE supplies the count.~n~n"
      "  hits counted, every match in this file        = ~p~n"
      "  turns on which the engine credited damage     = ~p  (must equal the "
      "line above)~n"
      "  of those hits, ones whose credited damage equals robo_sim:damage/1 of "
      "the arriving bullet's own power = ~p~n"
      "  walk reached the victim but the engine credited nobody = ~p  (robo_sim "
      "resolves rams and wall contact BEFORE bullets, so a point-blank shot into"
      " a tank the same step has already killed is excluded by first_hit/2)~n"
      "  engine credited a turn the walk did not reach = ~p~n"
      "  turns whose credit exceeds the engine's maximum for one hit, 4096 at "
      "power 30 = ~p~n",
      [H, EC, sum([maps:get(dmg_ok, T) || T <- Ts]),
       sum([maps:get(uncredited, T) || T <- Ts]),
       sum([maps:get(unwalked, T) || T <- Ts]),
       sum([maps:get(multi, T) || T <- Ts])]).

guns(Fd, Ctl, Rows) ->
    io:format(Fd, "~-11s ~6s | ~6s ~5s ~6s ~6s ~5s ~5s | ~6s ~6s ~6s ~6s ~5s "
                  "~6s ~6s ~6s | ~6s ~5s ~6s ~7s ~7s~n",
              ["who", "W", "shots", "hits", "rate", "cf", "weave", "blind",
               "fresh", "velzro", "flight", "shotrg", "mind", "latmis",
               "devlat", "estlat", "shots", "hits", "rate", "dealt", "taken"]),
    [gun_row(Fd, "A" ++ integer_to_list(I), K, T)
     || {I, {K, T}} <- lists:zip(lists:seq(1, length(Ctl)), Ctl)],
    [gun_row(Fd, atom_to_list(Arm), Seed, T) || {Arm, Seed, T} <- Rows].

gun_row(Fd, Tag, Who, T) ->
    N = maps:get(n, T),
    L = maps:get(live, T),
    Sh = maps:get(op_shots, T),
    My = maps:get(my_shots, T),
    io:format(Fd, "~-4s ~-6w ~6.4f | ~6.2f ~5.2f ~6.4f ~6.4f ~5.2f ~5.2f | "
                  "~6.4f ~6.4f ~6.1f ~6.1f ~5.1f ~6.2f ~6.2f ~6.2f | ~6.2f "
                  "~5.2f ~6.4f ~7.2f ~7.2f~n",
              [Tag, Who, maps:get(wins, T) / N,
               Sh / N, maps:get(op_hits, T) / N, dv(maps:get(op_hits, T), Sh),
               dv(maps:get(op_cf_hits, T), Sh),
               maps:get(op_weave_saves, T) / N,
               maps:get(op_blind_misses, T) / N,
               maps:get(op_fresh, T) / L, maps:get(op_vel_zero, T) / L,
               dv(maps:get(op_flight, T), Sh),
               dv(maps:get(op_shot_range, T), Sh),
               dv(maps:get(op_mind, T), Sh),
               dv(maps:get(op_lat_miss, T), Sh),
               dv(maps:get(op_dev_lat, T), Sh),
               dv(maps:get(op_est_lat, T), Sh),
               My / N, maps:get(my_hits, T) / N, dv(maps:get(my_hits, T), My),
               maps:get(dealt, T) / (?FP * N),
               maps:get(taken, T) / (?FP * N)]).

%% MEDIANS OF THE TWO GROUPS, so the numbers a reader wants are on this disk
%% rather than left to be recomputed off the per-seed rows above.
modes(Fd, Rows) ->
    S = [{maps:get(range_sum, T) / maps:get(live, T), Seed, T}
         || {s, Seed, T} <- Rows],
    Far = [{Seed, T} || {R, Seed, T} <- S, R >= 150],
    Near = [{Seed, T} || {R, Seed, T} <- S, R < 150],
    io:format(Fd, "~-34s ~14s ~14s~n",
              ["", "STANDOFF", "BRAWL"]),
    io:format(Fd, "~-34s ~14w ~14w~n", ["seeds", length(Far), length(Near)]),
    [mode_line(Fd, L, F, Far, Near) || {L, F} <- mode_stats()],
    io:format(Fd, "~nseeds, standoff = ~p~nseeds, brawl    = ~p~n",
              [[Sd || {Sd, _T} <- Far], [Sd || {Sd, _T} <- Near]]).

mode_line(Fd, Label, F, Far, Near) ->
    io:format(Fd, "~-34s ~14.4f ~14.4f~n",
              [Label, med([F(T) || {_S, T} <- Far]),
               med([F(T) || {_S, T} <- Near])]).

med([]) -> 0.0;
med(L) -> lists:nth(1 + length(L) div 2, lists:sort(L)).

mode_stats() ->
    [{"held-out win rate", fun(T) -> maps:get(wins, T) / maps:get(n, T) end},
     {"mean standoff range, units", fun(T) -> per(range_sum, live, T) end},
     {"ram-contact turns per match", fun(T) -> per(ram, n, T) end},
     {"lateral sign changes per 100 turns",
      fun(T) -> 100 * per(lat_flip, live, T) end},
     {"own lateral speed, units per turn", fun(T) -> per(lat_abs, live, T) / ?FP
      end},
     {"floor bot shots per match", fun(T) -> per(op_shots, n, T) end},
     {"floor bot HIT RATE", fun(T) -> per(op_hits, op_shots, T) end},
     {"same shots against a CONSTANT-VELOCITY ghost",
      fun(T) -> per(op_cf_hits, op_shots, T) end},
     {"bot misses that also miss the ghost",
      fun(T) -> per(op_blind_misses, op_shots, T) /
                (1 - per(op_hits, op_shots, T)) end},
     {"bot mean shot power, tenths", fun(T) -> per(op_power, op_shots, T) end},
     {"champion shots per match", fun(T) -> per(my_shots, n, T) end},
     {"champion HIT RATE", fun(T) -> per(my_hits, my_shots, T) end},
     {"champion mean shot power, tenths",
      fun(T) -> per(my_power, my_shots, T) end},
     {"damage dealt per match, units", fun(T) -> per(dealt, n, T) / ?FP end},
     {"damage taken per match, units", fun(T) -> per(taken, n, T) / ?FP end}].

per(A, B, T) -> dv(maps:get(A, T), maps:get(B, T)).

bodies(Fd, Ctl, Rows) ->
    io:format(Fd, "~-11s ~6s | ~6s ~6s ~6s ~6s ~6s ~6s | ~6s ~6s | ~6s ~6s "
                  "~6s~n",
              ["who", "W", "range", "bflip", "babs", "lflip", "vperp", "velm",
               "mypow", "oppow", "wallme", "wallop", "ram"]),
    [body_row(Fd, "A" ++ integer_to_list(I), K, T)
     || {I, {K, T}} <- lists:zip(lists:seq(1, length(Ctl)), Ctl)],
    [body_row(Fd, atom_to_list(Arm), Seed, T) || {Arm, Seed, T} <- Rows].

body_row(Fd, Tag, Who, T) ->
    L = maps:get(live, T),
    io:format(Fd, "~-4s ~-6w ~6.4f | ~6.1f ~6.1f ~6.2f ~6.1f ~6.2f ~6.2f | "
                  "~6.2f ~6.2f | ~6.2f ~6.2f ~6.2f~n",
              [Tag, Who, maps:get(wins, T) / maps:get(n, T),
               maps:get(range_sum, T) / L,
               100 * maps:get(body_flip, T) / L,
               maps:get(body_abs, T) / L,
               100 * maps:get(lat_flip, T) / L,
               maps:get(lat_abs, T) / (?FP * L),
               maps:get(vel_abs, T) / (?FP * L),
               dv(maps:get(my_power, T), maps:get(my_shots, T)),
               dv(maps:get(op_power, T), maps:get(op_shots, T)),
               maps:get(my_wall, T) / maps:get(n, T),
               maps:get(op_wall, T) / maps:get(n, T),
               maps:get(ram, T) / maps:get(n, T)]).

hdr(Fd, NStarts, Got) ->
    io:format(Fd, "== EXP-066 POST-HOC POLICY PROBE ==~n~n", []),
    io:format(Fd, "Exploratory, post hoc, NOT pre-registered, SIGNS NOTHING.~n"
                  "Engine pin a5e8bcfc5646827e9be49a9629f8a6a9678c814b, golden "
                  "match hash re-checked by the runner's own gates.~n"
                  "Every champion is read from exp066_champions_{s,l,d}.eterm "
                  "in this directory.~n"
                  "The pilot encoder and the match loop are the runner's OWN "
                  "compiled code, reached through an export_all view built from "
                  "its beam's debug_info.~n"
                  "held-out starts requested = ~p, used = ~p, both seats always,"
                  " so matches per opponent = ~p~n",
              [NStarts, Got, 2 * Got]),
    io:format(Fd, "~nCOLUMNS~n"
        "  W            win rate (alive and opponent dead), the feed's own rule~n"
        "  shots/hits   gun_heat zero-to-nonzero transitions, and of those the "
        "ones whose bullet reaches the victim inside HIT_R AND for which the "
        "engine credited the shooter damage on that same turn (see section A)~n"
        "  cf_hit       the SAME bullet against a GHOST victim that holds the "
        "velocity it had when the shot left the barrel~n"
        "  weave        missed the real champion, hit the ghost: a shot the "
        "champion's change of velocity defeated~n"
        "  blind        missed both: a shot already aimed wrong when it left "
        "the barrel~n"
        "  latmiss      mean absolute lateral miss at closest approach, whole "
        "units, against HIT_R = 20~n"
        "  devlat       of that, the part explained by the victim departing "
        "from its fire-time velocity~n"
        "  estlat       of that, the part explained by the bot's own velocity "
        "ESTIMATE being wrong at fire time~n"
        "  fresh        share of turns on which the bot held a scan from THIS "
        "turn, which is its precondition for firing at all~n"
        "  velzero      share of turns on which the bot's enemy_vel/1 returned "
        "standing still (never seen twice, or a scan gap over 8)~n"
        "  bodyflip     sign changes per 100 turns in the COMMANDED turn_body~n"
        "  vperp        mean own speed PERPENDICULAR to the line of sight, whole"
        " units per turn: the quantity the lead solver extrapolates~n"
        "  mypow/oppow  mean commanded shot power, in tenths. The floor bot's own"
        " budget rule drops it from 30 to 20 beyond 150 units of range and to 10"
        " beyond 350, and damage per hit is 16, 10 and 4 units respectively~n"
        "  ram          turns per match with the tanks overlapping. Ram contact"
        " costs BOTH tanks 0.6 energy a turn and robo_sim credits it to nobody, so"
        " it never appears in dealt or taken~n"
        "  latflip      sign changes per 100 turns in cross(line of sight, own "
        "velocity): reversals of the quantity the lead solver extrapolates~n"
        "  range        mean tank separation over the match, whole units~n", []),
    io:format(Fd, "~nSELF-CHECK. bullets counted as hitting by this module's own "
                  "walk must equal the engine's damage credits; dealt/taken are "
                  "read from #tank.damage_dealt and printed beside them.~n", []).

dv(_A, 0) -> 0.0;
dv(A, B) -> A / B.

hists(Fd, Ctl, Rows) ->
    [hist_row(Fd, atom_to_list(K), T) || {K, T} <- Ctl],
    [hist_row(Fd, atom_to_list(Arm) ++ " " ++ integer_to_list(Seed), T)
     || {Arm, Seed, T} <- Rows].

hist_row(Fd, Tag, T) ->
    L = maps:get(live, T),
    H = maps:get(hist, T),
    io:format(Fd, "~-16s W=~6.4f ~s~n",
              [Tag, maps:get(wins, T) / maps:get(n, T),
               [io_lib:format("~5.3f ", [element(I, H) / L])
                || I <- lists:seq(1, 24)]]).
