
-module(receiver).
-compile(export_all).
-record(state,{socket,coordinator}).

init(Coordinator,Port)->
    {ok,Socket}=gen_udp:open(Port),
    loop(#state{socket=Socket,coordinator=Coordinator}).

loop(#state{socket=Socket,coordinator=Coordinator})->
    receive
	{udp, Socket, _IP, _InPortNo, Packet} -> 
	    Time=get_timestamp(),
	    Slot=get_slot_for_msec(Time),
	    Coordinator ! {Slot,Time,Packet};
	kill -> 
	    io:format("Received kill command"),
	    gen_udp:close(Socket),
	    exit(normal);
	Any -> io:format("Received garbage: ~p~n",[Any])
    end.


    % gets a timestamp in ms from the epoch
get_timestamp() ->
    {Mega,Sec,Micro} = erlang:now(),
    (Mega*1000000+Sec)*1000000+Micro.

get_slot_for_msec(Time)->
    erlang:trunc(((Time rem 1000)/50)).
