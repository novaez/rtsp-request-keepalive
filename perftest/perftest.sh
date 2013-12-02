#!/bin/bash

host=${1:-"10.85.2.230:5544"}
pnum=${2:-"1"}
killmetimeout=${3:-"7"}
logdir=${4:-"log"}
msginterval=${5:-"40"} # 25 messages/second
msgvariation=${6:-"4"}
ptfile=${7}

realptfile="pt.tmp"

trap "rm ${realptfile}; killall; exit 1" INT KILL

killall () {
    netstat -tpn 2>&1 | grep perl | grep ${host} | awk '{print $7}' | cut -d / -f 1| grep -v "-" | xargs kill &>/dev/null
}

if [ ${logdir} ]
then
    if [ -e ${logdir} ]
    then
        rm -rf ${logdir}
    fi
    mkdir ${logdir}
fi

echo
echo "------------------------------------------------"
echo "Processes Number          :   ${pnum}"
echo "SETUP Message Interval    :   ${msginterval}ms"
echo "SETUP Message Variation   :   ${msgvariation}ms"
echo "Killme Timeout            :   ${killmetimeout}s"
echo "Log Directory             :   ${logdir}"
echo "------------------------------------------------"
echo

# Prepare purchase tokens file
> ${realptfile}
if [ ${ptfile} ]
then
    # Create a file containing purchase tokens as the input file
    ptnum=$(cat ${ptfile} | wc -l)
    for i in $(seq $((pnum / ptnum)))
    do
        cat ${ptfile} >> ${realptfile} 
    done
    head -$((pnum % ptnum)) ${ptfile} >> ${realptfile}
else
    # Use number as purchase tokens
    seq ${pnum} > ${realptfile}
fi

showbar(){
    barlength=$(($(tput cols) - 25))
    percdone=$(echo "$1 * 100 / $2" | bc)
    bardone=$(echo "$1 * ${barlength} / $2" | bc)
    printf -v bar "%*s>" $((bardone - 1))
    bar=${bar// /=}
    printf -v bar "[%s%*s]" ${bar} $((barlength - ${#bar}))
    printf "%2s%%${bar} $1/$2\r" ${percdone}
}

i=0
while read line
do
    ((i++))

    #echo "Start process $i..."
    showbar $i ${pnum}

    pt=${line}
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
    #pid[i]=$!
    #trap "kill $(echo ${pid[@]:0}); exit 1" SIGINT

    # SRM is busy, let's send another SETUP message after a while.
    interval=$(echo "$((msginterval + (RANDOM % msgvariation))) / 1000" | bc -l)
    sleep ${interval}
done <${realptfile} 
rm ${realptfile}
echo


netstatus=$(netstat -tpn 2>&1 | grep ${host})
echo 
echo "TCP Connections"
echo "------------------------------------------------"
echo "${netstatus}"
echo "------------------------------------------------"
echo "All               : $(echo "${netstatus}" | grep -v "" | wc -l)"
echo "ESTABLISHED       : $(echo "${netstatus}" | grep "ESTABLISHED" | wc -l)"
echo "TIME_WAIT         : $(echo "${netstatus}" | grep "TIME_WAIT" | wc -l)"
echo "SYN_SENT          : $(echo "${netstatus}" | grep "SYN_SENT" | wc -l)"
echo


if (( ${killmetimeout} != 0 ))
then
    echo "Terminate all children processes after ${killmetimeout}s..."
    sleep ${killmetimeout}
    #echo ${pid[@]:0} | xargs kill
    killall
    exit 1
fi


echo "Waiting for all children processes terminating..."
wait
exit 1
