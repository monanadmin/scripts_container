#!/bin/bash
set -e
trap 'echo -e "\n${RED}==>${NC} $(basename "$0") failed.\n"' ERR


# Load the MONAN environment configuration: ---------------------------------------------------------
#----------------------------------------------------------------------------------------------------
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash
#----------------------------------------------------------------------------------------------------


# Input variables: ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------
github_link="https://github.com/monanadmin/MONAN-Model.git"   # Switch to your fork when you need to make changes or develop the model.
monan_branch=1.4.4
convertmpas_branch=1.2.0
EXP=GFS                    # (EXP) Options: GFS or ERA.
RES=30km_LAC_REG           # (RES_MESH)                 
                           #            Options-Global:     2562 = 480km;
			   #                               10242 = 240km;
			   #                               40962 = 120km; 
                           #                              163842 =  60km;
			   #                              655362 =  30Km;
			   #                             1024002 =  24km;
			   #                             2621442 =  15Km;
			   #                             5898242 =  10Km.
			   #            Options-Regional (default): 30km_LAC_REG = 30km Latin America and the Caribbean (excl. Mexico);
			   #                                        10km_LAC_REG = 10km Latin America and the Caribbean (excl. Mexico);
			   #                                        05km_LAC_REG = 05km Latin America and the Caribbean (excl. Mexico).
			   #                                        <your_mesh> saved in 'datain/fixed' (x1.<your_mesh>).
YYYYMMDDHHi=2025102500     # (LABELI) Check the available dates for the initial and boundary conditions (regional), especially for ERA5 data.
FCST=24                    # (FCST).
#----------------------------------------------------------------------------------------------------


# STEP 1: Installing and compiling the A-MONAN model and utility programs:
#time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
#exit

# STEP 2: Executing the pre-processing fase. Preparing all CI/CC files needed:
#time ${SCRIPTS}/2.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit

# STEP 3: Executing the Model run:
#time ${SCRIPTS}/3.run_model.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit

# STEP 4: Executing the Post of Model run:
#time ${SCRIPTS}/4.run_post.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit

