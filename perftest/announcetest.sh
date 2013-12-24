#! /bin/bash

clientip=${1:-"10.85.2.229"}
srmip=${2:-"$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')"}
srmport="5544"
srmip="${srmip}:${srmport}"
logdir=${3:-"logs"}
clientdir=${4:-"/soft/rtsp-request-keepalive/perftest"}

echo "SRM: ${srmip}"
echo "Client: ${clientip}"
echo "Log Directory: ${logdir}"

# SRM & ERM log
rm -rf ${logdir}
mkdir -p ${logdir}

# Client log
ssh -t root@${clientip} -- rm -rf ${clientdir}/${logdir}
ssh -t root@${clientip} -- mkdir -p ${clientdir}/${logdir}

getermrunpid(){
    ps aux | grep ermrun.sh | grep -v grep | awk '{print $2}'
}

waitermrun(){
    ermrunpid=$(getermrunpid)
    if [[ -n $ermrunpid ]]
    then
        echo "Waiting for ermrun.sh(${ermrunpid})..."
        wait ${ermrunpid}
    fi
}

run(){
    __caseno=$1
    __threshold=$2
    __start=$3
    __end=$4
    __anumber=$5
    __cnumber=$6
    __log="${logdir}/${__caseno}-t${__threshold}-c${__cnumber}-a${__anumber}-s${__start}-e${__end}"
    echo "Announce Test Case: ${__log#*/}"
    echo $(getermrunpid) | xargs kill &>/dev/null
    ./ermrun.sh ${srmip} ${__threshold} \
        "random-announce {'startPoint':${__start},'endPoint':${__end},'executingNumber':${__anumber}}" \
        ${__end} 1 ${__log} | tee ${__log} &
    trap "kill $(getermrunpid); exit 1;" INT KILL
    echo "Waiting for SRM to send GET_PARAMETER to ERM..."
    sleep 60
    echo "Starting client..."
    ssh -t root@${clientip} -- ${clientdir}/run.sh ${__cnumber} 0 ${srmip} ${__log} 47 7
    ./ermanalyze.sh ${__log}
    waitermrun
}

run "tc1"      30000   30  60  100     30000

#run "tc1"     100     30  60  100     100
#run "tc2"     100     20  30  100     100
#run "tc3"     100     20  21  100     100
#
#run "tc4"     1000    30  60  100     1200
#run "tc5"     1000    20  30  100     1200
#run "tc6"     1000    20  21  100     1200
#
#run "tc7"     5000    30  60  100     6000
#run "tc8"     5000    20  30  100     6000
#run "tc9"     5000    20  21  100     6000
#
#run "tc10"    5000    30  60  500     6000
#run "tc11"    5000    20  30  500     6000
#run "tc12"    5000    20  21  500     6000
#
#run "tc13"    7000    30  60  500     8000
#run "tc14"    7000    20  30  500     8000
#run "tc15"    7000    20  21  500     8000

#run "tc16"    7000    30  60  700     7500
#run "tc17"    7000    20  30  700     7500
#run "tc18"    7000    20  21  700     7500

#run "tc10"    10000   30  60  10000   12000


echo
echo "ERM Analysis"
echo "===================================="
for file in $(ls ${logdir}/*); do echo ">>>>>>"; echo "$file";./ermanalyze.sh $file; echo; done;
echo
