
-module(receiver).
-compile(export_all).
-record(state,{socket,coordinator,lastFrame}).

init(Coordinator,Port)->
    {ok,Socket}=gen_udp:open(Port),
	CurrentFrame=get_current_frame(),
    loop(#state{socket=Socket,coordinator=Coordinator,lastFrame=CurrentFrame}).

loop(State=#state{socket=Socket,coordinator=Coordinator,lastFrame=LastFrame})->
    receive
	{udp, Socket, _IP, _InPortNo, Packet} -> 
		CurrentFrame=get_current_frame(),
		if CurrentFrameSec > LastFrame ->
				Coordinator ! reset_slot_wishes;
			true -> ok
		end,
	    Time=get_timestamp(),
	    Slot=get_slot_for_msec(Time),
	    Coordinator ! {received,Slot,Time,Packet},
		loop(State#state{lastFrame=CurrentFrame);
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

get_current_frame()->
	{_,CurrentFrame,_}=erlang:now(),
	CurrentFrame.
