#!/bin/bash

# Select the target machine:
export MACHINE="desktopSIF"   # < egeon | egeonSIF | jaci | jaciSIF | pomerodeSIF | desktopSIF | sdumontSIF | sdumont2SIF >

# Select the simulation mode:
export MODERUN=G     # R=Regional simulation and G=Global simulation.
export LBCINT=10800  # Interval (seconds) for updating lateral boundary conditions (when regional mode).

# Define container environment variables:
export SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SIF_PATH=$(dirname "$(dirname "$SCRIPTS")")
export STOOLS=${SCRIPTS}/stools/${MACHINE}
export BC=${STOOLS}/cmd-bc
export BCL=${STOOLS}/cmd-bcl
export GRADS=${STOOLS}/cmd-grads
source ${STOOLS}/setenv

