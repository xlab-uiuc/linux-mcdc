# Measure Linux Kernel's MC/DC

## 0. Prerequisites

- The following instructions are tested with:
    - Architecture: x86_64
    - Distro: Ubuntu 22.04
    - Kernel: 5.15.0-86-generic

    Other settings can possibly work, but they are not fully tested.

- If we don't plan to build LLVM from source, please reserve ~30G of disk
  space; otherwise reserve ~150G.

## 1. Install dependencies

```shell
# For building LLVM from source (optional)
sudo apt-get install cmake ninja-build mold

# For building the kernel
sudo apt-get install git bc libncurses-dev wget busybox \
    libssl-dev libelf-dev dwarves flex bison build-essential

# For booting the kernel
sudo apt-get install qemu qemu-system-x86
```

Set up KVM

```shell
sudo chmod 666 /dev/kvm
```

## 2. Pull the source code and apply patches

```shell
cd /path/to/our/workdir
export MCDC_HOME=$(realpath .)

# This meta repository
git clone https://github.com/xlab-uiuc/linux-mcdc.git
# LLVM if we want to build it from source (optional)
git clone https://github.com/llvm/llvm-project.git --branch llvmorg-18.1.6 --depth 5
# Linux kernel
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --branch v5.15.153 --depth 5

# Apply kernel patches
cd $MCDC_HOME/linux
git apply $MCDC_HOME/linux-mcdc/patches/v0.4/0001-clang_instr_profile-add-Clang-s-Source-based-Code-Co.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.4/0002-kbuild-clang_instr_profile-disable-instrumentation-i.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.4/0003-clang_instr_profile-add-Clang-s-MC-DC-support.patch
```

## 3. Get LLVM

We can either

- [Build LLVM from source](#build-from-source), or
- If we are on a Debian/Ubuntu machine and don't plan to change LLVM source code, [install nightly packages](#install-nightly-packages)

### Build from source

```shell
cd $MCDC_HOME/llvm-project
$MCDC_HOME/linux-mcdc/scripts/build-llvm.sh
```

After the build script finishes, set $PATH up:

```shell
export PATH="$MCDC_HOME/llvm-project/build/bin:$PATH"
```

### Install nightly packages

Get the installation script:

```shell
cd /tmp
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
```

Install LLVM 18:

```shell
sudo ./llvm.sh 18
```

After installation, set $PATH up:

```shell
export PATH="/usr/lib/llvm-18/bin:$PATH"
```

Visit https://apt.llvm.org/ for more information.

## 4. Build the kernel

```shell
cd $MCDC_HOME/linux
make LLVM=1 defconfig
```

Starting with the default configuration, let's further enable the following
groups of options:

1. Features used by our [QEMU wrapper script](../scripts/q). E.g.
   [9p](https://wiki.qemu.org/Documentation/9p) for easily moving data to/from
   the virtual machine.

    ```shell
    ./scripts/config -e CONFIG_9P_FS_POSIX_ACL
    ./scripts/config -e CONFIG_9P_FS
    ./scripts/config -e CONFIG_NET_9P_VIRTIO
    ./scripts/config -e CONFIG_NET_9P
    ./scripts/config -e CONFIG_PCI
    ./scripts/config -e CONFIG_VIRTIO_PCI
    ./scripts/config -e OVERLAY_FS
    ./scripts/config -e CONFIG_DEBUG_FS
    ./scripts/config -e CONFIG_CONFIGFS_FS
    ./scripts/config -e CONFIG_MAGIC_SYSRQ
    make LLVM=1 olddefconfig
    ```

2. Enable KUnit tests

    ```shell
    ./scripts/config -e CONFIG_KUNIT
    ./scripts/config -e CONFIG_KUNIT_ALL_TESTS
    make LLVM=1 olddefconfig
    ```

3. **Enable MC/DC**.

    ```shell
    ./scripts/config -e CONFIG_INSTR_PROFILE_CLANG
    ./scripts/config -e CONFIG_SCC_CLANG
    ./scripts/config -e CONFIG_MCDC_CLANG
    make LLVM=1 olddefconfig
    ```

    They are the options added by [our kernel patch](../patches/). In menuconfig
    mode, they are located under path -> "General architecture-dependent options"
    -> "Clang's instrumentation-based kernel profiling (EXPERIMENTAL)" where we
    can find more detailed explanation for each.

4. Exclude one option from the default config, due to a toolchain bug we are
   investigating (similar to https://github.com/llvm/llvm-project/issues/87000
   and https://github.com/llvm/llvm-project/issues/92216):

    ```shell
    ./scripts/config -d CONFIG_DRM_I915
    make LLVM=1 olddefconfig
    ```

With all the configuration done, let's build the kernel.

```shell
make LLVM=1 -j$(nproc)
```

> [!NOTE]
>
> At this stage we will see many warnings and the process will slow down near
> the end of building (LD, KSYMS etc).
>
> This is expected. The warnings are due to
> [two limitations](https://releases.llvm.org/18.1.0/tools/clang/docs/SourceBasedCodeCoverage.html#mc-dc-instrumentation)
> of the current MC/DC implementation in Clang.
> Extra overhead is brought by code instrumentation (counters, bitmaps, MOV and
> ADD instructions to increment the counters), and
> [coverage mapping](https://releases.llvm.org/18.1.0/docs/CoverageMappingFormat.html)
> in order to associate such information with the actual source code locations.
> Together they lead to larger binary size and longer linking time.

## 5. Boot the kernel and collect coverage

Boot the kernel using our [QEMU wrapper script](../scripts/q):

```shell
cd $MCDC_HOME/linux
$MCDC_HOME/linux-mcdc/scripts/q
```

During the booting process, KUnit tests are also executed since we enabled
relevant options earlier. The results are printed to the kernel log in
[TAP format](https://testanything.org/), like below:

```text
[    4.524452]     # Subtest: qos-kunit-test
[    4.524453]     1..3
[    4.525259]     ok 1 - freq_qos_test_min
[    4.525750]     ok 2 - freq_qos_test_maxdef
[    4.526547]     ok 3 - freq_qos_test_readd
[    4.527282] # qos-kunit-test: pass:3 fail:0 skip:0 total:3
[    4.528000] # Totals: pass:3 fail:0 skip:0 total:3
[    4.528954] ok 17 - qos-kunit-test
```

Now we should have entered an interactive shell of the guest machine.

```shell
# (guest)
uname -a
```

Let's inspect the directory added to debugfs by our patch:

```shell
# (guest)
ls /sys/kernel/debug/clang_instr_profile
```

which should contain two pseudo files: `profraw` and `reset`.

- Writing to `reset` will clear the in-memory counters and bitmaps
- Reading `profraw` will serialize the in-memory counters and bitmaps in a
  [proper format](https://releases.llvm.org/18.1.0/docs/InstrProfileFormat.html)
  that is recognized by LLVM tools.

Let's copy the profile to current directory, which is [shared with host
directory `$MCDC_HOME/linux` through 9p](../scripts/q#L79-L86), so that we can
access the same file outside VM and complete the remaining steps on the host
machine.

```shell
# (guest)
cp /sys/kernel/debug/clang_instr_profile/profraw .
```

Press Ctrl+D to exit the VM. We will get back to `$MCDC_HOME/linux` of the host
and should have had a copy of `profraw` there.

```shell
# (host)
file profraw
```

Now we can analyze the profile and generate coverage reports in a similar way to
[what we would do to user space programs](https://releases.llvm.org/18.1.0/tools/clang/docs/SourceBasedCodeCoverage.html#creating-coverage-reports),
as if `vmlinux` is the "executable":

```shell
mkdir -p $MCDC_HOME/analysis
mv profraw $MCDC_HOME/analysis
cd $MCDC_HOME/analysis

llvm-profdata merge profraw -o profdata
llvm-cov show --show-mcdc                                                      \
              --show-mcdc-summary                                              \
              --show-region-summary=false                                      \
              --show-branch-summary=false                                      \
              --format=html                                                    \
              -output-dir=html-coverage-reports                                \
              -instr-profile profdata                                          \
              $MCDC_HOME/linux/vmlinux
```

The results will be put under `$MCDC_HOME/analysis/html-coverage-reports`.