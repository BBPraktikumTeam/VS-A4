#!/bin/bash
for i in *log; do echo ${i%.log}; cat $i | grep "Coll" | echo "coll" `wc -l`; cat $i | grep "ready to send" | echo "sent" `wc -l`; echo; done
