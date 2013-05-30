#!/bin/bash

gst-launch shmsrc socket-path=/tmp/switcher_default_pulsestream_2_custom_0 ! gdpdepay ! decodebin2 !  queue2 use-buffering=true max-size-time=500000000 ! identity sync=true ! pulsesink sync=false
