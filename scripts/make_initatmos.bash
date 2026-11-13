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
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
GEODATA=${DATAIN}/WPS_GEOG
cores=${INITATMOS_ncores}
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
         echo -e "${GREEN}==>${NC} downloading meshes tgz files ... \n"
         cd ${DATAIN}/fixed
         if wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}.tar.gz
         then
            tar -xzvf x1.${RES}.tar.gz
            rm -fr x1.${RES}.tar.gz
         else
            echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
            echo -e  "${RED}==>${NC} Make Init Atmosphere phase fails: Global file 'x1.${RES}.tar.gz' not found on 'MPAS atmosphere meshes site'.\n"
            echo -e  "${RED}==>${NC} Exiting script.\n"
            exit 1
         fi
      else
         echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
         echo -e  "${RED}==>${NC} Make Init Atmosphere phase fails: Regional file 'x1.${RES}.graph.info' not found in '${DATAIN}/fixed.'\n"
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
if grep -qE "^\s*config_native_gwd_gsl_static\s*=\s*true\s*(!.*)?$" ${SCRIPTS}/namelists/namelist.init_atmosphere.STATIC; then
    files_needed=("${SCRIPTS}/namelists/namelist.init_atmosphere.TEMPLATE" "${SCRIPTS}/namelists/streams.init_atmosphere.TEMPLATE" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAIN}/fixed/x1.${RES}.ugwp_oro_data.nc" "${DATAOUT}/${YYYYMMDDHHi}/Pre/${EXP}:${start_date:0:13}" "${EXECS}/init_atmosphere_model")
else
    files_needed=("${SCRIPTS}/namelists/namelist.init_atmosphere.TEMPLATE" "${SCRIPTS}/namelists/streams.init_atmosphere.TEMPLATE" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAIN}/fixed/x1.${RES}.static.nc" "${DATAOUT}/${YYYYMMDDHHi}/Pre/${EXP}:${start_date:0:13}" "${EXECS}/init_atmosphere_model")
fi

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


# Set BLEND_BDY_TERRAIN according to simulation mode: -----------------------------------------------
#----------------------------------------------------------------------------------------------------
if [[ $MODERUN == "R" ]]; then
   BLEND_BDY_TERRAIN=true
   echo -e "\nInit_atmos is running in Regional (limited-area) mode.\n"
elif [[ $MODERUN == "G" ]]; then
   BLEND_BDY_TERRAIN=false
   echo -e "\nInit_atmos is running in Global mode.\n"
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Init_atmos fails! Please select MODERUN=R (Regional) or MODERUN=G (Global) in 'setenv.bash'.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit 1
fi
#----------------------------------------------------------------------------------------------------


# Init_atmosphere phase: ----------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
sed -e "s,#LABELI#,${start_date},g;s,#GEODAT#,${GEODATA},g;s,#RES#,${RES},g;s,#EXP#,${EXP},g;s,#BLEND_BDY_TERRAIN#,${BLEND_BDY_TERRAIN},g" \
    ${SCRIPTS}/namelists/namelist.init_atmosphere.TEMPLATE > ${DIRRUN}/namelist.init_atmosphere

sed -e "s,#RES#,${RES},g" \
    ${SCRIPTS}/namelists/streams.init_atmosphere.TEMPLATE > ${DIRRUN}/streams.init_atmosphere

cp -f ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${DIRRUN}
cp -f ${DATAIN}/fixed/x1.${RES}.static.nc ${DIRRUN}
cp -f ${DATAIN}/fixed/QNWFA_QNIFA_SIGMA_MONTHLY.dat ${DIRRUN}
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Pre/${EXP}\:${start_date:0:13} ${DIRRUN}
cp -f ${EXECS}/init_atmosphere_model ${DIRRUN}
cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}

chmod 755 ${DIRRUN}/*
chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Pre/*

rm -f ${DIRRUN}/initatmos.bash 

source ${STOOLS}/2makeinitatmos
chmod a+x ${DIRRUN}/initatmos.bash

source ${STOOLS}/2runinitatmos
mv ${DIRRUN}/initatmos.bash ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs
#----------------------------------------------------------------------------------------------------


# Verify init_atmosphere output file: ---------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
if [ ! -s ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ]
then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} Init Atmosphere phase fails! Check logs at ${DATAOUT}/logs/initatmos.* .\n"
  echo -e  "${RED}==>${NC} Exiting script. \n"
  exit -1
fi
#----------------------------------------------------------------------------------------------------


chmod -R 755 ${DATAOUT}/${YYYYMMDDHHi}/Pre/*
rm -fr ${DIRRUN}

