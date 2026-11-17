#!/bin/bash

# Select the target machine: ------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
export MACHINE="jaci"   # < egeon | egeonSIF | jaci | jaciSIF | pomerodeSIF | desktopSIF | sdumontSIF | sdumont2SIF >
#----------------------------------------------------------------------------------------------------


# Select the simulation mode: -----------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
export MODERUN=R     # R=Regional simulation and G=Global simulation.
export LBCINT=10800  # Interval (seconds) for updating lateral boundary conditions (when regional mode).
#----------------------------------------------------------------------------------------------------


# Define container environment variables: -----------------------------------------------------------
#----------------------------------------------------------------------------------------------------
export SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SIF_PATH=$(dirname "$(dirname "$SCRIPTS")")
export STOOLS=${SCRIPTS}/stools/${MACHINE}
export BC=${STOOLS}/cmd-bc
export BCL=${STOOLS}/cmd-bcl
export GRADS=${STOOLS}/cmd-grads
source ${STOOLS}/setenv
#----------------------------------------------------------------------------------------------------


# Standart directories variables: -------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
export DIRHOMES=${SIF_PATH}/scripts_container;       mkdir -p ${DIRHOMES}
export DIRHOMED=${SIF_PATH}/scripts_container;       mkdir -p ${DIRHOMED}
export SCRIPTS=${DIRHOMES}/scripts;                  mkdir -p ${SCRIPTS}
export DATAIN=${DIRHOMED}/datain;                    mkdir -p ${DATAIN}
export DATAOUT=${DIRHOMED}/dataout;                  mkdir -p ${DATAOUT}
export SOURCES=${DIRHOMES}/sources;                  mkdir -p ${SOURCES}
export EXECS=${DIRHOMED}/execs;                      mkdir -p ${EXECS}
#----------------------------------------------------------------------------------------------------

