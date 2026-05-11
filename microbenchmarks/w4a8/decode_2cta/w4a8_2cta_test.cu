/***************************************************************************************************
 * Test TU for the decode_2cta experiment.
 *
 * Compiled WITH the three CUTLASS_W4A8_* macro overrides, so the cooperative
 * grouped GEMM kernel uses __launch_bounds__(384, 2) and setmaxnreg.dec/inc(40, 88).
 * The instantiated schedule is Int4Fp8GemmGivenScheduleStaged<C1Tile, Coop, kStages=9>.
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

#include "sm90_int4_fp8_grouped_2cta.cuh"

#include "cutlass/cutlass.h"
#include "cutlass/util/device_memory.h"

#include "helper.h"

#include "w4a8_2cta_runners.h"

#if !defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED)

W4A8RunResult run_test(W4A8SharedInputs & /*shared*/, W4A8BenchOptions const & /*opt*/) {
  W4A8RunResult r;
  r.result.name = "decode_2cta C1 (Stages=9, MinBlocks=2, sm_count=264)";
  r.result.ok = false;
  r.result.status = "SKIP: requires CUDA 12.3+ and CUTLASS SM90";
  return r;
}

#else

namespace {
using TestConfig = GemmConfig<cute::Shape<cute::_128, cute::_16, cute::Int<TileShapeK>>,
                              cute::Shape<cute::_1, cute::_1, cute::_1>>;
// kStages=9: chosen so per-block dynamic SMEM drops below the H200 232 KiB / 2
// budget, letting the runtime block scheduler actually pack 2 CTAs/SM. At
// kStages=10 the SMEM was 121 KiB/block (2x = 242 KiB > 228 KiB usable) and
// `Block Limit Shared Mem` stayed at 1, defeating the entire experiment.
using TestSchedule = Int4Fp8GemmGivenScheduleStaged<
    TestConfig,
    cutlass::gemm::KernelPtrArrayTmaWarpSpecializedCooperative,
    /*kStages=*/9>;
using TestGemm = typename TestSchedule::GemmScaleOnly;
}

W4A8RunResult run_test(W4A8SharedInputs &shared, W4A8BenchOptions const &opt) {
  W4A8RunResult r;
  r.result.name = "decode_2cta C1 (Stages=9, MinBlocks=2, sm_count=264)";

  W4A8GemmContext<TestGemm> ctx;
  ctx.shared = &shared;
  ctx.allocate(opt);

  TestGemm gemm;
  auto arguments = ctx.make_arguments(opt);
  size_t workspace_size = TestGemm::get_workspace_size(arguments);
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

  ctx.zero_outputs();
  W4A8_CUDA_SYNC();
  CUTLASS_CHECK(gemm.run());
  W4A8_CUDA_SYNC();

  r.host_D.resize(ctx.block_D.size());
  ctx.block_D.copy_to_host(r.host_D.data());
  return r;
}

#endif // CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_SUPPORTED
