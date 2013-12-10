#!/bin/bash

pnum=${1:-"10"}
killme=${2:-"7"}
host=${3:-"10.85.2.230:5544"}
logdir=${4:-"log"}
msginterval=${5:-"40"} # 25 messages/second
msgvariation=${6:-"4"}
ptfile=${7}

netmonifile="moni.log"

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
netmonifile=${logdir}/${netmonifile}

if [ ${logdir} ]
then
    mkdir -p ${logdir}
fi

${MYDIR}/netmonitor.sh ${host} &>${netmonifile} &
pidmoni=$!
trap "kill ${pidmoni}; exit 1" INT

${MYDIR}/perftest.sh ${host} ${pnum} ${killme} ${logdir} ${msginterval} ${msgvariation} ${ptfile}

kill ${pidmoni}

${MYDIR}/analyze.sh 1 SETUP ${logdir}

echo
cat ${netmonifile}
echo


