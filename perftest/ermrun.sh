#!/bin/bash

if (( $# < 4 ))
then
    echo "Usage: $0 srm_ip_address threshold random_announce test_interval [test_count] [erm_log_file] [client_ip_address]"
    exit 1
fi

srmip=$1
threshold=$2
randomannounce=$3
cmdinterval=$4
testcount=${5:-"0"}
ermlogfile=${6:-"ermlog"}
clientip=${7:-"10.85.2.229"}

teardowntimeout=300

pavdir="/home/root/SRM_Iso/GDC/pav-emulator-for-stress-test"
ermdir="/soft/srm-emus/target"
vssdir="/home/root/SRM_Iso/GDC/artefact/srm-emus/target"

pavlogfile="pav.out"
vsslogfile="vss.out"

pipe="/tmp/testpipe"

trap "service srm stop; \
    rm -f ${pipe}; \
    exit 1" INT KILL

getpidwithport(){
    netstat -tpln | grep $1 | awk '{print $7}' | cut -d "/" -f1
}

echo
echo "------------------------------------------"
echo "SRM IP Address            :   ${srmip}"
echo "Connections Threshold     :   ${threshold}"
echo "Random ANNOUNCEs Command  :   ${randomannounce}"
echo "Command Interval          :   ${cmdinterval}"
echo "ERM Log File              :   ${ermlogfile}"
echo "Pipe File                 :   ${pipe}"
echo "TEARDOWNs Timeout         :   ${teardowntimeout}"
echo "------------------------------------------"
echo

echo "Restaring PAV..."
kill $(getpidwithport 8180) &>/dev/null
pushd ${pavdir}
./run.sh 8180 &>${pavlogfile} &
popd

echo "Restarting VSS..."
kill $(getpidwithport 5546) &>/dev/null
java -Dcom.nagra.multiscreen.r2vs.ephemeralSessions \
    -cp ${vssdir}/classes:${vssdir}/lib/* \
    com.nagra.multiscreen.srm.emu.r2vs.R2VsServer 5546 false &>${vsslogfile} &

if [[ ! -p ${pipe} ]]
then
    mkfifo ${pipe}
fi
echo
echo "Restaring ERM..."
kill $(getpidwithport 5540) &>/dev/null
tail -f ${pipe} | java -Dcom.nagra.multiscreen.s6erm.bulkmode=true \
    -Dcom.nagra.multiscreen.s6erm.ephemeralSessions \
    -cp ${ermdir}/classes:${ermdir}/lib/* \
    com.nagra.multiscreen.srm.emu.s6erm.S6ErmServer 5540 false >>${ermlogfile} 2>&1 &

echo "Restaring SRM..."
service srm restart




testid=1
while true
do
    count=$(netstat -tpn | grep ${srmip} | grep ESTABLISHED | wc -l)

    if (( count >= threshold ))
    then
        echo
        echo "Current connections between SRM and Clients : ${count}"
        echo "Sending random announces command to ERM..."
        echo "${randomannounce}" > ${pipe}
        echo "ANNOUNCEs are being sent, sleeping for ${cmdinterval}s..."
        sleep ${cmdinterval}
        if (( testcount != 0 ))
        then 
            if (( testid++ >= testcount ))
            then
                echo
                echo "Waiting for all TEARDOWNs from SRM, sleeping for ${teardowntimeout}s..."
                sleep ${teardowntimeout}
                echo "Killing ERM..."
                kill ${ermpid}
                rm -f ${pipe}
                count=$(netstat -tpn | grep ${srmip} | grep ESTABLISHED | wc -l)
                echo "Current connections between SRM and Clients : ${count}"
                echo "Stopping SRM..."
                service srm stop
                echo "Exiting Announce test..."
                exit 0
            fi
        fi
    fi

    sleep 3
done
