#!/bin/bash

# Parameters
SENDER_URL=`echo http://localhost:8260`
SDP_PCL_FILE_LOCATION_1="http://posture101.local:8250/sdp?rtpsession=pclsender&destination=pclmixer_1"
SDP_PCL_FILE_LOCATION_2="http://Linux-Desktop-2.local:8270/sdp?rtpsession=pclsender&destination=pclmixer_2"
SDP_PULSE_FILE_LOCATION_1="http://posture101.local:8250/sdp?rtpsession=pulsesender&destination=pulsemixer_1"
SDP_PULSE_FILE_LOCATION_2="http://Linux-Desktop-2.local:8260/sdp?rtpsession=pulsesender&destination=pulsemixer_2"
SDP_GET_QUID=uridecodebin

# Point clouds
switcher-ctrl -S $SENDER_URL -C $SDP_GET_QUID pclstream_1
sleep 1
switcher-ctrl -S $SENDER_URL -i pclstream_1 to_shmdata $SDP_PCL_FILE_LOCATION_1
sleep 2
switcher-ctrl -S $SENDER_URL -C $SDP_GET_QUID pclstream_2
sleep 1
switcher-ctrl -S $SENDER_URL -i pclstream_2 to_shmdata $SDP_PCL_FILE_LOCATION_2
sleep 2

rm /tmp/posture*
ln -s /tmp/switcher_pclreceiver_pclstream_1_custom_0 /tmp/posture101-readsm
ln -s /tmp/switcher_pclreceiver_pclstream_2_custom_0 /tmp/posture103-readsm

# Pulse
switcher-ctrl -S $SENDER_URL -C $SDP_GET_QUID pulsestream_1
sleep 1
switcher-ctrl -S $SENDER_URL -i pulsestream_1 to_shmdata $SDP_PULSE_FILE_LOCATION_1
sleep 2
switcher-ctrl -S $SENDER_URL -C $SDP_GET_QUID pulsestream_2
sleep 1
switcher-ctrl -S $SENDER_URL -i pulsestream_2 to_shmdata $SDP_PULSE_FILE_LOCATION_2
