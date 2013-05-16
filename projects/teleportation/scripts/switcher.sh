#!/bin/bash

killall switcher

SERVER_NAME=posturesender
SERVER_PORT=$1

function startserver {
    log_file=`echo switcher_log`
    echo "--------" >> $log_file
    date >> $log_file
    echo "--------" >> $log_file
    switcher -p $2 -d >> $log_file
}

startserver $SERVER_PORT &
