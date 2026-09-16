#!/usr/bin/env bash
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Runs a device integration test through the cutlass_compiler GPU pipeline and
# JIT-launches the kernel via mlir-runner on **real GPU silicon**
# (SM90/SM100, etc.). Uses the native CUDA driver.
#
# Pipeline
#   cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base
#                    -base-prepare -one-shot-convert-to-llvm
#                    -attach-nvvm-target=chip=<sm>,features=<ptx>
#                    -emit-gpu-binary=compilation-target=<fmt>
#   | mlir-runner -e <entry> -entry-point-result=void
#                 --shared-libs=$MLIR_CUDA_RUNTIME
#                 --shared-libs=$MLIR_RUNNER_UTILS
#                 --shared-libs=$MLIR_C_RUNNER_UTILS
#
# Usage
#   run_integration_device.sh <input.mlir>
#       [--sm <sm_xx>]                       # default: CUTLASS_COMPILER_DEVICE_SM / TEST_GPU_ARCH / sm_90
#       [--compilation-target <isa|bin|fatbin|llvm>]  # default: bin
#       [-e <entry-point>]                   # default: main
#       [-- <extra mlir-runner flags>]
#
# Required env
#   CUTLASS_COMPILER_BUILD_DIR  - top-level cutlass_compiler build dir.
#
# Optional env
#   CUTLASS_COMPILER_DEVICE_SM, TEST_GPU_ARCH, CUDA_PATH, CUDA_HOME,
#   CUTLASS_COMPILER, MLIR_RUNNER, MLIR_CUDA_RUNTIME,
#   MLIR_RUNNER_UTILS, MLIR_C_RUNNER_UTILS.

set -euo pipefail

cutlass_compiler_resolve_target_sm() {
  local fallback="${1:-sm_90}"
  if [ -n "${CUTLASS_COMPILER_DEVICE_SM:-}" ]; then
    echo "$CUTLASS_COMPILER_DEVICE_SM"
    return
  fi
  if [ -n "${TEST_GPU_ARCH:-}" ]; then
    echo "$TEST_GPU_ARCH"
    return
  fi
  echo "$fallback"
}

cutlass_compiler_ensure_cuda_path() {
  if [ -n "${CUDA_PATH:-}" ] && [ -d "$CUDA_PATH" ]; then
    export CUDA_HOME="${CUDA_HOME:-$CUDA_PATH}"
    return 0
  fi

  local candidate tool_path
  local candidates=(
    "${CUDA_HOME:-}"
    "${CUDA_TOOLKIT_PATH:-}"
    "${CUDA_TOOLKIT_LOCATION:-}"
    "/usr/local/cuda"
    "${CUTLASS_COMPILER_BUILD_DIR:-}/third_party/cuda"
    "${CUTLASS_COMPILER_BUILD_DIR:-}/../third_party/cuda"
  )
  for candidate in "${candidates[@]}"; do
    if [ -n "$candidate" ] && [ -d "$candidate" ] && \
       { [ -x "$candidate/bin/ptxas" ] || [ -x "$candidate/bin/nvcc" ]; }; then
      export CUDA_PATH="$candidate"
      export CUDA_HOME="${CUDA_HOME:-$CUDA_PATH}"
      return 0
    fi
  done

  for tool in ptxas nvcc; do
    if tool_path="$(command -v "$tool" 2>/dev/null)"; then
      candidate="$(cd "$(dirname "$tool_path")/.." && pwd)"
      if [ -d "$candidate" ]; then
        export CUDA_PATH="$candidate"
        export CUDA_HOME="${CUDA_HOME:-$CUDA_PATH}"
        return 0
      fi
    fi
  done
  return 1
}

if [ "$#" -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  sed -n '30,58p' "$0"
  exit 0
fi

INPUT=""
TARGET_SM=""
COMPILATION_TARGET="bin"
ENTRY="main"
RUNNER_EXTRA=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --sm)
      TARGET_SM="$2"
      shift 2
      ;;
    --compilation-target)
      COMPILATION_TARGET="$2"
      shift 2
      ;;
    -e)
      ENTRY="$2"
      shift 2
      ;;
    --)
      shift
      RUNNER_EXTRA=("$@")
      break
      ;;
    --*|-*)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
    *)
      if [ -n "$INPUT" ]; then
        echo "error: only one positional <input.mlir> supported (already have $INPUT, got $1)" >&2
        exit 2
      fi
      INPUT="$1"
      shift
      ;;
  esac
done

if [ -z "$INPUT" ]; then
  echo "error: missing positional <input.mlir>" >&2
  exit 2
fi
if [ ! -e "$INPUT" ]; then
  echo "error: input file not found: $INPUT" >&2
  exit 4
fi

if [ -z "${CUTLASS_COMPILER_BUILD_DIR:-}" ] || [ ! -d "$CUTLASS_COMPILER_BUILD_DIR" ]; then
  echo "error: CUTLASS_COMPILER_BUILD_DIR must point at the cutlass_compiler build dir." >&2
  exit 3
fi

if [ -z "$TARGET_SM" ]; then
  TARGET_SM="$(cutlass_compiler_resolve_target_sm sm_90)"
fi

case "$COMPILATION_TARGET" in
  bin|fatbin)
    if ! cutlass_compiler_ensure_cuda_path; then
      echo "error: CUDA_PATH must point at a CUDA toolkit for compilation-target=$COMPILATION_TARGET." >&2
      exit 3
    fi
    ;;
esac

if [ -n "${CUDA:-}" ] && [ ! -d "$CUDA" ]; then
  unset CUDA
fi

resolve_build_artifact() {
  local standalone_path="$1" legacy_path="$2"
  if [ -e "$standalone_path" ]; then
    printf '%s\n' "$standalone_path"
  else
    printf '%s\n' "$legacy_path"
  fi
}

CUTLASS_COMPILER="${CUTLASS_COMPILER:-$(resolve_build_artifact \
  "${CUTLASS_COMPILER_BUILD_DIR}/tools/cutlass-compiler/cutlass-compiler" \
  "${CUTLASS_COMPILER_BUILD_DIR}/cutlass_compiler/tools/cutlass-compiler/cutlass-compiler")}"
MLIR_RUNNER="${MLIR_RUNNER:-$(resolve_build_artifact \
  "${CUTLASS_COMPILER_BUILD_DIR}/llvm-project/bin/mlir-runner" \
  "${CUTLASS_COMPILER_BUILD_DIR}/llvm-prebuilt/bin/mlir-runner")}"
MLIR_CUDA_RUNTIME="${MLIR_CUDA_RUNTIME:-$(resolve_build_artifact \
  "${CUTLASS_COMPILER_BUILD_DIR}/llvm-project/lib/libmlir_cuda_runtime.so" \
  "${CUTLASS_COMPILER_BUILD_DIR}/llvm-prebuilt/lib/libmlir_cuda_runtime.so")}"
MLIR_RUNNER_UTILS="${MLIR_RUNNER_UTILS:-$(resolve_build_artifact \
  "${CUTLASS_COMPILER_BUILD_DIR}/llvm-project/lib/libmlir_runner_utils.so" \
  "${CUTLASS_COMPILER_BUILD_DIR}/llvm-prebuilt/lib/libmlir_runner_utils.so")}"
MLIR_C_RUNNER_UTILS="${MLIR_C_RUNNER_UTILS:-$(resolve_build_artifact \
  "${CUTLASS_COMPILER_BUILD_DIR}/llvm-project/lib/libmlir_c_runner_utils.so" \
  "${CUTLASS_COMPILER_BUILD_DIR}/llvm-prebuilt/lib/libmlir_c_runner_utils.so")}"

MLIR_LIB_DIR="$(dirname "$MLIR_RUNNER_UTILS")"
if [ -d "$MLIR_LIB_DIR" ]; then
  case ":${LD_LIBRARY_PATH:-}:" in
    *:"$MLIR_LIB_DIR":*) ;;
    *) export LD_LIBRARY_PATH="${MLIR_LIB_DIR}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
  esac
fi

require_executable() {
  local p="$1" label="$2"
  if [ ! -x "$p" ]; then
    echo "error: required tool $label is not executable: $p" >&2
    exit 4
  fi
}
require_file() {
  local p="$1" label="$2"
  if [ ! -e "$p" ]; then
    echo "error: required file $label is not found: $p" >&2
    exit 4
  fi
}

require_executable "$CUTLASS_COMPILER" "cutlass-compiler"
require_executable "$MLIR_RUNNER" "mlir-runner"
require_file "$MLIR_CUDA_RUNTIME" "libmlir_cuda_runtime.so"
require_file "$MLIR_RUNNER_UTILS" "libmlir_runner_utils.so"
require_file "$MLIR_C_RUNNER_UTILS" "libmlir_c_runner_utils.so"

RUN_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$RUN_TMPDIR"' EXIT
COMPILED_IR="$RUN_TMPDIR/compiled.mlir"

RUNNER_CMD=(
  "$MLIR_RUNNER"
  -e "$ENTRY"
  -entry-point-result=void
  --shared-libs="$MLIR_CUDA_RUNTIME"
  --shared-libs="$MLIR_RUNNER_UTILS"
  --shared-libs="$MLIR_C_RUNNER_UTILS"
)
if [ "${#RUNNER_EXTRA[@]}" -gt 0 ]; then
  RUNNER_CMD+=("${RUNNER_EXTRA[@]}")
fi

"$CUTLASS_COMPILER" \
  -cute-fold-static -cute-expand-ops -cute-to-base \
  -base-prepare -one-shot-convert-to-llvm \
  "-attach-nvvm-target=chip=$TARGET_SM" \
  "-emit-gpu-binary=compilation-target=$COMPILATION_TARGET" \
  "$INPUT" \
  -o "$COMPILED_IR"

exec "${RUNNER_CMD[@]}" "$COMPILED_IR"
