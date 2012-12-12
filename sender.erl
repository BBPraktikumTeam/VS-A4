-module(sender).
-compile(export_all).

-record(state,{dataqueue, socket, ip, lastSlot}).



init(Coordinator, Socket, Ip) ->
	Dataqueue = spawn(fun()-> dataqueue:start() end).
	loop(#state{dataqueue = Dataqueue, socket = Socket, ip = Ip})
	

loop(State = #state{dataqueue = Dataqueue, socket = Socket, ip = Ip, lastSlot = LastSlot} ->
	receive
	%% Sending after 
		{slot, Slot} -> 
			Dataqueue ! {get_data, self()}
			receive
				{input,Input} ->	
					Packet = create_packet(Input, NextSlot)
					gen_udp:send(Socket,Ip,<<Input,integer_to_list(Slot),utilities:get_timestamp()>>)
					
					
					
					
create_packet(Input,NextSlot) ->
	
