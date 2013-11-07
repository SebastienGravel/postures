#!/bin/bash

killall node
cd padweb
node app.js -ip athena.local -o athena -s /SPIN/timeline-pierrebarouh/athena -alpha 195
