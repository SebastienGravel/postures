#!/bin/bash

SENDER_NAME=pulsesender
SENDER_PORT=8392
SENDER_URL=`echo http://localhost:${SENDER_PORT}`

DESTINATION_IP=posture101.local

function startserver {
    log_file=`echo switcher_$1_log`
    echo "--------" >> $log_file
    date >> $log_file
    echo "--------" >> $log_file
    switcher -s $1 -p $2 -d >> $log_file
}

startserver $SENDER_NAME $SENDER_PORT &
sleep 2

switcher-ctrl -S $SENDER_URL -C gstsrc mic
sleep 1
switcher-ctrl -S $SENDER_URL -i mic to_shmdata 'pulsesrc volume=1 ! capsfilter caps="audio/x-raw-int, endianness=(int)1234, signed=(boolean)true, width=(int)16, depth=(int)16, rate=(int)44100, channels=(int)1" !  audioresample ! audioconvert'
sleep 1
switcher-ctrl -S $SENDER_URL -C rtpsession pulsesender
sleep 1
switcher-ctrl -S $SENDER_URL -i pulsesender add_data_stream /tmp/switcher_pulsesender_mic_gstsrc
sleep 1
switcher-ctrl -S $SENDER_URL -i pulsesender add_destination pulsemixer ${DESTINATION_IP}
sleep 1
switcher-ctrl -S $SENDER_URL -i pulsesender add_udp_stream_to_dest /tmp/switcher_pulsesender_mic_gstsrc pulsemixer 21640
