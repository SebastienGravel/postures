#!/bin/bash

killall posture-camera
killall posture-merge
rm /tmp/cam*
rm /tmp/pcl

posture-camera -H -s /tmp/cam0 -c 0 &
posture-camera -H -s /tmp/cam1 -c 1 &
posture-camera -H -s /tmp/cam2 -c 2 &

sleep 5
posture-merge -C -s /tmp/pcl /tmp/cam0 /tmp/cam1 /tmp/cam2 &
sleep 5

killall switcher
rm /tmp/switcher*
./scripts/pcl-posture102-sender.sh
./scripts/pulse-posture102-sender.sh
