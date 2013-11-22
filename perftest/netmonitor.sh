#!/bin/bash

host=${1:?"Missing host"}


echo "TIME | CONNECTED | ESTABLISHED"
echo "========================================="

while ((1))
do
    connected=$(netstat -tpn 2>&1 | grep ${host} | wc -l)
    established=$(netstat -tpn 2>&1 | grep ${host} | grep "ESTABLISHED" | wc -l)
    printf -v line "$(date +%T) | ${connected} | ${established}"
    echo ${line}
    sleep 60
done
