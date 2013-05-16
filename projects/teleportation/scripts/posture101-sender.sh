#!/bin/bash

SENDER_URL=`echo http://localhost:8250`
DESTINATION_IP_1=posture102.local
DESTINATION_IP_2=Linux-Desktop-2.local
PCL_NAME=/tmp/pcl

# Send point clouds
echo '------ PCL ------'
switcher-ctrl -S $SENDER_URL -C rtpsession pclsender
sleep 1
switcher-ctrl -S $SENDER_URL -i pclsender add_data_stream $PCL_NAME
sleep 1
switcher-ctrl -S $SENDER_URL -i pclsender add_destination pclmixer_1 $DESTINATION_IP_1
sleep 1
switcher-ctrl -S $SENDER_URL -i pclsender add_destination pclmixer_2 $DESTINATION_IP_2
sleep 1
switcher-ctrl -S $SENDER_URL -i pclsender add_udp_stream_to_dest $PCL_NAME pclmixer_1 21650
sleep 1
switcher-ctrl -S $SENDER_URL -i pclsender add_udp_stream_to_dest $PCL_NAME pclmixer_2 21652

# Send sound
echo '------  -S $SENDER_URLPULSE ------'
switcher-ctrl -S $SENDER_URL -C gstsrc mic
sleep 1
switcher-ctrl -S $SENDER_URL -i mic to_shmdata 'pulsesrc device=alsa_input.usb-PreSonus_Audio_AudioBox_USB-01-USB.analog-stereo volume=1 ! capsfilter caps="audio/x-raw-int, endianness=(int)1234, signed=(boolean)true, width=(int)16, depth=(int)16, rate=(int)44100, channels=(int)1" !  audioresample ! audioconvert'
sleep 1
switcher-ctrl -S $SENDER_URL -C rtpsession pulsesender
sleep 1
switcher-ctrl -S $SENDER_URL -i pulsesender add_data_stream /tmp/switcher_pulsesender_mic_gstsrc
sleep 1
switcher-ctrl -S $SENDER_URL -i pulsesender add_destination pulsemixer_1 $DESTINATION_IP_1
sleep 1
switcher-ctrl -S $SENDER_URL -i pulsesender add_destination pulsemixer_2 $DESTINATION_IP_2
sleep 1
switcher-ctrl -S $SENDER_URL -i pulsesender add_udp_stream_to_dest /tmp/switcher_pulsesender_mic_gstsrc pulsemixer_1 21654
sleep 1
switcher-ctrl -S $SENDER_URL -i pulsesender add_udp_stream_to_dest /tmp/switcher_pulsesender_mic_gstsrc pulsemixer_2 21656
