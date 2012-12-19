-module(receiver).
-compile(export_all).
-record(state,{socket,coordinator}).

init(Coordinator,Socket)->
	gen_udp:controlling_process(Socket, self()),
    loop(#state{socket=Socket,coordinator=Coordinator}).

loop(State=#state{socket=Socket,coordinator=Coordinator})->
    receive
	{udp, _ReceiveSocket, _IP, _InPortNo, Packet} -> 
	    Time=utilities:get_timestamp(),
	    Slot=utilities:get_slot_for_msec(Time),
	    Coordinator ! {received,Slot,Time,Packet},
		loop(State);
	kill -> 
	    io:format("Received kill command"),
	    gen_udp:close(Socket),
	    exit(normal);
	Any -> io:format("receiver: Received garbage: ~p~n",[Any]),
	    loop(State)
    end.



