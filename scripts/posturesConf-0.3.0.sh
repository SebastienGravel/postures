# This is a helper script that can be sourced to provide aliases and any other
# useful features for Postures/NTA ::

NTA=~/src/nta
POSTURES=~/src/postures/trunk
SPINWIDGETS=~/src/spinwidgets-0.3.0
PDSHEEFA=~/src/pdsheefa-0.3.0
SPIN=~/src/spinframework-0.3.0
AUDIOSCAPE=~/src/audioscape-2.3.0

export BOOST_ROOT=/usr/include

# copy the latest .pdsettings from our svn repository:
`cp ${POSTURES}/scripts/pdsettings-0.3.0 ~/.pdsettings`

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


