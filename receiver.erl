-module(receiver).
-compile(export_all).
-record(state,{socket,coordinator,lastFrame}).

init(Coordinator,Socket)->
    
	CurrentFrame=utilities:get_current_frame(),
    loop(#state{socket=Socket,coordinator=Coordinator,lastFrame=CurrentFrame}).

loop(State=#state{socket=Socket,coordinator=Coordinator,lastFrame=LastFrame})->
    receive
	{udp, Socket, _IP, _InPortNo, Packet} -> 
		CurrentFrame=utilities:get_current_frame(),
	    Time=utilities:get_timestamp(),
	    Slot=utilities:get_slot_for_msec(Time),
	    Coordinator ! {received,Slot,Time,Packet},
		loop(State#state{lastFrame=CurrentFrame});
	kill -> 
	    io:format("Received kill command"),
	    gen_udp:close(Socket),
	    exit(normal);
	Any -> io:format("Received garbage: ~p~n",[Any])
    end.



