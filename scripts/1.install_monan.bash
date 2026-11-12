#!/bin/bash 

#-----------------------------------------------------------------------------#
# !SCRIPT: install_monan
#
# !DESCRIPTION:
#     Script to install the MONAN model and convert_MPAS.
#     
#     Performs the following tasks:
# 
#        o Clone the Monan model github repository in a local directory
#        o Make the script make-all.sh that compiles the Atmosphere Model and the Init Atmosphere Model
#        o As alternative for advanced users, this script creates a simple compile script that just compile the Atmosphere Model
#        o Clone the Convert_mpas tool from the monanadmin repository for convert the output model files in lat-lon grid.
#        o Compile the convert_mpas
#
#-----------------------------------------------------------------------------#


# Fixed parameters: ---------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
github_link_CONVERT_MPAS="https://github.com/monanadmin/convert_mpas.git"
#----------------------------------------------------------------------------------------------------


# Functions: ----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
function checkout_system() {
  local source_dir=$1
  local github_link=$2
  local tag_or_branch_name=$3
  if [ -d "${source_dir}" ]; then
      echo -e  "${GREEN}==>${NC} Source dir already exists, updating it ...\n"
  else
      echo -e  "${GREEN}==>${NC} Cloning your fork repository...\n"
      git clone ${github_link} ${source_dir}
      if [ ! -d "${source_dir}" ]; then
          echo -e "${RED}==>${NC} An error occurred while cloning your fork. Possible causes:  wrong URL, user or password.\n"
          exit -1
      fi
  fi

  cd ${source_dir}
  if git checkout "${tag_or_branch_name}" 2>/dev/null; then
      git pull
      echo -e "${GREEN}==>${NC} Successfully checked out and updated: ${BLUE}${tag_or_branch_name}"
  else
      echo -e "${RED}==>${NC} Failed to check out branch: ${BLUE}${tag_or_branch_name}"
      echo -e "${RED}==>${NC} Please check if you have this branch. Exiting ..."
      exit -1
  fi
  git log | head -1
}

get_github_file() {
    local repo="$1"
    local branch="$2"
    local file="$3"
    repo="${repo%.git}"
    repo="${repo#https://github.com/}"
    curl -fsSL "https://raw.githubusercontent.com/${repo}/${branch}/${file}"
}
#----------------------------------------------------------------------------------------------------


# Usage instructions: -------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
if [ $# -lt 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} [G] [M] [C]"
   echo ""
   echo "G   :: MONAN GitHub link of your personal fork, eg: https://github.com/MYUSER/MONAN-Model.git"
   echo "M   :: MONAN tag or branch name of your personal fork. (will be used 'develop' if not informed)" 
   echo "C   :: Convert_MPAS tag from ${github_link_CONVERT_MPAS} (will be used 'develop' if not informed)"
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
DIRHOMES=${DIR_SCRIPTS}/scripts_container;  mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_container;    mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;            mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;              mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;            mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;            mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;                mkdir -p ${EXECS}
#----------------------------------------------------------------------------------------------------


# Input variables: ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
github_link_MONAN=${1};   #github_link=https://github.com/monanadmin/MONAN-Model.git
tag_or_branch_name_MONAN=${2}
tag_or_branch_name_MONAN=${tag_or_branch_name_MONAN:="release/1.3.1-rc"}
echo "MONAN branch name in use: ${tag_or_branch_name_MONAN}"

tag_or_branch_name_CONVERT_MPAS=${3}
tag_or_branch_name_CONVERT_MPAS=${tag_or_branch_name_CONVERT_MPAS:="1.1.0"}
echo "convert_mpas branch name in use: ${tag_or_branch_name_CONVERT_MPAS}"
#----------------------------------------------------------------------------------------------------


# Local variables: ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
MONANDIR=${SOURCES}/MONAN-Model_${tag_or_branch_name_MONAN}
CONVERT_MPAS_DIR=${SOURCES}/convert_mpas_${tag_or_branch_name_CONVERT_MPAS}
DATE_TIME_NOW=$(date +"%Y%m%d%H%M%S")
CDCTVERSION=$(head -n 1 ${DIRHOMES}/VERSION.txt | xargs)
$(sed -i "s;MONANDIR=.*$;MONANDIR=$MONANDIR;" ${STOOLS}/setenv)
#----------------------------------------------------------------------------------------------------


# Check MONAN version first local and next github file: ---------------------------------------------
#----------------------------------------------------------------------------------------------------
if [ -f $MONANDIR/VERSION.txt ]; then
    MONANVERSION=$(head -n 1 $MONANDIR/VERSION.txt)
elif ! MONANVERSION=$(get_github_file "${github_link_MONAN}" "${tag_or_branch_name_MONAN}" "VERSION.txt"); then
    echo -e "\n${RED}==>${NC} FAIL! Unable to retrieve MONAN version file from GitHub, check:"
    echo -e "- Repository:${NC} ${github_link_MONAN}"
    echo -e "- Branch/Tag:${NC} ${tag_or_branch_name_MONAN}\n"
    exit 1
fi
#----------------------------------------------------------------------------------------------------


# Check compatible Scritps_CD-CT x MONAN-Model: -----------------------------------------------------
#----------------------------------------------------------------------------------------------------
echo ""
echo "*********************************************************************************"
echo "* ATTENTION:                                                                    *"
echo "*********************************************************************************"
echo "*                    scripts_CD-CT / MONAN-Model Compatibility                  *"
echo "*********************************************************************************"
echo "*                                                                               *"
echo "*    scripts_CD-CT Version        Compatible MONAN-Model Version                *"
echo "*    ---------------------------  --------------------------------              *"
echo "*    (...)                        (...)                                         *"
echo "*    1.4.0                        1.4.3-rc                                      *"
echo "*    1.4.1                        1.4.4                                         *"
echo "*    1.5.0                        2.0.0-rc                                      *"
echo "*    1.6.0                        1.4.3-rc, 1.4.4, 1.4.5, 2.0.0-rc and develop  *"
echo "*                                                                               *"
echo "*********************************************************************************"
echo ""
echo -e "Your MONAN-Model Version = ${MONANVERSION} -> using the tag/branch: ${tag_or_branch_name_MONAN}"
echo -e "Your Scripts_CD-CT Version = ${CDCTVERSION} -> using the tag/branch: $(git describe --tags --exact-match 2>/dev/null || git branch --show-current)"
echo ""
echo -e "${GREEN}==>${NC} Check compatibility: Scripts_CD-CT x MONAN-Model...\n"
if [ ! -d ${SCRIPTS}/namelists/${MONANVERSION} ]; then
    echo -e "${RED}==>${NC} FAIL! 'Scripts_CD-CT' and 'MONAN-Model' versions are incompatible.\n"
    exit 1
else
    echo -e "${GREEN}==>${NC} Compatibility OK.\n"
fi
#----------------------------------------------------------------------------------------------------


# Copy namelists compatible version: ----------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
echo -e "${GREEN}==>${NC} Copying 'namelists' for the corresponding 'MONAN-Model' x 'Scripts_CD-CT' versions...\n"
if [ ! -f ${SCRIPTS}/namelists/NMLVERSION.txt ]; then
    #---first time -> copy all
    cp -r ${SCRIPTS}/namelists/${MONANVERSION}/* ${SCRIPTS}/namelists/
    echo -e "${MONANVERSION}" > ${SCRIPTS}/namelists/NMLVERSION.txt
    echo -e "Copied all namelist files for the first time.\n"
else
    NMLVERSION=$(head -n 1 ${SCRIPTS}/namelists/NMLVERSION.txt | xargs)
    if [ ${MONANVERSION} == ${NMLVERSION} ]; then
        #---other times with same version -> preserve user files
        cp -u ${SCRIPTS}/namelists/${MONANVERSION}/* ${SCRIPTS}/namelists/
        echo -e "${MONANVERSION}" > ${SCRIPTS}/namelists/NMLVERSION.txt
        echo -e "User-modified files preserved; only new/updated namelist files copied.\n"
    else
  #--- MONAN-Model version changed -> force full copy and preserve user-modified files in the backup folder
        if diff -rq "${SCRIPTS}/namelists/${NMLVERSION}" "${SCRIPTS}/namelists/" 2>/dev/null | grep -q "differ"; then
            mkdir -p ${SCRIPTS}/namelists/${NMLVERSION}.user.bkp.${DATE_TIME_NOW}
            for f in ${SCRIPTS}/namelists/${NMLVERSION}/*; do
                fname=$(basename "$f")
                [ -f "${SCRIPTS}/namelists/${fname}" ] && cp "${SCRIPTS}/namelists/${fname}" "${SCRIPTS}/namelists/${NMLVERSION}.user.bkp.${DATE_TIME_NOW}/"
            done
            echo -e "Created 'user backup folder' with modified namelist files."
        else
            echo -e "No user modifications. Backup not required."
        fi
        cp -r ${SCRIPTS}/namelists/${MONANVERSION}/* ${SCRIPTS}/namelists/
        echo -e "${MONANVERSION}" > ${SCRIPTS}/namelists/NMLVERSION.txt
  echo -e "MONAN-Model version changed; copied all namelist files and preserved user-modified files, if any, in the 'user' backup folder.\n"
    fi
fi
#----------------------------------------------------------------------------------------------------


checkout_system ${MONANDIR} ${github_link_MONAN} ${tag_or_branch_name_MONAN}
checkout_system ${CONVERT_MPAS_DIR} ${github_link_CONVERT_MPAS} ${tag_or_branch_name_CONVERT_MPAS}

rm -rf $MONANDIR/default_inputs/ $MONANDIR/src/core_atmosphere/physics/physics_wrf/files
rm -f  $MONANDIR/stream_list.* $MONANDIR/streams.* $MONANDIR/namelist.* 
rm -f  $MONANDIR/make*.output.atmosphere $MONANDIR/make*.output.init_atmosphere $MONANDIR/make-all.sh
rm -fr $MONANDIR/src/core_atmosphere/inc $MONANDIR/src/core_init_atmosphere/inc


#Download automatico do .SIF
#if [[ "${MACHINE}" == *SIF && ! -f "${DIR_SCRIPTS}/monan.sif" ]]; then
#    if [[ "${MACHINE}" == "pomerodeSIF" ]]; then
#        echo -e "${GREEN}==>${NC} downloading Pomerode container from dataserver......\n"
#        wget -O "${DIR_SCRIPTS}/monan.sif" "https://dataserver.cptec.inpe.br/dataserver_dimnt/monan/CONTAINER_DATA/monan-nvhpc25.11_X64.sif"
#    elif [[ "${MACHINE}" == "desktopSIF" && ( "$(uname -m)" == "arm64" || "$(uname -m)" == "aarch64" ) ]]; then
#        echo -e "${GREEN}==>${NC} downloading ARM64 container from dataserver......\n"
#        wget -O "${DIR_SCRIPTS}/monan.sif" "https://dataserver.cptec.inpe.br/dataserver_dimnt/monan/CONTAINER_DATA/monan-mpich4.3.0_ARM64.sif"
#    else
#        echo -e "${GREEN}==>${NC} downloading container from dataserver......\n"
#        wget -O "${DIR_SCRIPTS}/monan.sif" "https://dataserver.cptec.inpe.br/dataserver_dimnt/monan/CONTAINER_DATA/monan.sif"
#    fi
#fi


# Installing atmosphere_model, init_atmosphere_model and convert_mpas: ------------------------------
#----------------------------------------------------------------------------------------------------
echo ""
echo -e  "${GREEN}==>${NC} Making compile script...\n"

cd $MONANDIR

source ${STOOLS}/1makeinstall
chmod a+x make-all.sh

echo ""
echo -e  "${GREEN}==>${NC} Installing init_atmosphere_model and atmosphere_model...\n"
echo ""
# install monan model
source ${STOOLS}/1compile_monan

cd ${CONVERT_MPAS_DIR}
echo ""
echo -e  "${GREEN}==>${NC} Installing convert_mpas...\n"
# install convert_mpas
source ${STOOLS}/1compile_convertmpas
#----------------------------------------------------------------------------------------------------


# Copy and verify executable files: -----------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
mv ${CONVERT_MPAS_DIR}/convert_mpas ${EXECS}/
cp ${CONVERT_MPAS_DIR}/VERSION.txt ${EXECS}/CONVMPAS-VERSION.txt

all_exec_files=(
    "atmosphere_model"
    "build_tables"
    "init_atmosphere_model"
    "convert_mpas"
)

for exec_file in "${all_exec_files[@]}"
do
    if [ -s "${EXECS}/${exec_file}" ]; then
        echo ""
        echo -e "${GREEN}==>${NC} ${exec_file} generated successfully and copied to ${EXECS}!"
        echo ""
    else
        echo -e "${RED}==>${NC} !!! ERROR: ${exec_file} was not generated or is empty. Check build output."
        exit 1
    fi
done
#----------------------------------------------------------------------------------------------------


echo -e "\n$(basename "$0") completed successfully.\n"

