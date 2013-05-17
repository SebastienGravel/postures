#!/bin/bash

killall gst-launch-0.10

shmaudio /tmp/switcher_default_pulsestream_1_custom_0 &
shmaudio /tmp/switcher_default_pulsestream_2_custom_0
