#!/bin/bash
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

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash



# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_container; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_container;   mkdir -p ${DIRHOMED}  
export SCRIPTS=${DIRHOMES}/scripts;    mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024042000
FCST=${4};        #FCST=40
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Post/logs


# Local variables--------------------------------------
START_DATE_YYYYMMDD="${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}"
START_HH="${YYYYMMDDHHi:8:2}"
maxpostpernode=30    # <------ qtde max de convert_mpas por no!
VARTABLE=".OPER"
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
N_MODEL_LEV=55
#-------------------------------------------------------

# Variables for flex outpout interval from streams.atmosphere------------------------
t_strout=$(cat ${SCRIPTS}/namelists/streams.atmosphere.TEMPLATE | sed -n '/<stream name="diagnostics"/,/<\/stream>/s/.*output_interval="\([^"]*\)".*/\1/p')
t_stroutsec=$(echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
t_strouthor=$(echo "scale=4; (${t_stroutsec}/60)/60" | ${BC})
#------------------------------------------------------------------------------------

# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"

# Calculating default parameters for different resolutions
if [ $RES -eq 1024002 ]; then  #24Km
   NLAT=721  #180/0.25
   NLON=1441 #360/0.25
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 2621442 ]; then  #15Km
   NLAT=1201 #180/0.15
   NLON=2401 #360/0.15
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 2562 ]; then  #480Km
   NLAT=150 #180/1.2
   NLON=300 #360/1.2
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 40962 ]; then  #120Km
   NLAT=150 #180/1.2
   NLON=300 #360/1.2
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 5898242 ]; then  #10Km
   NLAT=1801 #180/0.10 (+1)
   NLON=3601 #360/0.10 (+1)
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
fi
#-------------------------------------------------------

# NLEVS get from t_iso_levels in Registry_isobaric.xml:
if [ -s ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml ]
then
   NLEV=$(grep "t_iso_levels" ${MONANDIR}/src/core_atmosphere/diagnostics/Registry_isobaric.xml | grep definition | cut -d\" -f4)
else
   NLEV=18
fi


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
