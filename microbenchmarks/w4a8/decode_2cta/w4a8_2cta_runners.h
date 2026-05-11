#pragma once

// Cross-TU interface for the decode_2cta experiment driver.
//
// The experiment ships three translation units. Two run the GEMM kernel:
//
//   w4a8_2cta_ref.cu   compiled WITHOUT the CUTLASS_W4A8_* macro overrides;
//                      instantiates and runs the canonical baseline C1 schedule.
//                      Time + output captured here is what every speedup number
//                      is measured against.
//
//   w4a8_2cta_test.cu  compiled WITH the macro overrides
//                      (CUTLASS_W4A8_MIN_BLOCKS_PER_SM=2,
//                       CUTLASS_W4A8_MMA_REG_REQUIREMENT=88,
//                       CUTLASS_W4A8_LOAD_REG_REQUIREMENT=40);
//                      instantiates and runs the experimental decode_2cta
//                      schedule (StageCount=9 + 2 CTAs/SM via launch bounds).
//
//   w4a8_2cta_main.cu  drives both: parses CLI, owns W4A8SharedInputs, calls
//                      run_ref / run_test, runs the equality check and prints
//                      the comparison.
//
// Each runner returns its measured timing AND copies its bf16 block_D out to a
// caller-owned host vector so the main TU can compare without any cross-TU
// W4A8GemmContext type leakage.

#include <cstddef>
#include <vector>

#include "cutlass/numeric_types.h"

#include "common/w4a8_bench_common.hpp"

// Forward declaration; full definition lives in common/w4a8_grouped_setup.cuh.
struct W4A8SharedInputs;

struct W4A8RunResult {
  SweepResult result;
  std::vector<cutlass::bfloat16_t> host_D;  // populated by a deterministic re-run.
};

W4A8RunResult run_ref(W4A8SharedInputs &shared, W4A8BenchOptions const &opt);
W4A8RunResult run_test(W4A8SharedInputs &shared, W4A8BenchOptions const &opt);
