#!/bin/bash
for host in "$@"
do
    ssh $USER@$host -o BatchMode=yes "cd $HOME/workspace/VS-A4/; kill `cat $host.pid`; rm $host.pid; killall java"
done