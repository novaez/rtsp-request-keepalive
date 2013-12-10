#!/bin/bash

cseqno=${1:-"1"}
methodname=${2:-"SETUP"}
logdir=${3:-"log"}/"procs"

respcseq="CSeq: ${cseqno}\.\."
reqcseq="cseq: ${cseqno}"

okline="200 OK"

echo "Usage: $0 [cseq_no] [method_name] [log_dir]"

if [[ ! -e ${logdir} ]]
then
    echo "Could not found: ${logdir}!"
    exit 1
fi

pushd ${logdir} > /dev/null

echo
echo "${methodname}(${respcseq}) No Response Processes"
echo "------------------------------------------------"
#for i in $(grep -L "${respcseq}" * 
for i in $(comm -3 <(ls | sort) <(grep -l "CSeq: 1\.\." * | sort))
do
    echo "==> $i <=="
    cat "$i"
    echo
done
echo 

echo
echo "${methodname}(${respcseq}) Failed"
echo "------------------------------------------------"
grep -B 1 "${respcseq}" * | grep -v "${respcseq}" | grep -v '\-\-' | grep -v '200 OK' | cut -d "-" -f 1 | sort | xargs grep -A 3 -B 1 "${respcseq}"
echo

echo
echo "${methodname}(${respcseq}) Failed Histogram"
echo "------------------------------------------------"
grep -B 1 "CSeq: 1\.\." * | grep -v "CSeq: 1\.\." | grep -v '\-\-' | grep -v '200 OK' | cut -d "-" -f 1 | sort | xargs grep "x-srm-error-message" | awk -F 'x-srm-error-message: ' '{print $2}' | sort | uniq -c | sort -nr | awk '!max{max=$1;}{r="";i=s=60*$1/max;while(i-->0)r=r"#";name="";for(i=2;i<=NF;++i)name=name" "$i;printf "%s\n %5d %s\n",name,$1,r;}'
echo

echo
echo "${methodname}(${respcseq})"
echo "------------------------------------------------"
echo "Processes Number           :   $(ls * | wc -l)"
echo "Messages Sent              :   $(grep "${reqcseq}" * | wc -l)"
echo "Responses Received         :   $(grep "${respcseq}" * | wc -l)"
echo "Response Not Received      :   $(grep -L "${respcseq}" * | wc -l)"
echo "OK                         :   $(grep -B 1 "${respcseq}" * | grep -c '200 OK')"
echo "Failed                     :   $(grep -B 1 "${respcseq}" * | grep -v "${respcseq}" | grep -v '\-\-' | grep -nc -v '200 OK')"
echo

popd > /dev/null

