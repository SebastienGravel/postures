#!/bin/bash

RECEIVER_NAME=pulsereceiver
RECEIVER_PORT=8399
RECEIVER_URL=`echo http://localhost:${RECEIVER_PORT}`
SDP_FILE_LOCATION="http://posture102.local:8392/sdp?rtpsession=pulsesender&destination=pulsemixer"
SDP_GET_QUID=uridecodebin

function startserver {
   log_file=`echo switcher_$1_log`
   echo "---------" >> $log_file
   date >> $log_file
   echo "---------" >> $log_file
   switcher -s $1 -p $2 -d >> $log_file
}

startserver $RECEIVER_NAME $RECEIVER_PORT &
sleep 2

switcher-ctrl -S $RECEIVER_URL -C ${SDP_GET_QUID} pulsestream
sleep 1
switcher-ctrl -S $RECEIVER_URL -i pulsestream to_shmdata ${SDP_FILE_LOCATION}
