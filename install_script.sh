#!/bin/bash

# Exit on any error
set -e

# Usage function
usage() {
    echo "Usage: $0 --cmake <CMAKE_VERSION> --cuda <CUDA_VERSION> --cudnn <CUDNN_VERSION> --opencv <OPENCV_VERSION> --ubuntu <UBUNTU_VERSION>"
    exit 1
}

# Display usage if no arguments are provided
if [ $# -eq 0 ]; then
    usage
fi

# Initialize flags for optional installations
INSTALL_CMAKE=0
INSTALL_CUDA=0
INSTALL_CUDNN=0
INSTALL_OPENCV=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --cmake)
            CMAKE_VERSION=$2
            INSTALL_CMAKE=1
            shift 2
            ;;
        --cuda)
            CUDA_VERSION=$2
            INSTALL_CUDA=1
            shift 2
            ;;
        --cudnn)
            CUDNN_VERSION=$2
            INSTALL_CUDNN=1
            shift 2
            ;;
        --opencv)
            OPENCV_VERSION=$2
            INSTALL_OPENCV=1
            shift 2
            ;;
        --ubuntu)
            UBUNTU_VERSION=$2
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo "Invalid option: $1"
            usage
            ;;
    esac
done

# Check for required parameters
if [ -z "${UBUNTU_VERSION}" ]; then
    usage
fi

# Function to handle errors
handle_error() {
    echo "An error occurred. Exiting..."
    exit 1
}

# Trap errors and execute error handling function
trap 'handle_error' ERR

# Uninstall existing CUDA and NVIDIA drivers
sudo apt-get --purge remove "*cublas*" "*cufft*" "*curand*" \
"*cusolver*" "*cusparse*" "*npp*" "*nvjpeg*" "cuda*" "nsight*" "*nvidia*"
sudo apt-get autoremove
sudo apt-get autoclean
sudo rm -rf /usr/local/cuda*

# Install NVIDIA drivers
sudo ubuntu-drivers autoinstall

# Check installed cmake version
if [ "${INSTALL_CMAKE}" -eq 1 ]; then
    INSTALLED_CMAKE_VERSION=$(cmake --version | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -n 1)
    echo "Installed CMake version: ${INSTALLED_CMAKE_VERSION}"

    # Compare installed cmake version with required cmake version
    if [[ $(echo "${INSTALLED_CMAKE_VERSION} < ${CMAKE_VERSION}" | bc -l) -eq 1 ]]; then
        echo "Removing old CMake version: ${INSTALLED_CMAKE_VERSION}"
        sudo apt-get remove cmake
        echo "Installing CMake version: ${CMAKE_VERSION}"
        sudo apt-get install -y cmake=${CMAKE_VERSION}-*
    else
        echo "CMake version is up to date: ${INSTALLED_CMAKE_VERSION}"
    fi
fi

# Install CUDA
if [ "${INSTALL_CUDA}" -eq 1 ]; then
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION}/x86_64/cuda-ubuntu${UBUNTU_VERSION}.pin
    sudo mv cuda-ubuntu${UBUNTU_VERSION}.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/cuda-repo-ubuntu${UBUNTU_VERSION}-${CUDA_VERSION}-local_${CUDA_VERSION}-470.57.02-1_amd64.deb
    sudo dpkg -i cuda-repo-ubuntu${UBUNTU_VERSION}-${CUDA_VERSION}-local_${CUDA_VERSION}-470.57.02-1_amd64.deb
    sudo apt-key add /var/cuda-repo-ubuntu${UBUNTU_VERSION}-${CUDA_VERSION}-local/7fa2af80.pub
    sudo apt-get update
    sudo apt-get -y install cuda
fi

# Install cuDNN
if [ "${INSTALL_CUDNN}" -eq 1 ]; then
    wget https://developer.download.nvidia.com/compute/redist/cudnn/v${CUDNN_VERSION}/cudnn-${CUDNN_VERSION}-linux-x64-v${CUDNN_VERSION}.tgz
    tar -xzvf cudnn-${CUDNN_VERSION}-linux-x64-v${CUDNN_VERSION}.tgz
    sudo cp cuda/include/cudnn*.h /usr/local/cuda/include
    sudo cp cuda/lib64/libcudnn* /usr/local/cuda/lib64
    sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*
    sudo cp cuda/include/cudnn.h /usr/include
    sudo cp cuda/lib64/libcudnn* /usr/lib/x86_64-linux-gnu/
    sudo chmod a+r /usr/lib/x86_64-linux-gnu/libcudnn*
fi

# Download and compile OpenCV
if [ "${INSTALL_OPENCV}" -eq 1 ]; then
    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get install -y cmake pkg-config unzip yasm git checkinstall \
    libjpeg-dev libpng-dev libtiff-dev libavcodec-dev libavformat-dev \
    libswscale-dev libavresample-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev libxvidcore-dev x264 libx264-dev \
    libfaac-dev libmp3lame-dev libtheora-dev libvorbis-dev \
    libopencore-amrnb-dev libopencore-amrwb-dev \
    libdc1394-22 libdc1394-22-dev libxine2-dev libv4l-dev v4l-utils \
    libgtk-3-dev libtbb-dev libatlas-base-dev gfortran

    cd ~/Downloads
    wget -O opencv.zip https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.zip
    unzip opencv.zip
    cd opencv-${OPENCV_VERSION}
    mkdir build
    cd build

    # Configure OpenCV build
    cmake_cmd="cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local/bin \
    -D WITH_TBB=ON \
    -D ENABLE_FAST_MATH=1 \
    -D CUDA_FAST_MATH=1 \
    -D WITH_CUBLAS=1 \
    -D WITH_CUDA=ON \
    -D BUILD_opencv_cudacodec=OFF \
    -D WITH_CUDNN=ON \
    -D OPENCV_DNN_CUDA=ON \
    -D WITH_V4L=ON \
    -D WITH_QT=OFF \
    -D WITH_OPENGL=ON \
    -D WITH_GSTREAMER=ON \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D OPENCV_PC_FILE_NAME=opencv.pc \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D OPENCV_PYTHON3_INSTALL_PATH=/usr/local/lib/python3.6/dist-packages \
    -D PYTHON_EXECUTABLE=/usr/bin/python3 \
    -D INSTALL_PYTHON_EXAMPLES=OFF \
    -D INSTALL_C_EXAMPLES=OFF \
    -D BUILD_EXAMPLES=OFF .."

    eval ${cmake_cmd}

    # Compile and install OpenCV
    nproc=$(nproc)  # Get number of CPU cores
    make_cmd="make -j${nproc}"
    sudo_cmd="sudo make install"

    eval ${make_cmd}
    eval ${sudo_cmd}

    # Configure library paths for OpenCV
    sudo /bin/bash -c 'echo "/usr/local/lib" >> /etc/ld.so.conf.d/opencv.conf'
    sudo ldconfig

    # Verify OpenCV installation
    python3 -c "import cv2; print(cv2.getBuildInformation())"
fi

echo "Installation completed successfully."
