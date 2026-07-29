%%%-------------------------------------------------------------------
%%% @doc EXP-066 -- Robo Rumble phase 0: the COMPETENCE FLOOR gate.
%%%
%%% Pre-registration (DESIGN-gated, BUILD_WITH_CHANGES, amendments applied):
%%% exp066_single_population_floor.md. That document is binding; this runner
%%% implements it and invents nothing.
%%%
%%% THE QUESTION, asked symmetrically. Does single-population evolution against
%%% the scripted gauntlet produce a controller that reliably beats the floor bot
%%% predictive_gun, or does it fail to, and by what pre-registered measurement
%%% would we tell the two apart from an instrument that never asked the
%%% question? Only CLEARED unlocks phase 1. PARTIAL, INCONCLUSIVE, FAILED and
%%% UNGRADEABLE all stop the front and prescribe different next moves.
%%%
%%% WHY THE GATE EXISTS. PLAN_ROBO_RUMBLE.md section 2: absence of cycling is
%%% uninterpretable below a competence floor, because at low competence a tank
%%% arena is transitive, so a null there is a statement about the OPTIMISER and
%%% not about the SUBSTRATE. That is the search under-convergence confound the
%%% closed Flatland programme left open.
%%%
%%% WHAT THIS FILE OWNS
%%%   1. The evolved controller (the pilot): 17 integer channels in, 5 outputs
%%%      onto an intent record, driven through robo_net's integer forward pass.
%%%   2. The deterministic 120-start generator and its train / held-out /
%%%      calibration split.
%%%   3. The match loop, which pins the perception contract.
%%%   4. The lazy ladder fitness, graded on damage MARGIN in arena fixed point,
%%%      never on energy and never on survival time.
%%%   5. The arms, the frozen constants, the decision rule and the twelve
%%%      instrument-failure codes.
%%%
%%% WHAT THIS FILE DOES NOT TOUCH. robo_sim, robo_net, robo_gauntlet and
%%% robo_match are consumed, never modified, so robo_match_tests' golden match
%%% vector still holds; gate 1 below asserts it by recomputation.
%%%
%%% DEVIATION FROM THE PRE-REGISTRATION, recorded rather than hidden. The
%%% pre-registration places the controller in a new faber-tweann module named
%%% robo_pilot and names the runner exp066_competence_floor_tests. No such
%%% engine module exists at the pinned commit and the engine pin is the
%%% provenance, so the controller lives here, in ONE module, with the perception
%%% boundary enforced by the same code shape robo_gauntlet:act/4 uses. Moving it
%%% into the engine later is a pin bump plus a file move, and nothing about the
%%% measurement changes. The runner name follows the task instruction.
%%%
%%% THE PERCEPTION BOUNDARY IS A SHAPE, NOT A COMMENT. pilot_act/4 destructures
%%% the arena to its scans field and to nothing else, then filters those scans to
%%% the acting tank's own observer id. The tanks and bullets lists are therefore
%%% NOT IN SCOPE below that line, so an opponent's tank record cannot be read
%%% from pilot_decide/3 even by accident. This is stated here because the task
%%% asked for it to be stated, but the defence is the destructuring, not this
%%% paragraph.
%%%
%%% DETERMINISM. The match path is integer only: no float, no libm, no clock, no
%%% rand, no process and no ETS below pilot_act/4. robo_net:quantize/1 is the ONE
%%% float boundary and it runs at phenotype build time, inside the fitness and
%%% outside the match. Everything hashed is flattened to tuples and lists,
%%% because term_to_binary is not canonical for maps and that has already bitten
%%% this front once.
%%%
%%% THE SCORING TRAP, ALREADY MEASURED. robo_gauntlet budgets every gun so a bot
%%% that is MISSING decays toward its fire floor while a bot that NEVER FIRES
%%% keeps a full bar, so ANY energy-derived fitness structurally rewards not
%%% shooting. The fitness here never reads energy and never reads survival time.
%%% @end
%%%-------------------------------------------------------------------
-module(exp066_single_population_floor_tests).

%% Kill gates and cheap instrument checks. Exported separately from the study so
%% they can be run BEFORE any compute is committed.
-export([gates/0, gates/1]).
%% Protocol step 2: the frozen constants. Scripted bots only, no pilot involved.
-export([constants/0, constants/1]).
%% Kill gate 0b: the hand-CONSTRUCTED weight vector driven through the pilot.
-export([arm_c/0, arm_c/1, arm_c_gains/0, arm_c_weights/1]).
%% The study.
-export([run/0, run/1, pilot/0, defaults/0, pilot_opts/0]).
%% The start generator and the archive format, exposed for later phases.
-export([inputs/0, starts/0, split/1, champion_id/1, champion_write/2]).

-include_lib("faber_tweann/include/robo_sim.hrl").

%%%============================================================================
%%% Engine constants, mirrored. Every one of these is a robo_sim value that
%%% robo_sim does not export; each is named here once so no magic number appears
%%% in the channel encodings below.
%%%============================================================================
-define(INPUTS, 17).
%% The ONE topology arm_c_weights/1 can build. It emits one bias plus 17 weights
%% per output neuron, so it is [17,5] by construction and nothing else.
-define(C_LAYERS, [17, 5]).
-define(FP, 256).                %% arena fixed-point scale
-define(SIN_SCALE, 32768).       %% the engine's sine scale
-define(TANK_R, 4608).           %% 18 whole units
-define(BAR, 25600).             %% robo_sim START_ENERGY: the death floor
-define(ORBIT, 51200).           %% 200 whole units, the gauntlet's own orbit range
-define(WALL_SPAN, 32768).       %% 128 whole units of clearance reads danger 0
-define(W_CLAMP, 2048).          %% robo_net:weight_limit(), restated for IF-4

%% The five rungs, lowest first, exactly robo_gauntlet:kinds/0.
-define(FLOOR, predictive_gun).

%% Determinism of the harness itself (not the match path).
-define(BOOT_SEED, 66).
-define(BOOT_N, 10000).
-define(NEG_INF, -1.0e308).

%% robo_match_tests' golden match vector, restated so this runner asserts by
%% RECOMPUTATION that the engine is untouched rather than trusting that it is.
-define(GOLDEN_MATCH,
        <<"DFCD8106EDC9AE214F6AE99BB5F4988FE441243284A6D3769634D778B3895E88">>).

%%%============================================================================
%%% Records. Records, never maps, for anything that is threaded through a match
%%% or hashed.
%%%============================================================================

%% What the pilot remembers between turns. All integer, carried by value exactly
%% as robo_gauntlet's own bot record is.
%%
%% Two contacts are kept, not one, because a velocity estimate is a difference of
%% successive positions and there is nothing else in this substrate to
%% difference. The tick of each is stored so the GAP is known: scans arrive only
%% when the radar sweeps, so successive sightings are not one turn apart and
%% dividing by a presumed gap of one reports a velocity several times too large.
-record(pilot, {
    tick = 0 :: non_neg_integer(),
    seen = 0 :: 0..2,                %% 0 none, 1 position, 2 also velocity
    age = 0 :: non_neg_integer(),    %% turns since the latest contact
    dist = 0 :: integer(),           %% range at the latest contact, fixed point
    ex = 0 :: integer(),             %% latest contact position, absolute
    ey = 0 :: integer(),
    etick = 0 :: non_neg_integer(),
    px = 0 :: integer(),             %% previous contact position, absolute
    py = 0 :: integer(),
    ptick = 0 :: non_neg_integer(),
    prev_e = ?BAR :: integer(),      %% own energy last turn
    d_e = 0 :: integer(),            %% own energy change since last turn
    target = none :: term()
}).

%% One match in flight. probe is off, or an accumulator for the channel-range
%% diagnostic; it is the only branch in the loop and it is a function clause.
-record(mrun, {
    pid = a :: term(),               %% the SUBJECT's seat; outcomes report from it
    ctl = [] :: list(),
    pulls = 0 :: non_neg_integer(),  %% commanded fire greater than zero
    shots = 0 :: non_neg_integer(),  %% gun_heat zero-to-nonzero: shots the engine took
    opp_shots = 0 :: non_neg_integer(),
    probe = off :: off | list()
}).

%% The per-run collector's state. mu_lambda_es exposes no trace, so wrapping the
%% fitness covers both optimiser arms uniformly.
-record(col, {
    lambda = 1 :: pos_integer(),
    checks = [] :: [pos_integer()],
    n = 0 :: non_neg_integer(),
    best = {none, ?NEG_INF} :: {none | [integer()], float()},
    marks = [] :: list(),
    block = [] :: list(),
    distinct = [] :: [non_neg_integer()],
    clamp = [] :: [float()]
}).

%% One seed's result. Every field goes into the raw feed: the exp064 gate found
%% the prior feed had kept 12 summary numbers and discarded the 72 per-run
%% values, leaving nothing re-analysable. That does not happen again.
-record(res, {
    arm, seed, layers, dim, evals, fit, q,
    w = 0.0, l = 0.0, d = 0.0,           %% held-out win / loss / draw rates
    margin = 0.0,                        %% mean held-out damage margin, whole units
    caps = 0.0,                          %% fraction of held-out matches at the turn cap
    shots = 0.0, pulls = 0.0,            %% per match, held-out
    won_opp_shots = 0.0,                 %% floor bot's shots in the champion's WON matches
    train_w = 0.0,                       %% train-split win rate, for IF-8
    distinct_last = 0,                   %% distinct quantised phenotypes, last generation
    clamp_last = 0.0,                    %% mean clamped-coordinate fraction, last generation
    clamp_frac = 0.0,                    %% the CHAMPION's coordinates at the clamp: IF-4
    profile = [],                        %% [{Kind, W, L, D}] over all five rungs
    marks = []                           %% [{Evaluations, HeldOutWinRate}]
}).

%%%============================================================================
%%% THE PILOT. One module, and the perception boundary is its shape.
%%%============================================================================

%% How many sensor channels the pilot emits. The runner ASSERTS a topology's
%% first width equals this, because robo_net:fit/2 silently pads or truncates and
%% a mismatch would never fail a test.
-spec inputs() -> pos_integer().
inputs() -> ?INPUTS.

pilot_init() -> #pilot{}.

%% THE PERCEPTION BOUNDARY. The arena is destructured to its scans field and to
%% NOTHING ELSE, so #arena.tanks and #arena.bullets are not in scope below this
%% line and an opponent's #tank{} record cannot be reached from pilot_decide/3.
%% The scans are then narrowed to the entries this tank observed. Identical in
%% shape to robo_gauntlet:act/4, deliberately: a comment would not survive
%% review, a shape the compiler can check does.
pilot_act(Net, State, #tank{id = Id} = Me, #arena{scans = Scans}) ->
    Mine = [S || {Observer, _T, _D, _V} = S <- Scans, Observer =:= Id],
    Next = pilot_observe(State, Me, Mine),
    {pilot_decide(Net, Next, Me), Next}.

%% Fold this turn's scans into memory. A silent turn ages the track, which is the
%% whole cost of pointing a radar at the wrong part of the arena.
pilot_observe(#pilot{tick = T, age = A} = S, Me, []) ->
    own_energy(S#pilot{tick = T + 1, age = A + 1}, Me);
pilot_observe(#pilot{tick = T} = S, #tank{x = MX, y = MY} = Me, Scans) ->
    {_O, Target, D, {DX, DY}} = nearest(Scans),
    own_energy(latch(S#pilot{tick = T + 1, age = 0, dist = D},
                     MX + DX, MY + DY, T, Target), Me).

%% Channel 4's source, and the ONLY proprioception of incoming fire that exists.
own_energy(#pilot{prev_e = P} = S, #tank{energy = E}) ->
    S#pilot{prev_e = E, d_e = E - P}.

%% Absolute contact position is own position plus the scan delta: a derivation
%% from two permitted facts, not a peek at the opponent's record. Switching
%% target id resets to a single sighting, so a velocity estimate can never
%% difference two DIFFERENT opponents.
latch(#pilot{target = Target} = S, X, Y, T, Target) ->
    #pilot{ex = EX, ey = EY, etick = ET, seen = N} = S,
    S#pilot{px = EX, py = EY, ptick = ET, ex = X, ey = Y, etick = T,
            seen = min(2, N + 1)};
latch(S, X, Y, T, Target) ->
    S#pilot{px = X, py = Y, ptick = T, ex = X, ey = Y, etick = T,
            seen = 1, target = Target}.

%% Nearest contact, strictly closer so ties keep list order, which the engine
%% fixes.
nearest([H | Rest]) -> lists:foldl(fun closer/2, H, Rest).

closer({_O, _T, D, _V} = C, {_BO, _BT, Best, _BV}) when D < Best -> C;
closer(_C, Best) -> Best.

%% Contact velocity per turn, by differencing the two latched positions.
%% Dividing by the GAP is arithmetic, not strategy, and it is mandatory. There is
%% NO trust window and NO gating, unlike robo_gauntlet:enemy_vel/1: a stale
%% estimate attenuates because the gap divides it, and channel 8 tells the net
%% how much to believe the track. That call belongs to evolution.
contact_vel(#pilot{seen = N}) when N < 2 -> {0, 0};
contact_vel(#pilot{ex = X, ey = Y, px = PX, py = PY, etick = T, ptick = P}) ->
    Gap = max(1, T - P),
    {(X - PX) div Gap, (Y - PY) div Gap}.

%%%----------------------------------------------------------------------------
%%% The 17 channels. Arena scale 256, every channel inside -256 to 256.
%%%----------------------------------------------------------------------------
channels(S, Me) -> own(S, Me) ++ place(Me) ++ contact(S, Me).

%% 1 own_speed, 2 own_energy, 3 gun_heat, 4 energy_delta.
%%
%% Engine velocity is always along the heading, so one scalar is all of own
%% motion. MAX_VEL 2048 maps to 256 exactly; START_ENERGY 25600 maps to 256; the
%% hottest reachable gun (power 30) reads 204, so channel 3's clamp never bites.
%% Channel 4 conflates being shot, hitting a wall, being rammed, paying to fire
%% and being paid for a hit: irreducible, since separating the causes needs
%% engine internals the boundary forbids.
own(#pilot{d_e = DE}, #tank{vel = V, energy = E, gun_heat = GH}) ->
    [V div 8, min(256, E div 100), min(256, GH div 2), clamp(DE div 16, 256)].

%% 5 pos_fwd, 6 pos_port, 7 wall_danger.
%%
%% Arena size is a rule of the game, not opponent state, so consulting it breaks
%% no perception rule (robo_gauntlet:wall_push/1 already does). Position is given
%% in BODY frame because acting on a world-frame position requires a rotation,
%% and a rotation is a product of activations that a fixed-topology MLP cannot
%% form. wall_danger is DANGER rather than clearance so the channel is SILENT in
%% the common case and does not perturb an untrained baseline.
place(#tank{x = X, y = Y, heading = H}) ->
    {W, A} = robo_sim:arena_size(),
    {FX, FY} = rotate(X - W div 2, Y - A div 2, H),
    [FX div 512, FY div 512, wall_danger(X, Y, W, A)].

wall_danger(X, Y, W, H) ->
    C = lists:min([X - ?TANK_R, W - ?TANK_R - X, Y - ?TANK_R, H - ?TANK_R - Y]),
    256 - min(256, max(0, C) * 256 div ?WALL_SPAN).

%% 8 contact_fresh, 9-14 the three bearing frames, 15 contact_prox,
%% 16 target_lateral, 17 target_range_rate.
%%
%% ALL EXACTLY ZERO when no contact has ever been seen, which combined with
%% robo_net's per-neuron bias makes "behave sensibly while blind" a learnable
%% bias term rather than a special case.
%%
%% THREE FRAMES, DELIBERATELY REDUNDANT. Recovering one frame from another is a
%% rotation, a rotation is a product of activations, and a fixed-topology MLP
%% cannot form products. Spending two channels to remove a multiplication the
%% architecture cannot perform is the correct trade every time: aiming, orbiting
%% and radar tracking each collapse to a single weight.
contact(#pilot{seen = 0}, _Me) -> lists:duplicate(10, 0);
contact(#pilot{age = A, dist = D} = S, #tank{heading = H, gun = G, radar = R} = Me) ->
    {UX, UY} = sight(S, Me),
    {BC, BS} = unit(UX, UY, H),
    {GC, GS} = unit(UX, UY, G),
    {RC, RS} = unit(UX, UY, R),
    {WC, WS} = unit(UX, UY, 0),
    {VX, VY} = contact_vel(S),
    [fresh(A), BC, BS, GC, GS, RC, RS,
     (256 * ?ORBIT) div (?ORBIT + D),
     clamp((WC * VY - WS * VX) div 2048, 256),
     clamp((WC * VX + WS * VY) div 2048, 256)].

%% 256 on a scan turn, 128 at eight turns, floor 1 at the cap. Exactly 0 if never
%% seen, and that zero is a structural sentinel, which is why this is only ever
%% reached from the seen-nonzero clause above.
fresh(A) -> 2048 div (8 + min(A, 1024)).

%% DEAD RECKONING IS IN, PREDICTION IS OUT. The bearing channels report the
%% contact's ESTIMATED POSITION NOW: latched position plus estimated velocity
%% times age, clamped to arena bounds. Keeping the sensor's meaning constant
%% across turns is what makes a radar track a track rather than a snapshot.
%% Solving flight time is strategy and is withheld; channels 16 and 17 let the
%% net learn the lead itself. This VOIDS any future claim that the controller
%% "learned to track" or "learned to handle intermittent observation".
sight(#pilot{ex = EX, ey = EY, age = A} = S, #tank{x = MX, y = MY}) ->
    {VX, VY} = contact_vel(S),
    {PX, PY} = inside(EX + VX * A, EY + VY * A),
    {PX - MX, PY - MY}.

inside(X, Y) ->
    {W, H} = robo_sim:arena_size(),
    {min(max(X, 0), W), min(max(Y, 0), H)}.

%% THE BEARING TRICK. No atan2 and none added: a scan carries a vector, never a
%% bearing. The delta is rotated into a part's frame against robo_sim's own sine
%% table, then BOTH components are divided by the octagonal norm OF THE ROTATED
%% VECTOR, recomputed rather than reused from the scan's Distance field, because
%% the octagonal metric is not rotation invariant. Max component is exactly 256,
%% so axis-aligned deltas sit exactly ON robo_net's contract edge rather than
%% inside it; the pair norm wobbles between 0.9318 and 1.0275, which is a bounded
%% deterministic gain modulation identical for every controller, not a direction
%% error. The scan's own Distance is used for channel 15, so the range the net
%% sees is the number the engine reported.
unit(UX, UY, A) ->
    {RX, RY} = rotate(UX, UY, A),
    scale_pair(RX, RY, robo_sim:dist({0, 0}, {RX, RY})).

scale_pair(_RX, _RY, 0) -> {0, 0};
scale_pair(RX, RY, N) -> {RX * 256 div N, RY * 256 div N}.

%% A world vector into a part's frame. Positive Y is to the LEFT of the part,
%% matching the engine's counter-clockwise-positive rotations.
rotate(DX, DY, A) ->
    C = robo_sim:cos(A),
    S = robo_sim:sin(A),
    {(DX * C + DY * S) div ?SIN_SCALE, (DY * C - DX * S) div ?SIN_SCALE}.

%%%----------------------------------------------------------------------------
%%% The 5 outputs
%%%
%%% From robo_net:eval_q12/3 so the last four bits are not thrown away, each
%%% through robo_net:to_range/2 with THE ENGINE'S OWN CLAMP as Max, so the
%%% network's reachable set is exactly the legal set and no output is wasted on
%%% values the engine will refuse.
%%%
%%% FIRING IS ONE CONTINUOUS OUTPUT AND THE THRESHOLD IS THE ENGINE'S.
%%% robo_sim:clamp_power/1 already reads anything at or below zero as hold and
%%% anything above as a power in tenths, so to_range(A, 30) covers hold and every
%%% power on one monotone axis with NO hand-chosen constant and no second output.
%%% Do NOT add a hold-biased encoding or a separate fire-decision output: the
%%% recorded hazard on this front runs the other way, "never fire" is the strong
%%% local optimum, and a neutral untrained prior is a mild counterweight.
%%%----------------------------------------------------------------------------
pilot_decide({Layers, Ws}, S, Me) ->
    intent(robo_net:eval_q12(Layers, Ws, channels(S, Me))).

intent([A, B, C, D, E | _]) ->
    #intent{turn_body = robo_net:to_range(A, 7),
            turn_gun = robo_net:to_range(B, 14),
            turn_radar = robo_net:to_range(C, 32),
            accel = robo_net:to_range(D, 512),
            fire = robo_net:to_range(E, 30)};
intent(_Short) -> #intent{}.

clamp(V, Max) -> max(-Max, min(Max, V)).

%%%============================================================================
%%% THE START GENERATOR. One deterministic generator, integer only, no rand and
%%% no libm.
%%%
%%% THE HEADING OFFSET IS THE CORRECTION THAT MATTERS AND IT WAS MEASURED, NOT
%%% REASONED. Under an all-mutually-facing generator, predictive_gun against its
%%% own clone draws 106 of 160 with 70 percent of matches hitting the turn cap.
%%% With the per-index offset the same 80 geometries give 67 wins / 67 losses /
%%% 26 draws. The all-facing rule was manufacturing stalemates by starting the
%%% mirror match perfectly symmetric, and it would have left the primary endpoint
%%% 70 percent censored. The offset also kills a second degeneracy: with at least
%%% 8 angle units of offset on every start, no tank is ever bore-sighted at turn
%%% 1, so "fire straight ahead immediately" cannot clear rung 1 by itself.
%%% Because the offset is ONE RULE applied to all 120 indices, train and held-out
%%% remain exchangeable draws from a single distribution.
%%%============================================================================
-spec starts() -> [tuple()].
starts() -> [start(I) || I <- lists:seq(1, 120)].

start(I) ->
    AX = 60 + (I * 137) rem 681,
    AY = 60 + (I * 191) rem 481,
    {BX, BY} = separate(I, AX, AY, 0),
    Face = robo_gauntlet:angle_of({BX - AX, BY - AY}),
    {AX, AY, robo_sim:wrap(Face + off(I)),
     BX, BY, robo_sim:wrap(Face + 128 + off(I div 8 + 3))}.

%% B is walked by a fixed stride until the pair is at least 150 whole units
%% apart, so no match opens inside ram range (2 * TANK_R = 36). K IS BOUNDED, with
%% a deterministic reflection fallback, so the walk cannot fail to terminate.
separate(_I, AX, AY, K) when K > 64 -> {800 - AX, 600 - AY};
separate(I, AX, AY, K) ->
    BX = 60 + ((I * 251) + K * 97) rem 681,
    BY = 60 + ((I * 313) + K * 89) rem 481,
    far_enough(I, AX, AY, K, BX, BY, robo_sim:dist({AX, AY}, {BX, BY}) >= 150).

far_enough(_I, _AX, _AY, _K, BX, BY, true) -> {BX, BY};
far_enough(I, AX, AY, K, _BX, _BY, false) -> separate(I, AX, AY, K + 1).

off(I) -> element(1 + (I rem 8), {-96, -64, -32, -8, 8, 32, 64, 96}).

%% TRAIN 1..6, HELD-OUT 7..86 (THE GATE LIVES HERE), CALIBRATION 87..116 (used to
%% BUILD AND TUNE arm C and for nothing else), 117..120 generated and
%% deliberately unused.
-spec split(train | heldout | calibration) -> [tuple()].
split(train) -> lists:sublist(starts(), 1, 6);
split(heldout) -> lists:sublist(starts(), 7, 80);
split(calibration) -> lists:sublist(starts(), 87, 30).

take(L, N) -> lists:sublist(L, N).

train_starts(O) -> take(split(train), maps:get(train, O)).
heldout_starts(O) -> take(split(heldout), maps:get(heldout, O)).
calib_starts(O) -> take(split(calibration), maps:get(calibration, O)).

%%%============================================================================
%%% THE MATCH LOOP. The runner owns its own loop; robo_match:run/4 is
%%% gauntlet-only and is NOT modified.
%%%
%%% THE PERCEPTION CONTRACT, as robo_match pins it: act on the CURRENT arena,
%%% whose scans came from the step that produced these tanks, and only THEN step.
%%% A runner that steps first hands every controller a one-turn-stale world,
%%% silently, and nothing fails. Encoder state is threaded by value exactly as
%%% robo_gauntlet's bot record is. Only live tanks act. The runner reads RAW
%%% #tank.damage_dealt, never robo_match's whole-unit division, because a power
%%% 0.1 pellet does 0.4 damage and whole units report that as 0, and that dead
%%% zone sits exactly where cheap exploratory shooting lives.
%%%============================================================================

%% Both seats at one start, which is what a fair pairing means when the start
%% geometry is not symmetric. BOTH SEATS ALWAYS: robo_sim folds fire_all/2 and
%% first_hit/2 in tank list order, and 27 of 80 held-out starts show
%% circle_strafer versus predictive_gun differing by seat.
duel(Subject, Opp, Start) ->
    [play_seat(Subject, Opp, Start, a, off),
     play_seat(Subject, Opp, Start, b, off)].

play_seat(Subject, Opp, {AX, AY, AH, BX, BY, BH}, Seat, Probe) ->
    Arena = robo_sim:new([{a, AX, AY, AH}, {b, BX, BY, BH}]),
    play(Arena, #mrun{pid = Seat, ctl = seats(Seat, Subject, Opp), probe = Probe}).

seats(a, Subject, Opp) -> [{a, mk(Subject)}, {b, mk(Opp)}];
seats(b, Subject, Opp) -> [{a, mk(Opp)}, {b, mk(Subject)}].

mk({net, Layers, Ws}) -> {pilot, {Layers, Ws}, pilot_init()};
mk({script, Kind}) -> {script, Kind, robo_gauntlet:init(Kind)}.

play(Arena, R) -> play_step(Arena, R, robo_sim:finished(Arena)).

play_step(Arena, R, true) -> report(Arena, R);
play_step(Arena, R, false) ->
    Acted = [act_one(T, R#mrun.ctl, Arena) || T <- robo_sim:alive(Arena)],
    Next = robo_sim:step(Arena, [{Id, I} || {Id, I, _C} <- Acted]),
    play(Next, tick(R, Arena, Next, Acted)).

act_one(#tank{id = Id} = T, Ctl, Arena) ->
    {Id, C} = lists:keyfind(Id, 1, Ctl),
    {I, C2} = drive(C, T, Arena),
    {Id, I, C2}.

drive({script, Kind, S}, T, Arena) ->
    {I, S2} = robo_gauntlet:act(Kind, S, T, Arena),
    {I, {script, Kind, S2}};
drive({pilot, Net, S}, T, Arena) ->
    {I, S2} = pilot_act(Net, S, T, Arena),
    {I, {pilot, Net, S2}}.

tick(R, Arena, Next, Acted) ->
    Ctl = lists:foldl(fun({Id, _I, C}, Acc) -> lists:keystore(Id, 1, Acc, {Id, C}) end,
                      R#mrun.ctl, Acted),
    probe_acc(count_shots(count_pulls(R#mrun{ctl = Ctl}, Acted), Arena, Next),
              Arena, Acted).

count_pulls(R, Acted) -> pulls(R, lists:keyfind(R#mrun.pid, 1, Acted)).

pulls(R, {_Id, #intent{fire = F}, _C}) when F > 0 -> R#mrun{pulls = R#mrun.pulls + 1};
pulls(R, _Other) -> R.

%% SHOTS ACTUALLY FIRED, not trigger pulls: a gun_heat zero-to-nonzero
%% transition, since the engine refuses a hot or unaffordable shot.
count_shots(R, Before, After) ->
    R#mrun{shots = R#mrun.shots + fired(R#mrun.pid, Before, After),
           opp_shots = R#mrun.opp_shots + fired(other(R#mrun.pid), Before, After)}.

fired(Id, #arena{tanks = B}, #arena{tanks = A}) ->
    heat_step(lists:keyfind(Id, #tank.id, B), lists:keyfind(Id, #tank.id, A)).

heat_step(#tank{gun_heat = 0}, #tank{gun_heat = H}) when H > 0 -> 1;
heat_step(_B, _A) -> 0.

other(a) -> b;
other(b) -> a.

probe_acc(#mrun{probe = off} = R, _Arena, _Acted) -> R;
probe_acc(R, Arena, Acted) ->
    probe_one(R, Arena, lists:keyfind(R#mrun.pid, 1, Acted)).

probe_one(R, #arena{tanks = Ts}, {Id, _I, {pilot, _Net, S}}) ->
    R#mrun{probe = [{lists:keyfind(Id, #tank.id, Ts), S} | R#mrun.probe]};
probe_one(R, _Arena, _Other) -> R.

report(#arena{turn = Turn, tanks = Ts}, R) ->
    Me = lists:keyfind(R#mrun.pid, #tank.id, Ts),
    Opp = lists:keyfind(other(R#mrun.pid), #tank.id, Ts),
    #{dealt => Me#tank.damage_dealt,
      taken => Opp#tank.damage_dealt,
      alive => not Me#tank.dead,
      opp_alive => not Opp#tank.dead,
      turns => Turn,
      pulls => R#mrun.pulls,
      shots => R#mrun.shots,
      opp_shots => R#mrun.opp_shots,
      probe => R#mrun.probe}.

%%%============================================================================
%%% THE FITNESS: a ladder over the scripted gauntlet, graded on damage MARGIN,
%%% walked lazily. IT NEVER READS ENERGY AND IT NEVER READS SURVIVAL TIME.
%%%
%%% taken is the OPPONENT's damage_dealt, which in a duel is exactly the bullet
%%% damage the learner absorbed, so no engine counter is needed. robo_sim credits
%%% damage_dealt on bullet hits ONLY, never on rams or walls, so ram farming is
%%% impossible under this rule.
%%%
%%% WHY THE DEATH FLOOR IS NOT A TUNING KNOB. Raw margin pays a losing controller
%%% to end the match early, because dying truncates the damage the opponent can
%%% still inflict: a wall suicide takes 100 turns and concedes about half a bar,
%%% against the 1.04 bars that surviving and losing to the floor bot concedes.
%%% Flooring the loss at one bar makes dying weakly worse than surviving with the
%%% same damage taken, at every turn. The constant is the tank's own starting
%%% energy, not a chosen number.
%%%============================================================================
margin(#{dealt := D, taken := T, alive := true}) -> D - T;
margin(#{dealt := D, taken := T, alive := false}) -> D - max(T, ?BAR).

%% F = (rungs cleared, walking from the bottom) + squash(mean margin on the
%% frontier rung).
%%
%% cleared(Rung) iff EVERY match of that rung has margin greater than zero: a
%% sign test, no invented threshold. all for clearing and mean for the frontier
%% is deliberate, because a rung cleared on average is a rung with a geometry the
%% controller cannot handle, while the mean grades partial progress so the rung
%% is never a plateau.
%%
%% WALK FROM THE BOTTOM, STOP AT THE FIRST UNCLEARED RUNG. Two consequences.
%% Compute: nothing above the frontier is read, so nothing above it is simulated,
%% and this is EXACT, not an approximation. Anti-forgetting, which matters more:
%% a rung once cleared must STAY cleared or the count drops, so rung 5's "circle
%% and never fire" attractor cannot eat the marksmanship learned on the gunless
%% rungs. The never-fire optimum is fenced off, not argued away.
%%
%% NO SHAPING. No term for scans held, radar coverage, gun alignment, near
%% misses, shots fired or hits counted. The floor is defined by PREDICTION, and
%% every cheap intermediate signal available here is precisely what
%% circle_strafer does, which is measured at 0 wins in 160 against the floor bot.
%% A per-scan reward would be worse than useless: a radar sweeping at maximum
%% rate acquires MORE distinct contacts than a radar that locks.
ladder(Subject, Rungs, Starts) -> ladder(Subject, Rungs, Starts, 0, []).

ladder(_Subject, [], _Starts, N, []) -> N * 1.0;
%% Once the whole ladder is cleared the frontier becomes the WEAKEST rung by
%% mean, so a champion keeps being pushed on its worst opponent, not its best.
ladder(_Subject, [], _Starts, N, Means) -> N + squash(lists:min(Means));
ladder(Subject, [K | Rest], Starts, N, Means) ->
    Ms = [margin(O) || Start <- Starts, O <- duel(Subject, {script, K}, Start)],
    rung(lists:all(fun(M) -> M > 0 end, Ms), Subject, Rest, Starts, N, mean(Ms), Means).

rung(true, Subject, Rest, Starts, N, Mean, Means) ->
    ladder(Subject, Rest, Starts, N + 1, [Mean | Means]);
rung(false, _Subject, _Rest, _Starts, N, Mean, _Means) ->
    N + squash(Mean).

%% THE TAIL TERM IS AN ORDERING, NOT AN EXCHANGE RATE. Confined below 1.0, so
%% clearing a rung outranks every possible margin gain on it. This is sound ONLY
%% because both optimisers select by RANK: mu_lambda_es sorts and keeps the best
%% mu, sep_cma_es sorts and recombines the best mu, and neither reads a
%% magnitude. An optimiser that read magnitudes would silently turn this into a
%% weighted sum with weights nobody chose.
squash(M) -> (clampf(M, 2.0 * ?BAR) + 2.0 * ?BAR) / (4.0 * ?BAR + 1).

clampf(V, Max) -> max(-Max, min(Max, V)).

%% Arm D's fitness: rung 5 only, so F degenerates to plain margin and the
%% curriculum is removed entirely.
rungs(d) -> [?FLOOR];
rungs(_Arm) -> robo_gauntlet:kinds().

%%%============================================================================
%%% THE COLLECTOR. Checkpoints and the per-generation diagnostics, captured by
%%% wrapping the fitness with one send to a per-run process. mu_lambda_es exposes
%%% no trace, so the wrapper covers both arms uniformly.
%%%
%%% DISTINCT QUANTISED PHENOTYPES is recorded from the first run, not added after
%%% a null. quantize/1 puts the search on a finite integer lattice at scale 256
%%% with a hard clamp at plus or minus 2048, so once sep-CMA's per-coordinate
%%% sigma falls below about 1/256 every offspring collapses to the SAME
%%% phenotype, fitness goes constant, the selection differential vanishes and the
%%% covariance keeps contracting. A run ending that way looks exactly like a
%%% converged negative and is not one (IF-5).
%%%============================================================================
col_start(Lambda, Checks) ->
    spawn_link(fun() -> col_loop(#col{lambda = Lambda, checks = Checks}) end).

col_loop(C) ->
    receive
        {eval, Q, F} -> col_loop(col_eval(C, Q, F));
        {stop, From} -> From ! {col, col_final(C)}
    end.

col_eval(C, Q, F) ->
    N = C#col.n + 1,
    C2 = C#col{n = N, best = better(C#col.best, Q, F), block = [Q | C#col.block]},
    col_block(col_mark(C2, N), N).

better({BQ, BF}, _Q, F) when F =< BF -> {BQ, BF};
better(_Best, Q, F) -> {Q, F}.

col_mark(C, N) -> mark(C, N, lists:member(N, C#col.checks)).

mark(C, N, true) -> C#col{marks = [{N, C#col.best} | C#col.marks]};
mark(C, _N, false) -> C.

col_block(C, N) -> close_block(C, N rem C#col.lambda =:= 0).

close_block(C, false) -> C;
close_block(C, true) ->
    B = C#col.block,
    C#col{block = [],
          distinct = [length(lists:usort(B)) | C#col.distinct],
          clamp = [mean([clamp_frac(Q) || Q <- B]) | C#col.clamp]}.

%% IF-4's raw material. sep_cma_es can emit 1.0e308-scale values from a diverging
%% covariance, which quantize/1 clamps silently.
clamp_frac(Q) -> length([1 || W <- Q, abs(W) >= ?W_CLAMP]) / max(1, length(Q)).

%% A TUPLE, never a map: term_to_binary is not canonical for maps.
col_final(C) ->
    {C#col.n, C#col.best, lists:reverse(C#col.marks),
     lists:reverse(C#col.distinct), lists:reverse(C#col.clamp)}.

%%%============================================================================
%%% ONE RUN. Seeded and reproducible: rand state is per process, so parallelism
%%% is deterministic.
%%%============================================================================
one_run(Arm, Seed, Layers, Opts) ->
    Dim = robo_net:weight_count(Layers),
    Lambda = lambda_for(Arm, Dim, Opts),
    Budget = maps:get(budget, Opts),
    %% DEFECT FIX (D3). Generations round UP, so every arm reaches at least the
    %% budget and therefore every checkpoint survives. Rounding DOWN dropped the
    %% 50,000 mark for any arm whose lambda does not divide the budget: lambda 17
    %% gave 49,997 evaluations and lambda 70 gave 49,980, so arms L and M silently
    %% kept two checkpoints of three while S and D kept all three. IF-9 then
    %% differenced 25k against 10k for two arms and 50k against 25k for the other
    %% two, comparing arms on different budget windows with nothing in the feed
    %% saying so. The overshoot is at most lambda-1 evaluations past the final
    %% checkpoint and cannot affect a reading taken AT a checkpoint.
    Gens = max(1, (Budget + Lambda - 1) div Lambda),
    Checks = [C || C <- maps:get(checkpoints, Opts), C =< Gens * Lambda],
    _ = rand:seed(exsss, {Seed, Seed * 7 + 1, Seed * 13 + 3}),
    Tab = ets:new(exp066_cache, [set, private]),
    Col = col_start(Lambda, Checks),
    Fit = fitness_fun(Layers, rungs(Arm), train_starts(Opts), Col, Tab),
    Res = optimise(Arm, Fit, Dim, Lambda, Gens),
    Col ! {stop, self()},
    Final = receive {col, X} -> X end,
    true = ets:delete(Tab),
    {Res, Final}.

%% INITIALISATION. sep_cma_es defaults x0 to the ZERO VECTOR, and a zero weight
%% vector makes every neuron activate(0) = 0, so every intent field is zero and
%% the initial mean IS LITERALLY A SITTING DUCK. x0 is therefore set explicitly
%% to a per-seed N(0,1) draw from the run's own seeded stream. mu_lambda_es has
%% no x0 option and already draws N(0,1) parents, so the two arms start from the
%% same distribution.
optimise(m, Fit, Dim, Lambda, Gens) ->
    mu_lambda_es:evolve(Fit, Dim, #{mu => 10, lambda => Lambda,
                                    max_generations => Gens, init_sigma => 1.0});
optimise(_Arm, Fit, Dim, Lambda, Gens) ->
    X0 = [rand:normal() || _ <- lists:seq(1, Dim)],
    sep_cma_es:evolve(Fit, Dim, #{lambda => Lambda, max_generations => Gens,
                                  init_sigma => 1.0, x0 => X0}).

%% BUDGET is in UNIQUE evaluations. Both optimisers evaluate only offspring
%% (mu_lambda_es uses comma selection, sep_cma_es samples lambda fresh points),
%% so evaluations equal lambda times generations with NO parent re-scoring. That
%% is the accounting defect the exp064 and exp065 gates found in the hand-rolled
%% EA, and it is absent here.
lambda_for(m, _Dim, Opts) -> maps:get(lambda_m, Opts);
lambda_for(_Arm, Dim, Opts) -> resolve_lambda(maps:get(lambda, Opts), Dim).

resolve_lambda(auto, Dim) -> cma_lambda(Dim);
resolve_lambda(L, _Dim) -> L.

%% sep_cma_es's own default, restated so the runner and the optimiser agree on
%% the generation count. Dim 281 gives 20, Dim 90 gives 17.
cma_lambda(N) -> 4 + trunc(3.0 * math:log(N)).

%% THE ONE FLOAT BOUNDARY, at phenotype build time, inside the fitness and
%% OUTSIDE the match.
%%
%% The cache is keyed on a canonical digest of the quantised integer weight list
%% rather than on the list itself, for memory: 50000 entries of 281 integers is
%% about 340 MB per run and 20 runs are meant to be parallel. The key is derived
%% from a LIST of integers with the deterministic option set, never a map.
fitness_fun(Layers, Rungs, Starts, Col, Tab) ->
    Net = fun(Q) -> ladder({net, Layers, Q}, Rungs, Starts) end,
    fun(Xs) ->
        Q = robo_net:quantize(Xs),
        F = cached(Tab, Q, Net),
        Col ! {eval, Q, F},
        F
    end.

cached(Tab, Q, Net) ->
    K = genome_key(Q),
    hit(Tab, K, Q, Net, ets:lookup(Tab, K)).

hit(_Tab, _K, _Q, _Net, [{_K2, F}]) -> F;
hit(Tab, K, Q, Net, []) ->
    F = Net(Q),
    true = ets:insert(Tab, {K, F}),
    F.

genome_key(Q) ->
    crypto:hash(sha256, term_to_binary(Q, [deterministic, {minor_version, 2}])).

%%%============================================================================
%%% THE PRIMARY ENDPOINT. Per-seed held-out win rate over 160 matches, where a
%%% WIN requires the predictive_gun tank DEAD and the champion tank ALIVE at
%%% match end.
%%%
%%% Draws (turn cap with both alive, or mutual death) count as NOT beating. This
%%% is chosen over any W + D/2 rule for a specific reason: a pure evader that
%%% never fires would score exactly the parity value under such a rule, which
%%% readmits the pre-measured never-fire local optimum through the scoring door.
%%%============================================================================
heldout(Subject, Kind, Starts) ->
    [O || Start <- Starts, O <- duel(Subject, {script, Kind}, Start)].

rates(Os) ->
    N = max(1, length(Os)),
    W = length([1 || #{alive := true, opp_alive := false} <- Os]),
    L = length([1 || #{alive := false, opp_alive := true} <- Os]),
    {W / N, L / N, (N - W - L) / N}.

win_rate(Os) -> element(1, rates(Os)).

%% Mean per-match damage margin in WHOLE units. THE MARGIN IS NOT A COMPETENCE
%% ORDERING AND MAY NOT BE USED AS ONE: measured on the held-out 80, the RAMMER
%% out-damages the CIRCLE_STRAFER while both lose almost everything. It is a
%% CENSORING DIAGNOSTIC and nothing more.
mean_margin(Os) -> mean([(maps:get(dealt, O) - maps:get(taken, O)) / ?FP || O <- Os]).

cap_share(Os) -> mean([b(maps:get(turns, O) >= 2000) || O <- Os]).

%% IF-12's raw material: the floor bot's shots in the champion's WON matches. A
%% controller that stays out of the radar beam faces an opponent that holds fire
%% unless the track is from this turn. That is legitimate exploitation of the
%% partial observability this substrate was chosen for, but it is a DIFFERENT
%% finding from out-shooting the floor bot.
won_opp_shots(Os) ->
    mean([maps:get(opp_shots, O) || #{alive := true, opp_alive := false} = O <- Os]).

profile(Subject, Starts) ->
    [begin
         Os = heldout(Subject, K, Starts),
         {W, L, D} = rates(Os),
         {K, W, L, D}
     end || K <- robo_gauntlet:kinds()].

%%%============================================================================
%%% THE FROZEN CONSTANTS. All measured on the FINAL generator, at the engine pin,
%%% BEFORE any evolution arm runs, with SCRIPTED BOTS ONLY.
%%%
%%% k = 4 IS THE ONE CHOSEN CONSTANT IN THE DESIGN AND IT IS NAMED AS SUCH. Four
%%% standard errors above parity puts CLEARED beyond any reading of
%%% "statistically indistinguishable from the floor bot's own clone", and it does
%%% not move with the constructor's skill in either direction. The gate killed the
%%% original gap-closing form B = P + 0.60 * (W_0b - P), under which the person
%%% who built arm C set the difficulty of the gate they then wanted evolution to
%%% clear.
%%%============================================================================
constants() -> constants(defaults()).

constants(Opts0) ->
    Opts = merged(Opts0),
    Starts = heldout_starts(Opts),
    %% P: predictive_gun against its own CLONE. Both seats are played through the
    %% same instrument the champions face, so the reference and the endpoint are
    %% the same measurement rather than two similar ones.
    Os = heldout({script, ?FLOOR}, ?FLOOR, Starts),
    {P, _PL, _PD} = rates(Os),
    Boot = bootstrap_se(Os),
    Binom = math:sqrt(max(0.0, P * (1 - P)) / max(1, length(Os))),
    SE = max(Boot, Binom),
    #{p => P,
      se => SE,
      se_bootstrap => Boot,
      se_binomial => Binom,
      s_par => mean([maps:get(opp_shots, O) || O <- Os]),
      cap_share => cap_share(Os),
      b => P + 4 * SE,
      r_line => P + 2 * SE,
      d_min => 2 * SE,
      n_scripted => scripted_null(Starts),
      matches => length(Os)}.

%% START-LEVEL bootstrap, both seats of a resampled start kept TOGETHER, floored
%% at the binomial value by the caller. The original design derived its noise
%% scale as half the spread of P over "four disjoint 40-start subsets"; they were
%% NOT disjoint (first/last and odd/even are two OVERLAPPING partitions of the
%% same 160 matches), which understated the SE by roughly threefold and would
%% have CLEARED a champion statistically indistinguishable from the floor bot's
%% own clone.
%%
%% THE GATE'S OWN FALSIFIER, recorded so its critique is not immune either: the
%% band critique is falsified if this bootstrap returns an SE at or below about
%% 0.020, in which case the original constants were adequately separated. It is
%% run and reported whatever it returns.
bootstrap_se(Os) ->
    Ps = list_to_tuple(pairs(Os)),
    N = tuple_size(Ps),
    _ = rand:seed(exsss, {?BOOT_SEED, ?BOOT_SEED * 7 + 1, ?BOOT_SEED * 13 + 3}),
    Rs = [boot_one(Ps, N) || _ <- lists:seq(1, ?BOOT_N)],
    M = mean(Rs),
    math:sqrt(mean([(X - M) * (X - M) || X <- Rs])).

pairs([A, B | Rest]) -> [{A, B} | pairs(Rest)];
pairs(_Short) -> [].

boot_one(Ps, N) ->
    Samp = [element(rand:uniform(N), Ps) || _ <- lists:seq(1, N)],
    win_rate(lists:append([[A, B] || {A, B} <- Samp])).

%% N: the scripted-ladder null against the floor bot on the same 160 matches.
%% Measured at authoring at or below 0.0125 (sitting_duck 0/160, spinner 0/160,
%% rammer 2/160, circle_strafer 0/160).
scripted_null(Starts) ->
    [{K, win_rate(heldout({script, K}, ?FLOOR, Starts))}
     || K <- robo_gauntlet:kinds(), K =/= ?FLOOR].

%% R: the best-of-30 random-genome held-out win rate, at the frozen encoding.
%%
%% FAILED IS DELIBERATELY NEAR-UNREACHABLE AND THE EXPECTED FORM OF A NEGATIVE IS
%% INCONCLUSIVE. R is a best-of-K ORDER STATISTIC and therefore inflated relative
%% to a mean random net; that conservatism is acceptable for a claim as strong as
%% "no better than random", but it means the FAILED branch will almost never fire
%% and its non-firing carries no information.
random_null(Layers, Starts, K) ->
    lists:max([win_rate(heldout({net, Layers, Q}, ?FLOOR, Starts))
               || Q <- random_genomes(Layers, K)]).

%% IF-2's reference: the best TRAINING fitness of K random vectors from the same
%% init distribution.
inert_null(Arm, Layers, Starts, K) ->
    lists:max([ladder({net, Layers, Q}, rungs(Arm), Starts)
               || Q <- random_genomes(Layers, K)]).

%% Calibration and null seeds 1..K, DISJOINT from the measurement seeds.
random_genomes(Layers, K) ->
    Dim = robo_net:weight_count(Layers),
    [begin
         _ = rand:seed(exsss, {I, I * 7 + 1, I * 13 + 3}),
         robo_net:quantize([rand:normal() || _ <- lists:seq(1, Dim)])
     end || I <- lists:seq(1, K)].

%%%============================================================================
%%% THE DECISION RULE. Pre-committed, computed on held-out ONLY, all outcomes
%%% reachable. The three CLEARED conditions do distinct work: typical strength,
%%% reliability across runs, and DIRECTION. The third is not decorative: at
%%% parity wins equal losses exactly, so "more wins than losses by at least
%%% D_min" is a genuine directional test.
%%%============================================================================
verdict(Rs, K) ->
    Ws = [R#res.w || R <- Rs],
    Ls = [R#res.l || R <- Rs],
    N = length(Ws),
    B = maps:get(b, K),
    Rel = length([1 || W <- Ws, W >= maps:get(r_line, K)]),
    Dir = length([1 || {W, L} <- lists:zip(Ws, Ls), W - L >= maps:get(d_min, K)]),
    Part = length([1 || {W, L} <- lists:zip(Ws, Ls),
                        W >= B, W - L >= maps:get(d_min, K)]),
    Med = median(Ws),
    decide(Med >= B andalso Rel >= ceil_frac(3, 4, N) andalso Dir >= ceil_frac(3, 4, N),
           Med =< maps:get(r, K, 0.0),
           Part >= ceil_frac(1, 4, N)).

decide(true, _Failed, _Partial) -> cleared;
decide(false, true, _Partial) -> failed;
decide(false, false, true) -> partial;
decide(false, false, false) -> inconclusive.

%% 15 of 20 and 5 of 20 scale to 8 of 10 and 3 of 10 on the same fractions.
ceil_frac(Num, Den, N) -> (Num * N + Den - 1) div Den.

%%%============================================================================
%%% INSTRUMENT FAILURE, distinguished from a real negative. Each is
%%% pre-committed. IF-1 through IF-6 void or replace a verdict; IF-7, IF-8 and
%%% IF-12 are MODIFIERS that LABEL a verdict; IF-9 through IF-11 are observables
%%% that constrain a reading.
%%%============================================================================
flags(Rs, K, Inert) ->
    Med = median_res(Rs),
    Ws = [R#res.w || R <- Rs],
    B = maps:get(b, K),
    [{'IF-2 SEARCH-INERT', median([R#res.fit || R <- Rs]) =< Inert,
      "the fitness supplies no usable gradient; NOT 'evolution cannot reach the floor'"},
     {'IF-3 DEGENERATE-NON-FIRING', Med#res.shots =< 0.0,
      "the pre-measured never-fire optimum was selected; the floor question was never asked"},
     {'IF-4 SEARCH-DIVERGED', Med#res.clamp_frac > 0.5,
      "a diverging covariance emitted values quantize/1 clamped silently"},
     {'IF-5 LATTICE-COLLAPSE', Med#res.distinct_last =< 1,
      "the run collapsed onto a lattice point; it has not answered the question"},
     {'IF-7 CAP-DOMINATED', Med#res.caps > 0.40,
      "2.5x the measured parity cap share; the verdict is cap-conditional and must be LABELLED so"},
     {'IF-8 MEMORISATION', Med#res.train_w >= B andalso Med#res.w < B,
      "MODIFIER; pre-registered next rung is the stochastic-start variant, NOT more budget"},
     {'IF-9 BUDGET-LIMITED', budget_gain(Rs) >= 0.05,
      "read ONLY on a FAILED or INCONCLUSIVE verdict: the negative is budget-limited"},
     {'IF-10 LADDER-INVERSION', inverted(Med#res.profile),
      "an OBSERVABLE. NOT claimed as intransitivity; that is phase 1's question"},
     %% Read ONLY when there is a won match to read it on: with no wins the mean
     %% is UNDEFINED, not zero, and a modifier that fires on every zero-win arm
     %% would label exactly the verdicts it says nothing about.
     {'IF-12 RADAR-STARVED',
      Med#res.w > 0.0 andalso Med#res.won_opp_shots < 0.25 * maps:get(s_par, K),
      "MODIFIER; the champion won by staying out of the beam, a DIFFERENT finding"},
     {'note median W_s', median(Ws), "the primary endpoint"}].

%% Median W_s at the last checkpoint minus the median at the one before it.
budget_gain(Rs) ->
    Marks = [R#res.marks || R <- Rs],
    gain([M || M <- Marks, length(M) >= 2]).

gain([]) -> 0.0;
gain(Ms) ->
    Last = median([element(2, lists:last(M)) || M <- Ms]),
    Prev = median([element(2, lists:nth(length(M) - 1, M)) || M <- Ms]),
    Last - Prev.

inverted(Profile) ->
    lists:any(fun({K, W, L, _D}) ->
                  lists:member(K, [sitting_duck, spinner]) andalso L > W
              end, Profile).

%% The MEDIAN CHAMPION, by held-out win rate. Every IF code above that speaks of
%% "the median champion" reads this one seed, not a pooled average.
median_res(Rs) ->
    S = lists:sort(fun(A, B) -> A#res.w =< B#res.w end, Rs),
    lists:nth(max(1, length(S) div 2 + length(S) rem 2), S).

%%%============================================================================
%%% ARM C: KILL GATE 0b, EXPRESSIBILITY.
%%%
%%% A hand-CONSTRUCTED WEIGHT VECTOR driven through the pilot, NOT hand-written
%%% Erlang. Kill gate 0b must prove the NETWORK CLASS expresses the capability; a
%%% bespoke Erlang bot that beats predictive_gun proves nothing about it.
%%%
%%% Built and tuned on CALIBRATION starts ONLY, so its held-out number is an
%%% honest generalisation read with no in-sample advantage. It FREEZES THE
%%% ENCODING at the instant its held-out rate is measured. It does NOT set the
%%% bar: the bar is absolute, and the precondition is that arm C itself clears
%%% it, which proves the bar reachable BY CONSTRUCTION while leaving it
%%% independent of constructor skill in both directions.
%%%
%%% STOP RULE, PRE-REGISTERED. An ATTEMPT is one edit to the gains below, or one
%%% topology change, followed by one full evaluation on the 30 calibration
%%% starts. Construction stops when either the calibration win rate reaches B and
%%% 5 consecutive further attempts fail to raise it, or 40 attempts total (20 per
%%% topology) have been made without reaching B, in which case UNGRADEABLE fires.
%%% The attempt count and the full calibration trajectory go into the raw feed.
%%%
%%% REPRESENTABILITY OF THE TRIGGER, AND IT SETS THE TOPOLOGY FALLBACK.
%%% Fire-when-aligned is an EVEN function of aim error. Channel 12 is odd and
%%% cannot supply it; channel 11 is the even one, so a positive weight on channel
%%% 11 plus a negative bias thresholds on alignment. Sharpness is bounded by the
%%% weight cap: weights cap at 8.0 and tanh saturates at 4.875 in Q12, so a
%%% linear unit can threshold at roughly cos at or above 0.9, about plus or minus
%%% 25 degrees, against the floor bot's AIM_TOL of about 2.8 degrees. That is the
%%% sharpest known representability limit of the linear arm and it is stated in
%%% advance. If [17,5] cannot clear the precondition for this reason, the
%%% pre-registered move is [17,12,5], where a hidden layer builds a sharper
%%% conjunction from channels 11 and 12, and the fact is recorded as the reason.
%%%============================================================================

%% ATTEMPT 1. Every value below is a gain on ONE channel, and every one of them
%% is capped at plus or minus 8.0 by quantize/1: THE BIAS IS CAPPED TOO, which is
%% what fixes the trigger threshold at about cos 0.92 rather than anywhere
%% sharper.
arm_c_gains() ->
    #{orbit => 4.0,        %% turn_body  gets -orbit * bear_body_cos: equilibrium
                           %%            at cos 0, that is the contact held at
                           %%            ninety degrees, which is orbiting
      centre => 0.5,       %% turn_body  gets -centre * pos_port: turn toward the
                           %%            arena centre, since wall contact costs a
                           %%            full unit of energy per turn
      body_bias => 0.3,    %% turn_body  bias: the blind slow curve, matching
                           %%            robo_gauntlet:hunt/1's turn_body of 2
      aim => 2.0,          %% turn_gun   gets +aim * bear_gun_sin, THE AIM ERROR:
                           %%            the signed quantity a positive turn_gun
                           %%            reduces. Aim is ONE positive weight.
      lead => 3.0,         %% turn_gun   gets +lead * target_lateral: lead angle
                           %%            is lateral speed over bullet speed and
                           %%            is range-independent to first order, so
                           %%            ONE weight is a working lead
      lock => 3.0,         %% turn_radar gets +lock * bear_radar_sin, THE LOCK
                           %%            ERROR. Radar tracking is one weight.
      sweep => 5.0,        %% turn_radar bias: sweep while blind
      sweep_off => 5.0,    %% turn_radar gets -sweep_off * contact_fresh, so the
                           %%            sweep bias is cancelled by a fresh track
                           %%            and restored as the track ages
      throttle => 8.0,     %% accel      bias: full throttle. Coasting beats
                           %%            braking here, measured: the engine has
                           %%            no drag, so a sustained negative command
                           %%            drives the tank backwards into the wall
                           %%            it was fleeing.
      trigger => 8.0,      %% fire       gets +trigger * bear_gun_cos, the EVEN
                           %%            alignment channel
      fresh => 0.5,        %% fire       gets +fresh * contact_fresh
      close => 0.3,        %% fire       gets +close * contact_prox
      hold => -8.0}.       %% fire       bias, at the cap: blind reads -8.0, tanh
                           %%            saturates, to_range gives -30 and
                           %%            clamp_power reads that as HOLD

%% The flat genome, in robo_net's layout: layers in order, neurons within a layer
%% in order, and FOR EACH NEURON ITS BIAS FIRST followed by one weight per input
%% in input order. Output order is turn_body, turn_gun, turn_radar, accel, fire.
-spec arm_c_weights(map()) -> [float()].
arm_c_weights(G) ->
    neuron([{9, -gain(orbit, G)}, {6, -gain(centre, G)}], gain(body_bias, G))
        ++ neuron([{12, gain(aim, G)}, {16, gain(lead, G)}], 0.0)
        ++ neuron([{14, gain(lock, G)}, {8, -gain(sweep_off, G)}], gain(sweep, G))
        ++ neuron([], gain(throttle, G))
        ++ neuron([{11, gain(trigger, G)}, {8, gain(fresh, G)},
                   {15, gain(close, G)}], gain(hold, G)).

neuron(Pairs, Bias) -> [Bias | [weight_at(I, Pairs) || I <- lists:seq(1, ?INPUTS)]].

weight_at(I, Pairs) -> pair_val(lists:keyfind(I, 1, Pairs)).

pair_val(false) -> 0.0;
pair_val({_I, V}) -> V.

gain(K, G) -> maps:get(K, G, 0.0).

arm_c() -> arm_c(#{}).

%% Reports the calibration rate (the tuning surface), the held-out rate W_0b (the
%% precondition), the shots per match (the only source of a firing-rate scale for
%% IF-3) and the FULL LADDER PROFILE, which exists for IF-11: an arm C that
%% clears the precondition while LOSING to a lower rung is the signature of a
%% construction that beats predictive_gun by exploiting its perception rather
%% than out-fighting it.
arm_c(Opts0) ->
    Opts = merged(Opts0),
    Layers = maps:get(c_layers, Opts),
    ?INPUTS = hd(Layers),
    %% DEFECT FIX (D1). arm_c_weights/1 emits exactly one bias plus 17 weights per
    %% output neuron, which is the [17,5] layout and no other. Passing [17,12,5]
    %% used to hand a 90-parameter genome to a 281-parameter network; robo_net
    %% zero-fills the remainder, so the construction was silently destroyed and
    %% measured as losing every match to rammer, circle_strafer and the floor bot.
    %% A hand construction that cannot be built must say so rather than produce a
    %% number. See the D9 note on arm_c_role/0 for why no hidden-layer fallback
    %% was written instead.
    Layers =:= ?C_LAYERS orelse
        error({arm_c_topology_unsupported, [{given, Layers}, {supported, ?C_LAYERS}]}),
    Q = robo_net:quantize(arm_c_weights(maps:get(gains, Opts))),
    Net = {net, Layers, Q},
    Cal = heldout(Net, ?FLOOR, calib_starts(Opts)),
    Held = heldout(Net, ?FLOOR, heldout_starts(Opts)),
    #{layers => Layers,
      dim => robo_net:weight_count(Layers),
      calibration => win_rate(Cal),
      w_0b => win_rate(Held),
      margin => mean_margin(Held),
      shots => mean([maps:get(shots, O) || O <- Held]),
      caps => cap_share(Held),
      profile => profile(Net, heldout_starts(Opts)),
      genome => Q}.

%%%============================================================================
%%% CHAMPION ARCHIVING. The champion is the ES-returned best-by-TRAINING-fitness
%%% vector, NEVER re-picked on held-out; held-out is never fed back and never
%%% used for early stopping.
%%%
%%% The archived form is a TUPLE of tuples, lists, integers and atoms, so
%%% term_to_binary is canonical over it and the digest is stable across VMs. A
%%% map here would reproduce the exact accident that made robo_match's first
%%% golden vector differ between eunit and a plain erl.
%%%============================================================================
champion(Arm, Seed, Layers, Q, Fit, Evals) ->
    {champion, Arm, Seed, Layers, Q, Fit, Evals}.

-spec champion_id(tuple()) -> binary().
champion_id({champion, Arm, Seed, Layers, Q, _Fit, _Evals}) ->
    binary:encode_hex(
      crypto:hash(sha256,
                  term_to_binary({Arm, Seed, Layers, Q},
                                 [deterministic, {minor_version, 2}]))).

%% One Erlang term per line, so file:consult/1 reads the archive back.
-spec champion_write(string(), [tuple()]) -> ok.
champion_write(Path, Champs) ->
    {ok, Fd} = file:open(Path, [write]),
    [io:format(Fd, "~w.~n", [C]) || C <- Champs],
    file:close(Fd).

%%%============================================================================
%%% THE ARMS.
%%%
%%% WHY L IS MANDATORY. The encoding is built to make the floor nearly linearly
%%% representable, so a pass by arm S alone would have to be reported honestly as
%%% "a 17-channel linear map suffices and the ES found it" rather than
%%% "neuroevolution reached competence". Without this arm the phase-0 claim is
%%% inflated in a way no later analysis can undo.
%%%
%%% WHY D IS MANDATORY. The staircase is itself a curriculum, so a stall is a
%%% statement about the curriculum. If S stalls at rung 3, "did not reach the
%%% floor" would be uninterpretable in exactly the way the plan says a null must
%%% not be. D removes the curriculum entirely.
%%%
%%% WHY THE STOPPING RULE IS ASYMMETRIC. CLEARED is an EXISTENCE claim, so one
%%% optimiser class suffices. FAILED is a UNIVERSAL claim, so it needs two,
%%% because a negative from a single optimiser reproduces verbatim the search
%%% under-convergence confound this gate exists to remove. Arm M therefore runs
%%% ONLY if S does not clear. Fixed in advance so it cannot be used to shop for a
%%% result.
%%%============================================================================
arm_layers(l) -> [17, 5];
arm_layers(_Arm) -> [17, 12, 5].

arm_seeds(Arm, Opts) ->
    Seed0 = maps:get(seed0, Opts),
    lists:seq(Seed0, Seed0 + maps:get(seed_key(Arm), Opts) - 1).

seed_key(s) -> seeds_s;
seed_key(l) -> seeds_l;
seed_key(d) -> seeds_d;
seed_key(m) -> seeds_m.

arm(Arm, Opts) ->
    Layers = arm_layers(Arm),
    ?INPUTS = hd(Layers),
    pmap(fun(Seed) -> seed_run(Arm, Seed, Layers, Opts) end,
         arm_seeds(Arm, Opts), maps:get(workers, Opts)).

seed_run(Arm, Seed, Layers, Opts) ->
    {Res, {N, {Q, Fit}, Marks, Distinct, Clamp}} = one_run(Arm, Seed, Layers, Opts),
    ok = check_champion_agrees(Res, Q, Marks),
    Held = heldout_starts(Opts),
    Net = {net, Layers, Q},
    Os = heldout(Net, ?FLOOR, Held),
    {W, L, D} = rates(Os),
    #res{arm = Arm, seed = Seed, layers = Layers,
         dim = robo_net:weight_count(Layers),
         evals = evals_of(Res, N), fit = Fit, q = Q,
         w = W, l = L, d = D,
         margin = mean_margin(Os),
         caps = cap_share(Os),
         shots = mean([maps:get(shots, O) || O <- Os]),
         pulls = mean([maps:get(pulls, O) || O <- Os]),
         won_opp_shots = won_opp_shots(Os),
         train_w = win_rate(heldout(Net, ?FLOOR, train_starts(Opts))),
         distinct_last = last_or(Distinct, 0),
         clamp_last = last_or(Clamp, 0.0),
         clamp_frac = clamp_frac(Q),
         profile = profile(Net, Held),
         %% All three checkpoints are evaluated on held-out. The final checkpoint
         %% must equal the ES-returned best; check_champion_agrees/3 asserts it.
         marks = [{At, win_rate(heldout({net, Layers, MQ}, ?FLOOR, Held))}
                  || {At, {MQ, _MF}} <- Marks]}.

%% DEFECT FIX (D2). The pre-registration says "the 50,000 record MUST equal the
%% ES-returned best; that equality is the wrapper's self-check", and it was not
%% checked. The champion and every checkpoint were taken from the COLLECTOR, and
%% the optimiser's own best was read nowhere outside the determinism gate, so the
%% stated equality was true by construction: the same collector field compared
%% with itself. evals_of/2 compares evaluation COUNTS, which is a different and
%% much weaker claim than genome equality.
%%
%% Now the collector's champion is compared against the optimiser's returned best
%% after the same quantisation, which is the only comparison that means anything:
%% the collector stores quantised integers and the ES carries floats. A mismatch
%% means the collector and the optimiser disagree about which genome won, and no
%% result from that seed is trustworthy, so it raises rather than warns.
check_champion_agrees(Res, Q, Marks) ->
    Best = maps:get(best, Res, undefined),
    agree(Q, Best, last_mark_q(Marks)).

last_mark_q([]) -> undefined;
last_mark_q(Marks) -> element(1, element(2, lists:last(Marks))).

agree(_Q, undefined, _LastQ) -> ok;          %% optimiser exposes no best; nothing to check
agree(Q, Best, LastQ) -> agree_q(Q, robo_net:quantize(Best), LastQ).

agree_q(Q, Q, undefined) -> ok;
agree_q(Q, Q, Q) -> ok;
agree_q(Q, BestQ, LastQ) -> error({champion_disagrees, [{collector, Q},
                                                        {optimiser, BestQ},
                                                        {last_mark, LastQ}]}).

evals_of(Res, N) -> {maps:get(evaluations, Res, N), N}.

last_or([], D) -> D;
last_or(L, _D) -> lists:last(L).

%% Runs are independent and pure and rand state is per process, so this is
%% deterministic however it is scheduled.
%% DEFECT FIX (D4). This was not a pool. workers = 1 ran serially and any other
%% value spawned one process PER SEED regardless of the number, so workers => 4
%% gave 20 concurrent runs rather than four. Combined with a default of 1, a run
%% at pre-registered settings executed every seed sequentially: about 34 hours
%% against about 2.4 hours. It now runs in ordered chunks of N, which bounds
%% concurrency at N and preserves result order.
%%
%% Scheduling cannot affect results. Each seed is an independent pure run whose
%% rand state is seeded inside its own process, so the champion of a given seed
%% is identical however the work is spread. That is what makes it safe for the
%% default to follow the machine.
pmap(F, Xs, N) when not is_integer(N); N < 1 -> pmap(F, Xs, 1);
pmap(F, Xs, 1) -> lists:map(F, Xs);
pmap(F, Xs, N) -> lists:append([pmap_chunk(F, C) || C <- chunk(N, Xs)]).

pmap_chunk(F, Xs) ->
    Parent = self(),
    Kids = [spawn_monitor(fun() -> Parent ! {res, self(), F(X)} end) || X <- Xs],
    [collect_kid(P, R) || {P, R} <- Kids].

chunk(_N, []) -> [];
chunk(N, Xs) when length(Xs) =< N -> [Xs];
chunk(N, Xs) -> {H, T} = lists:split(N, Xs), [H | chunk(N, T)].

collect_kid(Pid, Ref) ->
    receive
        {res, Pid, V} -> demonitor(Ref, [flush]), V;
        {'DOWN', Ref, process, Pid, Reason} -> error({worker_died, Reason})
    end.

%%%============================================================================
%%% THE KILL GATES AND THE INSTRUMENT CHECKS. All before the arms, all cheap, and
%%% exported separately so they can be run before any compute is committed. ANY
%%% FAILURE STOPS THE PROTOCOL AT STEP 1.
%%%============================================================================
gates() -> gates(#{}).

gates(Opts0) ->
    Opts = merged(Opts0),
    io:format("== EXP-066 kill gates and instrument checks ==~n"),
    G = [gate_golden(), gate_topology(), gate_starts(), gate_boundary(),
         gate_channels(Opts), gate_solo(Opts), gate_determinism(Opts)],
    io:format("~n~s~n", [gate_verdict(lists:all(fun({_N, Ok, _D}) -> Ok end, G))]),
    G.

gate_verdict(true) ->
    "GATES PASS -- protocol step 2 (measure and FREEZE P, SE, S_par, B, R_line, "
    "D_min) may proceed. Nothing above commits compute to an evolution arm.";
gate_verdict(false) ->
    "GATES FAIL -- STOP. A failing instrument check makes every downstream number "
    "on this front meaningless; do not relax it, fix it.".

%% Gate 1. The engine is UNTOUCHED, asserted by recomputation rather than
%% trusted. robo_match_tests' golden vector is recomputed here through
%% robo_match's own unmodified runner, with maps canonicalised out before
%% hashing, exactly as that suite does.
gate_golden() ->
    Got = binary:encode_hex(golden_trace()),
    report_gate("golden match vector (robo_sim/net/gauntlet/match untouched)",
                Got =:= ?GOLDEN_MATCH, Got).

golden_trace() ->
    Results = [canon(robo_match:match(A, B, S))
               || {A, B} <- [{predictive_gun, circle_strafer},
                             {rammer, spinner},
                             {circle_strafer, sitting_duck}],
                  S <- robo_match:starts()],
    crypto:hash(sha256, term_to_binary(Results, [deterministic, {minor_version, 2}])).

canon(#{a := A, b := B, turns := T}) -> {T, outcome_tuple(A), outcome_tuple(B)}.

outcome_tuple(#{damage := D, survived := S, alive := L}) -> {D, S, L}.

%% Gate 2. TOPOLOGY WIDTH. robo_net:fit/2 silently pads or truncates, so a
%% mismatch between the channel count and the first layer width would never fail
%% a test. The weight counts are asserted against robo_net:weight_count/1 rather
%% than restated.
gate_topology() ->
    Wide = robo_net:weight_count([17, 12, 5]),
    Lin = robo_net:weight_count([17, 5]),
    Ok = hd(arm_layers(s)) =:= inputs() andalso hd(arm_layers(l)) =:= inputs()
        andalso Wide =:= 281 andalso Lin =:= 90
        andalso length(channels(#pilot{}, #tank{})) =:= inputs(),
    report_gate("topology width and weight counts",
                Ok, {inputs(), {'[17,12,5]', Wide}, {'[17,5]', Lin}}).

%% Gate 3. THE START GENERATOR: 120 distinct starts, separation at least 150
%% whole units so no match opens inside ram range, and at least 8 angle units of
%% heading offset on every start so no tank is ever bore-sighted at turn 1.
gate_starts() ->
    Ss = starts(),
    Ds = [robo_sim:dist({AX, AY}, {BX, BY}) || {AX, AY, _AH, BX, BY, _BH} <- Ss],
    Ok = length(lists:usort(Ss)) =:= 120 andalso lists:min(Ds) >= 150
        andalso lists:min([abs(off(I)) || I <- lists:seq(1, 120)]) >= 8
        andalso length(split(train)) =:= 6 andalso length(split(heldout)) =:= 80
        andalso length(split(calibration)) =:= 30
        andalso split(train) -- split(heldout) =:= split(train),
    report_gate("start generator: 120 distinct, min separation, offsets, disjoint splits",
                Ok, {distinct, length(lists:usort(Ss)), min_sep, lists:min(Ds),
                     median_sep, median([D * 1.0 || D <- Ds]), max_sep, lists:max(Ds)}).

%% Gate 4. THE PERCEPTION CONTRACT, on the PILOT. A controller must be handed the
%% arena whose scans were produced by the same step that produced its own tank. A
%% runner that stepped first would hand it a one-turn-stale world, silently, and
%% nothing would fail. Probed on the pilot STATE rather than the intent, because
%% two consecutive arenas can carry identical scans when nothing has moved.
gate_boundary() ->
    Arena = robo_sim:step(robo_sim:new([{a, 100, 300, 0}, {b, 400, 300, 128}]), []),
    Blind = Arena#arena{scans = []},
    T = lists:keyfind(a, #tank.id, Arena#arena.tanks),
    Net = {[17, 5], robo_net:quantize(arm_c_weights(arm_c_gains()))},
    {_, Fresh} = pilot_act(Net, pilot_init(), T, Arena),
    {_, Stale} = pilot_act(Net, pilot_init(), T, Blind),
    Ok = Arena#arena.scans =/= [] andalso Fresh =/= Stale
        andalso Stale#pilot.seen =:= 0 andalso Fresh#pilot.seen =:= 1,
    report_gate("perception contract: a stale arena is DETECTABLE for the pilot",
                Ok, {fresh_seen, Fresh#pilot.seen, stale_seen, Stale#pilot.seen}).

%% Gate 5. THE CHANNEL RANGE DIAGNOSTIC. A channel that never leaves a narrow
%% band is invisible to selection, and finding that out AFTER a null is worth
%% much less than finding it out before. Reports each channel's realised min, max
%% and variance across full matches over random genomes.
gate_channels(Opts) ->
    Layers = arm_layers(s),
    Start = hd(heldout_starts(Opts)),
    Vs = lists:append([probe_channels(Layers, Q, Start)
                       || Q <- random_genomes(Layers, maps:get(random_null, Opts))]),
    Cols = [[lists:nth(I, V) || V <- Vs] || I <- lists:seq(1, inputs())],
    Stats = [{I, lists:min(C), lists:max(C), variance(C)}
             || {I, C} <- lists:zip(lists:seq(1, inputs()), Cols)],
    [io:format("   ch ~2w  min ~5w  max ~5w  var ~10.1f~n", [I, Lo, Hi, V])
     || {I, Lo, Hi, V} <- Stats],
    Dead = [I || {I, Lo, Hi, _V} <- Stats, Hi - Lo < 4],
    report_gate("channel range diagnostic (dead channels are invisible to selection)",
                Dead =:= [], {samples, length(Vs), dead_channels, Dead}).

%% Channels are a pure function of the post-observe state and the acting tank, so
%% recording those two per turn and recomputing is EXACT, and it keeps the probe
%% out of the hot loop's arithmetic.
probe_channels(Layers, Q, Start) ->
    #{probe := Pr} = play_seat({net, Layers, Q}, {script, ?FLOOR}, Start, a, []),
    [channels(S, T) || {T, S} <- Pr].

%% Gate 6. THE SOLO OSCILLATION DIAGNOSTIC. There is no clock input and no
%% recurrence, deliberately: a hand-chosen oscillation period is a hand-designed
%% behaviour smuggled in as a sensor. Weaving and radar wobble must therefore
%% arise as limit cycles THROUGH THE WORLD. A champion flat in isolation that
%% loses to a predictive gun has failed for a REPRESENTATIONAL reason, not an
%% optimiser one, so this is measured before any champion exists.
gate_solo(Opts) ->
    Layers = maps:get(c_layers, Opts),
    Q = robo_net:quantize(arm_c_weights(maps:get(gains, Opts))),
    Cmds = solo({Layers, Q}, hd(heldout_starts(Opts)), 400),
    NA = length(lists:usort([A || {A, _B} <- Cmds])),
    NB = length(lists:usort([B || {_A, B} <- Cmds])),
    report_gate("solo oscillation: accel and turn_body are non-constant alone",
                NA > 1 orelse NB > 1, {distinct_accel, NA, distinct_turn_body, NB}).

%% robo_sim:finished/1 is true immediately with a single tank, so the arena is
%% stepped directly rather than through the match loop, exactly as
%% robo_match_tests' solo check does. The perception contract is the same: act on
%% the current arena, then step.
solo(Net, {X, Y, H, _BX, _BY, _BH}, N) ->
    solo_loop(robo_sim:new([{a, X, Y, H}]), Net, pilot_init(), N, []).

solo_loop(_Arena, _Net, _S, 0, Acc) -> lists:reverse(Acc);
solo_loop(Arena, Net, S, N, Acc) ->
    T = lists:keyfind(a, #tank.id, Arena#arena.tanks),
    {I, S2} = pilot_act(Net, S, T, Arena),
    solo_loop(robo_sim:step(Arena, [{a, I}]), Net, S2, N - 1,
              [{I#intent.accel, I#intent.turn_body} | Acc]).

%% Gate 7. DETERMINISM. Re-running one seed reproduces the champion
%% BIT-IDENTICALLY. Run at a REDUCED budget, because the pre-registration files
%% this under "all cheap" and a full-budget re-run is 2.8 CPU-hours; the property
%% under test is reproducibility of the pipeline, which a short run exercises in
%% full (seeding, x0 draw, quantisation, the cache, the collector).
gate_determinism(Opts) ->
    Probe = Opts#{budget := maps:get(probe_budget, Opts),
                  train := min(2, maps:get(train, Opts))},
    {A, _} = one_run(s, maps:get(seed0, Opts), arm_layers(s), Probe),
    {B, _} = one_run(s, maps:get(seed0, Opts), arm_layers(s), Probe),
    QA = robo_net:quantize(maps:get(best, A)),
    QB = robo_net:quantize(maps:get(best, B)),
    report_gate("determinism: a re-run reproduces the champion bit-identically",
                QA =:= QB andalso maps:get(fitness, A) =:= maps:get(fitness, B),
                {evaluations, maps:get(evaluations, A),
                 champion_id(champion(s, maps:get(seed0, Opts), arm_layers(s), QA,
                                      maps:get(fitness, A), maps:get(evaluations, A)))}).

report_gate(Name, Ok, Detail) ->
    io:format("~s ~s~n   ~p~n", [pass(Ok), Name, Detail]),
    {Name, Ok, Detail}.

pass(true) -> "PASS";
pass(false) -> "FAIL".

%%%============================================================================
%%% THE STUDY.
%%%
%%% ORDER OF OPERATIONS, AND IT IS LOAD-BEARING. Everything that could be tuned
%%% is measured and frozen BEFORE the first evolution arm runs, every
%%% generator-dependent constant is measured under the FINAL start rule, and the
%%% bar is frozen before arm C is built, so the person building arm C cannot set
%%% the difficulty of the gate they then want evolution to clear.
%%%
%%% UNGRADEABLE, and the evolution arms are NOT RUN, if W_0b is below B on both
%%% topologies under the stop rule. That is a cheap phase-0 finding and is
%%% treated as one, NOT as a reason to lower the bar.
%%%============================================================================
run() -> run(#{}).

pilot() -> run(pilot_opts()).

%% A cheap pilot: one seed, a tiny budget, a small held-out set. Anything but the
%% pre-registered configuration is a PILOT and NOT a result, and run/1 says so in
%% the feed rather than leaving a reader to notice.
pilot_opts() ->
    #{arms => [s], budget => 300, seeds_s => 1, train => 2, heldout => 8,
      calibration => 4, checkpoints => [100, 200, 300], random_null => 3,
      inert_null => 20, probe_budget => 40, feed => "exp066_pilot_feed.txt"}.

defaults() ->
    #{arms => [s, l, d],
      budget => 50000,
      lambda => auto,
      lambda_m => 70,
      seeds_s => 20, seeds_l => 10, seeds_d => 10, seeds_m => 20,
      seed0 => 2001,
      train => 6, heldout => 80, calibration => 30,
      checkpoints => [10000, 25000, 50000],
      %% Follows the machine. Safe because seeds are independent pure runs with
      %% per-process rand state, so concurrency changes wall clock and nothing
      %% else. Set workers => 1 to force serial execution when debugging.
      workers => erlang:system_info(schedulers_online),
      probe_budget => 40,
      random_null => 30,
      inert_null => 200,
      c_layers => ?C_LAYERS,
      gains => arm_c_gains(),
      feed => "exp066_floor_feed.txt"}.

merged(Opts) -> maps:merge(defaults(), Opts).

%% Protocol step 1, enforced rather than documented. Refuses to go further if any
%% instrument check fails, and names the ones that failed rather than reporting a
%% bare false, because the operator needs to know which instrument is broken.
require_gates(Opts) ->
    Results = gates(Opts),
    case [Name || {Name, false, _} <- Results] of
        [] -> ok;
        Failed -> error({gates_failed, Failed})
    end.

run(Opts0) ->
    Opts = merged(Opts0),
    %% DEFECT FIX (D5). The protocol's step 1 is the instrument checks and says
    %% "any failure stops here", but run/1 used to begin at step 2, so the whole
    %% study, or an UNGRADEABLE verdict, could be produced on an instrument that
    %% had never passed a check. The gates cost four seconds against hours of
    %% evolution, so there was never a cost argument for keeping them optional.
    ok = require_gates(Opts),
    {ok, Fd} = file:open(maps:get(feed, Opts), [write]),
    emit(Fd, "== EXP-066: does single-population evolution reach the COMPETENCE FLOOR? ==~n"),
    emit(Fd, "~s~n", [config_note(Opts)]),
    emit(Fd, "config: ~p~n", [maps:without([gains], Opts)]),
    K0 = constants(Opts),
    emit(Fd, "~n-- FROZEN CONSTANTS (scripted bots only, measured before any arm) --~n"),
    emit(Fd, "P=~.4f  SE=~.4f (bootstrap ~.4f, binomial floor ~.4f)  S_par=~.2f  cap_share=~.4f~n",
         [maps:get(p, K0), maps:get(se, K0), maps:get(se_bootstrap, K0),
          maps:get(se_binomial, K0), maps:get(s_par, K0), maps:get(cap_share, K0)]),
    emit(Fd, "B=~.4f  R_line=~.4f  D_min=~.4f (k=4 is the ONE chosen constant)~n",
         [maps:get(b, K0), maps:get(r_line, K0), maps:get(d_min, K0)]),
    emit(Fd, "N (scripted ladder vs the floor bot) = ~p~n", [maps:get(n_scripted, K0)]),
    emit(Fd, "~s~n", [se_note(maps:get(se_bootstrap, K0))]),
    C = arm_c(Opts),
    emit(Fd, "~n-- ARM C: kill gate 0b, expressibility (built on CALIBRATION only) --~n"),
    emit(Fd, "layers=~p dim=~p calibration=~.4f  W_0b=~.4f  margin=~.2f  shots/match=~.2f  caps=~.3f~n",
         [maps:get(layers, C), maps:get(dim, C), maps:get(calibration, C),
          maps:get(w_0b, C), maps:get(margin, C), maps:get(shots, C), maps:get(caps, C)]),
    emit(Fd, "arm C ladder profile (IF-11 reads this): ~p~n", [maps:get(profile, C)]),
    gradeable(Fd, Opts, K0, C, maps:get(w_0b, C) >= maps:get(b, K0)),
    file:close(Fd),
    ok.

config_note(Opts) ->
    pilot_note(maps:get(budget, Opts) =:= 50000 andalso maps:get(heldout, Opts) =:= 80
               andalso maps:get(train, Opts) =:= 6).

pilot_note(true) -> "PRE-REGISTERED CONFIGURATION.";
pilot_note(false) ->
    "PILOT CONFIGURATION -- NOT THE PRE-REGISTERED RUN. The thresholds below are "
    "computed on a reduced ensemble and NO VERDICT FROM THIS FEED IS SIGNABLE.".

se_note(Boot) when Boot =< 0.020 ->
    "NOTE: the bootstrap SE is at or below 0.020, which FALSIFIES the design "
    "gate's own band critique. Re-derive the bar arithmetic from the bootstrap.";
se_note(_Boot) ->
    "NOTE: the bootstrap SE exceeds 0.020, so the gate's band critique stands and "
    "the four-standard-error bar is the defensible one.".

%% DEFECT FIX (D9). Arm C used to BLOCK: if its held-out rate fell below B, the
%% evolution arms were not run at all and the front reported IF-1 UNGRADEABLE as
%% a finding about the ENCODING. The pilot measured that reading to be false on
%% this very encoding. Arm S reached 0.4875 held-out against the floor bot after
%% 3,000 evaluations, with a positive damage margin, while the hand construction
%% scored 0.0000. The encoding is demonstrably adequate; the hand construction is
%% what failed, and blaming the encoding for that would have been a signed wrong
%% answer produced by the instrument rather than by the substrate.
%%
%% Blocking on arm C also reinstated as a GATE precisely the dependency the DESIGN
%% gate identified as fatal flaw 2 and removed from the BAR: the experimenter's
%% own construction skill deciding the outcome. Relocating it from the threshold
%% to the precondition does not remove it.
%%
%% Expressibility is a property of the NETWORK CLASS. An evolved champion that
%% beats the floor bot establishes it a fortiori and far more strongly than any
%% hand construction can. So arm C is now a DIAGNOSTIC that is always reported and
%% never blocks, and UNGRADEABLE is reserved for what it was meant to mean:
%% nothing, constructed OR evolved, could use the encoding at all. That is decided
%% after the arms, by ungradeable_check/4, because it cannot be known before them.
gradeable(Fd, Opts, K, C, Precondition) ->
    arm_c_note(Fd, K, C, Precondition),
    Done = [{A, arm_report(Fd, A, K, Opts)} || A <- maps:get(arms, Opts)],
    maybe_arm_m(Fd, K, Opts, lists:keyfind(s, 1, Done)),
    ungradeable_check(Fd, K, C, Done).

arm_c_note(Fd, _K, _C, true) ->
    emit(Fd, "~narm C cleared the expressibility precondition. The arms run.~n");
arm_c_note(Fd, K, C, false) ->
    emit(Fd, "~narm C did NOT clear: W_0b=~.4f is below B=~.4f. The arms RUN ANYWAY.~n",
         [maps:get(w_0b, C), maps:get(b, K)]),
    emit(Fd, "Arm C is a DIAGNOSTIC, not a gate. A hand construction failing says "
             "something about the constructor; only evolution ALSO failing says "
             "anything about the encoding. See IF-1 below, decided after the arms.~n").

%% IF-1 now needs BOTH halves: the construction failed AND evolution never beat
%% its own random-genome null. Either alone is uninformative about the encoding.
ungradeable_check(_Fd, _K, _C, []) -> ok;
ungradeable_check(Fd, K, C, Done) ->
    CFailed = maps:get(w_0b, C) < maps:get(b, K),
    NoArm = lists:all(fun({_A, V}) -> V =:= failed end, Done),
    ungradeable_verdict(Fd, CFailed andalso NoArm, CFailed).

ungradeable_verdict(Fd, true, _CFailed) ->
    emit(Fd, "~nIF-1 UNGRADEABLE: the hand construction did not clear AND no evolution arm "
             "beat its random-genome null. Nothing, constructed or evolved, could use this "
             "encoding, which is the one reading that implicates the ENCODING rather than "
             "the constructor. Next move: the encoding.~n");
ungradeable_verdict(Fd, false, true) ->
    emit(Fd, "~nIF-1 quiet: the hand construction failed but evolution did not, so "
             "expressibility is established BY EVOLUTION and the encoding is not "
             "implicated. Arm C's failure is a note about the construction only.~n");
ungradeable_verdict(_Fd, false, false) -> ok.

%% Arm M runs ONLY if S does not clear. A negative from a single optimiser class
%% reproduces the confound this gate exists to remove; running M unconditionally
%% would double the spend to harden a claim that does not need hardening.
maybe_arm_m(Fd, _K, _Opts, {s, cleared}) ->
    emit(Fd, "~narm S CLEARED, so arm M is NOT run: CLEARED is an EXISTENCE claim and one "
             "optimiser class suffices.~n");
maybe_arm_m(Fd, K, Opts, {s, _Other}) ->
    emit(Fd, "~narm S did not clear, so arm M RUNS: FAILED is a UNIVERSAL claim and needs a "
             "second optimiser class.~n"),
    _ = arm_report(Fd, m, K, Opts),
    ok;
maybe_arm_m(_Fd, _K, _Opts, false) -> ok.

arm_report(Fd, Arm, K0, Opts) ->
    Layers = arm_layers(Arm),
    Held = heldout_starts(Opts),
    R = random_null(Layers, Held, maps:get(random_null, Opts)),
    Inert = inert_null(Arm, Layers, train_starts(Opts), maps:get(inert_null, Opts)),
    K = K0#{r => R},
    Rs = arm(Arm, Opts),
    V = verdict(Rs, K),
    emit(Fd, "~n-- ARM ~s (~s, ~p, dim ~p, ~p seeds) --~n",
         [string:uppercase(atom_to_list(Arm)), optimiser(Arm), Layers,
          robo_net:weight_count(Layers), length(Rs)]),
    emit(Fd, "R (best of ~p random genomes) = ~.4f ; IF-2 inert reference (best of ~p "
             "random TRAINING fitness) = ~.4f~n",
         [maps:get(random_null, Opts), R, maps:get(inert_null, Opts), Inert]),
    [emit(Fd, "seed ~p  W=~.4f L=~.4f D=~.4f  margin=~.2f caps=~.3f shots=~.2f pulls=~.2f "
              "trainW=~.4f fit=~.4f evals=~p distinct_last=~p clamp_gen=~.3f "
              "clamp_champ=~.3f id=~s~n",
          [X#res.seed, X#res.w, X#res.l, X#res.d, X#res.margin, X#res.caps,
           X#res.shots, X#res.pulls, X#res.train_w, X#res.fit, X#res.evals,
           X#res.distinct_last, X#res.clamp_last, X#res.clamp_frac,
           champion_id(champion(Arm, X#res.seed, Layers, X#res.q, X#res.fit, X#res.evals))])
     || X <- Rs],
    [emit(Fd, "seed ~p checkpoints (unique evals -> held-out W) = ~p~n",
          [X#res.seed, X#res.marks]) || X <- Rs],
    [emit(Fd, "seed ~p rung profile = ~p~n", [X#res.seed, X#res.profile]) || X <- Rs],
    emit(Fd, "median W_s=~.4f  median margin=~.2f  seeds at R_line=~p/~p  seeds directional=~p/~p~n",
         [median([X#res.w || X <- Rs]), median([X#res.margin || X <- Rs]),
          length([1 || X <- Rs, X#res.w >= maps:get(r_line, K)]), length(Rs),
          length([1 || X <- Rs, X#res.w - X#res.l >= maps:get(d_min, K)]), length(Rs)]),
    [emit(Fd, "  ~s ~s : ~p~n", [flag_mark(Fired), Code, Detail])
     || {Code, Fired, Detail} <- flags(Rs, K, Inert)],
    emit(Fd, "VERDICT arm ~p = ~s~n", [Arm, string:uppercase(atom_to_list(V))]),
    emit(Fd, "~s~n", [secondary(median([X#res.margin || X <- Rs]), V)]),
    champion_write(archive_path(Opts, Arm),
                   [champion(Arm, X#res.seed, Layers, X#res.q, X#res.fit, X#res.evals)
                    || X <- Rs]),
    V.

archive_path(Opts, Arm) ->
    maps:get(feed, Opts) ++ "." ++ atom_to_list(Arm) ++ ".champions".

optimiser(m) -> "mu_lambda_es";
optimiser(_Arm) -> "sep_cma_es".

flag_mark(true) -> "FIRED  ";
flag_mark(false) -> "quiet  ";
flag_mark(Other) -> io_lib:format("~p", [Other]).

%% THE SECONDARY ENDPOINT, with its reading pre-committed. robo_sim credits
%% damage_dealt on bullet hits ONLY, so this separates marksmanship from
%% attrition.
secondary(M, V) when V =:= failed orelse V =:= inconclusive ->
    censoring(M >= 25.0, M);
secondary(M, cleared) when M =< 0.0 ->
    io_lib:format("SECONDARY: the primary is CLEARED but median damage margin is ~.2f, "
                  "so the champion is winning by RAM OR WALL ATTRITION and that is named.", [M]);
secondary(M, _V) ->
    io_lib:format("SECONDARY: median held-out damage margin = ~.2f whole units.", [M]).

censoring(true, M) ->
    io_lib:format("SECONDARY: the champion OUT-DAMAGES the floor bot (median margin ~.2f) "
                  "but CANNOT CONVERT inside the 2000-turn cap. That is a different finding "
                  "from not reaching the floor.", [M]);
censoring(false, M) ->
    io_lib:format("SECONDARY: median held-out damage margin = ~.2f whole units; no "
                  "censoring reading is licensed.", [M]).

%%%============================================================================
%%% Small stats and the feed. The feed IS the record: all per-seed values, seeds,
%%% returned evaluation counts, per-checkpoint held-out rates, per-rung profiles
%%% and the full fingerprint go into it.
%%%============================================================================
mean([]) -> 0.0;
mean(L) -> lists:sum(L) / length(L).

variance([]) -> 0.0;
variance(L) ->
    M = mean([X * 1.0 || X <- L]),
    mean([(X - M) * (X - M) || X <- L]).

median([]) -> 0.0;
median(L) ->
    S = lists:sort(L),
    N = length(S),
    mid(S, N, N rem 2).

mid(S, N, 1) -> lists:nth(N div 2 + 1, S) * 1.0;
mid(S, N, 0) -> (lists:nth(N div 2, S) + lists:nth(N div 2 + 1, S)) / 2.0.

b(true) -> 1;
b(false) -> 0.

emit(Fd, F) -> emit(Fd, F, []).

emit(Fd, F, A) -> io:format(Fd, F, A), io:format(F, A).
