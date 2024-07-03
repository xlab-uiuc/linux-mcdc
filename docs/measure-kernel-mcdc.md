# Measure Linux Kernel's MC/DC

> [!NOTE]
>
> The following instructions use **LLVM 19** and patch >= v0.6. The differences
> between patch v0.5 and v0.6 be found [here](https://github.com/xlab-uiuc/linux-mcdc/compare/llvm19...v0.6-wip).

## 0. Prerequisites

- The following instructions are tested with:
    - Architecture: x86_64
    - Distro: Ubuntu 22.04
    - Kernel: 5.15.0-86-generic

    Other settings (e.g. Arm) can possibly work, but they are not fully tested.

- Larger than 24G of main memory is recommended for successfully linking the
  kernel image.
- If we don't plan to build LLVM from source, please reserve ~15G of disk
  space; otherwise reserve ~20G.
  <!-- As observed in a recent run, the built LLVM is ~6.2G (with
       -DCMAKE_BUILD_TYPE="Release"); the built Linux is ~9.8G; LLVM downloaded
       from apt.llvm.org is 912M; other dpkg packages are less than 500M.    -->

## 1. Install dependencies

```shell
# For building LLVM from source (optional)
sudo apt-get install cmake ninja-build mold

# For building the kernel
sudo apt-get install git bc libncurses-dev wget busybox \
    libssl-dev libelf-dev dwarves flex bison build-essential

# For booting the kernel
sudo apt-get install qemu-system-x86
```

<!--

(Optional) Set up KVM for better performance

1. If `/dev/kvm` exists on host...

    ```shell
    sudo usermod -aG kvm $USER
    newgrp kvm
    ```

    Even if we don't set this up, it should still work fine as now our QEMU
    wrapper script will automatically downgrade to TCG mode.

2. If `/dev/kvm` doesn't exist on host...

    No action is required. QEMU will run in TCG mode.

-->

## 2. Pull the source code and apply patches

```shell
cd /path/to/our/workdir
export MCDC_HOME=$(realpath .)

# This meta repository
git clone https://github.com/xlab-uiuc/linux-mcdc.git --branch v0.6-wip
# LLVM if we want to build it from source (optional)
git clone https://github.com/llvm/llvm-project.git --branch main --depth 5
# Linux kernel
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git --branch v5.15.153 --depth 5

# Apply kernel patches
cd $MCDC_HOME/linux
git apply $MCDC_HOME/linux-mcdc/patches/v0.6-wip/0001-llvm-cov-add-Clang-s-Source-based-Code-Coverage-supp.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.6-wip/0002-kbuild-llvm-cov-disable-instrumentation-in-odd-or-se.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.6-wip/0003-llvm-cov-add-Clang-s-MC-DC-support.patch
git apply $MCDC_HOME/linux-mcdc/patches/v0.5/0004-kbuild-clang_instr_profile-disable-instrumentation-i.patch
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

The essential steps are described below. For more information about these
nightly packages, visit https://apt.llvm.org/.

Get the installation script:

```shell
cd /tmp
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
```

Install LLVM 19:

```shell
sudo ./llvm.sh 19
```

After installation, set $PATH up:

```shell
export PATH="/usr/lib/llvm-19/bin:$PATH"
```

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
    ./scripts/config -e CONFIG_OVERLAY_FS
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
    ./scripts/config -e CONFIG_LLVM_COV_KERNEL
    ./scripts/config -e CONFIG_LLVM_COV_KERNEL_MCDC
    ./scripts/config --set-val LLVM_COV_KERNEL_MCDC_MAX_CONDITIONS 44
    make LLVM=1 olddefconfig
    ```

    They are the options added by [our kernel patch](../patches/). In menuconfig
    mode, they are located under path -> "General architecture-dependent options"
    -> "Clang's source-based kernel coverage measurement (EXPERIMENTAL)" where we
    can find more detailed explanation for each.

    About `LLVM_COV_KERNEL_MCDC_MAX_CONDITIONS` and its value, please refer to
    [this issue](https://github.com/xlab-uiuc/linux-mcdc/issues/5).

<!--

Sanity check:

$ ./scripts/config -s CONFIG_9P_FS_POSIX_ACL     &&\
  ./scripts/config -s CONFIG_9P_FS               &&\
  ./scripts/config -s CONFIG_NET_9P_VIRTIO       &&\
  ./scripts/config -s CONFIG_NET_9P              &&\
  ./scripts/config -s CONFIG_PCI                 &&\
  ./scripts/config -s CONFIG_VIRTIO_PCI          &&\
  ./scripts/config -s CONFIG_OVERLAY_FS          &&\
  ./scripts/config -s CONFIG_DEBUG_FS            &&\
  ./scripts/config -s CONFIG_CONFIGFS_FS         &&\
  ./scripts/config -s CONFIG_MAGIC_SYSRQ         &&\
  ./scripts/config -s CONFIG_KUNIT               &&\
  ./scripts/config -s CONFIG_KUNIT_ALL_TESTS     &&\
  ./scripts/config -s CONFIG_LLVM_COV_KERNEL     &&\
  ./scripts/config -s CONFIG_LLVM_COV_KERNEL_MCDC

All should print "y".

  ./scripts/config -s LLVM_COV_KERNEL_MCDC_MAX_CONDITIONS

It should print "44".

-->

With all the configuration done, let's build the kernel.

```shell
make LLVM=1 -j$(nproc)
```

<!--

Sanity check:

$ make LLVM=1 -j1

This will *serially* rebuild the kernel, to make sure no error was hidden in the
lengthy and interleaving log during our first build.

$ llvm-readelf --sections vmlinux |\
  grep -e '__llvm_prf_bits'        \
       -e '__llvm_prf_cnts'

to verify the sections for counters and bitmaps are indeed included.

-->

> [!NOTE]
>
> At this stage we will see many warnings and the process will slow down near
> the end of building (LD, KSYMS etc).
>
> This is expected. The warnings are due to
> [two limitations](https://clang.llvm.org/docs/SourceBasedCodeCoverage.html#mc-dc-instrumentation)
> of the current MC/DC implementation in Clang.
> Extra overhead is brought by code instrumentation (counters, bitmaps, MOV and
> ADD instructions to increment the counters), and
> [coverage mapping](https://releases.llvm.org/18.1.0/docs/CoverageMappingFormat.html)
> in order to associate such information with the actual source code locations.
> Together they lead to larger binary size and longer linking time.

<!-- The limitation on the number of conditions has changed by
     https://github.com/llvm/llvm-project/pull/82448, which is a major
     difference between our kernel patch v0.5 and v0.6. Since we don't have 19
     releases yet. Point to the latest documentation.                        -->

## 5. Boot the kernel and collect coverage

Boot the kernel using our [QEMU wrapper script](../scripts/q):

```shell
cd $MCDC_HOME/linux
$MCDC_HOME/linux-mcdc/scripts/q
```

(In case we have trouble booting: exit QEMU by first pressing Ctrl+A and then
pressing X, check whether [this post](https://github.com/xlab-uiuc/linux-mcdc/issues/4)
can solve the problem. If not, please [open an Issue](https://github.com/xlab-uiuc/linux-mcdc/issues/new).)

If all goes well, during the booting process, KUnit tests will also be executed
since we've enabled relevant options earlier. The results are printed to the
kernel log in [TAP format](https://testanything.org/), like below:

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

The hostname part should be "guest", as specified [here](../scripts/q#L21). The
kernel version should be 5.15.153.

<!--

Sanity check:

Besides being printed to kernel log during the booting process, KUnit results
are also accessible in debugfs. E.g. inside the guest,

$ ls /sys/kernel/debug/kunit/
$ cat /sys/kernel/debug/kunit/qos-kunit-test/results

-->

Let's inspect the directory added to debugfs by our patch:

```shell
# (guest)
ls /sys/kernel/debug/llvm-cov
```

which should contain three pseudo files: `profraw`, `cnts_reset` and `bits_reset`.

- Writing to `cnts_reset` will clear the in-memory counters
- Writing to `bits_reset` will clear the in-memory bitmaps
- Reading `profraw` will serialize the in-memory counters and bitmaps in a
  [proper format](https://llvm.org/docs/InstrProfileFormat.html)
  <!-- The essential difference between LLVM 18 and 19 is this format. Since we
       don't have 19 releases yet. Point to the latest documentation.        -->
  that is recognized by LLVM tools.

Let's copy the profile to current directory, which is [shared with host
directory `$MCDC_HOME/linux` through 9p](../scripts/q#L79-L86), so that we can
access the same file outside VM and complete the remaining steps on the host
machine.

```shell
# (guest)
cp /sys/kernel/debug/llvm-cov/profraw .
```

Press Ctrl+D to exit the VM. We will get back to `$MCDC_HOME/linux` of the host
and should have had a copy of `profraw` there.

```shell
# (host)
file profraw
```

The result should be:

```text
profraw: LLVM raw profile data, version 10
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
              -show-directory-coverage                                         \
              -output-dir=html-coverage-reports                                \
              -instr-profile profdata                                          \
              $MCDC_HOME/linux/vmlinux
```

The results will be put under `$MCDC_HOME/analysis/html-coverage-reports`.

<!--

Sanity check:

Compare the overall coverage with the screenshot in this repo, i.e. line
coverage being ~10%, MC/DC being ~2%.

Pick up some decisions and inspect their detailed MC/DC reports, e.g.
arch/x86/events/probe.c.html#L43.

-->

## Troubleshooting

For any trouble, feel free to [open an Issue](https://github.com/xlab-uiuc/linux-mcdc/issues/new).

To assure ourselves nothing goes fundamentally wrong in the middle, we can also
go to the ["Code" view](./measure-kernel-mcdc.md?plain=1) of this page, search
for "Sanity check" hidden in comments and follow the instructions there.
