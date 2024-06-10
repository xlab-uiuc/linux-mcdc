#!/bin/bash

mkdir -p build
cd build
cmake -GNinja -DCMAKE_BUILD_TYPE="Release" \
              -DCMAKE_C_FLAGS="-pipe" \
              -DCMAKE_CXX_FLAGS="-pipe" \
              -DCMAKE_C_COMPILER="gcc" \
              -DCMAKE_CXX_COMPILER="g++" \
              -DLLVM_TARGETS_TO_BUILD="X86" \
              -DLLVM_ENABLE_ASSERTIONS="OFF" \
              -DLLVM_ENABLE_PROJECTS="clang;lld" \
              -DLLVM_USE_LINKER="mold" \
              -DLLVM_ENABLE_RUNTIMES="compiler-rt" \
              -DLLVM_PARALLEL_LINK_JOBS="2" \
              -DCMAKE_EXPORT_COMPILE_COMMANDS="ON" \
              ../llvm
ninja -j$(nproc)
