%% -------------------------------------------------------------------
%%
%% Copyright (c) 2011 Basho Technologies, Inc.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @doc Simple pass-thru fitting.  Just passes its input directly to
%%      its output.  This fitting should work with any
%%      partition-choice function.  It ignores its argument, and
%%      requires no archiving for handoff.
-module(riak_pipe_w_pass).
-behaviour(riak_pipe_vnode_worker).

-export([init/2,
         process/2,
         done/1]).

-include("riak_pipe.hrl").
-include("riak_pipe_log.hrl").

-record(state, {p :: riak_pipe_vnode:partition(),
                fd :: #fitting_details{}}).

%% @doc Initialization just stows the partition and fitting details in
%%      the module's state, for sending outputs in {@link process/2}.
-spec init(riak_pipe_vnode:partition(), #fitting_details{}) ->
        {ok, #state{}}.
init(Partition, FittingDetails) ->
    {ok, #state{p=Partition, fd=FittingDetails}}.

%% @doc Process just sends `Input' directly to the next fitting.  This
%%      function also generates two trace messages: `{processing,
%%      Input}' before sending the output, and `{processed, Input}' after
%%      the blocking output send has returned.  This can be useful for
%%      dropping in another pipeline to watching data move through it.
-spec process(term(), #state{}) -> {ok, #state{}}.
process(Input, #state{p=Partition, fd=FittingDetails}=State) ->
    ?T(FittingDetails, [], {processing, Input}),
    riak_pipe_vnode_worker:send_output(Input, Partition, FittingDetails),
    ?T(FittingDetails, [], {processed, Input}),
    {ok, State}.

%% @doc Unused.
-spec done(#state{}) -> ok.
done(_State) ->
    ok.
