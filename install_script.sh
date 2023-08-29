#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

# Print colored text
print_color() {
    COLOR=$1
    TEXT=$2
    echo -e "${COLOR}${TEXT}${NC}"
}

# Function to handle errors
handle_error() {
    print_color "${RED}" "An error occurred. Exiting..."
    exit 1
}

# Trap errors and execute error handling function
trap 'handle_error' ERR

# Uninstall existing CUDA and NVIDIA drivers
print_color "${GREEN}" "Uninstalling existing CUDA and NVIDIA drivers..."
sudo apt-get --purge remove "*cublas*" "*cufft*" "*curand*" \
"*cusolver*" "*cusparse*" "*npp*" "nvidia-*" "cuda-*" "nsight-*" || true
sudo apt-get autoremove
sudo apt-get autoclean
sudo rm -rf /usr/local/cuda*

# Install required packages
required_packages="cmake pkg-config unzip yasm git checkinstall \
libjpeg-dev libpng-dev libtiff-dev libavcodec-dev libavformat-dev \
libswscale-dev libavresample-dev libgstreamer1.0-dev \
libgstreamer-plugins-base1.0-dev libxvidcore-dev x264 libx264-dev \
libfaac-dev libmp3lame-dev libtheora-dev libvorbis-dev \
libopencore-amrnb-dev libopencore-amrwb-dev \
libdc1394-22 libdc1394-22-dev libxine2-dev libv4l-dev v4l-utils \
libgtk-3-dev libtbb-dev libatlas-base-dev gfortran"

print_color "${GREEN}" "Installing required packages..."
sudo apt-get update
sudo apt-get install -y ${required_packages} || true

# Determine the latest NVIDIA driver version
NVIDIA_DRIVER_VERSION=$(sudo ubuntu-drivers list | grep nvidia-driver | awk '{print $3}')
NVIDIA_VERSION_FULL=$(apt-cache show nvidia-driver-${NVIDIA_DRIVER_VERSION} | grep Version | awk '{print $2}')
NVIDIA_VERSION=${NVIDIA_VERSION_FULL%-*}  # Remove the package suffix

# Install NVIDIA drivers
print_color "${GREEN}" "Installing NVIDIA drivers..."
sudo apt-get install -y nvidia-driver-${NVIDIA_DRIVER_VERSION} || true

# Install CUDA (if needed)
if [ -n "${CUDA_VERSION}" ]; then
    # Download and install CUDA
    print_color "${GREEN}" "Installing CUDA..."
    CUDA_REPO_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64"
    CUDA_PIN_URL="${CUDA_REPO_URL}/cuda-ubuntu1804.pin"
    CUDA_DEB_URL="https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/cuda-repo-ubuntu1804-${CUDA_VERSION}-local_${CUDA_VERSION}-${NVIDIA_VERSION}-1_amd64.deb"
    wget ${CUDA_PIN_URL}
    sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget ${CUDA_DEB_URL}
    sudo dpkg -i cuda-repo-ubuntu1804-${CUDA_VERSION}-local_${CUDA_VERSION}-${NVIDIA_VERSION}-1_amd64.deb
    sudo apt-key add /var/cuda-repo-ubuntu1804-${CUDA_VERSION}-local/7fa2af80.pub
    sudo apt-get update
    sudo apt-get -y install cuda || true
fi

# Install cuDNN (if needed)
if [ -n "${CUDNN_VERSION}" ]; then
    # Download and install cuDNN
    print_color "${GREEN}" "Installing cuDNN..."
    CUDNN_URL="https://developer.download.nvidia.com/compute/redist/cudnn/v${CUDNN_VERSION}/cudnn-${CUDNN_VERSION}-linux-x64-v${CUDNN_VERSION}.tgz"
    wget ${CUDNN_URL}
    tar -xzvf cudnn-${CUDNN_VERSION}-linux-x64-v${CUDNN_VERSION}.tgz
    sudo cp cuda/include/cudnn*.h /usr/local/cuda/include
    sudo cp cuda/lib64/libcudnn* /usr/local/cuda/lib64
    sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*
    sudo cp cuda/include/cudnn.h /usr/include
    sudo cp cuda/lib64/libcudnn* /usr/lib/x86_64-linux-gnu/
    sudo chmod a+r /usr/lib/x86_64-linux-gnu/libcudnn*
fi

# Download and compile OpenCV (if needed)
if [ -n "${OPENCV_VERSION}" ]; then
    # Download and compile OpenCV
    print_color "${GREEN}" "Compiling OpenCV..."
    cd ~/Downloads
    wget -O opencv.zip https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.zip
    unzip opencv.zip
    cd opencv-${OPENCV_VERSION}
    mkdir build
    cd build
    cmake_cmd="cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local/bin \
    -D WITH_TBB=ON \
    -D ENABLE_FAST_MATH=1 \
    -D CUDA_FAST_MATH=1 \
    -D WITH_TBB=ON \
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
    -D OPENCV_EXTRA_MODULES_PATH=/home/ubuntu/opencv_env/opencv_contrib-${OPENCV_VERSION}/modules \
    -D INSTALL_PYTHON_EXAMPLES=OFF \
    -D INSTALL_C_EXAMPLES=OFF \
    -D BUILD_EXAMPLES=OFF .."
    eval ${cmake_cmd}
    nproc_num=$(nproc)
    make_cmd="make -j${nproc_num}"
    eval ${make_cmd}
    sudo make install
fi

print_color "${GREEN}" "Installation completed successfully."
