#!/bin/bash
set -e

echo ""
echo "MONAN-PC - Slurm install"
echo "======================================================"
echo ""

echo "[1/6] Slurm => Installing dependencies..."
apt-get update
apt-get install -y build-essential munge slurm-wlm slurmdbd slurmctld slurmd mariadb-server libmunge-dev libmunge2 munge libpam0g-dev

echo "[2/6] Slurm => Configuring MUNGE..."
chown munge: /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
systemctl enable --now munge

echo "[3/6] Slurm => Creating directories for slurm..."
mkdir -p /etc/slurm /var/spool/slurmd /var/log/slurm
chown slurm: /var/spool/slurmd /var/log/slurm

echo "[4/6] Slurm => Creating slurm configuration file..."

cat <<EOF > /etc/slurm/slurm.conf
ClusterName=meuCluster
ControlMachine=$(hostname)
MpiDefault=none
ProctrackType=proctrack/linuxproc
ReturnToService=2
SlurmctldPidFile=/var/run/slurmctld.pid
SlurmdPidFile=/var/run/slurmd.pid
SlurmdSpoolDir=/var/spool/slurmd
SlurmUser=slurm
StateSaveLocation=/var/spool/slurmd
SwitchType=switch/none
TaskPlugin=task/none

NodeName=$(hostname) CPUs=$(nproc) State=UNKNOWN
PartitionName=batch Nodes=$(hostname) Default=YES MaxTime=INFINITE State=UP
EOF

echo "[5/6] Slurm => Enabling and starting slurm service..."
systemctl enable --now slurmctld
systemctl enable --now slurmd

echo "[6/6] Slurm => Checking the status..."
sinfo

echo "SLURM installed and running locally on node $(hostname)."




echo ""
echo ""
echo "MONAN-PC - Singularity install"
echo "======================================================"
echo ""

# Versões
#GO_VERSION=1.21.5
#APPTAINER_VERSION=v1.2.5

GO_VERSION=1.24.6
APPTAINER_VERSION=v1.4.5


echo "[1/6] Singularity => Installing dependencies..."
sudo apt update
sudo apt install -y build-essential libseccomp-dev pkg-config squashfs-tools cryptsetup curl git

echo "[2/6] Singularity => Installing Go ${GO_VERSION}..."
curl -LO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

echo "[3/6] Singularity => Setting Go PATH..."
if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
fi
export PATH=$PATH:/usr/local/go/bin

echo "[4/6] Singularity => Cloning Apptainer (Singularity)..."
git clone https://github.com/apptainer/apptainer.git
cd apptainer
git checkout ${APPTAINER_VERSION}

echo "[5/6] Singularity => Compiling Apptainer..."
./mconfig
make -C builddir
sudo make -C builddir install

echo "[6/6] Singularity => Checking the status..."
singularity version

echo "Singularity installed and running locally on node $(hostname)."
