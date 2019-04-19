-module(server).
-export([start/1,stop/1]).

%% Start TCP server on the given port
%% Returns an obscure object to pass later to stop/1
start( Port ) ->
    Pid_hub = spawn( fun () -> hub([], []) end ),
    case gen_tcp:listen( Port, [ {active, false} ] ) of
        {ok, ListenSocket} ->
            spawn( fun () -> acceptor( Pid_hub, ListenSocket ) end ),
            {ListenSocket , Pid_hub};
        {error, Reason} ->  %% usually eaddrinuse
            {error, Reason}
    end.

%% Using result of start/1 (if successful) stop accepting
%% new connections, kickof existing connections, stop
%% all processes
stop( {ListenSocket, Pid_hub} ) ->
    gen_tcp:close( ListenSocket ),
    Pid_hub ! {stop},               %% Hub will notify existing connections
    true.

%% Broascast the message from a perticipant to the others
%% Participants is list of tuple with socket and name
broadcast( SenderSocket, Message, Participants ) ->
    io:format( "Sending ~p~n", [Message] ),
    [ gen_tcp:send( Socket, Message )  %% send message
      || {Socket, _} <- Participants,  %% on each participant's socket
	  Socket =/= SenderSocket ].       %% except the sender's one

%% Resend chat history to the given socket
%% History is a list of messages
replay( Socket, History ) ->
    gen_tcp:send( Socket, "--[History]---\r\n" ),
    [ gen_tcp:send( Socket, Message )
      || Message <- History ],
    gen_tcp:send( Socket, "--------------\r\n" ).

%% Close all participants connections
kickof( Participants ) ->
    [ gen_tcp:close( Socket )
        || {Socket, _} <- Participants ].

%% Handle inter-participant communication
%% Participants is list of tuple with socket and name
%% History is a list of messages
hub( Participants, History ) ->
    receive
        %% new user logged in
        {Socket, enter, Name} ->
            Text = [ "NEW COMER: ", Name ],
            broadcast( Socket, Text, Participants),                 %% send message to other participants
            replay( Socket, History),                               %% and history to the new comer
            hub( [ {Socket, string:trim(Name)} | Participants ],    %% add participant
                 History ++ [Text] );                               %% add message to history
        %% user enters a message
        {Socket, message, Message} ->
            {_, Name} = lists:keyfind(Socket, 1, Participants),     %% participant name lookup
            Text = [ Name, ": ", Message ],
            broadcast( Socket, Text, Participants ),
            hub( Participants, History ++ [Text] );                 %% add message to history
        %% user leaves the chat
        {Socket, leave} ->
            {_, Name} = lists:keyfind( Socket, 1, Participants ),
            Text = [ "LEAVING: ", Name, "\r\n" ],
            broadcast( Socket, Text, Participants ),
            hub( lists:keydelete( Socket, 1, Participants ),        %% remove participant
                 History ++ [Text] );
        %% shutdown
        {stop} ->
            kickof( Participants )
    end.

%% Accept a new connection, launch a process to accept new ones
%% and handle the incoming connection. Start by asking the name
%% (initial step).
acceptor( Pid_hub, ListenSocket ) ->
    case gen_tcp:accept( ListenSocket ) of
        %% new incoming connection
        {ok, Socket} ->
            spawn( fun () -> acceptor( Pid_hub, ListenSocket ) end ),
            gen_tcp:send( Socket, "\r\n--------------\r\n"                ++
                                  "At any time enter 'quit' to leave\r\n" ++
                                  "Enter your name?\r\n" ),
            handle( Pid_hub, Socket, initial );
        %% server shutdown
        {error,closed} ->
            gen_tcp:close( ListenSocket ),
            false
    end.

%% Process accepting new connections
handle( Pid_hub, Socket, Occurence ) ->
    inet:setopts( Socket, [{active, once}] ),
    %%
    receive
        %% user enters 'quit' (or something starting with 'quit')
        {tcp, Socket, "quit" ++ _} ->
            Pid_hub ! {Socket, leave},
            gen_tcp:close( Socket );
        %% user enters a regular message
        {tcp, Socket, Msg} ->
            case Occurence of
                initial    -> Pid_hub ! {Socket, enter,   Msg};
                noninitial -> Pid_hub ! {Socket, message, Msg}
            end,
            handle(Pid_hub, Socket, noninitial);
        %% user closes TCP connection (or died)
        {tcp_closed, Socket} ->
            Pid_hub ! {Socket, leave},
            gen_tcp:close( Socket )
    end.
