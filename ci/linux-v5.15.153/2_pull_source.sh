#!/bin/bash

repo=${1:-"xlab-uiuc/linux-mcdc"}
branch=${2:-"llvm-trunk-next"}
llvm_ref=${3:-"6b98a723653214a6cde05ae3cb5233af328ff101"}

echo $repo
echo $branch

cd $MCDC_HOME

# This meta repository
git clone https://github.com/$repo.git --branch $branch
# LLVM if we want to build it from source (optional)
git clone https://github.com/llvm/llvm-project.git
# Linux kernel
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --branch v5.15.153 --depth 5

# Use a specific ref of LLVM
cd $MCDC_HOME/llvm-project
git checkout $llvm_ref

# Apply kernel patches
cd $MCDC_HOME/linux
git apply $MCDC_HOME/linux-mcdc/patches/v0.6/0001-llvm-cov-add-Clang-s-Source-based-Code-Coverage-supp.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.6/0002-kbuild-llvm-cov-disable-instrumentation-in-odd-or-se.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.6/0003-llvm-cov-add-Clang-s-MC-DC-support.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.6/0004-kbuild-llvm-cov-disable-instrumentation-in-odd-or-se.patch
