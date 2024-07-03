#!/bin/bash

cd $MCDC_HOME

# This meta repository
git clone https://github.com/xlab-uiuc/linux-mcdc.git --branch v0.6-wip
# LLVM if we want to build it from source (optional)
git clone https://github.com/llvm/llvm-project.git --depth 5
# Linux kernel
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --branch v5.15.153 --depth 5

# Apply kernel patches
cd $MCDC_HOME/linux
git apply $MCDC_HOME/linux-mcdc/patches/v0.6-wip/0001-llvm-cov-add-Clang-s-Source-based-Code-Coverage-supp.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.6-wip/0002-kbuild-llvm-cov-disable-instrumentation-in-odd-or-se.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.6-wip/0003-llvm-cov-add-Clang-s-MC-DC-support.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.6-wip/0004-kbuild-clang_instr_profile-disable-instrumentation-i.patch
