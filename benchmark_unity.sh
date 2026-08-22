#!/bin/bash
#
# benchmark_unity.sh — Measure the effect of CMake unity build mode on CUTLASS
# kernel compilation across different kernel counts and batch sizes.
#
# Two-phase build:
#   Phase 1: Build profiler infrastructure ONCE with CUTLASS_PROFILER_ONLY=ON
#   Phase 2: For each (config, unity_mode): build ONLY kernel .so files
#   Phase 3: Run profiler from base build, loading kernel .so dynamically
#
# Outputs: unity_benchmark_results.csv
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="${SCRIPT_DIR}/small_test_unity_benchmark_results.csv"
BUILD_BASE="${SCRIPT_DIR}/build_base"
BUILD_KERNELS="${SCRIPT_DIR}/build_kernels"
NPROC=8

# Profiler arguments (constant across all test cases)
PROFILER_ARGS=(
  --operation=Gemm
  --m=4096 --n=4096 --k=4096
  --A=f16:column --B=f16:row --D=f32:column
  --beta=0
  --warmup-iterations=5
  --profiling-iterations=20
  --verification-enabled=false
)

# ── Kernel configs ──────────────────────────────────────────────────────────
# Each entry: "config_name|kernel_pattern"
CONFIGS=(
  # "small|cutlass3x_sm90_tensorop_gemm_f16_f16_f32_void_f32_128x128x64_2x1x1_0_ntn_align8*"
  # "medium|cutlass3x_sm90_tensorop_gemm_f16_f16_f32_void_f32_128x128x64*ntn*"
  "large|cutlass3x_sm90_tensorop_gemm_f16_f16_f32_void_f32_128x128x64*"
)


# ── Unity modes ─────────────────────────────────────────────────────────────
# Each entry: "mode_label|batch_size|cmake_flags"
UNITY_MODES=(
  "OFF|0|-DCUTLASS_UNITY_BUILD_ENABLED=OFF"
  # "batch_1|1|-DCUTLASS_UNITY_BUILD_ENABLED=ON -DCUTLASS_UNITY_BUILD_BATCH_SIZE=1"
  "batch_4|4|-DCUTLASS_UNITY_BUILD_ENABLED=ON -DCUTLASS_UNITY_BUILD_BATCH_SIZE=4"
  # "batch_16|16|-DCUTLASS_UNITY_BUILD_ENABLED=ON -DCUTLASS_UNITY_BUILD_BATCH_SIZE=16"
)

# ── Helpers ─────────────────────────────────────────────────────────────────

# Measure wall-clock seconds of a command; stores result in TIME_RESULT.
measure_time() {
  local tmpfile
  tmpfile=$(mktemp)
  # /usr/bin/time writes to stderr; capture its output separately.
  /usr/bin/time -f "%e" -o "$tmpfile" "$@"
  local rc=$?
  TIME_RESULT=$(cat "$tmpfile")
  rm -f "$tmpfile"
  return $rc
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# ── Phase 1: Build profiler infrastructure ONCE ─────────────────────────────

log "============================================================"
log "Phase 1: Building profiler infrastructure (CUTLASS_PROFILER_ONLY=ON)"
log "============================================================"

if [[ -x "${BUILD_BASE}/tools/profiler/cutlass_profiler" ]]; then
  log "  Profiler binary already exists, skipping Phase 1"
  base_make_time="cached"
else
  rm -rf "$BUILD_BASE"
  mkdir -p "$BUILD_BASE"

  log "Running cmake (base) ..."
  cmake -S "$SCRIPT_DIR" -B "$BUILD_BASE" \
    -DCUTLASS_NVCC_ARCHS=90a \
    -DCUTLASS_PROFILER_ONLY=ON \
    -DCUTLASS_ENABLE_TESTS=OFF

  log "Building cutlass_profiler (base) ..."
  measure_time make -C "$BUILD_BASE" cutlass_profiler -j${NPROC}
  base_make_time="$TIME_RESULT"
  log "  Base profiler build time: ${base_make_time}s"
fi

profiler_bin="${BUILD_BASE}/tools/profiler/cutlass_profiler"

# ── Phase 2 & 3: For each config/unity, build kernels then profile ──────────

echo "config,kernel_count,unity_mode,batch_size,cmake_time_sec,make_time_sec,bench_time_sec,base_make_time_sec" > "$CSV_FILE"

total_cases=$(( ${#CONFIGS[@]} * ${#UNITY_MODES[@]} ))
case_num=0

for config_entry in "${CONFIGS[@]}"; do
  IFS='|' read -r config_name kernel_pattern <<< "$config_entry"

  for unity_entry in "${UNITY_MODES[@]}"; do
    IFS='|' read -r unity_mode batch_size unity_flags <<< "$unity_entry"

    case_num=$((case_num + 1))
    log "--- Case ${case_num}/${total_cases}: config=${config_name}  unity=${unity_mode} ---"

    # Phase 2: Build only kernel .so files
    rm -rf "$BUILD_KERNELS"
    mkdir -p "$BUILD_KERNELS"

    log "Running cmake (kernels) ..."
    # shellcheck disable=SC2086
    measure_time cmake -S "$SCRIPT_DIR" -B "$BUILD_KERNELS" \
      -DCUTLASS_NVCC_ARCHS=90a \
      -DCUTLASS_LIBRARY_KERNELS="$kernel_pattern" \
      -DCUTLASS_ENABLE_TESTS=OFF \
      -DCUTLASS_LIBRARY_INSTANTIATION_LEVEL="max" \
      $unity_flags
    cmake_time="$TIME_RESULT"
    log "  cmake time: ${cmake_time}s"

    # Count generated kernels
    kernel_list="${BUILD_KERNELS}/tools/library/generated_kernels.txt"
    if [[ -f "$kernel_list" ]]; then
      kernel_count=$(wc -l < "$kernel_list")
    else
      log "  WARNING: generated_kernels.txt not found"
      kernel_count=0
    fi
    log "  kernel count: ${kernel_count}"

    # Build kernel shared libraries only (not the full profiler)
    log "Building kernel libraries ..."
    measure_time make -C "$BUILD_KERNELS" cutlass_library -j${NPROC}
    make_time="$TIME_RESULT"
    log "  kernel make time: ${make_time}s"

    # Phase 3: Run profiler with dynamically loaded kernel .so files
    # Find all generated kernel .so files
    kernel_libs=$(find "$BUILD_KERNELS/tools/library" -name "libcutlass_*.so" -not -name "libcutlass.so" | paste -sd, -)

    if [[ -x "$profiler_bin" ]] && [[ -n "$kernel_libs" ]]; then
      log "Running profiler with --kernel-lib ..."
      measure_time "$profiler_bin" --kernel-lib="$kernel_libs" "${PROFILER_ARGS[@]}"
      bench_time="$TIME_RESULT"
      log "  bench time: ${bench_time}s"
    else
      if [[ ! -x "$profiler_bin" ]]; then
        log "  WARNING: cutlass_profiler binary not found; skipping benchmark"
      else
        log "  WARNING: no kernel .so files found; skipping benchmark"
      fi
      bench_time="N/A"
    fi

    # Record result
    echo "${config_name},${kernel_count},${unity_mode},${batch_size},${cmake_time},${make_time},${bench_time},${base_make_time}" >> "$CSV_FILE"
    log "  Row written to CSV"
  done
done

log "============================================================"
log "All ${total_cases} cases complete"
log "Results saved to: ${CSV_FILE}"
log "Base profiler build time: ${base_make_time}s (one-time cost)"
echo ""
column -t -s',' "$CSV_FILE"
