#!/bin/bash

killall posture-camera
killall posture-merge
rm /tmp/cam*
rm /tmp/pcl

posture-camera -s /tmp/cam0 -c 0 &
posture-camera -s /tmp/cam1 -c 1 &
posture-camera -s /tmp/cam2 -c 2 &

sleep 5
posture-merge -s /tmp/pcl /tmp/cam0 /tmp/cam1 /tmp/cam2
