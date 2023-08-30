#!/bin/bash

set -e
echo -e "\033[0;31mStarting CUDA Installer...\033[0m"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP_DIR="$DIR/tmp"

mkdir -p $TMP_DIR

CUDA_URL_BASE="https://developer.download.nvidia.com/compute/cuda"
CUDA_VERSION=$1
CUDNN_VERSION=$2
OPENCV_VERSION=$3
UBUNTU_VERSION=$4
CMAKE_VERSION=$5

# Helper function to download a file from a URL
download_file() {
    local URL=$1
    local OUTPUT=$2
    wget -O $OUTPUT $URL
}

# Remove existing NVIDIA driver, CUDA, and cuDNN
if [[ -n "$CUDA_VERSION" ]] || [[ -n "$CUDNN_VERSION" ]]; then
    sudo apt-get purge --auto-remove nvidia-*
fi

# Install Ubuntu driver
if [[ -n "$UBUNTU_VERSION" ]]; then
    sudo ubuntu-drivers autoinstall
fi

# Installing CUDA
if [[ -n "$CUDA_VERSION" ]]; then
    echo "Installing CUDA $CUDA_VERSION..."
    CUDA_URL="${CUDA_URL_BASE}/${CUDA_VERSION}/docs/sidebar/md5sum.txt"
    CUDA_FILE=$(curl -s $CUDA_URL | grep -oP "cuda_${CUDA_VERSION}.*_linux.run")
    download_file "${CUDA_URL_BASE}/${CUDA_VERSION}/local_installers/${CUDA_FILE}" "${TMP_DIR}/${CUDA_FILE}"
    sudo sh "${TMP_DIR}/${CUDA_FILE}" --silent --toolkit
fi

# TODO: Installing cuDNN
# As mentioned, you would follow a similar procedure as CUDA for cuDNN

# TODO: Installing OpenCV
# Based on $OPENCV_VERSION, you would clone the opencv repo, checkout the specific version, and then compile and install.

# Installing or upgrading CMake
if [[ -n "$CMAKE_VERSION" ]]; then
    INSTALLED_CMAKE_VERSION=$(cmake --version | grep -oP "cmake version \K[0-9.]+")
    if [[ $(echo "$CMAKE_VERSION $INSTALLED_CMAKE_VERSION" | awk '{print ($1 > $2)}') == 1 ]]; then
        echo "Upgrading CMake to version $CMAKE_VERSION..."
        # Download and install CMake based on the $CMAKE_VERSION
        download_file "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh" "${TMP_DIR}/cmake.sh"
        sudo sh "${TMP_DIR}/cmake.sh" --skip-license --prefix=/usr/local
    fi
fi

echo -e "\033[0;32mInstallation Completed\033[0m"
