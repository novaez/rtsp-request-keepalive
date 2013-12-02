#!/bin/bash

host=${1:?"Missing host"}
interval=${2:-"60"}

echo "Usage: $0 host [interval]"

echo
echo "TIME | ALL | ESTABLISHED | TIME-WAIT | SYN_SENT"
echo "==============================================="

while ((1))
do
    connected=
    established=
    synsent=
    #printf -v line "$(date +%T) |\
    echo "$(date +%T)\
 | $(netstat -tpn 2>&1 | grep ${host} | wc -l)\
 | $(netstat -tpn 2>&1 | grep ${host} | grep "ESTABLISHED" | wc -l)\
 | $(netstat -tpn 2>&1 | grep ${host} | grep "TIME-WAIT" | wc -l)\
 | $(netstat -tpn 2>&1 | grep ${host} | grep "SYS_SENT" | wc -l)\
"
    sleep ${interval} 
done
