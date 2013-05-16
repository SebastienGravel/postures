#!/bin/bash

# Parameters
SDP_PCL_FILE_LOCATION_1="http://posture102.local:8260/sdp?rtpsession=pclsender&destination=pclmixer"
SDP_PCL_FILE_LOCATION_2="http://Linux-Desktop-2.local:8270/sdp?rtpsession=pclsender&destination=pclmixer"
SDP_PULSE_FILE_LOCATION_1="http://posture102.local:8260/sdp?rtpsession=pulsesender&destination=pulsemixer"
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

# Pulse
switcher-ctrl -C $SDP_GET_QUID pulsestream_1
sleep 1
switcher-ctrl -i pulsestream_1 to_shmdata $SDP_PULSE_FILE_LOCATION_1
sleep 2
switcher-ctrl -C $SDP_GET_QUID pulsestream_2
sleep 1
switcher-ctrl -i pulsestream_2 to_shmdata $SDP_PULSE_FILE_LOCATION_2
