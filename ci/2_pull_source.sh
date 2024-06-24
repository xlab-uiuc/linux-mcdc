#!/bin/bash

cd $MCDC_HOME

# This meta repository
git clone https://github.com/xlab-uiuc/linux-mcdc.git --branch llvm19
# LLVM if we want to build it from source (optional)
git clone https://github.com/llvm/llvm-project.git --branch main
# Linux kernel
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --branch v5.15.153 --depth 5

# Use the snapshot of LLVM on June 11 2024
cd $MCDC_HOME/llvm-project
git checkout f5dcfb9968a3

# Apply kernel patches
cd $MCDC_HOME/linux
git apply $MCDC_HOME/linux-mcdc/patches/v0.5/0001-clang_instr_profile-add-Clang-s-Source-based-Code-Co.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.5/0002-kbuild-clang_instr_profile-disable-instrumentation-i.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.5/0003-clang_instr_profile-add-Clang-s-MC-DC-support.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.5/0004-kbuild-clang_instr_profile-disable-instrumentation-i.patch
