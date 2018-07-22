%%%-------------------------------------------------------------------
%%% @author Yqfclid 
%%% @copyright  Yqfclid (yqf@blackbird)
%%% @doc
%%%
%%% @end
%%% Created :  2018-07-16 16:51:34
%%%-------------------------------------------------------------------
-module(group_handler).

-behaviour(gen_server).

%% API
-export([]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-define(SERVER, ?MODULE).

-include("simple_chatroom.hrl").

-record(state, {id,
				owner,
				memebers,
				managers,
				forbided
				}).

%%%===================================================================
%%% API
%%%===================================================================
group_chat(GroupId, UId, Context) ->
	PName = chatroom_util:generate_pname(?MODULE, GroupId),
	gen_server:cast(PName, {group_chat, UId, Context}).

req_add_group(GroupId, UId) ->
	PName = chatroom_util:generate_pname(?MODULE, GroupId),
	gen_server:cast(PName, {req_add_group, UId}).	

start() ->
	case chatroom_util:mnesia_query(group, []) of
		{ok, Groups} ->
			lists:foreach(fun(Group) -> group_handler:start(Group) end, Groups);
		{error, Reason} ->
			lager:error("start group failed:~p", [Reason])
	end.

start(Group) ->
	#group{id = GroupId} = Group,
	PName = chatroom_util:generate_pname(?MODULE, GroupId),
    supervisor:start_child(group_handler_sup, [Group]).

stop(GroupId) ->
	PName = chatroom_util:generate_pname(?MODULE, GroupId),
	gen_server:cast(PName, stop).


%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the SERVER
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([Group]) ->

    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------

handle_call(_Request, _From, State) ->
    Reply = ok,
    lager:warning("Can't handle request: ~p", [_Request]),
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------

handle_cast({group_chat, UId, Context}, State) ->
	#state{memebers = Members, 
		   id = GroupId} = State,
	sets:foldl(
		fun(Member, _) ->
			message_router:send_message([GroupId, UId], Member, Context)
	end, ok, Members),
	{noreply, State};

% handle_cast({req_add_group, UId}, State) ->
% 	#state{managers = Managers} = State,
% 	sets:foldl(
% 		fun(Member, _) ->
% 			message_router:send_notify(?REQ_ADD_GROUP, [UId, Group, PushId])
% 	end, ok, Members),
% 	{noreply, State#state{}};

handle_cast(_Msg, State) ->
    lager:warning("Can't handle msg: ~p", [_Msg]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info({sync, Group}, State) ->
	#group{id = GroupId,
		   members = Members,
		   managers = Managers,
		   owner = Owner} = Group,
	{noreply, State#state{id = GroupId,
						  memebers = Members,
						  managers = Managers,
						  owner = Owner}};

handle_info(_Info, State) ->
    lager:warning("Can't handle info: ~p", [_Info]),
    {noreply, State}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================