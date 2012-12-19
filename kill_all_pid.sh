#!/bin/bash
for pid_name in `ls -1 | grep [\.]pid`
do
   host=${pid_name%.pid}
   echo "Killing: " $host
   ssh $USER@$host -o BatchMode=yes "cd $HOME/workspace/VS-A4/; kill `cat $host.pid`; rm $host.pid"
done
