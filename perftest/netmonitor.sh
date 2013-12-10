#!/bin/bash

host=${1:?"Missing host"}
interval=${2:-"60"}

echo "Usage: $0 host [interval]"

echo
echo "TIME | ALL | ESTABLISHED | TIME-WAIT | SYN_SENT | FIN-WAIT-1 | FIN-WAIT-2 | CLOSE-WAIT | CLOSING | LAST-ACK | CLOSED"
echo "===================================================================================================================="

while ((1))
do
    netstatus=$(netstat -tpn 2>&1 | grep ${host})
    echo "$(date +%T)\
 | $(echo "${netstatus}" | wc -l)\
 | $(echo "${netstatus}" | grep "ESTABLISHED" | wc -l)\
 | $(echo "${netstatus}" | grep "TIME-WAIT" | wc -l)\
 | $(echo "${netstatus}" | grep "SYS_SENT" | wc -l)\
 | $(echo "${netstatus}" | grep "FIN-WAIT-1" | wc -l)\
 | $(echo "${netstatus}" | grep "FIN-WAIT-2" | wc -l)\
 | $(echo "${netstatus}" | grep "CLOSE-WAIT" | wc -l)\
 | $(echo "${netstatus}" | grep "CLOSING" | wc -l)\
 | $(echo "${netstatus}" | grep "LAST-ACK" | wc -l)\
 | $(echo "${netstatus}" | grep "CLOSED" | wc -l)\
"
    sleep ${interval} 
done
