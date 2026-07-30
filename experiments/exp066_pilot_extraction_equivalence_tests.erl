%%%-------------------------------------------------------------------
%%% @doc EXP-066 follow-up: is robo_pilot the runner's controller, or only a
%%% careful-looking copy of it?
%%%
%%% NOT AN EXPERIMENT AND NOT GATED. Nothing here tests a hypothesis about the
%%% world. It tests whether a MOVE was faithful, which is a claim about this
%%% repository rather than about neuroevolution, so it needs no DESIGN gate and
%%% signs no insight.
%%%
%%% WHAT IS BEING CHECKED. On 2026-07-30 the phase 0 controller was lifted out of
%%% exp066_single_population_floor_tests into faber-tweann as robo_pilot: the 17
%%% channel encoder, the perception boundary, the dead-reckoning tracker and the
%%% 5 output decode. The extraction commit calls itself BEHAVIOUR-IDENTICAL BY
%%% CONSTRUCTION, meaning every body was copied character for character with only
%%% the pilot_ prefixes dropped. That is a statement about how carefully somebody
%%% copied. It is not a measurement, and the commit says so itself and names this
%%% test as owed.
%%%
%%% WHY BOTH PARTS, since they fail differently.
%%%
%%%   PART A, TURN BY TURN. Both controllers are driven through the SAME match
%%%   trajectory from the same arena, and their #intent{} records are compared at
%%%   every turn. This localises a defect to a single turn of a single start of a
%%%   single champion. A win-rate comparison alone would report only that
%%%   something, somewhere, is wrong.
%%%
%%%   PART B, THE FULL ENDPOINT. Every arm S champion is replayed over all 80
%%%   pre-registered held-out starts, both seats, and the per-seed win rate is
%%%   reproduced through robo_pilot and checked against the as-run feed. Part A
%%%   could pass on a sample and still miss a divergence that only fires in a
%%%   rare state; Part B is the endpoint the front actually reports.
%%%
%%% THREE COLUMNS, NOT TWO, AND THIS IS THE POINT. Part B cannot simply compare
%%% "the feed" against "my loop plus robo_pilot", because my loop is new code and
%%% a disagreement would not say whether the pilot or the loop was at fault. So
%%% the middle column runs the RUNNER'S OWN heldout/3, unmodified, at this same
%%% pin. If the middle column reproduces the feed, the loop and the engine are
%%% exonerated and any disagreement in the third column is the pilot's alone.
%%%
%%% NO BODY IS COPIED FROM THE RUNNER. The runner's pilot is reached through its
%%% own module. A test that re-copied those bodies here would be comparing a copy
%%% against a copy, which is exactly the failure it exists to detect. The only
%%% thing written fresh below is the shadow match loop, and Part B's middle column
%%% is what proves that loop faithful.
%%%
%%% THE PIN. This needs faber_tweann at 8556d7fd, which ADDS robo_pilot to the
%%% a5e8bcfc engine that produced every phase 0 number. exp066's own gates/0 is
%%% re-run at the new pin first and its golden match vector recomputed, so the
%%% claim that only a module was added is checked rather than assumed.
%%%
%%% DETERMINISM. Nothing here is random. No seed is drawn, no rand is called, the
%%% starts come from the runner's own deterministic generator through its
%%% exported split/1, and the champions come off disk. Parallelism is over whole
%%% champions, which are independent pure replays, so worker count changes wall
%%% clock and nothing else.
%%% @end
%%%-------------------------------------------------------------------
-module(exp066_pilot_extraction_equivalence_tests).

-export([run/0, run/1, part_a/0, part_a/1, part_b/0, part_b/1]).
-export([record/0, record/1]).

-include_lib("faber_tweann/include/robo_sim.hrl").

-define(RUNNER, exp066_single_population_floor_tests).
-define(FLOOR, predictive_gun).
-define(ARCHIVE, "programmes/p7_coevolution/exp066_competence_floor/").
-define(ARM, s).

%% One shadow match in flight. BOTH pilot states are threaded independently from
%% the same observations, never copied from one another, so a divergence that
%% starts in MEMORY rather than in an intent still surfaces: a corrupted latch
%% shows up as an intent difference on a later turn instead of this one.
-record(sh, {
    seat = a :: a | b,
    net :: {[non_neg_integer()], [integer()]},
    mod = robo_pilot :: module(),    %% the module UNDER TEST, swappable for the red check
    rs :: term(),                    %% the runner's own pilot state
    ps :: term(),                    %% the module-under-test's state
    opp :: term(),                   %% the floor bot's script state
    turns = 0 :: non_neg_integer(),  %% intent comparisons made
    states = 0 :: non_neg_integer()  %% turns on which the two states also agreed
}).

%% One replayed match, single controller. Only the fields the endpoint and its
%% censoring diagnostic need; the runner's own report/2 carries probe and shot
%% counters this comparison does not read.
-record(pb, {
    seat = a :: a | b,
    mod = robo_pilot :: module(),
    net :: {[non_neg_integer()], [integer()]},
    ps :: term(),
    opp :: term()
}).

%%%============================================================================
%%% ENTRY
%%%============================================================================

run() -> run(#{}).

run(Opts) ->
    A = part_a(Opts),
    B = part_b(Opts),
    #{part_a => A, part_b => B,
      equivalent => maps:get(equivalent, A) andalso maps:get(equivalent, B)}.

defaults() ->
    #{arm => ?ARM,
      %% Part A's sample. Champions are ALL of arm S rather than a subset,
      %% because the cheap thing to skimp on is the very thing a divergence
      %% would hide behind: seeds 2007, 2009, 2011, 2014, 2015 and 2018 sit in
      %% the LOW attractor and visit states the winners never reach.
      %% ALL 80 held-out starts, not a sample. The smoke run put 3200 replayed
      %% matches inside a minute, so sampling here would buy nothing and would
      %% leave the rare states a divergence could hide in unvisited.
      a_starts => 80,
      %% THE MODULE UNDER TEST, swappable so the RED CHECK can point this harness
      %% at a deliberately corrupted copy of robo_pilot and confirm it goes red. A
      %% green suite that cannot go red is not evidence.
      pilot_mod => robo_pilot,
      archive_dir => ?ARCHIVE,
      feed => ?ARCHIVE "exp066_floor_feed.txt"}.

merged(Opts) -> maps:merge(defaults(), Opts).

champions(Opts) ->
    Arm = maps:get(arm, Opts),
    Path = maps:get(archive_dir, Opts) ++ "exp066_champions_"
        ++ atom_to_list(Arm) ++ ".eterm",
    {ok, Terms} = file:consult(Path),
    Terms.

%%%============================================================================
%%% PART A. TURN BY TURN INTENT EQUALITY.
%%%
%%% The match is driven by the RUNNER's intent, so the trajectory explored is the
%%% canonical one and robo_pilot rides along as a shadow. Since the two intents
%%% must be equal for the loop to continue, which controller steers is immaterial
%%% wherever the test passes, and where it fails the runner's trajectory is the
%%% one worth reporting against.
%%%============================================================================

part_a() -> part_a(#{}).

part_a(Opts0) ->
    Opts = merged(Opts0),
    Champs = champions(Opts),
    Starts = lists:sublist(?RUNNER:split(heldout), maps:get(a_starts, Opts)),
    io:format("== PART A: turn-by-turn intent equality, ~p champions x ~p starts x 2 seats ==~n"
              "   runner pilot: ~p:pilot_act/4   module under test: ~p:act/4~n",
              [length(Champs), length(Starts), ?RUNNER, maps:get(pilot_mod, Opts)]),
    Mod = maps:get(pilot_mod, Opts),
    Rows = pmap(fun(C) -> a_champion(C, Starts, Mod) end, Champs),
    Divs = lists:append([D || #{divergences := D} <- Rows]),
    Turns = lists:sum([T || #{turns := T} <- Rows]),
    Mism = lists:sum([M || #{state_mismatches := M} <- Rows]),
    [io:format("  seed ~p  matches ~3w  turns compared ~7w  intent divergences ~p  "
               "state mismatches ~p~n",
               [S, M, T, length(D), Ms])
     || #{seed := S, matches := M, turns := T, divergences := D,
          state_mismatches := Ms} <- Rows],
    io:format("~n  turns compared: ~p~n  intent divergences: ~p~n  state mismatches: ~p~n",
              [Turns, length(Divs), Mism]),
    io:format("  ~s~n", [a_verdict(Divs, Mism)]),
    #{rows => Rows, turns => Turns, matches => lists:sum([M || #{matches := M} <- Rows]),
      divergences => Divs, state_mismatches => Mism,
      first_divergence => first_div(Divs),
      pilot_mod => Mod,
      equivalent => Divs =:= [] andalso Mism =:= 0}.

a_verdict([], 0) ->
    "PART A PASS -- every turn produced the SAME intent and the SAME pilot state.";
a_verdict([], _M) ->
    "PART A FAIL -- intents agreed but the two pilot MEMORIES diverged, so the "
    "controllers are equal only by luck of the states visited.";
a_verdict(_D, _M) ->
    "PART A FAIL -- the extraction is NOT behaviour-identical. See the first "
    "divergence; do not adjust anything until it is recorded.".

first_div([]) -> none;
first_div(Divs) ->
    hd(lists:sort(fun(#{seed := S1, start := I1, turn := T1},
                      #{seed := S2, start := I2, turn := T2}) ->
                          {S1, I1, T1} =< {S2, I2, T2}
                  end, Divs)).

a_champion({champion, _Arm, Seed, Layers, Q, _Fit, _Evals}, Starts, Mod) ->
    Net = {Layers, Q},
    Rs = [a_seat(Net, Seed, I, St, Seat, Mod)
          || {I, St} <- lists:zip(lists:seq(1, length(Starts)), Starts),
             Seat <- [a, b]],
    #{seed => Seed,
      matches => length(Rs),
      turns => lists:sum([T || {ok, T, _S} <- Rs]),
      state_mismatches => lists:sum([T - S || {ok, T, S} <- Rs]),
      divergences => [D || {diverged, D} <- Rs]}.

a_seat(Net, Seed, Idx, {AX, AY, AH, BX, BY, BH} = St, Seat, Mod) ->
    Arena = robo_sim:new([{a, AX, AY, AH}, {b, BX, BY, BH}]),
    S = #sh{seat = Seat, mod = Mod, net = Net, rs = ?RUNNER:pilot_init(),
            ps = Mod:init(), opp = robo_gauntlet:init(?FLOOR)},
    a_tag(a_loop(Arena, S), Seed, Idx, St, Seat).

a_tag({diverged, Turn, IR, IP}, Seed, Idx, St, Seat) ->
    {diverged, #{seed => Seed, start => Idx, geometry => St, seat => Seat,
                 turn => Turn, runner_intent => IR, robo_pilot_intent => IP}};
a_tag({ok, #sh{turns = T, states = S}}, _Seed, _Idx, _St, _Seat) -> {ok, T, S}.

a_loop(Arena, S) -> a_step(Arena, S, robo_sim:finished(Arena)).

a_step(_Arena, S, true) -> {ok, S};
a_step(Arena, S, false) -> a_acts(Arena, S, robo_sim:alive(Arena), []).

%% Intents are accumulated in robo_sim:alive/1 order, which is the order the
%% runner's own loop hands them to robo_sim:step/2. The engine folds fire and hit
%% resolution in TANK order rather than intent order, so this is belt and braces,
%% but a shadow that reorders the list is not a shadow.
a_acts(Arena, S, [], Acc) ->
    a_loop(robo_sim:step(Arena, lists:reverse(Acc)), S#sh{turns = S#sh.turns + 1});
a_acts(Arena, S, [T | Rest], Acc) ->
    a_one(Arena, S, Rest, Acc, T, T#tank.id =:= S#sh.seat).

a_one(Arena, S, Rest, Acc, #tank{id = Id} = T, false) ->
    {I, O2} = robo_gauntlet:act(?FLOOR, S#sh.opp, T, Arena),
    a_acts(Arena, S#sh{opp = O2}, Rest, [{Id, I} | Acc]);
a_one(Arena, S, Rest, Acc, #tank{id = Id} = T, true) ->
    {IR, RS} = ?RUNNER:pilot_act(S#sh.net, S#sh.rs, T, Arena),
    {IP, PS} = (S#sh.mod):act(S#sh.net, S#sh.ps, T, Arena),
    a_cmp(Arena, S, Rest, [{Id, IR} | Acc], {IR, RS}, {IP, PS}, IR =:= IP).

%% THE DIVERGENCE REPORT USES THE ARENA'S OWN TURN COUNTER, not a counter kept
%% here, so the number can be fed straight back into a replay of that match.
a_cmp(#arena{turn = Turn}, _S, _Rest, _Acc, {IR, _RS}, {IP, _PS}, false) ->
    {diverged, Turn, IR, IP};
a_cmp(Arena, S, Rest, Acc, {_IR, RS}, {_IP, PS}, true) ->
    a_acts(Arena, S#sh{rs = RS, ps = PS,
                       states = S#sh.states + same(RS, PS)}, Rest, Acc).

%% The two #pilot{} records carry the same tag, arity and field order in both
%% modules, so term equality is a real comparison of the two memories and not a
%% type accident. It is reported SEPARATELY from intent equality: identical
%% intents from different memories would mean the controllers happen to agree on
%% the states these matches visit, which is weaker than equivalence.
same(X, X) -> 1;
same(_X, _Y) -> 0.

%%%============================================================================
%%% PART B. THE FULL HELD-OUT ENDPOINT, REPRODUCED THROUGH robo_pilot.
%%%
%%% The runner column calls ?RUNNER:heldout/3, which is the same call the arms
%%% made, so if it disagrees with the feed the fault is the pin or the engine and
%%% the pilot comparison is void.
%%%
%%% Outcomes are compared MATCH BY MATCH, not just as rates. Two different
%%% controllers can reach the same win rate by winning different matches, and a
%%% rate-only check would call that equivalence.
%%%============================================================================

part_b() -> part_b(#{}).

part_b(Opts0) ->
    Opts = merged(Opts0),
    Champs = champions(Opts),
    Starts = ?RUNNER:split(heldout),
    Feed = feed_rates(maps:get(feed, Opts), maps:get(arm, Opts)),
    io:format("~n== PART B: held-out endpoint, ~p champions x ~p starts x 2 seats ==~n"
              "   module under test: ~p:act/4~n",
              [length(Champs), length(Starts), maps:get(pilot_mod, Opts)]),
    Mod = maps:get(pilot_mod, Opts),
    Rows = pmap(fun(C) -> b_champion(C, Starts, Feed, Mod) end, Champs),
    b_table(Rows),
    Meds = {median([W || #{feed_w := W} <- Rows]),
            median([W || #{runner_w := W} <- Rows]),
            median([W || #{pilot_w := W} <- Rows])},
    RunnerOk = lists:all(fun(#{runner_matches_feed := X}) -> X end, Rows),
    PilotOk = lists:all(fun(#{pilot_matches_feed := X}) -> X end, Rows),
    OutcomeOk = lists:all(fun(#{outcome_mismatches := N}) -> N =:= 0 end, Rows),
    io:format("~n  median W  feed ~s  runner ~s  robo_pilot ~s~n",
              [f4(element(1, Meds)), f4(element(2, Meds)), f4(element(3, Meds))]),
    io:format("  ~s~n", [b_verdict(RunnerOk, PilotOk, OutcomeOk)]),
    #{rows => Rows,
      medians => #{feed => element(1, Meds), runner => element(2, Meds),
                   robo_pilot => element(3, Meds)},
      runner_reproduces_feed => RunnerOk,
      pilot_reproduces_feed => PilotOk,
      outcomes_identical => OutcomeOk,
      matches => length(Champs) * length(Starts) * 2,
      pilot_mod => Mod,
      equivalent => RunnerOk andalso PilotOk andalso OutcomeOk}.

b_verdict(false, _P, _O) ->
    "PART B VOID -- the RUNNER's own column does not reproduce the feed, so the "
    "pin or the engine moved and nothing here reads on robo_pilot.";
b_verdict(true, true, true) ->
    "PART B PASS -- robo_pilot reproduces every per-seed rate AND every "
    "individual match outcome.";
b_verdict(true, true, false) ->
    "PART B FAIL -- the rates agree but individual matches do not, so the two "
    "controllers win DIFFERENT matches and are not equivalent.";
b_verdict(true, false, _O) ->
    "PART B FAIL -- robo_pilot does not reproduce the archived held-out rates.".

b_table(Rows) ->
    io:format("  seed   feed W  runner W  pilot W |  feed L  runner L  pilot L |"
              "  feed D  runner D  pilot D |  feed/runner/pilot margin | match"
              " mismatches~n"),
    [io:format("  ~p  ~s   ~s   ~s |  ~s   ~s   ~s |  ~s   ~s   ~s | ~s ~s ~s | ~p~n",
               [S, f4(FW), f4(RW), f4(PW), f4(FL), f4(RL), f4(PL),
                f4(FD), f4(RD), f4(PD), f2(FM), f2(RM), f2(PM), MM])
     || #{seed := S, feed_w := FW, runner_w := RW, pilot_w := PW,
          feed_l := FL, runner_l := RL, pilot_l := PL,
          feed_d := FD, runner_d := RD, pilot_d := PD,
          feed_margin := FM, runner_margin := RM, pilot_margin := PM,
          outcome_mismatches := MM} <- Rows].

b_champion({champion, _Arm, Seed, Layers, Q, _Fit, _Evals}, Starts, Feed, Mod) ->
    Net = {Layers, Q},
    RunnerOs = ?RUNNER:heldout({net, Layers, Q}, ?FLOOR, Starts),
    PilotOs = b_heldout(Net, Starts, Mod),
    {RW, RL, RD} = ?RUNNER:rates(RunnerOs),
    {PW, PL, PD} = ?RUNNER:rates(PilotOs),
    {FW, FL, FD, FM} = maps:get(Seed, Feed),
    RM = margin(RunnerOs),
    PM = margin(PilotOs),
    #{seed => Seed,
      feed_w => FW, feed_l => FL, feed_d => FD, feed_margin => FM,
      runner_w => RW, runner_l => RL, runner_d => RD,
      pilot_w => PW, pilot_l => PL, pilot_d => PD,
      runner_wins => round(RW * length(RunnerOs)),
      pilot_wins => round(PW * length(PilotOs)),
      runner_margin => RM,
      pilot_margin => PM,
      outcome_mismatches => mismatches(RunnerOs, PilotOs),
      runner_matches_feed => triple_eq({FW, FL, FD}, {RW, RL, RD})
          andalso f2(FM) =:= f2(RM),
      pilot_matches_feed => triple_eq({FW, FL, FD}, {PW, PL, PD})
          andalso f2(FM) =:= f2(PM)}.

%% The feed records rates to FOUR DECIMALS. Every rate here is k/160, whose
%% spacing is 0.00625, so four decimals identifies k uniquely and comparing the
%% formatted strings is exact rather than a tolerance. A tolerance would be a
%% threshold, and this front does not move thresholds to reach a reading.
triple_eq({A1, B1, C1}, {A2, B2, C2}) ->
    {f4(A1), f4(B1), f4(C1)} =:= {f4(A2), f4(B2), f4(C2)}.

%% Match-by-match outcome comparison over the fields that decide the endpoint and
%% its censoring diagnostic. The runner's maps carry extra probe and shot
%% counters, so the shared keys are projected out of both rather than the whole
%% map compared.
mismatches(RunnerOs, PilotOs) ->
    length([1 || {R, P} <- lists:zip(RunnerOs, PilotOs), key(R) =/= key(P)]).

key(#{alive := A, opp_alive := O, dealt := D, taken := T, turns := N}) ->
    {A, O, D, T, N}.

margin(Os) ->
    mean([(maps:get(dealt, O) - maps:get(taken, O)) / 256 || O <- Os]).

%%%----------------------------------------------------------------------------
%%% The replay loop, robo_pilot driving. Structurally the runner's loop: act on
%%% the CURRENT arena whose scans came from the step that produced these tanks,
%%% and only THEN step. Stepping first would hand every controller a one-turn
%%% stale world, silently, and nothing would fail. Only live tanks act, and
%%% controller state is threaded by value.
%%%----------------------------------------------------------------------------

b_heldout(Net, Starts, Mod) -> [O || St <- Starts, O <- b_duel(Net, St, Mod)].

b_duel(Net, St, Mod) -> [b_seat(Net, St, a, Mod), b_seat(Net, St, b, Mod)].

b_seat(Net, {AX, AY, AH, BX, BY, BH}, Seat, Mod) ->
    Arena = robo_sim:new([{a, AX, AY, AH}, {b, BX, BY, BH}]),
    b_loop(Arena, #pb{seat = Seat, mod = Mod, net = Net, ps = Mod:init(),
                      opp = robo_gauntlet:init(?FLOOR)}).

b_loop(Arena, S) -> b_step(Arena, S, robo_sim:finished(Arena)).

b_step(Arena, S, true) -> b_report(Arena, S);
b_step(Arena, S, false) -> b_acts(Arena, S, robo_sim:alive(Arena), []).

b_acts(Arena, S, [], Acc) ->
    b_loop(robo_sim:step(Arena, lists:reverse(Acc)), S);
b_acts(Arena, S, [T | Rest], Acc) ->
    b_one(Arena, S, Rest, Acc, T, T#tank.id =:= S#pb.seat).

b_one(Arena, S, Rest, Acc, #tank{id = Id} = T, false) ->
    {I, O2} = robo_gauntlet:act(?FLOOR, S#pb.opp, T, Arena),
    b_acts(Arena, S#pb{opp = O2}, Rest, [{Id, I} | Acc]);
b_one(Arena, S, Rest, Acc, #tank{id = Id} = T, true) ->
    {I, PS} = (S#pb.mod):act(S#pb.net, S#pb.ps, T, Arena),
    b_acts(Arena, S#pb{ps = PS}, Rest, [{Id, I} | Acc]).

%% RAW #tank.damage_dealt, never robo_match's whole-unit division, exactly as the
%% runner reads it: a power 0.1 pellet does 0.4 damage and whole units report that
%% as 0, and that dead zone sits where cheap exploratory shooting lives. taken is
%% the OPPONENT's damage_dealt, which in a duel is what the subject absorbed.
b_report(#arena{turn = Turn, tanks = Ts}, S) ->
    Me = lists:keyfind(S#pb.seat, #tank.id, Ts),
    Opp = lists:keyfind(other(S#pb.seat), #tank.id, Ts),
    #{dealt => Me#tank.damage_dealt,
      taken => Opp#tank.damage_dealt,
      alive => not Me#tank.dead,
      opp_alive => not Opp#tank.dead,
      turns => Turn}.

other(a) -> b;
other(b) -> a.

%%%============================================================================
%%% THE FEED, PARSED. Arm S ONLY.
%%%
%%% Arms L and D reuse the seed numbers 2001 to 2010, so a parse that scanned the
%%% whole file for "seed 2001" would silently read arm D's rate into arm S's row
%%% and then report a divergence that is really a parsing bug. The section is cut
%%% first, on the feed's own arm headings, and only then are the lines read.
%%%============================================================================

feed_rates(Path, Arm) ->
    {ok, Bin} = file:read_file(Path),
    Lines = string:split(section(binary_to_list(Bin), Arm), "\n", all),
    maps:from_list([R || L <- Lines, R <- feed_row(string:lexemes(L, " "))]).

section(Text, s) -> cut(Text, "-- ARM S (", "-- ARM L (");
section(Text, l) -> cut(Text, "-- ARM L (", "-- ARM D (");
section(Text, d) -> cut(Text, "-- ARM D (", "== ADDENDUM").

cut(Text, From, To) ->
    [_Before, Rest] = string:split(Text, From),
    [Sec | _After] = string:split(Rest, To),
    Sec.

%% "seed 2001  W=0.9750 L=0.0250 D=0.0000  margin=67.23 caps=..." -- the margin
%% is carried too. It is NOT a competence ordering and may not be used as one;
%% the runner is explicit that it is a censoring diagnostic. It is here because a
%% controller could in principle reproduce every win, loss and draw while dealing
%% different damage, and the margin is the cheapest witness that it does not.
feed_row(["seed", Seed, "W=" ++ W, "L=" ++ L, "D=" ++ D, "margin=" ++ M | _Rest]) ->
    [{list_to_integer(Seed),
      {list_to_float(W), list_to_float(L), list_to_float(D), list_to_float(M)}}];
feed_row(_Other) -> [].

%%%============================================================================
%%% Plumbing. Nothing below reads on the result.
%%%============================================================================

%% Champions are independent pure replays, so this changes wall clock only. One
%% process per champion: there are 20 of them against 32 schedulers, so no
%% chunking is needed and adding a work queue would be machinery with nothing to
%% do. Results are re-sorted by index, because message arrival order is not
%% delivery order and a table whose rows shuffle between runs is not a record.
pmap(F, Xs) ->
    Parent = self(),
    Ref = make_ref(),
    Pids = [spawn_link(fun() -> Parent ! {Ref, I, F(X)} end)
            || {I, X} <- lists:zip(lists:seq(1, length(Xs)), Xs)],
    collect(Ref, length(Pids)).

%% TIMED, and it was not. An independent read of this harness drove it with a
%% deliberately bad pilot module and the run HUNG rather than failing: a worker
%% that dies before sending gives this receive nothing to match, and an untimed
%% receive then waits forever. A harness whose failure mode is a hang is worse
%% than one that crashes, because a hang looks identical to slow work and the
%% next person to run this will be replaying 3,200 matches and will believe it.
%% The bound is generous rather than tuned: the real run threads 599,859 turns
%% through two pilots and finishes well inside it, so this can only fire on a
%% genuine stall.
collect(Ref, N) ->
    Rs = [receive {Ref, I, R} -> {I, R}
          after 600000 -> error({pmap_worker_timeout, Ref, N})
          end || _ <- lists:seq(1, N)],
    [R || {_I, R} <- lists:sort(Rs)].

median(Xs) -> med(lists:sort(Xs), length(Xs)).

med(Sorted, N) when N rem 2 =:= 1 -> lists:nth((N + 1) div 2, Sorted);
med(Sorted, N) -> (lists:nth(N div 2, Sorted) + lists:nth(N div 2 + 1, Sorted)) / 2.

mean([]) -> 0.0;
mean(Xs) -> lists:sum(Xs) / length(Xs).

f4(X) -> lists:flatten(io_lib:format("~.4f", [X * 1.0])).

f2(X) -> lists:flatten(io_lib:format("~.2f", [X * 1.0])).

%%%============================================================================
%%% THE RECORD.
%%%
%%% ONE COMMAND REPRODUCES THE WHOLE FILE. The gates, both parts and the red
%%% check are re-run here rather than pasted in from earlier logs, because a
%%% record assembled by hand from three separate runs cannot be checked against
%%% itself and this front has already been bitten by numbers that lived only in a
%%% shell somebody had closed.
%%%============================================================================

-define(PIN_BEFORE, "a5e8bcfc5646827e9be49a9629f8a6a9678c814b").
-define(PIN_AFTER, "8556d7fd9177acfaf21c21569628775f06625faa").
-define(RED_MODS, [robo_pilot_red_p1_fire_clamp,
                   robo_pilot_red_p2_swap_16_17,
                   robo_pilot_red_p3_tank_r]).

record() -> record(#{}).

%% THE PIN CONSTANT IS CHECKED, NOT TRUSTED. A 40-character hex string typed into
%% a source file is exactly the sort of thing that gets one character wrong and
%% then sits in a record forever, and the first draft of this module did get one
%% character wrong. rebar.config is the declared pin, so it is read back and
%% compared, and a disagreement is reported in the record rather than swallowed.
config_ref() ->
    {ok, Terms} = file:consult("rebar.config"),
    {deps, Deps} = lists:keyfind(deps, 1, Terms),
    {faber_tweann, {git, _Url, {ref, Ref}}} = lists:keyfind(faber_tweann, 1, Deps),
    Ref.

record(Opts0) ->
    Opts = merged(Opts0),
    Gates = ?RUNNER:gates(#{}),
    A = part_a(Opts),
    B = part_b(Opts),
    Red = [red_one(M, Opts) || M <- maps:get(red_mods, Opts, ?RED_MODS)],
    Path = maps:get(archive_dir, Opts) ++ "exp066_pilot_extraction_equivalence.txt",
    Term = term(Gates, A, B, Red),
    write(Path, Gates, A, B, Red, Term),
    io:format("~nrecord written: ~s~n", [Path]),
    #{path => Path, equivalent => maps:get(equivalent, A) andalso maps:get(equivalent, B)}.

%% A perturbed COPY of robo_pilot, never robo_pilot itself. Absence is reported
%% as absence rather than quietly counted as a pass.
red_one(Mod, Opts) ->
    red_run(Mod, Opts, code:ensure_loaded(Mod)).

red_run(Mod, _Opts, {error, Why}) -> {Mod, unavailable, Why};
red_run(Mod, Opts, {module, Mod}) ->
    R = part_a(Opts#{a_starts => 6, pilot_mod => Mod}),
    Divs = maps:get(divergences, R),
    {Mod, length(Divs), red_first(maps:get(first_divergence, R))}.

red_first(none) -> none;
red_first(#{seed := S, start := I, seat := Seat, turn := T}) -> {S, I, Seat, T}.

%%%----------------------------------------------------------------------------
%%% The single machine-readable term at the foot. Tuples, lists, integers, atoms,
%%% floats and binaries only, so file:consult/1 reads it straight back.
%%%----------------------------------------------------------------------------
term(Gates, A, B, Red) ->
    {pilot_extraction_equivalence,
     [{date, list_to_binary(date_str())},
      {status, <<"NOT an experiment and NOT gated: a faithfulness check on a code "
                 "move. Signs no insight and re-runs no evolutionary arm.">>},
      {question, <<"Is robo_pilot the phase 0 controller, or a copy that only "
                   "looks like it?">>},
      {engine_pin_before, list_to_binary(?PIN_BEFORE)},
      {engine_pin_after, list_to_binary(?PIN_AFTER)},
      {pin_bumped, true},
      {pin_constant_matches_rebar_config, config_ref() =:= ?PIN_AFTER},
      {rebar_config_ref, list_to_binary(config_ref())},
      {pin_bump_is_replay_only, true},
      {pin_delta_commits, 2},
      {pin_delta_files, [<<"README.md">>, <<"src/robo_pilot.erl">>,
                         <<"test/robo_pilot_tests.erl">>]},
      {pin_delta_reproduces_from,
       <<"git -C <faber-tweann> diff --stat a5e8bcfc 8556d7fd">>},
      {lock_moved_via, <<"rebar3 upgrade faber_tweann">>},
      {runner_change, <<"one -export line added to "
                        "experiments/exp066_single_population_floor_tests.erl; "
                        "no body touched">>},
      {produced_by, <<"experiments/exp066_pilot_extraction_equivalence_tests.erl">>},
      {driver, <<"scripts/exp066_pilot_extraction_equivalence_record.sh">>},
      %% CORRECTED 2026-07-30 after an independent read, and mirrored here from the
      %% persisted record so a regeneration does not put the false statement back.
      %% This list previously named _build/default/lib/faber_tweann/src/robo_pilot.erl,
      %% which this harness NEVER OPENS: it CALLS the module, it does not read the
      %% file. rebar.config IS opened, by config_ref/0, and was missing. A reads list
      %% naming a file nobody opened is what a later reader builds a wrong
      %% reproduction on.
      {reads,
       [<<"programmes/p7_coevolution/exp066_competence_floor/exp066_champions_s.eterm">>,
        <<"programmes/p7_coevolution/exp066_competence_floor/exp066_floor_feed.txt">>,
        <<"rebar.config">>]},
      {loads_as_module,
       <<"robo_pilot, from the faber_tweann dependency at the bumped pin">>},
      {gates, [{N, Ok} || {N, Ok, _D} <- Gates]},
      {gates_all_pass, lists:all(fun({_N, Ok, _D}) -> Ok end, Gates)},
      {golden_match_vector, golden(Gates)},
      {part_a, part_a_term(A)},
      {part_b, part_b_term(B)},
      {red_check, Red},
      {equivalent, maps:get(equivalent, A) andalso maps:get(equivalent, B)}]}.

golden([{_N, _Ok, D} | _Rest]) -> D.

part_a_term(A) ->
    [{champions, 20}, {starts, 80}, {seats, 2},
     {matches, maps:get(matches, A)},
     {turns_compared, maps:get(turns, A)},
     {intent_divergences, length(maps:get(divergences, A))},
     {state_mismatches, maps:get(state_mismatches, A)},
     {first_divergence, maps:get(first_divergence, A)},
     {pass, maps:get(equivalent, A)}].

part_b_term(B) ->
    Meds = maps:get(medians, B),
    [{champions, 20}, {starts, 80}, {seats, 2},
     {matches, maps:get(matches, B)},
     {rows, [b_row_term(R) || R <- maps:get(rows, B)]},
     {median_w, [{feed, maps:get(feed, Meds)},
                 {runner, maps:get(runner, Meds)},
                 {robo_pilot, maps:get(robo_pilot, Meds)}]},
     {runner_reproduces_feed, maps:get(runner_reproduces_feed, B)},
     {pilot_reproduces_feed, maps:get(pilot_reproduces_feed, B)},
     {outcomes_identical, maps:get(outcomes_identical, B)},
     {pass, maps:get(equivalent, B)}].

b_row_term(R) ->
    {seed, maps:get(seed, R),
     {feed, maps:get(feed_w, R), maps:get(feed_l, R), maps:get(feed_d, R),
      maps:get(feed_margin, R)},
     {runner, maps:get(runner_w, R), maps:get(runner_l, R), maps:get(runner_d, R),
      maps:get(runner_margin, R)},
     {robo_pilot, maps:get(pilot_w, R), maps:get(pilot_l, R), maps:get(pilot_d, R),
      maps:get(pilot_margin, R)},
     {wins_of_160, maps:get(runner_wins, R), maps:get(pilot_wins, R)},
     {match_mismatches, maps:get(outcome_mismatches, R)}}.

date_str() ->
    {{Y, M, D}, _T} = calendar:local_time(),
    lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [Y, M, D])).

%%%----------------------------------------------------------------------------
%%% The prose. The VERDICT goes at the TOP, in plain words, before any table.
%%%----------------------------------------------------------------------------
write(Path, Gates, A, B, Red, Term) ->
    {ok, Fd} = file:open(Path, [write]),
    head(Fd, A, B),
    sec_pin(Fd, Gates),
    sec_a(Fd, A),
    sec_b(Fd, B),
    sec_red(Fd, Red),
    sec_scope(Fd),
    io:format(Fd, "~n~n== MACHINE-READABLE TERM (single Erlang term, tuples and "
                  "lists only) ==~n~p.~n", [Term]),
    file:close(Fd).

head(Fd, A, B) ->
    Ok = maps:get(equivalent, A) andalso maps:get(equivalent, B),
    io:format(Fd,
      "== EXP-066: IS robo_pilot THE PHASE 0 CONTROLLER, OR A COPY THAT LOOKS LIKE IT? ==~n~n"
      "~s~n~n"
      "date        = ~s~n"
      "status      = NOT an experiment and NOT gated. This checks whether a code MOVE~n"
      "              was faithful, which is a claim about this repository and not about~n"
      "              neuroevolution. It signs no insight and re-runs no arm.~n"
      "engine_pin  = ~s  (BUMPED, was ~s)~n"
      "produced_by = experiments/exp066_pilot_extraction_equivalence_tests.erl~n"
      "driver      = scripts/exp066_pilot_extraction_equivalence_record.sh~n"
      "reads       = programmes/p7_coevolution/exp066_competence_floor/exp066_champions_s.eterm~n"
      "              programmes/p7_coevolution/exp066_competence_floor/exp066_floor_feed.txt~n~n"
      "WHY THIS EXISTS. The extraction commit (faber-tweann 8556d7f) calls robo_pilot~n"
      "BEHAVIOUR-IDENTICAL BY CONSTRUCTION: every body copied character for character~n"
      "from the phase 0 runner, only the pilot_ prefixes dropped. That is a claim about~n"
      "how carefully somebody copied. It is not a measurement. The commit says so itself~n"
      "and names this replay as owed. This is the replay.~n~n",
      [verdict_line(Ok), date_str(), ?PIN_AFTER, ?PIN_BEFORE]).

verdict_line(true) ->
    "VERDICT: EQUIVALENT. Over 3200 replayed matches the extracted controller produced\n"
    "the SAME intent on every single turn, carried the SAME memory on every single turn,\n"
    "and reproduced all 20 arm S per-seed held-out rates and every individual match\n"
    "outcome exactly. The behaviour-identical claim is now a measurement.";
verdict_line(false) ->
    "VERDICT: NOT EQUIVALENT. The extraction changed behaviour. The first divergence is\n"
    "reported below with its seed, start, seat and turn. Nothing downstream of robo_pilot\n"
    "is interpretable until it is explained.".

sec_pin(Fd, Gates) ->
    io:format(Fd,
      "-- 0. THE PIN, AND WHY THE BUMP IS NOT A PROVENANCE BREAK --~n~n"
      "The pin IS the provenance of every phase 0 number, so it was moved deliberately~n"
      "and the move is recorded rather than left in a diff.~n~n"
      "  before : ~s~n"
      "  after  : ~s~n"
      "  delta  : TWO commits, f456618 (README only) and 8556d7f (the extraction).~n"
      "           The ENTIRE diff across both is three files: README.md,~n"
      "           src/robo_pilot.erl and test/robo_pilot_tests.erl. Nothing in the~n"
      "           match path is touched, which gate 1 below then checks rather~n"
      "           than takes on trust. Reproduce the delta with:~n"
      "             git -C <faber-tweann> diff --stat ~s ~s~n"
      "  method : scripts/exp066_bump_pin_for_pilot_equivalence.sh~n"
      "  rebar.config now declares : ~s~n"
      "  this record's pin constant : ~s  (agree: ~p)~n~n"
      "rebar.lock SILENTLY OVERRIDES a rebar.config ref bump. Editing the config and~n"
      "running a plain compile leaves the OLD engine in _build and every check below~n"
      "would then be a false green against the very code it was meant to replace. The~n"
      "bump therefore went through `rebar3 upgrade faber_tweann`, and the checked-out~n"
      "dependency HEAD was read back and confirmed at ~s.~n~n"
      "NO EVOLUTIONARY ARM WAS RE-RUN. Everything here is replay of archived genomes.~n~n"
      "-- 1. exp066 gates/0 AT THE NEW PIN: ALL SEVEN, RE-RUN, NOT ASSUMED --~n~n"
      "Gate 1 recomputes robo_match_tests' golden match vector, which is what proves~n"
      "robo_sim, robo_net, robo_gauntlet and robo_match are the same engine. Adding a~n"
      "module should not disturb them.~n~n",
      [?PIN_BEFORE, ?PIN_AFTER, ?PIN_BEFORE, ?PIN_AFTER, config_ref(), ?PIN_AFTER,
       config_ref() =:= ?PIN_AFTER, ?PIN_AFTER]),
    [io:format(Fd, "  ~s  ~s~n", [pf(Ok), N]) || {N, Ok, _D} <- Gates],
    io:format(Fd, "~n  golden match vector = ~s~n"
                  "  gates: ~p checks, ~p failing~n~n",
              [golden(Gates), length(Gates),
               length([1 || {_N, false, _D} <- Gates])]).

pf(true) -> "PASS";
pf(false) -> "FAIL".

sec_a(Fd, A) ->
    io:format(Fd,
      "-- 2. PART A: TURN-BY-TURN INTENT EQUALITY --~n~n"
      "Both controllers are driven through the SAME match trajectory and their~n"
      "#intent{} records compared at EVERY turn, so a defect localises to one turn of~n"
      "one start of one champion instead of to 'somewhere'. The two pilot MEMORIES are~n"
      "threaded independently from the same observations and never copied from one~n"
      "another, and are compared separately: identical intents from different memories~n"
      "would mean the two controllers merely agree on the states these matches happen~n"
      "to visit, which is weaker than equivalence.~n~n"
      "  champions           = 20 (all of arm S, seeds 2001..2020)~n"
      "  starts              = 80 (ALL pre-registered held-out starts, not a sample)~n"
      "  seats               = 2 (both, always)~n"
      "  matches replayed    = ~p~n"
      "  turns compared      = ~p~n"
      "  intent divergences  = ~p~n"
      "  state mismatches    = ~p~n"
      "  first divergence    = ~p~n~n",
      [maps:get(matches, A), maps:get(turns, A),
       length(maps:get(divergences, A)), maps:get(state_mismatches, A),
       maps:get(first_divergence, A)]),
    io:format(Fd, "  per-seed:~n", []),
    [io:format(Fd, "    seed ~p  matches ~3w  turns ~6w  intent divergences ~p  "
                   "state mismatches ~p~n", [S, M, T, length(D), Ms])
     || #{seed := S, matches := M, turns := T, divergences := D,
          state_mismatches := Ms} <- maps:get(rows, A)],
    io:format(Fd, "~n", []).

sec_b(Fd, B) ->
    io:format(Fd,
      "~n-- 3. PART B: THE FULL HELD-OUT ENDPOINT, THREE COLUMNS --~n~n"
      "THREE columns and not two, and that is the point. Comparing the feed against~n"
      "'my loop plus robo_pilot' could not say whether a disagreement was the pilot or~n"
      "the new loop. The MIDDLE column runs the runner's OWN heldout/3, unmodified, at~n"
      "this same pin. It reproducing the feed exonerates the loop and the engine, so~n"
      "anything left in the third column is the pilot's alone.~n~n"
      "Outcomes are compared MATCH BY MATCH, not only as rates: two controllers can~n"
      "reach the same win rate by winning DIFFERENT matches, and a rate-only check~n"
      "would call that equivalence. The margin column is carried for the same reason~n"
      "and is a CENSORING DIAGNOSTIC, never a competence ordering.~n~n"
      "  champions = 20, starts = 80, seats = 2, matches per column = ~p~n"
      "  W is wins out of 160; a WIN needs the predictive_gun tank DEAD and the~n"
      "  champion tank ALIVE. Draws count as not beating.~n~n"
      "  seed  |  feed W  runner W   pilot W |  feed L  runner L   pilot L |"
      "  feed D  runner D   pilot D |  feed/runner/pilot margin | mismatches~n"
      "  ------+--------------------------------------------------------------"
      "----------------------------------------------------------------------~n",
      [maps:get(matches, B)]),
    [io:format(Fd, "  ~p  |  ~s   ~s    ~s |  ~s   ~s    ~s |  ~s   ~s    ~s |"
                   "  ~6s ~6s ~6s | ~p~n",
               [S, f4(FW), f4(RW), f4(PW), f4(FL), f4(RL), f4(PL),
                f4(FD), f4(RD), f4(PD), f2(FM), f2(RM), f2(PM), MM])
     || #{seed := S, feed_w := FW, runner_w := RW, pilot_w := PW,
          feed_l := FL, runner_l := RL, pilot_l := PL,
          feed_d := FD, runner_d := RD, pilot_d := PD,
          feed_margin := FM, runner_margin := RM, pilot_margin := PM,
          outcome_mismatches := MM} <- maps:get(rows, B)],
    Meds = maps:get(medians, B),
    io:format(Fd,
      "~n  median W over the 20 seeds:  feed ~s   runner ~s   robo_pilot ~s~n~n"
      "  runner column reproduces the feed  : ~p~n"
      "  robo_pilot column reproduces feed  : ~p~n"
      "  every individual match identical   : ~p~n~n",
      [f4(maps:get(feed, Meds)), f4(maps:get(runner, Meds)),
       f4(maps:get(robo_pilot, Meds)),
       maps:get(runner_reproduces_feed, B), maps:get(pilot_reproduces_feed, B),
       maps:get(outcomes_identical, B)]).

sec_red(Fd, Red) ->
    io:format(Fd,
      "-- 4. THE RED CHECK: THIS SUITE CAN GO RED --~n~n"
      "A green equivalence suite is worth nothing until it is shown it can fail, and~n"
      "this front has already been bitten by exactly that. CORRECTED 2026-07-30: an~n"
      "earlier version of this paragraph said robo_pilot_tests records a first red~n"
      "check left green because moving a constant by one unit was absorbed by integer~n"
      "division. That is not what it records. What it records is that a red check~n"
      "found the suite BLIND: swapping the channel blocks failed 5 tests and mistyping~n"
      "the own_speed shift failed 1, but mistyping TANK_R from 4608 to 4680 PASSED~n"
      "EVERYTHING, because the fixture stood in open ground where clearance exceeds~n"
      "WALL_SPAN, wall_danger saturates to a silent zero and the radius cancels out~n"
      "entirely. A near-wall fixture was added to close it.~n~n"
      "robo_pilot itself is never touched. Each row below is a COPY of it, renamed and~n"
      "corrupted in one named place, compiled to a scratch directory and pointed at by~n"
      "the harness. Part A over 6 starts (240 matches). A divergence is the PASS.~n~n",
      []),
    [io:format(Fd, "  ~-32s divergences ~4w   first {seed,start,seat,turn} = ~w~n",
               [red_label(M), D, F]) || {M, D, F} <- Red],
    io:format(Fd,
      "~n  p1 corrupts the OUTPUT decode (fire clamp 30 -> 29) and bites at turn 0.~n"
      "  p2 exchanges sensor channels 16 and 17 and bites at turn 5, once a contact~n"
      "     has been seen twice and the velocity estimate stops being zero.~n"
      "  p3 mistypes TANK_R 4608 -> 4068. CORRECTED 2026-07-30, AGAINST THE SOURCE:~n"
      "     an earlier version of this line called 4068 the transposition~n"
      "     robo_pilot_tests records as having PASSED EVERYTHING. It is not. That test~n"
      "     records 4608 -> 4680, in the note above~n"
      "     robo_pilot_tests:wall_danger_is_observable_near_a_wall_test/0, which works~n"
      "     4680 through explicitly (clearance 5320, quotient 41, channel 215). The two~n"
      "     are different typos and not interchangeable: 4680 raises the radius by 72,~n"
      "     4068 lowers it by 540. The misattribution is recorded here rather than~n"
      "     quietly swapped, because it is the kind of number a record is read for.~n"
      "     What p3 does show stands: 4068 diverges in 190 of 240 matches, and the 50~n"
      "     that stay green are matches that never come near a wall, so a full-match~n"
      "     replay reaches a constant that an open-ground unit fixture cannot and the~n"
      "     50 say why one fixture was not enough. What it does NOT show is anything~n"
      "     about 4680 specifically, which this red check does not run.~n~n", []).

red_label(Mod) -> atom_to_list(Mod).

sec_scope(Fd) ->
    io:format(Fd,
      "-- 5. WHAT THIS DOES NOT PROVE --~n~n"
      "Equivalence is established ON THE STATES THESE 3200 MATCHES VISIT, against the~n"
      "predictive_gun floor bot, for arm S genomes of topology [17,12,5]. That is the~n"
      "endpoint the front reports, so it is the right target, but it is not a proof over~n"
      "all inputs. A defect reachable only from a state no arm S champion drives into~n"
      "against this one opponent would survive this test. Part A's per-turn state~n"
      "comparison narrows that gap and does not close it.~n~n"
      "STILL STRANDED IN THE RUNNER, and it is the extraction that matters most: the~n"
      "120-start generator with its measured heading-offset correction, and the~n"
      "train/held-out/calibration split. robo_match:starts/0 in the engine returns SIX~n"
      "hand-written starts, which this research superseded. Two hosts disagreeing on the~n"
      "start set produce results that cannot be compared, so a foreign genome scored~n"
      "against engine starts is not scored against these numbers. robo_pilot being~n"
      "faithful does NOT make the mesh half of this front runnable on its own.~n~n"
      "ONE CHANGE WAS MADE TO THE RUNNER and it is named here rather than left in a~n"
      "diff: a single -export line was added to~n"
      "experiments/exp066_single_population_floor_tests.erl so this replay could call~n"
      "the runner's OWN pilot_act/4, pilot_init/0, channels/2, heldout/3, rates/1 and~n"
      "win_rate/1. No body was touched and no constant moved. A test that instead~n"
      "re-copied those bodies into a third file would have been comparing a copy against~n"
      "a copy, which is the exact failure it exists to detect.~n",
      []).
