#!/bin/bash 
umask 022

# Usage instructions: -------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
if [ $# -ne 4 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP_NAME RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "            :: Others options to be added later..."
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} GFS 1024002 2024010100 24"
   echo ""

   exit
fi
#----------------------------------------------------------------------------------------------------


# Load the MONAN environment configuration: ---------------------------------------------------------
#----------------------------------------------------------------------------------------------------
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash
#----------------------------------------------------------------------------------------------------


# Standart directories variables: -------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_container; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_container;   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------------------------------------


# Input variables: ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=24
#----------------------------------------------------------------------------------------------------


# Local variables: ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
GEODATA=${DATAIN}/WPS_GEOG
cores=${STATIC_ncores}
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#----------------------------------------------------------------------------------------------------


# Download mesh files and generate graph partitions: ------------------------------------------------
#----------------------------------------------------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs
if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ]
then
   if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info ]
   then
      if [[ $MODERUN == "G" || $MODERUN == "R" ]]
      then
         echo -e "${GREEN}==>${NC} Downloading Global meshes tgz files ... \n"
         mkdir -p ${DATAIN}/fixed   
         cd ${DATAIN}/fixed
         if wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}.tar.gz
         then
            tar -xzvf x1.${RES}.tar.gz
            rm -fr x1.${RES}.tar.gz
	 else
            echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
            echo -e  "${RED}==>${NC} Make Static phase fails: Global file 'x1.${RES}.tar.gz' not found on 'MPAS atmosphere meshes site'.\n"
            echo -e  "${RED}==>${NC} Exiting script.\n"
            exit 1
	 fi
      else
         echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
         echo -e  "${RED}==>${NC} Make Static phase fails: Regional file 'x1.${RES}.graph.info' not found in '${DATAIN}/fixed'.\n"
         echo -e  "${RED}==>${NC} Exiting script.\n"
         exit 1
      fi
   fi
   echo -e "${GREEN}==>${NC} Creating x1.${RES}.graph.info.part.${cores} ... \n"
   cd ${DATAIN}/fixed
   source ${STOOLS}/cmd-gpmetis
   chmod 755 *
fi
#----------------------------------------------------------------------------------------------------


# Verify required files: ----------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
files_needed=("${EXECS}/init_atmosphere_model" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAIN}/fixed/x1.${RES}.grid.nc" "${SCRIPTS}/namelists/namelist.init_atmosphere.STATIC" "${SCRIPTS}/namelists/streams.init_atmosphere.STATIC")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit 1
  fi
done
#----------------------------------------------------------------------------------------------------


# Static phase: -------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
cp -f ${DATAIN}/fixed/*.TBL ${DIRRUN}
cp -f ${DATAIN}/fixed/*.GFS ${DIRRUN}
cp -f ${EXECS}/init_atmosphere_model ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.grid.nc ${DIRRUN}

sed -e "s,#GEODAT#,${GEODATA},g;s,#RES#,${RES},g" \
   ${SCRIPTS}/namelists/namelist.init_atmosphere.STATIC \
   > ${DIRRUN}/namelist.init_atmosphere

sed -e "s,#RES#,${RES},g" \
   ${SCRIPTS}/namelists/streams.init_atmosphere.STATIC \
   > ${DIRRUN}/streams.init_atmosphere

cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
mkdir -p ${DATAOUT}/logs
rm -f ${DIRRUN}/static.bash

source ${STOOLS}/2makestatic
chmod a+x ${DIRRUN}/static.bash
rm -fr ${DATAIN}/fixed/x1.${RES}.static.nc
rm -fr ${DATAIN}/fixed/x1.${RES}.ugwp_oro_data.nc

source ${STOOLS}/2runstatic
mv ${DIRRUN}/static.bash ${DATAOUT}/logs/
#----------------------------------------------------------------------------------------------------


# Verify static output files: -----------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
if [ -s ${DIRRUN}/x1.${RES}.static.nc ]
then
   mv ${DIRRUN}/x1.${RES}.static.nc ${DATAIN}/fixed
   chmod 755 ${DATAIN}/fixed/*
else
   echo -e  "${RED}==>${NC} File ${DIRRUN}/x1.${RES}.static.nc was not created. \n"
   exit 1
fi

#check config_native_gwd_gsl_static is true you need ugwp_oro_data.nc file
if grep -qE "^\s*config_native_gwd_gsl_static\s*=\s*true\s*(!.*)?$" ${SCRIPTS}/namelists/namelist.init_atmosphere.STATIC; then
    if [ -s ${DIRRUN}/x1.${RES}.ugwp_oro_data.nc ]; then
       mv ${DIRRUN}/x1.${RES}.ugwp_oro_data.nc ${DATAIN}/fixed
       chmod 755 ${DATAIN}/fixed/*
    else
       echo -e  "${RED}==>${NC} File ${DIRRUN}/x1.${RES}.ugwp_oro_data.nc was not created. \n"
       exit 1
    fi
else
    : #config_native_gwd_gsl_static is false
fi
#----------------------------------------------------------------------------------------------------


chmod -R 755 ${DATAOUT}/logs/*
rm -fr ${DIRRUN}

