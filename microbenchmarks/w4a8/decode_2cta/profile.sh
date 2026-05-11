#!/usr/bin/env bash
# Profile the decode_2cta experiment kernel with Nsight Compute.
# Builds the experiment binary if needed, runs ncu against w4a8_2cta filtered to
# the StageCount=10 (test) kernel only, and saves the report + a details dump
# + a raw-metrics CSV.
#
# Usage:
#   CUDA_VISIBLE_DEVICES=4 ./profile.sh                # default report
#   CUDA_VISIBLE_DEVICES=4 PMSAMPLE=1 ./profile.sh     # adds PC sampling
#
# Modes:
#   default                : SpeedOfLight + memory/scheduler/warp/instruction/launch/occupancy sections.
#   PMSAMPLE=1             : adds SourceCounters + PmSampling + PmSampling_WarpStates so the SASS view
#                            in ncu-ui can break down stalls per source/SASS line.
#                            Writes to profiles/decode_2cta_pmsample.ncu-rep so the default report is
#                            preserved untouched.
#
# Note: the binary launches BOTH the reference C1 kernel (StageCount=19, stock
# CUTLASS launch bounds) and the experimental decode_2cta kernel (StageCount=9,
# 2 CTAs/SM launch bounds). The ncu --kernel-name regex below filters down to the
# StageCount=9 instance only (mangled name fragment "MainloopSm90Array...Li9E"),
# so the captured launches are unambiguously the experiment kernel.
#
# Requires CUDA 12.3+ and a Hopper (SM90) GPU. Pinned to GPU 4 by default.
# Needs access to NVIDIA GPU perf counters - either run as root (sudo -E ...) or set
#   NVreg_RestrictProfilingToAdminUsers=0 on the nvidia kernel module.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-${ROOT}/build}"
PROFILES_DIR="${ROOT}/profiles"
CUTLASS_DIR="${CUTLASS_DIR:-$(cd "${ROOT}/../../.." && pwd)}"
PMSAMPLE="${PMSAMPLE:-0}"

# Filter to the StageCount=9 (test) kernel by default. The cooperative
# CollectiveMma carries StageCount as the first non-type template arg, mangled
# as Li9E for the test kernel and Li19E for the ref. Override via env if the
# StageCount parameter changes.
NCU_KERNEL_REGEX="${NCU_KERNEL_REGEX:-regex:.*MainloopSm90ArrayTmaGmmaWarpSpecializedMixedInputILi9E.*}"

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
if ! command -v ncu >/dev/null 2>&1; then
  echo "ncu (Nsight Compute) not found. Add CUDA toolkit bin/ to PATH." >&2
  exit 1
fi

cmake -S "${ROOT}" -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCUTLASS_DIR="${CUTLASS_DIR}" \
  -DCMAKE_CUDA_ARCHITECTURES=90a \
  -DCMAKE_CUDA_COMPILER="${CMAKE_CUDA_COMPILER}" >/dev/null

cmake --build "${BUILD_DIR}" -j "${JOBS:-$(nproc 2>/dev/null || echo 64)}" --target w4a8_2cta

mkdir -p "${PROFILES_DIR}"
REPORT_SUFFIX=""
NCU_LAUNCH_COUNT=3
NCU_BENCH_ITERATIONS=4

NCU_SECTIONS=(
  --section SpeedOfLight
  --section SpeedOfLight_RooflineChart
  --section LaunchStats
  --section Occupancy
  --section MemoryWorkloadAnalysis
  --section MemoryWorkloadAnalysis_Chart
  --section MemoryWorkloadAnalysis_Tables
  --section SchedulerStats
  --section WarpStateStats
  --section ComputeWorkloadAnalysis
  --section InstructionStats
)

NCU_EXTRA_ARGS=()
if [[ "${PMSAMPLE}" == "1" ]]; then
  NCU_SECTIONS+=(
    --section SourceCounters
    --section PmSampling
    --section PmSampling_WarpStates
  )
  NCU_EXTRA_ARGS+=(--import-source yes)
  REPORT_SUFFIX="_pmsample"
  NCU_LAUNCH_COUNT=2
  NCU_BENCH_ITERATIONS=8
fi
REPORT_BASE="${PROFILES_DIR}/decode_2cta${REPORT_SUFFIX}"

export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-4}"

# --launch-skip 1: drop the runner's first warmup launch (issued before the
# profile_variant timing window).
ncu \
  --target-processes all \
  --kernel-name-base mangled \
  --kernel-name "${NCU_KERNEL_REGEX}" \
  --launch-skip 1 \
  --launch-count "${NCU_LAUNCH_COUNT}" \
  "${NCU_SECTIONS[@]}" \
  "${NCU_EXTRA_ARGS[@]}" \
  --export "${REPORT_BASE}" --force-overwrite \
  "${BUILD_DIR}/w4a8_2cta" \
    --m=1 --n=1536 --k=4096 --groups=128 --c=128 \
    --warmup=1 --iterations="${NCU_BENCH_ITERATIONS}"

ncu --import "${REPORT_BASE}.ncu-rep" --page details --print-units base \
    > "${REPORT_BASE}_details.txt" 2>&1 || true

ncu --import "${REPORT_BASE}.ncu-rep" --csv --page raw \
    > "${REPORT_BASE}_metrics.csv" 2>&1 || true

echo
echo "ncu report   : ${REPORT_BASE}.ncu-rep"
echo "ncu details  : ${REPORT_BASE}_details.txt"
echo "ncu raw CSV  : ${REPORT_BASE}_metrics.csv"
echo "kernel filter: ${NCU_KERNEL_REGEX}"
if [[ "${PMSAMPLE}" == "1" ]]; then
  echo
  echo "PC sampling enabled. Open the report in Nsight Compute UI and switch to"
  echo "the Source page, then sort SASS by smsp__warp_issue_stalled_long_scoreboard"
  echo "(or stall_short_scoreboard / stall_mio_throttle) to see which SASS lines"
  echo "are absorbing the stalls."
fi
