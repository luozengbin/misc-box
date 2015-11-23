#!/bin/bash

trap '/etc/init.d/oracle-xe stop' EXIT

/etc/init.d/oracle-xe start

while true
do
    sleep 1m
done
