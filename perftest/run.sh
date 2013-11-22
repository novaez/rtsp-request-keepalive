#!/bin/bash

pnum=${1:-"10"}
killme=${2:-"7"}
host=${3:-"10.85.2.230:5544"}
logdir=${4:-"log"}

./netmonitor.sh ${host} > moni &
pidmoni=$!
trap "kill ${pidmoni}; exit 1" INT

./perftest.sh ${host} ${pnum} ${killme} ${logdir} | tee out

kill ${pidmoni}

sleep 0.5

echo
echo "SETUP"
echo "------------------------------------------------"
echo "Sent                :   $(ls log | wc -l)"
echo "Response Received   :   $(cat log/* | grep -c 'CSeq: 1\.\.')"
echo "OK                  :   $(cat log/* | grep -B 1 'CSeq: 1\.\.' | grep -c '200 OK')"
echo "Failed              :   $(cat log/* | grep -B 1 'CSeq: 1\.\.' | grep -v 'CSeq: 1\.\.' | grep -v '\-\-' | grep -nc -v '200 OK')"
echo

wait
