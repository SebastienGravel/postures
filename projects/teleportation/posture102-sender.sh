#!/bin/bash

killall posture-camera
killall posture-merge
rm /tmp/cam*
rm /tmp/pcl

posture-camera -s /tmp/cam0 -c 0 > /dev/null &
posture-camera -s /tmp/cam1 -c 1 > /dev/null &
posture-camera -s /tmp/cam2 -c 2 > /dev/null &

posture-merge -v -s /tmp/pcl /tmp/cam0 /tmp/cam1 /tmp/cam2 > /dev/null &
sleep 10

killall switcher
rm /tmp/switcher*
./scripts/pcl-posture102-sender.sh
./scripts/pulse-posture102-sender.sh
