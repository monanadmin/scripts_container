#!/bin/bash 
umask 022

# Usage instructions: -------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
if [ $# -ne 4 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP RES_MESH LABELI FCST"
   echo ""
   echo "EXP         :: Initial or lateral boundary condition dataset (GFS or ERA)"
   echo "RES_MESH    :: Number of horizontal grid cells (global) or regional mesh identifier (e.g., 655362 for the ~30 km mesh)"
   echo "LABELI      :: Forecast initialization date and time (YYYYMMDDHH), e.g., 2026080100"
   echo "FCST        :: Forecast length in hours (e.g., 24, 36, 48, etc.)"
   echo ""
   echo "Example of a 24-hour forecast:"
   echo "${0} GFS 655362 2026080100 24"
   echo ""
   exit
fi
#----------------------------------------------------------------------------------------------------


# Load the MONAN environment configuration: ---------------------------------------------------------
#----------------------------------------------------------------------------------------------------
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

echo ""
echo "---- Make LBCs ----"
echo ""
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
yyyymmddi=${YYYYMMDDHHi:0:8}
hhi=${YYYYMMDDHHi:8:2}
yyyymmddhhf=$(date +"%Y%m%d%H" -d "${yyyymmddi} ${hhi}:00 ${FCST} hours" )
final_date=${yyyymmddhhf:0:4}-${yyyymmddhhf:4:2}-${yyyymmddhhf:6:2}_${yyyymmddhhf:8:2}:00:00
GEODATA=${DATAIN}/WPS_GEOG
cores=${LBCS_ncores}
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
            echo -e  "${RED}==>${NC} Make LBCs phase fails: Global file 'x1.${RES}.tar.gz' not found on 'MPAS atmosphere meshes site'.\n"
            echo -e  "${RED}==>${NC} Exiting script.\n"
            exit 1
         fi
      else
         echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
         echo -e  "${RED}==>${NC} Make LBCs phase fails: Regional file 'x1.${RES}.graph.info' not found in '${DATAIN}/fixed.'\n"
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
files_needed=("${SCRIPTS}/namelists/namelist.init_atmosphere.LBCS" "${SCRIPTS}/namelists/streams.init_atmosphere.LBCS" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc" "${EXECS}/init_atmosphere_model")
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


# LBCs phase: ---------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
sed -e "s,#LABELI#,${start_date},g;s,#LABELF#,${final_date},g;s,#GEODAT#,${GEODATA},g;s,#LBCINT#,${LBCINT},g;s,#RES#,${RES},g;s,#EXP#,${EXP},g" \
	 ${SCRIPTS}/namelists/namelist.init_atmosphere.LBCS > ${DIRRUN}/namelist.init_atmosphere

sed -e "s,#RES#,${RES},g;s,#LBCINT#,${LBCINT},g" \
    ${SCRIPTS}/namelists/streams.init_atmosphere.LBCS > ${DIRRUN}/streams.init_atmosphere

cp -f ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${DIRRUN}
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ${DIRRUN}
cp -f ${DATAOUT}/${YYYYMMDDHHi}/Pre/${EXP}\:* ${DIRRUN}
cp -f ${EXECS}/init_atmosphere_model ${DIRRUN}

cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}

rm -f ${DIRRUN}/lbcs.bash 
source ${STOOLS}/2make_lbcs
chmod a+x ${DIRRUN}/lbcs.bash

source ${STOOLS}/2run_lbcs
mv ${DIRRUN}/lbcs.bash ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs
#----------------------------------------------------------------------------------------------------


# Verify lbcs files: --------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
if [ -z "$(ls ${DATAOUT}/${YYYYMMDDHHi}/Pre/lbc* 2>/dev/null)" ]
then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} LBC phase fails! Check logs at ${DATAOUT}/${YYYYMMDDHHi}/Pre/logs/lbcs.* .\n"
  echo -e  "${RED}==>${NC} Exiting script. \n"
  exit 1
fi
#----------------------------------------------------------------------------------------------------


chmod -R 755 ${DATAOUT}/${YYYYMMDDHHi}/Pre/*
rm -fr ${DIRRUN}

