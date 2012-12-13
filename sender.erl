-module(sender).
-compile(export_all).

-record(state,{dataqueue, socket, ip, lastSlot}).



init(Coordinator, Socket, Ip) ->
	Dataqueue = spawn(fun()-> dataqueue:start() end),
	loop(#state{dataqueue = Dataqueue, socket = Socket, ip = Ip}).
	

loop(State = #state{dataqueue = Dataqueue, socket = Socket, ip = Ip, lastSlot = LastSlot}) ->
	receive
		{slot, NextSlot} ->
			Dataqueue ! {get_data, self()},
			receive
				{input,Input} ->	
					wait_for_slot(LastSlot),
					Packet = create_packet(Input, NextSlot),
					gen_udp:send(Socket,Ip,Packet),
					loop(State#state{lastSlot=NextSlot})
			end
	end.
					
					
					
					
create_packet(Input,NextSlot) ->
	Timestamp=utilities:get_timestamp(),
	<< (list_to_binary(Input))/binary, NextSlot, Timestamp:64/integer>>.

	
wait_for_slot(Slot)->
	timer:sleep(Slot*50 +25 -(utilities:get_timestamp() rem 1000)).