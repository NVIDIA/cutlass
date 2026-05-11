#!/usr/bin/env bash
# Build and run the W4A8 grouped GEMM "decode 2 CTAs/SM" experiment.
# Requires CUDA 12.3+ nvcc and a Hopper (SM90) GPU.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-${ROOT}/build}"
CUTLASS_DIR="${CUTLASS_DIR:-$(cd "${ROOT}/../../.." && pwd)}"

if [[ -n "${CUDA_HOME:-}" && -x "${CUDA_HOME}/bin/nvcc" ]]; then
  export PATH="${CUDA_HOME}/bin:${PATH}"
elif [[ -x "/usr/local/cuda/bin/nvcc" ]]; then
  export CUDA_HOME="/usr/local/cuda"
  export PATH="${CUDA_HOME}/bin:${PATH}"
fi
export CMAKE_CUDA_COMPILER="${CMAKE_CUDA_COMPILER:-$(command -v nvcc)}"

if ! command -v nvcc >/dev/null 2>&1; then
  echo "nvcc not found. Set CUDA_HOME or add CUDA toolkit to PATH." >&2
  exit 1
fi

cmake -S "${ROOT}" -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCUTLASS_DIR="${CUTLASS_DIR}" \
  -DCMAKE_CUDA_ARCHITECTURES=90a \
  -DCMAKE_CUDA_COMPILER="${CMAKE_CUDA_COMPILER}"

cmake --build "${BUILD_DIR}" -j "${JOBS:-$(nproc 2>/dev/null || echo 64)}" --target w4a8_2cta

# Default decode shape: 128 experts, M=1, N=1536, K=4096, c=128. GPU4 by default
# (override with CUDA_VISIBLE_DEVICES=...) per the established convention while
# other GPUs on this host are in use.
exec env CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-4}" \
  "${BUILD_DIR}/w4a8_2cta" \
  --groups=128 \
  --m=1 \
  --n=1536 \
  --k=4096 \
  --c=128 \
  --alpha=1 \
  --beta=0 \
  --warmup=20 \
  --iterations=200 \
  "$@"
