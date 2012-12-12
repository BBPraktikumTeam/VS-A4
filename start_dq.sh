#!/bin/bash
java datasource.DataSource 10 1 | erl -name sender -setcookie hallo -noshell -s dataqueue start 