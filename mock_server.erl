%%%-------------------------------------------------------------------
%%% @author krishnak <krishnak@inadmin-8.local>
%%% @copyright (C) 2019, krishnak
%%% @doc
%%% Mock TCP Server functionality
%%% @end
%%% Created : 26 Jan 2019 by krishnak <krishnak@inadmin-8.local>
%%%-------------------------------------------------------------------
-module(mock_server).

-behaviour(gen_server).

%% API
-export([start_link/0]).
-export([push_to_client/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).
-define(PORT,3031).

-record(state, {client_socket}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, Pid :: pid()} |
                      {error, Error :: {already_started, pid()}} |
                      {error, Error :: term()} |
                      ignore.
start_link() ->
    io:format("Server: Starting.. ~n",[]),
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
-spec init(Args :: term()) -> {ok, State :: term()} |
                              {ok, State :: term(), Timeout :: timeout()} |
                              {ok, State :: term(), hibernate} |
                              {stop, Reason :: term()} |
                              ignore.
init([]) ->
    process_flag(trap_exit, true),
    case gen_tcp:listen(?PORT, []) of
        {ok,LS} ->
            case gen_tcp:accept(LS) of
                {ok, S} ->
                    io:format("Server: Started with client ~p~n", [S]),
                    {ok, #state{client_socket = S}};
                {error, R} ->
                    io:format("Server: Could not accept connection from client ~p~n",[R]),
                    {stop, client_accept_error}
            end;
        {error, R} ->
            io:format("Server: Could not listen on port ~p for reason ~p~n",[?PORT,R]),
            {stop, client_listen_error}
    end.



%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
-spec handle_call(Request :: term(), From :: {pid(), term()}, State :: term()) ->
                         {reply, Reply :: term(), NewState :: term()} |
                         {reply, Reply :: term(), NewState :: term(), Timeout :: timeout()} |
                         {reply, Reply :: term(), NewState :: term(), hibernate} |
                         {noreply, NewState :: term()} |
                         {noreply, NewState :: term(), Timeout :: timeout()} |
                         {noreply, NewState :: term(), hibernate} |
                         {stop, Reason :: term(), Reply :: term(), NewState :: term()} |
                         {stop, Reason :: term(), NewState :: term()}.
handle_call({push, Data}, _From, State) ->
    case gen_tcp:send(State#state.client_socket, Data) of
        ok ->
            {reply, ok, State};
        {error, R} ->
            {reply, R, State}
    end;
handle_call(Request, _From, State) ->
    io:format("Server: Got message call ~p~n", [Request]),
    {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_cast(Request :: term(), State :: term()) ->
                         {noreply, NewState :: term()} |
                         {noreply, NewState :: term(), Timeout :: timeout()} |
                         {noreply, NewState :: term(), hibernate} |
                         {stop, Reason :: term(), NewState :: term()}.
handle_cast(Request, State) ->
    io:format("Server: Got message cast ~p~n", [Request]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info :: timeout() | term(), State :: term()) ->
                         {noreply, NewState :: term()} |
                         {noreply, NewState :: term(), Timeout :: timeout()} |
                         {noreply, NewState :: term(), hibernate} |
                         {stop, Reason :: normal | term(), NewState :: term()}.
handle_info(Info, State) ->
    io:format("Server: Got message info ~p~n", [Info]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
                State :: term()) -> any().
terminate(Reason, _State) ->
    io:format("Server: Terminating reason ~p~n", [Reason]),
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
                  State :: term(),
                  Extra :: term()) -> {ok, NewState :: term()} |
                                      {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
                    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================

push_to_client(D) ->
    case gen_server:call(?SERVER, {push, D}) of
        ok ->
            io:format("Server: Push to client success~n");
        Reason ->
            io:format("Server: Push to client failed, reason: ~p~n",[Reason])
    end.

