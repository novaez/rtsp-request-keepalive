#!/bin/bash

echo "# after, interval, count, args
0, 0, 0, -d -p -b -m SETUP rtsp://localhost:5544/;purchaseToken=d1084c8b-f3a7-4c84-a1d4-e8e66e5c0e61;serverID=localhost Require=com.comcast.ngod.s1 Transport=MP2T/DVBC/QAM;unicast;client=20001;qam_name=Gobelins-0.0 ClientSessionId=007
5, 6, *, -d -p -b -m PING rtsp://localhost:5544/ Require=com.comcast.ngod.s1 OnDemandSessionId= Session="
