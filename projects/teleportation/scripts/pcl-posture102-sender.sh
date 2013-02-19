#!/bin/bash

# Sending point clouds
SENDER_NAME=posturesender
SENDER_PORT=8293
SENDER_URL=`echo http://localhost:${SENDER_PORT}`

# Local point clouds
PCL_NAME=pcl

DESTINATION_IP=posture101.local

# Cleaning things
killall switcher
rm /tmp/switcher_*

function startserver {
    log_file=`echo switcher_$1_log`
    echo "--------" >> $log_file
    date >> $log_file
    echo "--------" >> $log_file
    switcher -s $1 -p $2 -d >> $log_file
}

# Starting switcher
startserver $SENDER_NAME $SENDER_PORT &
sleep 2

switcher-ctrl -S $SENDER_URL -C rtpsession pclsender
sleep 1
switcher-ctrl -S $SENDER_URL -i pclsender add_data_stream /tmp/pcl
sleep 1
switcher-ctrl -S $SENDER_URL -i pclsender add_destination pclmixer ${DESTINATION_IP}
sleep 1
switcher-ctrl -S $SENDER_URL -i pclsender add_udp_stream_to_dest /tmp/pcl pclmixer 21600
