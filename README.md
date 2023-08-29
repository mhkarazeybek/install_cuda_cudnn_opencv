# Automated Setup Script for CUDA, cuDNN, and OpenCV Installation

This script automates the installation process for CUDA, cuDNN, and OpenCV on an Ubuntu system. It provides a streamlined way to ensure that the required dependencies and libraries are properly installed for deep learning and computer vision development.

## Requirements

- Ubuntu operating system (tested on Ubuntu 20.04)
- NVIDIA GPU with CUDA support

## Usage

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/mhkarazeybek/install_cuda_cudnn_opencv.git
2. Navigate to the project directory:
   ```bash
   cd cuda-cudnn-opencv-installation
3. Make the script executable:
    ```bash
    chmod +x install_script.sh
4. Run the script with necessary arguments to specify the versions:

    Replace <CMAKE_VERSION>, <CUDA_VERSION>, <CUDNN_VERSION>, <OPENCV_VERSION>, and <UBUNTU_VERSION> with the desired versions of CMake, CUDA, cuDNN, OpenCV, and Ubuntu respectively.
    ```bash
    ./install_script.sh --cmake <CMAKE_VERSION> --cuda <CUDA_VERSION> --cudnn <CUDNN_VERSION> --opencv <OPENCV_VERSION> --ubuntu <UBUNTU_VERSION>
5. Follow the on-screen instructions and prompts.

## Notes
- The script first uninstalls existing CUDA, cuDNN, and NVIDIA drivers if they are detected.
- It then installs the necessary NVIDIA drivers automatically using the ubuntu-drivers command.
- The script compares the installed CMake version with the provided version. If the installed version is older, it removes the old version and installs the specified CMake version.
- CUDA, cuDNN, and OpenCV are installed based on the provided version numbers.
- After successful installation, the script verifies the OpenCV installation.