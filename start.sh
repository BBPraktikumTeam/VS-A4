#!/bin/bash
# example usage: 10 10 "225.10.1.2" "192.168.17.12"
java datasource.DataSource 10 1 | erl -sname sender -setcookie hallo -noshell -s coordinator start $1 $2 $3 $4