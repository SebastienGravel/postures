# This is a helper script that can be sourced to provide aliases and any other
# useful features for Postures

POSTURES=~/src/postures/trunk
SPINWIDGETS=~/src/spinwidgets
SPIN=~/src/spinframework

WHOAMI=`whoami`

# this can be removed once the code is more stable:
export LD_LIBRARY_PATH=${SPIN}/src/osgWrappers

export MY_IP=`perl -I${POSTURES}/scripts -MSys::IP -e "print ip()"`
case "$TERM" in xterm*|rxvt*)
	PROMPT_COMMAND='echo -ne "\033]0; ${MY_IP} : ${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
	;;
*)
	;;
esac


