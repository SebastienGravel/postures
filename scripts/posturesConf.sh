# This is a helper script that can be sourced to provide aliases and any other
# useful features for Postures/NTA ::

echo "Loaded Postures configuration"

NTA=~/content/nta
POSTURES=~/src/postures/trunk
PDSHEEFA=~/src/pdsheefa
SPIN=~/src/spinframework
SCENIC=~/src/scenic

export BOOST_ROOT=/usr/include

# copy the latest .pdsettings from our svn repository:
`cp ${POSTURES}/scripts/pdsettings ~/.pdsettings`

# use custom pd instead of installed version:
alias pd='pdextended -jack'
#alias pd='pd -jack'
#alias pd='~/src/pd-0.41-4/bin/pd -jack'


# some useful aliases:

alias cdnta='cd ${NTA}'
alias cdspin='cd ${SPIN}'
alias cdpostures='cd ${POSTURES}'
alias cdpds='cd ${PDSHEEFA}'

alias svnupALL='echo svn up ${NTA} && svn up ${NTA} && echo svn up ${SPIN} && svn up ${SPIN} && echo svn up ${PDSHEEFA} && svn up ${PDSHEEFA} && echo svn up ${POSTURES} && svn up ${POSTURES}'

alias ntaClient='pd ${NTA}/ntaClient.pd &'

#export PATH=${PATH}:${SPIN}/src/spin:${POSTURES}/panoViewer:${NTA}

export PATH=${PATH}:/usr/local/share/OpenSceneGraph/bin
export OSG_FILE_PATH=~/src/OpenSceneGraph-Data
export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:/usr/local/lib64/osgPlugins-2.9.8
export OSG_NOTIFY_LEVEL=FATAL

# this can be removed once the code is more stable:
#export LD_LIBRARY_PATH=${SPIN}/src/osgWrappers

