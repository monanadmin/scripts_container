#!/bin/bash
umask 022

#-----------------------------------------------------------------------------#
# !SCRIPT: run_post
#
# !DESCRIPTION:
#     Script to run the pos-processing of MONAN model over the forecast horizon.
#     
#     Performs the following tasks:
# 
#        o VCheck all input files before
#        o Creates the submition script
#        o Submit the post
#        o Veriffy all files generated
#        
#
#-----------------------------------------------------------------------------#

# Usage instructions: -------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
if [ $# -ne 4 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} ]EXP_NAME/OP] RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} GFS 1024002 2024010100 24"
   echo "${0} GFS   40962 2024010100 48"
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
echo "---- Run Post ----"
echo ""
#----------------------------------------------------------------------------------------------------


# Input variables: ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024042000
FCST=${4};        #FCST=40
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
#----------------------------------------------------------------------------------------------------


# Local variables: ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
START_DATE_YYYYMMDD="${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}"
START_HH="${YYYYMMDDHHi:8:2}"
maxpostpernode=30    # <------ qtde max de convert_mpas por no!
VARTABLE=".OPER"
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
N_MODEL_LEV=55
NLEV=18
#----------------------------------------------------------------------------------------------------


# Variables for flex outpout interval from streams.atmosphere: --------------------------------------
#----------------------------------------------------------------------------------------------------
t_strout=$(cat ${SCRIPTS}/namelists/streams.atmosphere.TEMPLATE | sed -n '/<stream name="diagnostics"/,/<\/stream>/s/.*output_interval="\([^"]*\)".*/\1/p')
t_stroutsec=$(echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
t_strouthor=$(echo "scale=4; (${t_stroutsec}/60)/60" | ${BC})
#----------------------------------------------------------------------------------------------------


# Set G (global) or R (regional) for MONAN_DIAG output filenames: -----------------------------------
#----------------------------------------------------------------------------------------------------
if [[ $MODERUN == "R" ]]; then
   RORG=R
   echo -e "Post is running in Regional (limited-area) mode.\n"
elif [[ $MODERUN == "G" ]]; then
   RORG=G
   echo -e "Post is running in Global mode.\n"
else
   echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"
   echo -e  "${RED}==>${NC} Post fails! Please select MODERUN=R (Regional) or MODERUN=G (Global) in 'setenv.bash'.\n"
   echo -e  "${RED}==>${NC} Exiting script. \n"
   exit 1
fi
#----------------------------------------------------------------------------------------------------


# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"


# Calculating default parameters for different resolutions: -----------------------------------------
#----------------------------------------------------------------------------------------------------
# GLOBAL mesh
if [[ "$RES" == "2562" ]]; then        # 480 Km
   NLAT=46  #180/4 + 1
   NLON=91 #360/4 + 1
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "10242" ]]; then     # 240 Km
   NLAT=91  #180/2 + 1
   NLON=181 #360/2 + 1
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "40962" ]]; then     # 120 Km
   NLAT=181 #180/1 + 1
   NLON=361 #360/1 + 1
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "163842" ]]; then    # 60 Km
   NLAT=361 #180/0.5 + 1
   NLON=721 #360/0.5 + 1
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "655362" ]]; then    # 30 Km
   NLAT=721 #180/0.25 + 1
   NLON=1441 #360/0.25 + 1
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "1024002" ]]; then   # 24 Km
   NLAT=901 #180/0.2 + 1
   NLON=1801 #360/0.2 + 1
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "2621442" ]]; then   # 15 Km
   NLAT=1441 #180/0.125 + 1
   NLON=2881 #360/0.125 + 1
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "5898242" ]]; then   # 10 Km
   NLAT=2161 #180/0.0833 +1
   NLON=4321 #360/0.0833 +1
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "23592962" ]]; then  # 5 Km
   NLAT=3601 #180/0.05
   NLON=7201 #360/0.05
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [[ "$RES" == "65536002" ]]; then  # 3 Km
   NLAT=7201 #180/0.025 +1
   NLON=14401 #360/0.025 +1
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0

# REGIONAL mesh
elif [[ "$RES" == "30km_LAC" ]]; then #30 km (AMS + Caribe)
   NLAT=354     #106/0.3 +1
   NLON=301     #90/0.3 +1
   STARTLAT=-64.0
   ENDLAT=42
   STARTLON=254.0
   ENDLON=344.0
elif [[ "$RES" == "10km_LAC" ]]; then #10 km (AMS + Caribe)
   NLAT=1061   #106/0.1 +1
   NLON=901   #90/0.1 +1
   STARTLAT=-64.0
   ENDLAT=42.0
   STARTLON=254.0
   ENDLON=344.0
elif [[ "$RES" == "05km_LAC" ]]; then #5 km (AMS + Caribe)
   NLAT=2121    #106/0.05 +1
   NLON=1801    #90/0.05 +1
   STARTLAT=-64.0
   ENDLAT=42.0
   STARTLON=254.0
   ENDLON=344.0
else

   # Define convert_mpas target domain automatically from the grid file
   echo -e "Calculating convert_mpas target domain of personalized mesh...\n"
   GRIDFILE="${DATAIN}/fixed/x1.${RES}.grid.nc"
   MESH_RES_RAD=$(ncdump -v nominalMinDc "${GRIDFILE}" 2>/dev/null | awk '/nominalMinDc =/ {print $3; exit}')
   MESH_RES_KM=$(awk -v res="${MESH_RES_RAD}" 'BEGIN {printf "%.0f", res * 6371.0}')
   # Domain margin ("gordura")
   DOMAIN_MARGIN=2
   GRID_SPACING=$(awk -v res="${MESH_RES_KM}" 'BEGIN {printf "%.1f", res / 100.0}')
   # Get minimum and maximum cell-center coordinates
   LAT_MIN_RAD=$(cdo -s infon -selname,latCell "${GRIDFILE}" 2>/dev/null | awk '/latCell/ {print $9; exit}')
   LAT_MAX_RAD=$(cdo -s infon -selname,latCell "${GRIDFILE}" 2>/dev/null | awk '/latCell/ {print $11; exit}')
   LON_MIN_RAD=$(cdo -s infon -selname,lonCell "${GRIDFILE}" 2>/dev/null | awk '/lonCell/ {print $9; exit}')
   LON_MAX_RAD=$(cdo -s infon -selname,lonCell "${GRIDFILE}" 2>/dev/null | awk '/lonCell/ {print $11; exit}')
   # Convert radians to degrees
   RAD2DEG=57.29577951308232
   LAT_MIN=$(awk -v x="${LAT_MIN_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   LAT_MAX=$(awk -v x="${LAT_MAX_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   LON_MIN=$(awk -v x="${LON_MIN_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   LON_MAX=$(awk -v x="${LON_MAX_RAD}" -v c="${RAD2DEG}" 'BEGIN {printf "%.1f", x*c}')
   # Add domain margin ("gordura")
   STARTLAT=$(awk -v x="${LAT_MIN}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x-m}')
   ENDLAT=$(awk -v x="${LAT_MAX}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x+m}')
   STARTLON=$(awk -v x="${LON_MIN}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x-m}')
   ENDLON=$(awk -v x="${LON_MAX}" -v m="${DOMAIN_MARGIN}" 'BEGIN {printf "%.1f", x+m}')
   # Number of intervals in the regular lat-lon grid.
   NLAT=$(awk -v start="${STARTLAT}" -v end="${ENDLAT}" -v d="${GRID_SPACING}" 'BEGIN {printf "%.0f", (end-start)/d}')
   NLON=$(awk -v start="${STARTLON}" -v end="${ENDLON}" -v d="${GRID_SPACING}" 'BEGIN {printf "%.0f", (end-start)/d}')
   echo -e "  Resolution     : ${MESH_RES_KM} km"
   echo -e "  STARTLAT       : ${STARTLAT}"
   echo -e "  ENDLAT         : ${ENDLAT}"
   echo -e "  STARTLON       : ${STARTLON}"
   echo -e "  ENDLON         : ${ENDLON}"
   echo -e "  NLAT           : ${NLAT}"
   echo -e "  NLON           : ${NLON}\n"
fi
#----------------------------------------------------------------------------------------------------


# NLEVS get from t_iso_levels in Registry_isobaric.xml:
if [ -s ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml ]
then
   NLEV=$(grep "t_iso_levels" ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml | grep definition | cut -d\" -f4)
else
   NLEV=18
fi


# Verify required files: ----------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
files_needed=("${SCRIPTS}/namelists/include_fields.diag${VARTABLE}" "${SCRIPTS}/namelists/convert_mpas.nml" "${SCRIPTS}/namelists/target_domain.TEMPLATE" "${EXECS}/convert_mpas" "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done
#----------------------------------------------------------------------------------------------------


# Post phase: ---------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
# Captura quantos arquivos do modelo tiverem para serem pos-processados e
# quando nos serao necessarios para executar ${maxpostpernode} convert_mpas por no:
#nfiles=$(ls -l ${DATAOUT}/${YYYYMMDDHHi}/Model/MONAN*nc | wc -l)
# from streams.atmosphere.TEMPLATE in diagnostics the output_interval is flexible
output_interval=${t_strouthor}
#nfiles=FCST/output_interval + 1(time zero file)
nfiles=$(echo "$FCST/$output_interval + 1" | ${BC})
echo "${nfiles} post to submit."
echo "Max ${maxpostpernode} submits per nodes."
how_many_nodes ${nfiles} ${maxpostpernode}

# Cria os diretorios e arquivos/links para cada saida do convert_mpas:
cd ${DIRRUN}
#cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}
for ii in $(seq 1 ${nfiles})
do
   i=$(printf "%04d" ${ii})
   mkdir -p ${DIRRUN}/dir.${i}
   #cp -f ${SCRIPTS}/setenv.bash ${DIRRUN}/dir.${i}
   cp -f ${SCRIPTS}/namelists/include_fields.diag${VARTABLE}  ${DIRRUN}/dir.${i}/include_fields.diag${VARTABLE}
   cp -f ${DIRRUN}/dir.${i}/include_fields.diag${VARTABLE} ${DIRRUN}/dir.${i}/include_fields
   sed -e "s,#NISOLEV#,${NLEV},g;s,#NMODELLEV#,${N_MODEL_LEV},g" \
      ${SCRIPTS}/namelists/convert_mpas.nml > ${DIRRUN}/dir.${i}/convert_mpas.nml
   sed -e "s,#NLAT#,${NLAT},g;s,#NLON#,${NLON},g;s,#STARTLAT#,${STARTLAT},g;s,#ENDLAT#,${ENDLAT},g;s,#STARTLON#,${STARTLON},g;s,#ENDLON#,${ENDLON},g;" \
      ${SCRIPTS}/namelists/target_domain.TEMPLATE > ${DIRRUN}/dir.${i}/target_domain

done

cd ${DIRRUN}

# Laco para criar os arquivos de submissao com os blocos de convertmpas para cada node:
node=1
inicio=1   
fim=$((maxpostpernode <= nfiles ? maxpostpernode : nfiles))
while [ ${inicio} -le ${nfiles} ]
do
   rm -f ${DIRRUN}/PostAtmos_node.${node}.sh
   source ${STOOLS}/4makepost1

   chmod a+x ${DIRRUN}/PostAtmos_node.${node}.sh
   cp -f ${DIRRUN}/PostAtmos_node.${node}.sh ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
   source ${STOOLS}/4runpost1
   echo "JobId node ${node} = ${jobid[${node}]} , convert_mpas ${inicio} to ${fim}"
  
   inicio=$((fim + 1))
   temp=$((fim + maxpostpernode))
   fim=$(( temp < nfiles ? temp : nfiles ))
   node=$((node+1))
   sleep 5
done




# Dependencias JobId:
dependency="afterok"
for job_id in "${jobid[@]}"
do
   dependency="${dependency}:${job_id}"
done


# Script final , para conferir todos os arquivos, criar o template final  e apagar o diretorio DIRRUN
node=0
rm -f ${DIRRUN}/PostAtmos_node.${node}.sh
source ${STOOLS}/4makepost0
chmod a+x ${DIRRUN}/PostAtmos_node.${node}.sh
source ${STOOLS}/4runpost0

#CR: passar este scriptpara dentro do script PostAtmos_node.0.sh, submetido.
cd ${SCRIPTS}
time ${SCRIPTS}/make_template.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
