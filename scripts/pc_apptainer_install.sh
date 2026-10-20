#!/bin/bash
set -Eeuo pipefail

# ============================================================
# Apptainer / Singularity Installation Script
# Operating System: Ubuntu 24.04
# ============================================================

GO_VERSION="1.25.7"
APPTAINER_VERSION="v1.5.4"
PREFIX="/usr/local"

echo "=================================================="
echo " Apptainer Installation"
echo " Operating System: Ubuntu 24.04"
echo "=================================================="


# ------------------------------------------------------------
# 1. Check operating system compatibility
# ------------------------------------------------------------

echo ">>> Checking operating system compatibility..."

if [[ ! -r /etc/os-release ]]; then
    echo "ERROR: Cannot identify the operating system."
    exit 1
fi

source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "ERROR: Unsupported operating system: ${PRETTY_NAME:-unknown}"
    echo "This installer supports Ubuntu 24.04 only."
    exit 1
fi

if [[ "${VERSION_ID:-}" != "24.04" ]]; then
    echo "ERROR: Unsupported Ubuntu version: ${VERSION_ID:-unknown}"
    echo "This installer supports Ubuntu 24.04 only."
    exit 1
fi

echo ">>> Operating system: ${PRETTY_NAME}"
echo ">>> Compatibility check passed."


# ------------------------------------------------------------
# 2. Check system architecture
# ------------------------------------------------------------

echo ">>> Checking system architecture..."

ARCH="$(uname -m)"

if [[ "${ARCH}" != "x86_64" ]]; then
    echo "ERROR: Unsupported architecture: ${ARCH}"
    echo "This installer currently supports x86_64 systems only."
    exit 1
fi

echo ">>> System architecture: ${ARCH}"
echo ">>> Architecture check passed."


# ------------------------------------------------------------
# 3. Check administrative privileges
# ------------------------------------------------------------

if ! command -v sudo >/dev/null 2>&1; then
    echo "ERROR: sudo is not installed."
    exit 1
fi

if ! sudo -v; then
    echo "ERROR: Unable to obtain administrative privileges."
    exit 1
fi


# ------------------------------------------------------------
# 4. Install system dependencies
# ------------------------------------------------------------

echo ">>> Updating package repositories..."

sudo apt-get update

echo ">>> Installing required packages..."

sudo apt-get install -y \
    build-essential \
    pkg-config \
    squashfs-tools \
    curl \
    wget \
    git \
    squashfuse \
    fuse2fs \
    gocryptfs \
    fuse3 \
    libfuse3-dev \
    uidmap \
    fakeroot \
    libseccomp-dev \
    libtalloc-dev \
    libattr1-dev \
    libprotobuf-c-dev \
    libsubid-dev \
    cryptsetup \
    tzdata \
    dh-apparmor


# ------------------------------------------------------------
# 5. Install Go
# ------------------------------------------------------------

echo ">>> Installing Go ${GO_VERSION}..."

TMPDIR_INSTALL="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_INSTALL"' EXIT

curl -fL \
    "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
    -o "${TMPDIR_INSTALL}/go.tar.gz"

sudo rm -rf /usr/local/go

sudo tar \
    -C /usr/local \
    -xzf "${TMPDIR_INSTALL}/go.tar.gz"

export PATH="/usr/local/go/bin:${PATH}"

echo ">>> Installed Go version:"
go version


# ------------------------------------------------------------
# 6. Download Apptainer source code
# ------------------------------------------------------------

echo ">>> Downloading Apptainer ${APPTAINER_VERSION}..."

git clone \
    --depth 1 \
    --branch "${APPTAINER_VERSION}" \
    https://github.com/apptainer/apptainer.git \
    "${TMPDIR_INSTALL}/apptainer"

cd "${TMPDIR_INSTALL}/apptainer"


# ------------------------------------------------------------
# 7. Build and install Apptainer
# ------------------------------------------------------------

echo ">>> Configuring the build..."

./mconfig --prefix="${PREFIX}"

echo ">>> Building Apptainer..."

make -C builddir -j"$(nproc)"

echo ">>> Installing Apptainer..."

sudo make -C builddir install


# ------------------------------------------------------------
# 8. Configure AppArmor for Ubuntu 24.04
# ------------------------------------------------------------

echo ">>> Configuring the dedicated AppArmor profile..."

sudo tee /etc/apparmor.d/apptainer >/dev/null <<'EOF'
abi <abi/4.0>,
include <tunables/global>

profile apptainer /usr/local/{bin/apptainer,libexec/apptainer/bin/starter{,-suid}}
    flags=(unconfined) {
    userns,
    include if exists <local/apptainer>
}
EOF

echo ">>> Reloading AppArmor..."

sudo systemctl reload apparmor


# ------------------------------------------------------------
# 9. Verify the installation
# ------------------------------------------------------------

echo ">>> Verifying the installation..."

export PATH="${PREFIX}/bin:/usr/local/go/bin:${PATH}"

if ! command -v apptainer >/dev/null 2>&1; then
    echo "ERROR: Apptainer executable not found."
    exit 1
fi

echo
echo ">>> Installed version:"

apptainer version

echo
echo ">>> Build configuration:"

apptainer buildcfg

echo
echo "=================================================="
echo " Apptainer installation completed!"
echo "=================================================="
echo
echo "To test the installation, run:"
echo "  apptainer exec monan.sif /bin/true"
echo
