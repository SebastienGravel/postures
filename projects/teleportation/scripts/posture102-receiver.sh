#!/bin/bash

# Parameters
SDP_PCL_FILE_LOCATION_1="http://posture101.local:8250/sdp?rtpsession=pclsender&destination=pclmixer"
SDP_PCL_FILE_LOCATION_2="http://Linux-Desktop-2.local:8270/sdp?rtpsession=pclsender&destination=pclmixer"
SDP_PULSE_FILE_LOCATION_1="http://posture101.local:8250/sdp?rtpsession=pulsesender&destination=pulsemixer"
SDP_PULSE_FILE_LOCATION_2="http://Linux-Desktop-2.local:8260/sdp?rtpsession=pulsesender&destination=pulsemixer"
SDP_GET_QUID=uridecodebin

# Point clouds
switcher-ctrl -C $SDP_GET_QUID pclstream_1
sleep 1
switcher-ctrl -i pclstream_1 to_shmdata $SDP_FILE_LOCATION_1
sleep 2
switcher-ctrl -C $SDP_GET_QUID pclstream_2
sleep 1
switcher-ctrl -i pclstream_2 to_shmdata $SDP_FILE_LOCATION_2
sleep 2

rm /tmp/posture*
ln -s /tmp/switcher_pclreceiver_pclstream_1_custom_0 /tmp/posture101-readsm
ln -s /tmp/switcher_pclreceiver_pclstream_2_custom_0 /tmp/posture103-readsm

# Pulse
switcher-ctrl -C $SDP_GET_QUID pulsestream_1
sleep 1
switcher-ctrl -i pulsestream_1 to_shmdata $SDP_PULSE_FILE_LOCATION_1
sleep 2
switcher-ctrl -C $SDP_GET_QUID pulsestream_2
sleep 1
switcher-ctrl -i pulsestream_2 to_shmdata $SDP_PULSE_FILE_LOCATION_2
