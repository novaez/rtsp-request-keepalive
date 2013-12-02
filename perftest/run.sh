#!/bin/bash

pnum=${1:-"10"}
killme=${2:-"7"}
host=${3:-"10.85.2.230:5544"}
logdir=${4:-"log"}
msginterval=${5:-"40"} # 25 messages/second
msgvariation=${6:-"4"}
ptfile=${7}

./netmonitor.sh ${host} > moni.log &
pidmoni=$!
trap "kill ${pidmoni}; exit 1" INT

./perftest.sh ${host} ${pnum} ${killme} ${logdir} ${msginterval} ${msgvariation} ${ptfile}

kill ${pidmoni}

./analyse.sh 1 SETUP ${logdir}

echo
cat moni.log
echo


