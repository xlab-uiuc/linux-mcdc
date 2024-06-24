#!/bin/bash

# For building LLVM from source (optional)
sudo apt-get -yq install cmake ninja-build mold

# For building the kernel
sudo apt-get -yq install git bc libncurses-dev wget busybox \
    libssl-dev libelf-dev dwarves flex bison build-essential

# For booting the kernel
sudo apt-get -yq install qemu-system-x86
