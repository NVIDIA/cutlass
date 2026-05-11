/***************************************************************************************************
 * Reference TU for the decode_2cta experiment.
 *
 * Compiled WITHOUT the CUTLASS_W4A8_* macro overrides, so the cooperative grouped
 * GEMM kernel keeps its CUTLASS-default __launch_bounds__(384, 1) and
 * setmaxnreg.dec/inc(40, 232). This produces the genuine "stock C1" timing that
 * the experimental decode_2cta variant is measured against.
 **************************************************************************************************/

#include <cstdio>
#include <cstdint>
#include <iostream>
#include <string>
#include <vector>

#include "common/w4a8_bench_common.hpp"
#include "common/w4a8_kernel_common.cuh"
#include "common/sm90_int4_fp8_grouped_baseline.cuh"
#include "common/w4a8_grouped_setup.cuh"

#include "cutlass/cutlass.h"
#include "cutlass/util/device_memory.h"

#include "helper.h"

#include "w4a8_2cta_runners.h"

#if !defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

W4A8RunResult run_ref(W4A8SharedInputs & /*shared*/, W4A8BenchOptions const & /*opt*/) {
  W4A8RunResult r;
  r.result.name = "baseline C1 (StageCountAuto, MinBlocks=1)";
  r.result.ok = false;
  r.result.status = "SKIP: requires CUDA 12.3+ and CUTLASS SM90";
  return r;
}

#else

using RefGemm = typename Int4Fp8C1BaselineSchedule::GemmScaleOnly;

W4A8RunResult run_ref(W4A8SharedInputs &shared, W4A8BenchOptions const &opt) {
  W4A8RunResult r;
  r.result.name = "baseline C1 (StageCountAuto, MinBlocks=1)";

  W4A8GemmContext<RefGemm> ctx;
  ctx.shared = &shared;
  ctx.allocate(opt);

  RefGemm gemm;
  auto arguments = ctx.make_arguments(opt);
  size_t workspace_size = RefGemm::get_workspace_size(arguments);
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  auto status_ci = gemm.can_implement(arguments);
  if (status_ci != cutlass::Status::kSuccess) {
    r.result.ok = false;
    r.result.status = std::string("SKIP can_implement: ") + cutlass::cutlassGetStatusString(status_ci);
    return r;
  }
  auto status_init = gemm.initialize(arguments, workspace.get());
  if (status_init != cutlass::Status::kSuccess) {
    r.result.ok = false;
    r.result.status = std::string("SKIP initialize: ") + cutlass::cutlassGetStatusString(status_init);
    return r;
  }

  auto status_run = gemm.run();
  if (status_run != cutlass::Status::kSuccess) {
    r.result.ok = false;
    r.result.status = std::string("SKIP run: ") + cutlass::cutlassGetStatusString(status_run);
    return r;
  }
  W4A8_CUDA_SYNC();

  r.result = profile_variant(r.result.name, opt, [&]() { CUTLASS_CHECK(gemm.run()); });

  // Deterministic re-run for the equality check: zero D, run once, sync, copy out.
  ctx.zero_outputs();
  W4A8_CUDA_SYNC();
  CUTLASS_CHECK(gemm.run());
  W4A8_CUDA_SYNC();

  r.host_D.resize(ctx.block_D.size());
  ctx.block_D.copy_to_host(r.host_D.data());
  return r;
}

#endif // CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED
