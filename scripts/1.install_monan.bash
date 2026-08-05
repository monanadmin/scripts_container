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

#Fixed parameters ------------------------------------------------------------#
github_link_CONVERT_MPAS="https://github.com/monanadmin/convert_mpas.git"
#-----------------------------------------------------------------------------#

#Functions -------------------------------------------------------------------#
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
#-----------------------------------------------------------------------------#


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


# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash

# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_container;  mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_container;    mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;            mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;              mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;            mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;            mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;                mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:-----------------------------------------------------
github_link_MONAN=${1};   #github_link=https://github.com/monanadmin/MONAN-Model.git
tag_or_branch_name_MONAN=${2}
tag_or_branch_name_MONAN=${tag_or_branch_name_MONAN:="release/1.3.1-rc"}
echo "MONAN branch name in use: ${tag_or_branch_name_MONAN}"

tag_or_branch_name_CONVERT_MPAS=${3}
tag_or_branch_name_CONVERT_MPAS=${tag_or_branch_name_CONVERT_MPAS:="1.1.0"}
echo "convert_mpas branch name in use: ${tag_or_branch_name_CONVERT_MPAS}"
#----------------------------------------------------------------------


# Local variables:-----------------------------------------------------
MONANDIR=${SOURCES}/MONAN-Model_${tag_or_branch_name_MONAN}
CONVERT_MPAS_DIR=${SOURCES}/convert_mpas_${tag_or_branch_name_CONVERT_MPAS}
$(sed -i "s;MONANDIR=.*$;MONANDIR=$MONANDIR;" setenv.bash)
#----------------------------------------------------------------------

#=====================================================================================
#
# ATTENTION, please:
# 
# scripts_container versions up to 1.1.0 run MONAN-Model versions up to 1.3.0
#
# scripts_container versions 1.2.0 onwards run MONAN-Model versions 1.3.1 onwards
#
#=====================================================================================

# Just making sure you will install the correct MONAN-model version,
#  for this version of scripts-CD-CT version:

echo ""
echo "********************************************************************************"
echo "*"
echo "* ATTENTION, please:"
echo "*"
echo "* scripts_container versions up to 1.1.0 run MONAN-Model only versions up to 1.3.0"
echo "*"
echo "* scripts_container versions 1.2.0 onwards run MONAN-Model only versions 1.3.1 onwards"
echo "*"
echo "********************************************************************************"

echo ""
echo -e "${GREEN}==>${NC} tag_or_branch_name_MONAN = ${tag_or_branch_name_MONAN}"
echo ""
read -p "Are you sure you are installing the right versions scripts x MONAN-Model ? [Y/n]" confirma
confirma=${confirma:-Y}

if [[ "${confirma}" =~ ^[Yy]$ ]]
then
   echo ""
   echo -e "${GREEN}==>${NC} OK, so keep going."
   echo ""
else
   echo ""
   echo -e "    ${RED}==>${NC} Please, make the right versions and try again."
   exit
   echo ""
fi


checkout_system ${MONANDIR} ${github_link_MONAN} ${tag_or_branch_name_MONAN}
checkout_system ${CONVERT_MPAS_DIR} ${github_link_CONVERT_MPAS} ${tag_or_branch_name_CONVERT_MPAS}

rm -rf $MONANDIR/default_inputs/ $MONANDIR/src/core_atmosphere/physics/physics_wrf/files
rm -f  $MONANDIR/stream_list.* $MONANDIR/streams.* $MONANDIR/namelist.* 
rm -f  $MONANDIR/make*.output.atmosphere $MONANDIR/make*.output.init_atmosphere $MONANDIR/make-all.sh
rm -fr $MONANDIR/src/core_atmosphere/inc $MONANDIR/src/core_init_atmosphere/inc


#CR: TODO: maybe later move this make script to main scripts directory.
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


#CR: TODO: put verify here if executable was created ok
mv ${CONVERT_MPAS_DIR}/convert_mpas ${EXECS}/
cp ${CONVERT_MPAS_DIR}/VERSION.txt ${EXECS}/CONVMPAS-VERSION.txt


if [ -s "${EXECS}/convert_mpas" ] ; then
    echo ""
    echo -e "${GREEN}==>${NC} File convert_mpas generated Sucessfully in ${CONVERT_MPAS_DIR} and copied to ${EXECS} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during convert_mpas build. Check output"
    exit -1
fi

