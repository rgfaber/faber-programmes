%%%-------------------------------------------------------------------
%%% @doc EXP-051 — <one-line title>
%%%
%%% Pre-registration: experiments/exp051_deceptive_maze_novelty.md
%%% Run: scripts/run_experiment.sh exp051_deceptive_maze_novelty_tests
%%%
%%% Archived after signing. This file is a permanent record of what was
%%% actually executed, not a maintained test.
%%% @end
%%%-------------------------------------------------------------------
-module(exp051_deceptive_maze_novelty_tests).

-include_lib("eunit/include/eunit.hrl").

%% eunit swallows io:format for PASSING tests. Write the feed to a file
%% (run_experiment.sh captures stdout too, but the file is the reliable copy).

deceptive_maze_novelty_test_() ->
    {timeout, 3600, fun run/0}.

run() ->
    ?assert(false).
