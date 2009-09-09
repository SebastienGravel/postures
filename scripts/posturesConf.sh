# This is a helper script that can be sourced to provide aliases and any other
# useful features for Postures/NTA ::

NTA=~/src/nta
POSTURES=~/src/postures/trunk
SPINWIDGETS=~/src/spinwidgets
PDSHEEFA=~/src/pdsheefa
SPIN=~/src/spinframework/trunk

export BOOST_ROOT=/usr/include

# copy the latest .pdsettings from our svn repository:
`cp ${POSTURES}/scripts/pdsettings ~/.pdsettings`

# use custom pd instead of installed version:
#alias pd='pd -jack'
alias pd='~/src/pd-0.41-4/bin/pd -jack'

# some useful aliases:

alias cdnta='cd ${NTA}'
alias cdspin='cd ${SPIN}/src/spin'
alias cdpostures='cd ${POSTURES}'
alias cdsw='cd ${SPINWIDGETS}/patches'
alias cdpds='cd ${PDSHEEFA}/patches'

alias svnupALL='svn up ${NTA}; svn up ${SPIN}; svn up ${SPINWIDGETS}; svn up ${PDSHEEFA}; svn up ${POSTURES}'

alias ntaClient='pd ${NTA}/ntaClient.pd &'
alias spin='cd ${SPIN}/src/spin; ./spin &'
alias spinServer='cd ${SPIN}/src/spin; ./spinServer &'
alias spinViewer='cd ${SPIN}/src/spin; ./spinViewer &'
alias panoViewer='cd ${POSTURES}/panoViewer; ./panoViewer &'


#export PATH=${PATH}:${SPIN}/src/spin:${POSTURES}/panoViewer:${NTA}


# this can be removed once the code is more stable:
export LD_LIBRARY_PATH=${SPIN}/src/osgWrappers

