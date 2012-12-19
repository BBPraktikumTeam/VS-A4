#!/bin/bash
ls -1 | grep [\.]pid |  while read pid_name
do
   host=${pid_name%.pid}
   ssh $USER@$host -o BatchMode=yes "cd $HOME/workspace/VS-A4/; kill `cat $host.pid`; rm $host.pid"
done
