#!/bin/bash

repo=${1:-"xlab-uiuc/linux-mcdc"}
branch=${2:-"llvm-trunk-next"}

echo $repo
echo $branch

kernel_latest_tag=v$(
    curl -s https://www.kernel.org/releases.json | jq -r '.releases[0].version'
)
echo $kernel_latest_tag
if [[ "$kernel_latest_tag" != "v6.11-rc3" ]]; then
    echo "There are updates in upstream. Patch v1.0 needs to be rebased."
    # Fail on purpose as likely we have to resolve some conflicts
    exit 1
fi

cd $MCDC_HOME

# This meta repository
git clone https://github.com/$repo.git --branch $branch
# LLVM if we want to build it from source (optional)
git clone https://github.com/llvm/llvm-project.git --depth 5
# Linux kernel
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --branch $kernel_latest_tag --depth 5

# Apply kernel patches
cd $MCDC_HOME/linux
git apply $MCDC_HOME/linux-mcdc/patches/v1.0/0001-llvm-cov-add-Clang-s-Source-based-Code-Coverage-supp.patch
git apply $MCDC_HOME/linux-mcdc/patches/v1.0/0002-kbuild-llvm-cov-disable-instrumentation-in-odd-or-se.patch
git apply $MCDC_HOME/linux-mcdc/patches/v1.0/0003-llvm-cov-add-Clang-s-MC-DC-support.patch