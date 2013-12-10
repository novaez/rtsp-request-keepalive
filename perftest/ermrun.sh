#!/bin/bash

if (( $# < 4 ))
then
    echo "Usage: $0 srm threshold random_announce test_interval [test_count] [erm_log_file] [client_ip_address]"
    exit 1
fi

srm=$1
threshold=$2
randomannounce=$3
cmdinterval=$4
testcount=${5:-"0"}
ermlogfile=${6:-"ermlog"}
clientip=${7:-"10.85.2.229"}

teardowntimeout=180
ermdir="/soft/srm-emus"
pipe="/tmp/testpipe"


echo "Restaring SRM..."
service srm restart


echo
echo "------------------------------------------"
echo "SRM Address               :   ${srm}"
echo "Connections Threshold     :   ${threshold}"
echo "Random ANNOUNCEs Command  :   ${randomannounce}"
echo "Command Interval          :   ${cmdinterval}"
echo "ERM Log File              :   ${ermlogfile}"
echo "Pipe File                 :   ${pipe}"
echo "TEARDOWNs Timeout         :   ${teardowntimeout}"
echo "------------------------------------------"
echo


if [[ ! -p ${pipe} ]]
then
    mkfifo ${pipe}
fi

echo
echo "Restaring ERM..."
ermpid=$(netstat -tlpn | grep 5540 | awk '{print $7}' | cut -d"/" -f1)
if [[ -n ${ermpid} ]]
then
    kill ${ermpid} 
fi
tail -f ${pipe} | java -Dcom.nagra.multiscreen.s6erm.respmode=UPDATE_PER_REQUEST \
    -Dcom.nagra.multiscreen.s6erm.respconffile=s6ermrequest.conf \
    -Dcom.nagra.multiscreen.s6erm.bulkmode=true -Dcom.nagra.multiscreen.s6erm.ephemeralSessions \
    -cp ${ermdir}/target/classes:${ermdir}/target/lib/* \
    com.nagra.multiscreen.srm.emu.s6erm.S6ErmServer 5540 false >>${ermlogfile} 2>&1 &

ermpid=$!
echo
echo "ERM pid: ${ermpid}"
trap "kill ${ermpid}; rm -f ${pipe}; exit 1" INT KILL

testid=1
while true
do
    count=$(netstat -tpn | grep ${srm} | grep ESTABLISHED | wc -l)

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
                count=$(netstat -tpn | grep ${srm} | grep ESTABLISHED | wc -l)
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
