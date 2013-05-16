#!/bin/bash

SENDER_NAME=posturesender
SENDER_PORT=$1

function startserver {
    log_file=`echo switcher_$1_log`
    echo "--------" >> $log_file
    date >> $log_file
    echo "--------" >> $log_file
    switcher -s $1 -p $2 -d >> $log_file
}

startserver $SENDER_NAME $SENDER_PORT &
