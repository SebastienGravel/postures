#!/bin/bash

./scripts/pcl-posture101-receiver.sh
./scripts/pulse-posture101-receiver.sh

rm /tmp/posture*
ln -s /tmp/pcl /tmp/posture101-readsm
ln -s /tmp/switcher_pclreceiver_pclstream_custom_0 /tmp/posture102-readsm

sleep 5
gst-launch shmsrc socket-path=/tmp/switcher_pulsereceiver_pulsestream_custom_0 ! gdpdepay ! decodebin2 ! pulsesink sync=false &
