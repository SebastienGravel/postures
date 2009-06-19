# This is a helper script that can be sourced to provide aliases and any other
# useful features for Postures/NTA ::

NTA=~/src/nta
POSTURES=~/src/postures/trunk
SPINWIDGETS=~/src/spinwidgets
PDSHEEFA=~/src/pdsheefa
SPIN=~/src/spinframework

SPINID=`hostname -s`

# copy the latest .pdsettings from our svn repository:
`cp ${POSTURES}/scripts/pdsettings ~/.pdsettings`

# use custom pd instead of installed version:
alias pd='~/src/pd-0.41-4/bin/pd'

# some useful aliases:

alias cdvess='cd ${SPIN}/src/vess'
alias cdpostures='cd ${POSTURES}'
alias cdsw='cd ${SPINWIDGETS}/patches'
alias cdpds='cd ${PDSHEEFA}/patches'

alias svnupALL='svn up ${NTA}; svn up ${SPIN}; svn up ${SPINWIDGETS}; svn up ${PDSHEEFA}; svn up ${POSTURES}'

alias spinEdit='pd ${SPINWIDGETS}/patches/spinEdit.pd'
alias spinViewer='${SPIN}/src/vess/asViewer -viewerID ${SPINID}'

# this can be removed once the code is more stable:
export LD_LIBRARY_PATH=${SPIN}/src/osgWrappers

