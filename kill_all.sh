#!/bin/bash
USERNAME=$1
shift
for host in "$@"
do
    ssh $USERNAME@$host "cd /home/stud6/$USERNAME/workspace/VS-A4/; kill `cat $host.pid`; rm $host.pid"
done