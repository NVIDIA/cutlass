#!/bin/bash
#
# test_dlopen_benchmark.sh — Test the two-phase dlopen workflow with a single
# configuration (unity OFF) and write results to a fresh CSV.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="${SCRIPT_DIR}/dlopen_benchmark_results.csv"
BUILD_BASE="${SCRIPT_DIR}/build_base"
BUILD_KERNELS="${SCRIPT_DIR}/build_kernels"
NPROC=32

KERNEL_PATTERN="cutlass3x_sm90_tensorop_gemm_f16_f16_f32_void_f32_128x128x64_2x1x1_0_ntn_align8*"

PROFILER_ARGS=(
  --operation=Gemm
  --m=4096 --n=4096 --k=4096
  --A=f16:column --B=f16:row --D=f32:column
  --beta=0
  --warmup-iterations=5
  --profiling-iterations=20
  --verification-enabled=false
)

# ── Helpers ─────────────────────────────────────────────────────────────────
measure_time() {
  local tmpfile
  tmpfile=$(mktemp)
  /usr/bin/time -f "%e" -o "$tmpfile" "$@"
  local rc=$?
  TIME_RESULT=$(cat "$tmpfile")
  rm -f "$tmpfile"
  return $rc
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# ── Phase 1: Build profiler infrastructure ──────────────────────────────────
log "=== Phase 1: Building profiler infrastructure (CUTLASS_PROFILER_ONLY=ON) ==="

rm -rf "$BUILD_BASE"
mkdir -p "$BUILD_BASE"

log "Running cmake (base) ..."
measure_time cmake -S "$SCRIPT_DIR" -B "$BUILD_BASE" \
  -DCUTLASS_NVCC_ARCHS=90a \
  -DCUTLASS_PROFILER_ONLY=ON \
  -DCUTLASS_ENABLE_TESTS=OFF
base_cmake_time="$TIME_RESULT"
log "  base cmake time: ${base_cmake_time}s"

log "Building cutlass_profiler (base) ..."
measure_time make -C "$BUILD_BASE" cutlass_profiler -j${NPROC}
base_make_time="$TIME_RESULT"
log "  base make time: ${base_make_time}s"

profiler_bin="${BUILD_BASE}/tools/profiler/cutlass_profiler"
if [[ ! -x "$profiler_bin" ]]; then
  log "ERROR: cutlass_profiler binary not found at $profiler_bin"
  exit 1
fi
log "  Profiler binary ready: $profiler_bin"

# ── Phase 2: Build kernel .so files (unity OFF) ────────────────────────────
log "=== Phase 2: Building kernel .so files (unity=OFF) ==="

rm -rf "$BUILD_KERNELS"
mkdir -p "$BUILD_KERNELS"

log "Running cmake (kernels) ..."
measure_time cmake -S "$SCRIPT_DIR" -B "$BUILD_KERNELS" \
  -DCUTLASS_NVCC_ARCHS=90a \
  -DCUTLASS_LIBRARY_KERNELS="$KERNEL_PATTERN" \
  -DCUTLASS_ENABLE_TESTS=OFF \
  -DCUTLASS_LIBRARY_INSTANTIATION_LEVEL="max" \
  -DCUTLASS_UNITY_BUILD_ENABLED=OFF
kernel_cmake_time="$TIME_RESULT"
log "  kernel cmake time: ${kernel_cmake_time}s"

# Count generated kernels
kernel_list="${BUILD_KERNELS}/tools/library/generated_kernels.txt"
if [[ -f "$kernel_list" ]]; then
  kernel_count=$(wc -l < "$kernel_list")
else
  log "  WARNING: generated_kernels.txt not found"
  kernel_count=0
fi
log "  kernel count: ${kernel_count}"

# Extract kernel-only CMake targets from generated manifest.cmake
# These are the SUFFIX values in cutlass_add_cutlass_library(SUFFIX ...)
manifest_cmake="${BUILD_KERNELS}/tools/library/generated/manifest.cmake"
kernel_targets=()
if [[ -f "$manifest_cmake" ]]; then
  while IFS= read -r suffix; do
    kernel_targets+=("cutlass_library_${suffix}")
  done < <(grep -oP 'SUFFIX\s+\K\S+' "$manifest_cmake")
fi

if [[ ${#kernel_targets[@]} -eq 0 ]]; then
  log "ERROR: no kernel targets found in $manifest_cmake"
  exit 1
fi
log "  Kernel targets: ${kernel_targets[*]}"

log "Building kernel libraries (kernel targets only) ..."
measure_time make -C "$BUILD_KERNELS" "${kernel_targets[@]}" -j${NPROC}
kernel_make_time="$TIME_RESULT"
log "  kernel make time: ${kernel_make_time}s"

# ── Phase 3: Run profiler with --kernel-lib ─────────────────────────────────
log "=== Phase 3: Running profiler with dynamically loaded kernels ==="

# Find kernel .so files
kernel_libs=$(find "$BUILD_KERNELS/tools/library" -name "libcutlass_*.so" -not -name "libcutlass.so" 2>/dev/null | paste -sd, -)

if [[ -z "$kernel_libs" ]]; then
  log "ERROR: no kernel .so files found in $BUILD_KERNELS/tools/library"
  log "Listing contents:"
  find "$BUILD_KERNELS/tools/library" -name "*.so" -o -name "*.a" | head -20
  exit 1
fi

log "  Found kernel libs: $kernel_libs"

log "Running profiler ..."
measure_time "$profiler_bin" --kernel-lib="$kernel_libs" "${PROFILER_ARGS[@]}"
bench_time="$TIME_RESULT"
log "  bench time: ${bench_time}s"

# ── Write CSV ───────────────────────────────────────────────────────────────
echo "config,kernel_count,unity_mode,base_cmake_sec,base_make_sec,kernel_cmake_sec,kernel_make_sec,bench_sec" > "$CSV_FILE"
echo "large,${kernel_count},OFF,${base_cmake_time},${base_make_time},${kernel_cmake_time},${kernel_make_time},${bench_time}" >> "$CSV_FILE"

log "=== Done ==="
log "Results:"
column -t -s',' "$CSV_FILE"
