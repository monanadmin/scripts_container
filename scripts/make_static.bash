#!/bin/bash 


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

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash


# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_container; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_container;   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=24
#-------------------------------------------------------


# Local variables--------------------------------------
GEODATA=${DATAIN}/WPS_GEOG
cores=${STATIC_ncores}
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
#-------------------------------------------------------


if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ]
then
   if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info ]
   then
      cd ${DATAIN}/fixed
      echo -e "${GREEN}==>${NC} downloading meshes tgz files ... \n"
      wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}.tar.gz --no-check-certificate
      wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}_static.tar.gz --no-check-certificate
      tar -xzvf x1.${RES}.tar.gz
      tar -xzvf x1.${RES}_static.tar.gz
   fi
   echo -e "${GREEN}==>${NC} Creating x1.${RES}.graph.info.part.${cores} ... \n"
   cd ${DATAIN}/fixed
   source ${STOOLS}/cmd-gpmetis
   rm -fr x1.${RES}.tar.gz x1.${RES}_static.tar.gz
fi



files_needed=("${EXECS}/init_atmosphere_model" "${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores}" "${DATAIN}/fixed/x1.${RES}.grid.nc" "${SCRIPTS}/namelists/namelist.init_atmosphere.STATIC" "${SCRIPTS}/namelists/streams.init_atmosphere.STATIC")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done

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


echo -e  "${GREEN}==>${NC} Executing sbatch static.bash...\n"
cd ${DIRRUN}
source ${STOOLS}/2runstatic
mv ${DIRRUN}/static.bash ${DATAOUT}/logs/


if [ -s ${DIRRUN}/x1.${RES}.static.nc ]
then
   mv ${DIRRUN}/x1.${RES}.static.nc ${DATAIN}/fixed
else
   echo -e  "${RED}==>${NC} File ${DIRRUN}/x1.${RES}.static.nc was not created. \n"
   exit -1
fi

rm -fr ${DIRRUN}

