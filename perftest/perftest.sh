#!/bin/bash

host=${1:-"10.85.2.230:5544"}
pnum=${2:-"1"}
killmetimeout=${3}
logdir=${4}
msginterval=${5:-"40"} # 25 messages/second
msgvariation=${6:-"4"}

if [ ${logdir} ]
then
    if [ -e ${logdir} ]
    then
        rm -rf ${logdir}
    fi
    mkdir ${logdir}
fi

echo "====================================================="
echo "Processes Number          :   ${pnum}"
echo "SETUP Message Interval    :   ${msginterval}s"
echo "Killme Timeout            :   ${killmetimeout}s"
echo "Log Directory             :   ${logdir}"
echo "====================================================="
echo

for i in $(seq $pnum)
do
    echo "Start process $i..."

    pt=$i
pt="014c7e2e-61f8-43bb-b8f3-97dac1e7a07a"
    read -d '' config <<EOF
# after, interval, count, args
0, 0, 0, -d -p -b -m SETUP rtsp://${host}/;purchaseToken=${pt};serverID=localhost Require=com.comcast.ngod.s1 Transport=MP2T/DVBC/QAM;unicast;client=20001;qam_name=Gobelins-0.0 ClientSessionId=007
5, 6, *, -d -p -b -m PING rtsp://${host}/ Require=com.comcast.ngod.s1 OnDemandSessionId= Session=
EOF

    if [ ${logdir} ]
    then
        fileno=$(printf "%0*d\n" 6 $i);
        logpath="${logdir}/proc_${fileno}"
        echo "$config" | ../rtsp-request-keepalive &>${logpath} &
        #echo "$config" | ../rtsp-request-keepalive 2>&1 | tee ${logpath} &
    else
        echo "$config" | ../rtsp-request-keepalive 2>&1 &
    fi
    pid[i]=$!
    trap "kill $(echo ${pid[@]:0}); exit 1" SIGINT

    # SRM is busy, let's send another SETUP message after a while.
    interval=$(echo "$((msginterval + (RANDOM % msgvariation))) / 1000" | bc -l)
    sleep ${interval}
done

#port=$(echo ${host} | cut -d : -f2)
#echo
#echo "Connections: $(netstat -tpn | grep ${port} | wc -l)"
#echo "Connections established: $(netstat -tpn | grep ${port} | grep "ESTABLISHED" | wc -l)"
#echo

if [ ${killmetimeout} ]
then
    echo "Terminate all children processes after ${killmetimeout}s..."
    sleep ${killmetimeout}
    echo ${pid[@]:0} | xargs kill
fi

echo "Waiting for all children processes terminating..."
wait

