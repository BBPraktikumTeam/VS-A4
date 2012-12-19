-module(dataqueue).
-compile(export_all).
-record(state,{queue}).

start()->
	Self=self(),
	%% register only for testing!
	register(dataqueue,Self),
	spawn(fun()->read(Self) end),
	loop(#state{queue=queue:new()}).

read(Pid)->
	Input=io:get_chars("",24),
	%% io:format("~p: ~s~n",[N,Input]),
	Pid ! {input,Input},
	read(Pid).

loop(State=#state{queue=Queue})->
	receive
		{input,Input} -> 
			QueueLen = queue:len(Queue),
			if (QueueLen >= 100) ->
			    {Out,Q} = queue:out(Queue),
				 io:format("dataqueue: Dropping item, so that queue doesnt get too big: ~p~n",[Out]),
				NewQueue = queue:in(Input,Q);
			true -> 
				  io:format("dataqueue: add new data: ~p~n",[Input]),
			      NewQueue=queue:in(Input,Queue)
			end,
			 loop(State#state{queue=NewQueue}) ;
		{get_data,Pid} -> 
			 {Item,NewQueue}=queue:out(Queue),
			 io:format("dataqueue: fetch item: ~p~n",[Item]),
			 Pid ! {input,Item},
			 loop(State#state{queue=NewQueue})
	end.

	
