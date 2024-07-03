#!/bin/bash

#
# Test the functionality of cnts_reset
#

GUEST_COMMANDS="true"
GUEST_COMMANDS="$GUEST_COMMANDS; uname -a"
GUEST_COMMANDS="$GUEST_COMMANDS; ls /sys/kernel/debug/llvm-cov"
GUEST_COMMANDS="$GUEST_COMMANDS; echo 1 > /sys/kernel/debug/llvm-cov/cnts_reset"
GUEST_COMMANDS="$GUEST_COMMANDS; cp /sys/kernel/debug/llvm-cov/profraw ."

cd $MCDC_HOME/linux
$MCDC_HOME/linux-mcdc/scripts/q -c "$GUEST_COMMANDS"

file profraw |& tee /tmp/file.log
if ! grep "LLVM raw profile data, version 10" /tmp/file.log > /dev/null; then
    printf "\nUnexpected profraw\n"
    exit 1
fi

mkdir -p $MCDC_HOME/analysis_cnts_reset
mv profraw $MCDC_HOME/analysis_cnts_reset
cd $MCDC_HOME/analysis_cnts_reset

llvm-profdata merge profraw -o profdata
llvm-cov show --show-mcdc                                                      \
              --show-mcdc-summary                                              \
              --show-region-summary=false                                      \
              --show-branch-summary=false                                      \
              --format=text                                                    \
              -use-color                                                       \
              -show-directory-coverage                                         \
              -output-dir=text-coverage-reports                                \
              -instr-profile profdata                                          \
              $MCDC_HOME/linux/vmlinux

#
# Test the functionality of bits_reset
#

GUEST_COMMANDS="true"
GUEST_COMMANDS="$GUEST_COMMANDS; uname -a"
GUEST_COMMANDS="$GUEST_COMMANDS; ls /sys/kernel/debug/llvm-cov"
GUEST_COMMANDS="$GUEST_COMMANDS; echo 1 > /sys/kernel/debug/llvm-cov/bits_reset"
GUEST_COMMANDS="$GUEST_COMMANDS; cp /sys/kernel/debug/llvm-cov/profraw ."

cd $MCDC_HOME/linux
$MCDC_HOME/linux-mcdc/scripts/q -c "$GUEST_COMMANDS"

file profraw |& tee /tmp/file.log
if ! grep "LLVM raw profile data, version 10" /tmp/file.log > /dev/null; then
    printf "\nUnexpected profraw\n"
    exit 1
fi

mkdir -p $MCDC_HOME/analysis_bits_reset
mv profraw $MCDC_HOME/analysis_bits_reset
cd $MCDC_HOME/analysis_bits_reset

llvm-profdata merge profraw -o profdata
llvm-cov show --show-mcdc                                                      \
              --show-mcdc-summary                                              \
              --show-region-summary=false                                      \
              --show-branch-summary=false                                      \
              --format=text                                                    \
              -use-color                                                       \
              -show-directory-coverage                                         \
              -output-dir=text-coverage-reports                                \
              -instr-profile profdata                                          \
              $MCDC_HOME/linux/vmlinux

#
# Actual coverage of KUnit + boot
#

GUEST_COMMANDS="true"
GUEST_COMMANDS="$GUEST_COMMANDS; uname -a"
GUEST_COMMANDS="$GUEST_COMMANDS; ls /sys/kernel/debug/llvm-cov"
GUEST_COMMANDS="$GUEST_COMMANDS; cp /sys/kernel/debug/llvm-cov/profraw ."

cd $MCDC_HOME/linux
$MCDC_HOME/linux-mcdc/scripts/q -c "$GUEST_COMMANDS"

file profraw |& tee /tmp/file.log
if ! grep "LLVM raw profile data, version 10" /tmp/file.log > /dev/null; then
    printf "\nUnexpected profraw\n"
    exit 1
fi

mkdir -p $MCDC_HOME/analysis
mv profraw $MCDC_HOME/analysis
cd $MCDC_HOME/analysis

llvm-profdata merge profraw -o profdata
llvm-cov show --show-mcdc                                                      \
              --show-mcdc-summary                                              \
              --show-region-summary=false                                      \
              --show-branch-summary=false                                      \
              --format=text                                                    \
              -use-color                                                       \
              -show-directory-coverage                                         \
              -output-dir=text-coverage-reports                                \
              -instr-profile profdata                                          \
              $MCDC_HOME/linux/vmlinux
