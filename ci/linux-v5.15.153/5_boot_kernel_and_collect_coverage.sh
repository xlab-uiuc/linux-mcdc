#!/bin/bash

guest_timeout=600

#
# Test the functionality of reset
#

GUEST_COMMANDS="true"
GUEST_COMMANDS="$GUEST_COMMANDS; uname -a"
GUEST_COMMANDS="$GUEST_COMMANDS; ls /sys/kernel/debug/llvm-cov"
GUEST_COMMANDS="$GUEST_COMMANDS; echo 1 > /sys/kernel/debug/llvm-cov/reset"
GUEST_COMMANDS="$GUEST_COMMANDS; cp /sys/kernel/debug/llvm-cov/profraw ."

cd $MCDC_HOME/linux
timeout $guest_timeout $MCDC_HOME/linux-mcdc/scripts/q -c "$GUEST_COMMANDS"
ret=$?
if [[ $ret -eq 124 ]]; then
    exit 1
fi

file profraw |& tee /tmp/file.log
if ! grep "LLVM raw profile data, version 10" /tmp/file.log > /dev/null; then
    printf "\nUnexpected profraw\n"
    exit 1
fi

mkdir -p $MCDC_HOME/analysis_reset
mv profraw $MCDC_HOME/analysis_reset
cd $MCDC_HOME/analysis_reset

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
timeout $guest_timeout $MCDC_HOME/linux-mcdc/scripts/q -c "$GUEST_COMMANDS"
ret=$?
if [[ $ret -eq 124 ]]; then
    exit 1
fi

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
