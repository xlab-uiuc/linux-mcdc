#!/bin/bash

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
