#!/bin/bash

host=${1:-"10.85.2.230:5544"}
pnum=${2:-"1"}
killmetimeout=${3:-"7"}
logdir=${4:-"log"}/"procs"
msginterval=${5:-"40"} # 25 messages/second
msgvariation=${6:-"4"}
ptfile=${7}

rtsprequest="../rtsp-request-keepalive"
realptfile="pt.tmp"

killall() {
    netstat -tpn 2>&1 | grep perl | grep ${host} | awk '{print $7}' | cut -d / -f 1| grep -v "-" | xargs kill &>/dev/null
}

showbar(){
    barlength=$(($(tput cols) - 40))
    percdone=$(echo "$1 * 100 / $2" | bc)
    bardone=$(echo "$1 * ${barlength} / $2" | bc)
    printf -v bar "%*s>" $((bardone - 1))
    bar=${bar// /=}
    printf -v bar "[%s%*s]" ${bar} $((barlength - ${#bar}))
    pbcurrent=$(date +%s)
    if (( pbcurrent == pbstart ))
    then
        nps=0
        remain="?"
    else
        nps=$(echo "$1 / (${pbcurrent} - ${pbstart})" | bc)
        remain=$(echo "($2 - $1) / ${nps}" | bc)
    fi
    printf -v bar "%3s%%${bar} $1/$2    ${nps}/s    ${remain}s" ${percdone}
    printf -v margin "%*s\r" $(( $(tput cols) - $(echo "${bar}" | wc -c) - 1 ))
    echo -ne "${bar}${margin}\r"
}

findself() {
     # Am I a symlink?
     if [ -L $0 ]; then # yes I am; find the real path
         #echo "Linky"
         MYDIR=$(readlink -e -n $0)
     elif [ ${0:0:1} = '/' ]; then
         #echo "Absolute path"
         MYDIR="$0"
     else
         #echo "Relative path"
         MYDIR="$PWD/$0"
     fi

     MYDIR=${MYDIR%\/*} # Takes complete path ($0) and removes the script name to leave the directory
     MYDIR=${MYDIR%\/\.*} # Remove "\." from the path looks like "/aaa/bbb/ccc/."
}

abspath() {
    if [ ! ${1:0:1} = '/' ]; then
        echo "${MYDIR}/$1"
    else
        echo "$1"
    fi
}


findself
logdir=$(abspath ${logdir})
rtsprequest=$(abspath ${rtsprequest})
realptfile=$(abspath ${realptfile})
ptfile=$(abspath ${ptfile})

trap "if [ -e ${realptfile} ]; then rm ${realptfile}; fi; killall; exit 1" INT KILL

if [ ${logdir} ]
then
    mkdir -p ${logdir}
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

i=0
pbstart=$(date +%s)
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
        echo "$config" | ${rtsprequest} &>${logpath} &
        #echo "$config" | ../rtsp-request-keepalive 2>&1 | tee ${logpath} &
    else
        echo "$config" | ${rtsprequest} 2>&1 &
    fi
    #pid[i]=$!
    #trap "kill $(echo ${pid[@]:0}); exit 1" SIGINT

    # SRM is busy, let's send another SETUP message after a while.
    random=$((RANDOM % (msgvariation * 10)))
    interval=$(echo "(${msginterval} + (${random} / 10)) / 1000" | bc -l)
    sleep ${interval}
done <${realptfile} 
rm ${realptfile}
echo


netstatus=$(netstat -tpn 2>&1 | grep ${host})
echo 
echo "TCP Connections"
echo "------------------------------------------------"
netstat -n | grep ${host} | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'
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
