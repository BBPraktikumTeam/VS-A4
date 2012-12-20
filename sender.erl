-module(sender).
-compile(export_all).

-record(state,{dataqueue, socket, ip, port, coordinator}).



init(Socket, Ip, Port, Coordinator) ->
	Dataqueue = spawn(fun()-> dataqueue:start() end),
	loop(#state{dataqueue = Dataqueue, socket = Socket, ip = Ip, port = Port, coordinator = Coordinator}).

%% Koordinator nicht benutzt
%% Last Slot wird nicht gebraucht, da wir immer den neuen Slot vom Koordinator bekommen.
loop(State = #state{dataqueue = Dataqueue, socket = Socket, ip = Ip, port = Port, coordinator = Coordinator}) ->
	receive
		{slot, NextSlot} ->
			io:format("sender: next slot: ~p~n",[NextSlot]),
			Dataqueue ! {get_data, self()},
			receive
				{input,{value, Input}} ->	
					wait_for_slot(NextSlot),
					io:format("sender: sending to coordinator~n"),
					Coordinator ! {validate_slot, NextSlot},
					receive
						slot_ok ->
							io:format("sender: slot is valid~n"),
							Packet = create_packet(Input, NextSlot);
						{new_slot, Slot} ->
							io:format("sender: slot was invalid, new slot: ~p~n", [Slot]),
							Packet = create_packet(Input, Slot)
					end,
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
	NextSlotTime = Slot*50 +10,
	CurrentTimeInMs = utilities:get_timestamp(),
	io:format("sender: next slot time: ~p~n",[NextSlotTime]),
	io:format("sender: current time in ms: ~p~n",[CurrentTimeInMs]),
	case NextSlotTime - (CurrentTimeInMs rem 1000) of
		TimeToWait when TimeToWait > 0 -> 
			io:format("sender: time to wait: ~p~n",[TimeToWait]),
			timer:sleep(TimeToWait);
		_TimeToWait -> 
			io:format("sender: no time to wait~n"),
			ok
	end.
%	timer:sleep(Slot*50 +25 -((utilities:get_timestamp() div 1000) rem 1000)).
