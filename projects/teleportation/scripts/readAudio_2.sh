#!/bin/bash

killall gst-launch-0.10
gst-launch shmsrc socket-path=/tmp/switcher_default_pulsestream_2_custom_0 ! gdpdepay ! decodebin2 ! pulsesink sync=false
