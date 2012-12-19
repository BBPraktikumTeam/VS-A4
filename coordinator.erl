-module(coordinator).
-compile(export_all).
-record(state,{teamNo,stationNo,socket,currentSlot,receiver,sender,slotWishes, usedSlots, ownPacketCollided}).

start([TeamNo,StationNo,MulticastIp,LocalIp])->
    {ok,MulticastIpTuple}=inet_parse:address(atom_to_list(MulticastIp)),
    {ok,LocalIpTuple}=inet_parse:address(atom_to_list(LocalIp)),
    init(list_to_integer(atom_to_list(TeamNo)),list_to_integer(atom_to_list(StationNo)),MulticastIpTuple,LocalIpTuple).

init(TeamNo,StationNo,MulticastIp,LocalIp)->
    Port=TeamNo+15000,
	{ok,Socket}=gen_udp:open(Port, [binary, {ip, LocalIp}, {add_membership, {MulticastIp, LocalIp}}]),
    io:format("Socket running on: ~p~n",[Port]),
    Coordinator=self(),
    Receiver=spawn(fun()->receiver:init(Coordinator,Socket) end),
    Sender=spawn(fun()->sender:init(Coordinator,Socket,MulticastIp) end),
	timer:sleep(1000 - (utilities:get_timestamp() rem 1000)), %% wait for first slot / first full second
	timer:send_after(1000,self(),reset_slot_wishes), %% set the first timer that calls to reset the slot wishes dict every second
    loop(#state{teamNo=TeamNo,stationNo=StationNo,socket=Socket,currentSlot=(random:uniform(20)-1),receiver=Receiver,sender=Sender,slotWishes=dict:new(), usedSlots = [], ownPacketCollided = false}).

loop(State=#state{slotWishes = SlotWishes, currentSlot = CurrentSlot, stationNo = StationNo, sender = Sender,receiver=Receiver, usedSlots = UsedSlots, ownPacketCollided = OwnPacketCollided})->
    receive
		reset_slot_wishes ->
			timer:send_after(1000,self(),reset_slot_wishes), %% reset slot wishes every second/frame
			if
				OwnPacketCollided ->
					Slot = calculate_slot_from_slotwishes(SlotWishes);
				true ->
					Slot = CurrentSlot
			end,
			Sender ! {slot, Slot},
			loop(State#state{slotWishes=dict:new(), usedSlots = [], ownPacketCollided = false, currentSlot = Slot});
		{received,Slot,Time,Packet} ->
			IsCollision = lists:member(Slot, UsedSlots),
			if
				IsCollision ->
					io:format("Collision detected in Slot ~p~n",[Slot]),
					SlotWishesNew = update_slot_wishes(Packet, SlotWishes),
					CollidedStations = dict:fetch(Slot, SlotWishesNew),
					OwnStationInvolved = lists:member(StationNo, CollidedStations),
					if
						OwnStationInvolved ->		
							loop(State#state{slotWishes=SlotWishesNew, ownPacketCollided = true});
						true ->
							loop(State#state{slotWishes=SlotWishesNew})
					end;
				true ->
					SlotWishesNew=update_slot_wishes(Packet,SlotWishes),
					UsedSlotsNew = lists:append([Slot], UsedSlots),
					loop(State#state{slotWishes=SlotWishesNew, usedSlots=UsedSlotsNew})
			end;
		kill -> 
			io:format("Received kill command"),
			Receiver ! kill,
			Sender ! kill,
			exit(normal);
		Any -> io:format("Received garbage: ~p~n",[Any]),
			loop(State#state{})
    end.

update_slot_wishes(Packet,SlotWishes)->
    {Station,Slot,_,_} = utilities:match_message(Packet),
	%% Appends the Clients to each SlotWish, so we can choose free slots afterwards
    dict:append(Slot,Station,SlotWishes).
    
    


			   
calculate_slot_from_slotwishes(SlotWishes) ->
	ValidSlotWishes = dict:filter(fun(_,V) -> (length(V) == 1) end, SlotWishes),		%%remove collisions
	FreeSlots = lists:subtract(lists:seq(0,19), dict:fetch_keys(ValidSlotWishes)),
	lists:nth(random:uniform(length(FreeSlots)), FreeSlots).
