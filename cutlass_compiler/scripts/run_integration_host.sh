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

# Runs a host-only integration test through the full cutlass_compiler
# pipeline and JIT-executes it with mlir-runner.
#
#   pipeline = cute-fold-static
#            -> cute-expand-ops
#            -> cute-to-base
#            -> base-prepare
#            -> one-shot-convert-to-llvm
#            (single cutlass-compiler invocation)
#            -> mlir-runner --entry-point=<entry> --entry-point-result=void
#
# Usage:
#   run_integration_host.sh <input.mlir> [-e <entry-point>] [-- <extra mlir-runner flags>]
#
# Defaults:
#   - entry-point:        main
#   - entry-point-result: void
#
# Environment:
#   CUTLASS_COMPILER_BUILD_DIR     build directory (required)
#   CUTLASS_COMPILER   override path to the cutlass-compiler binary
#   MLIR_RUNNER        override path to the mlir-runner binary
#
# Example:
#   $ run_integration_host.sh print_static_layout.mlir
#   (2,3):(1,2)
#
# This script is the canonical way to run a host integration test
# manually outside the LIT suite. The LIT tests under
# `test/Integration/host/` use the same invocation via a substitution.

set -euo pipefail

if [ "$#" -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  sed -n '30,59p' "$0"
  exit 0
fi

INPUT="$1"
shift

ENTRY="main"
RUNNER_EXTRA=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    -e)
      ENTRY="$2"
      shift 2
      ;;
    --)
      shift
      RUNNER_EXTRA=("$@")
      break
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [ -z "${CUTLASS_COMPILER_BUILD_DIR:-}" ]; then
  echo "CUTLASS_COMPILER_BUILD_DIR is not set; export it to the cutlass_compiler build dir." >&2
  exit 3
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

for tool in "$CUTLASS_COMPILER" "$MLIR_RUNNER"; do
  if [ ! -x "$tool" ]; then
    echo "Required tool not executable: $tool" >&2
    exit 4
  fi
done

"$CUTLASS_COMPILER" \
    -cute-fold-static -cute-expand-ops -cute-to-base \
    -base-prepare -one-shot-convert-to-llvm \
    "$INPUT" \
| "$MLIR_RUNNER" -e "$ENTRY" -entry-point-result=void ${RUNNER_EXTRA[@]+"${RUNNER_EXTRA[@]}"}
