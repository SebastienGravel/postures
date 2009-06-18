# This is a helper script that can be sourced to provide aliases and any other
# useful features for Postures

POSTURES=~/src/postures/trunk
SPINWIDGETS=~/src/spinwidgets
SPIN=~/src/spinframework

SPINID=`hostname -s`

alias cdvess='cd ${SPIN}/src/vess'
alias spinViewer='${SPIN}/src/vess/asViewer -viewerID ${SPINID}'

# this can be removed once the code is more stable:
export LD_LIBRARY_PATH=${SPIN}/src/osgWrappers


