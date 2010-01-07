# This is a helper script that can be sourced to provide aliases and any other
# useful features for Postures/NTA ::

NTA=~/src/nta
POSTURES=~/src/postures/trunk
SPINWIDGETS=~/src/spinwidgets
PDSHEEFA=~/src/pdsheefa
SPIN=~/src/spinframework/trunk
#AUDIOSCAPE=~/src/audioscape_2.0
AUDIOSCAPE=~/src/audioscape_2.1
MIVILLE=~/src/miville

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
alias cdas='cd ${AUDIOSCAPE}/patches'



alias svnupALL='echo svn up ${NTA} && svn up ${NTA} && echo svn up ${SPIN} && svn up ${SPIN} && echo svn up ${SPINWIDGETS} && svn up ${SPINWIDGETS} && echo svn up ${PDSHEEFA} && svn up ${PDSHEEFA} && echo svn up ${POSTURES} && svn up ${POSTURES} && echo svn up ${AUDIOSCAPE} && svn up ${AUDIOSCAPE} && echo svn up ${MIVILLE} && svn up ${MIVILLE}'

alias ntaClient='pd ${NTA}/ntaClient.pd &'

#export PATH=${PATH}:${SPIN}/src/spin:${POSTURES}/panoViewer:${NTA}


# this can be removed once the code is more stable:
#export LD_LIBRARY_PATH=${SPIN}/src/osgWrappers

