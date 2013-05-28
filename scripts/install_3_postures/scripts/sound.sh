#!/bin/bash
killall gst-launch-0.10
./readAudio_1.sh > /dev/null &
./readAudio_2.sh > /dev/null &
