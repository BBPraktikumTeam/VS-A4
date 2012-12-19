-module(sender).
-compile(export_all).

-record(state,{dataqueue, socket, ip, port}).



init(Socket, Ip, Port) ->
	Dataqueue = spawn(fun()-> dataqueue:start() end),
	loop(#state{dataqueue = Dataqueue, socket = Socket, ip = Ip, port = Port}).

%% Koordinator nicht benutzt
%% Last Slot wird nicht gebraucht, da wir immer den neuen Slot vom Koordinator bekommen.
loop(State = #state{dataqueue = Dataqueue, socket = Socket, ip = Ip, port = Port}) ->
	receive
		{slot, NextSlot} ->
			io:format("sender: next slot: ~p~n",[NextSlot]),
			Dataqueue ! {get_data, self()},
			receive
				{input,{value, Input}} ->	
					wait_for_slot(NextSlot),
					Packet = create_packet(Input, NextSlot),
					io:format("sender: packet ready to send: ~p~n",[Packet]),
					gen_udp:send(Socket,Ip,Port,Packet),
					loop(State);
				{input, empty} ->
					loop(State)
			end
	end.
					
					
					
					
create_packet(Input,NextSlot) ->
	Timestamp=utilities:get_timestamp(),
	<< (list_to_binary(Input))/binary, NextSlot, Timestamp:64/integer>>.

	
wait_for_slot(Slot)->
	NextSlotTime = Slot*50 +25,
	CurrentTimeInMs = utilities:get_timestamp() div 1000,
	TimeToWait = NextSlotTime - (CurrentTimeInMs rem 1000),
	io:format("sender: next slot time: ~p~n",[NextSlotTime]),
	io:format("sender: current time in ms: ~p~n",[CurrentTimeInMs]),
	io:format("sender: time to wait: ~p~n",[TimeToWait]),
	timer:sleep(TimeToWait).
%	timer:sleep(Slot*50 +25 -((utilities:get_timestamp() div 1000) rem 1000)).
