#!/bin/bash

logfile=${1:-"ermlog"}

echo
echo Command:
echo "$(grep "Random ANNOUNCEs Command" ${logfile})"
#echo "$(grep "Executing Points" ${logfile})"
echo

echo
echo "-------------------------------------------"
echo "$(grep "Connections Threshold" ${logfile})"
echo "ANNOUNCEs Count                   :  $(grep "Sending an ANNOUNCE on session" ${logfile} | awk '{print $10}' | wc -l)"
echo "Uniq ANNOUNCEs Count              :  $(grep "Sending an ANNOUNCE on session" ${logfile} | awk '{print $10}' | uniq -c | wc -l)"
echo "Failed ANNOUNCEs Count            :  $(grep "failed to send ANNOUNCE" ${logfile} | wc -l)"
echo "Teardowns Count                   :  $(grep "TEARDOWN rtsp://" ${logfile} | wc -l)"       
echo "Remaining Connections Count       :  $(grep "Current connections between SRM and Clients" ${logfile} | tail -1 | cut -d":" -f2 | sed "s/[[:space:]]*//")"
echo "-------------------------------------------"
echo


#echo
#echo "ANNOUNCEs Sent:"
#echo "..."
#grep "Sending an ANNOUNCE on session" ${logfile} | awk '{print $10}' | uniq -c | sort | tail -5
#echo


echo
echo "OnDemandSessionId without TEARDOWN:"
echo "-----------------------------------"
tanotmatch(){
    diff <(grep -A 3 "TEARDOWN rtsp://" ${logfile} | grep OnDemandSessionId | uniq | awk '{print $2}' | sort) <(grep "Sending an ANNOUNCE on session" ${logfile} | awk '{print $11}' | uniq | cut -d"=" -f2 | sort) | grep ">" | sed 's/> //'
}
echo "$(tanotmatch)"
echo "Total: $(tanotmatch | wc -l)"
echo
