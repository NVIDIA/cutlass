/***************************************************************************************************
 * Copyright (c) 2026 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/

/*
 * Blackwell FP16 GEMM with Green Context
 *
 * The two schedulers share identical kernel configurations (element types, tile shapes,
 * cluster shape, epilogue/mainloop builders) and differ only in:
 *
 *   TileScheduler type:
 *        - DynamicPersistentScheduler (CLC-based)
 *        - StaticPersistentScheduler
 *
 * Use --scheduler=dynamic (default) or --scheduler=static to select the scheduler.
 */

#include <iostream>

#include <cuda.h>

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"
#include "cutlass/tensor_ref.h"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/kernel/tile_scheduler_params.h"
#include "cutlass/gemm/kernel/tile_scheduler.hpp"

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/device/gemm.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/reference/device/tensor_fill.h"

#include "helper.h"

/// Panic wrapper for CUDA Driver API errors (CUresult).
#define CUDA_DRIVER_CHECK(status)                                       \
  do {                                                                  \
    CUresult error = status;                                            \
    if (error != CUDA_SUCCESS) {                                        \
      const char *error_string;                                         \
      cuGetErrorString(error, &error_string);                           \
      std::cerr << "Got CUDA driver error: " << error                   \
                << " (" << error_string << ")"                          \
                << " at: " << __LINE__ << std::endl;                    \
      exit(EXIT_FAILURE);                                               \
    }                                                                   \
  } while (0)

/// Alias for CUDA Runtime API error checks (cudaError_t).
/// CUDA_CHECK is defined in helper.h; this alias makes the API boundary explicit.
#define CUDA_RUNTIME_CHECK CUDA_CHECK

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Common GEMM kernel configuration (shared by both schedulers)
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace gemm_common_config {

  using namespace cute;

  using         ElementA    = half_t;
  using         LayoutA     = cutlass::layout::RowMajor;
  constexpr int AlignmentA  = 128 / cutlass::sizeof_bits<ElementA>::value;

  using         ElementB    = half_t;
  using         LayoutB     = cutlass::layout::ColumnMajor;
  constexpr int AlignmentB  = 128 / cutlass::sizeof_bits<ElementB>::value;

  using         ElementC    = float;
  using         LayoutC     = cutlass::layout::ColumnMajor;
  constexpr int AlignmentC  = 128 / cutlass::sizeof_bits<ElementC>::value;

  using ElementAccumulator  = float;
  using ArchTag             = cutlass::arch::Sm100;
  using OperatorClass       = cutlass::arch::OpClassTensorOp;

  using MmaTileShape_MNK = Shape<_256,_128,_64>;
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  using EpilogueScheduleType = cutlass::epilogue::TmaWarpSpecialized2Sm;
  using KernelScheduleType   = cutlass::gemm::KernelTmaWarpSpecialized2SmSm100;

} // namespace gemm_common_config

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Dynamic Persistent CLC kernel
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace dynamic_kernel_config {

  using namespace cute;
  using namespace gemm_common_config;

  using TileScheduler = cutlass::gemm::DynamicPersistentScheduler;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      ArchTag, OperatorClass,
      MmaTileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementAccumulator,
      ElementC, LayoutC, AlignmentC,
      ElementC, LayoutC, AlignmentC,
      EpilogueScheduleType
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      ArchTag, OperatorClass,
      ElementA, LayoutA, AlignmentA,
      ElementB, LayoutB, AlignmentB,
      ElementAccumulator,
      MmaTileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      KernelScheduleType
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int, int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      TileScheduler>;

} // namespace dynamic_kernel_config

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Static Persistent kernel
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace static_kernel_config {

  using namespace cute;
  using namespace gemm_common_config;

  using TileScheduler = cutlass::gemm::StaticPersistentScheduler;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      ArchTag, OperatorClass,
      MmaTileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementAccumulator,
      ElementC, LayoutC, AlignmentC,
      ElementC, LayoutC, AlignmentC,
      EpilogueScheduleType
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      ArchTag, OperatorClass,
      ElementA, LayoutA, AlignmentA,
      ElementB, LayoutB, AlignmentB,
      ElementAccumulator,
      MmaTileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      KernelScheduleType
    >::CollectiveOp;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int, int>,
      CollectiveMainloop,
      CollectiveEpilogue,
      TileScheduler>;

} // namespace static_kernel_config

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Gemm device adapter types
/////////////////////////////////////////////////////////////////////////////////////////////////

using DynamicGemm = cutlass::gemm::device::GemmUniversalAdapter<dynamic_kernel_config::GemmKernel>;
using StaticGemm  = cutlass::gemm::device::GemmUniversalAdapter<static_kernel_config::GemmKernel>;

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Common type aliases and global data (identical across both kernels)
/////////////////////////////////////////////////////////////////////////////////////////////////

using ElementA          = gemm_common_config::ElementA;
using ElementB          = gemm_common_config::ElementB;
using ElementC          = gemm_common_config::ElementC;
using LayoutA           = gemm_common_config::LayoutA;
using LayoutB           = gemm_common_config::LayoutB;
using LayoutC           = gemm_common_config::LayoutC;
using ElementAccumulator = gemm_common_config::ElementAccumulator;

using DeviceGemmReference = cutlass::reference::device::Gemm<
  ElementA, LayoutA,
  ElementB, LayoutB,
  ElementC, LayoutC,
  ElementAccumulator, ElementAccumulator>;

using StrideA = typename DynamicGemm::GemmKernel::StrideA;
using StrideB = typename DynamicGemm::GemmKernel::StrideB;
using StrideC = typename DynamicGemm::GemmKernel::StrideC;
using StrideD = typename DynamicGemm::GemmKernel::StrideD;

StrideA stride_A;
StrideB stride_B;
StrideC stride_C;
StrideD stride_D;
uint64_t seed = 0;

cutlass::DeviceAllocation<ElementA> block_A;
cutlass::DeviceAllocation<ElementB> block_B;
cutlass::DeviceAllocation<ElementC> block_C;
cutlass::DeviceAllocation<ElementC> block_D;
cutlass::DeviceAllocation<ElementC> block_ref_D;

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

struct Options {

  bool help;
  bool use_cuda_graph;
  int m, n, k;
  float alpha, beta;
  int iterations;
  int swizzle;
  int max_num_sm;
  std::string raster_order;
  std::string scheduler;

  Options():
    help(false),
    use_cuda_graph(false),
    m(8192), n(8192), k(8192),
    alpha(1.f), beta(0.f),
    iterations(30),
    swizzle(0),
    max_num_sm(0),
    raster_order("heuristic"),
    scheduler("dynamic")
  { }

  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("m", m);
    cmd.get_cmd_line_argument("n", n);
    cmd.get_cmd_line_argument("k", k);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("iterations", iterations);
    cmd.get_cmd_line_argument("swizzle", swizzle);
    cmd.get_cmd_line_argument("max_num_sm", max_num_sm);
    cmd.get_cmd_line_argument("raster_order", raster_order, std::string("heuristic"));
    cmd.get_cmd_line_argument("scheduler", scheduler, std::string("dynamic"));
    use_cuda_graph = cmd.check_cmd_line_flag("use_cuda_graph");
  }

  using RasterOrderOptions = cutlass::gemm::kernel::detail::RasterOrderOptions;
  RasterOrderOptions get_raster_order() const {
    if (raster_order == "along_m") {
      return RasterOrderOptions::AlongM;
    } else if (raster_order == "along_n") {
      return RasterOrderOptions::AlongN;
    } else {
      return RasterOrderOptions::Heuristic;
    }
  }

  std::ostream & print_usage(std::ostream &out) const {

    out << "95_blackwell_gemm_green_context\n\n"
      << "  Blackwell FP16 GEMM with Green Context support.\n"
      << "  Supports both Dynamic Persistent CLC and Static Persistent schedulers.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --scheduler=<string>        Tile scheduler: 'dynamic' (default) or 'static'\n"
      << "                                dynamic: DynamicPersistentScheduler (CLC-based)\n"
      << "                                static:  StaticPersistentScheduler\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --alpha=<f32>               Epilogue scalar alpha\n"
      << "  --beta=<f32>                Epilogue scalar beta\n\n"
      << "  --swizzle=<int>             Cluster rasterization swizzle\n"
      << "  --raster_order=<string>     Raster order: 'heuristic' (default), 'along_m', or 'along_n'\n"
      << "  --max_num_sm=<int>          Max number of SMs for green context partition (0 = use all SMs, no green context)\n"
      << "  --use_cuda_graph            If specified, use CUDA graph capture/replay for profiling iterations\n\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n";

    out
      << "\n\nExamples:\n\n"
      << "  # Dynamic scheduler, all SMs (no green context)\n"
      << "  $ 95_blackwell_gemm_green_context --scheduler=dynamic --m=8192 --n=8192 --k=8192\n\n"
      << "  # Static scheduler, 120-SM green context partition\n"
      << "  $ 95_blackwell_gemm_green_context --scheduler=static --m=8192 --n=8192 --k=8192 --max_num_sm=120\n\n";

    return out;
  }

  double gflops(double runtime_s) const
  {
    uint64_t flop = uint64_t(2) * m * n * k;
    double gflop = double(flop) / double(1.0e9);
    return gflop / runtime_s;
  }
};

struct Result
{
  double avg_runtime_ms;
  double gflops;
  cutlass::Status status;
  cudaError_t error;
  bool passed;

  Result(
    double avg_runtime_ms = 0,
    double gflops = 0,
    cutlass::Status status = cutlass::Status::kSuccess,
    cudaError_t error = cudaSuccess)
  :
    avg_runtime_ms(avg_runtime_ms), gflops(gflops), status(status), error(error), passed(false)
  {}

};

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

template <class Element>
void initialize_block(
  cutlass::DeviceAllocation<Element>& block,
  uint64_t seed=2023) {

  Element scope_max, scope_min;
  int bits_input = cutlass::sizeof_bits<Element>::value;

  if (bits_input == 1) {
    scope_max = Element(2);
    scope_min = Element(0);
  } else if (bits_input <= 8) {
    scope_max = Element(2);
    scope_min = Element(-2);
  } else {
    scope_max = Element(8);
    scope_min = Element(-8);
  }

  cutlass::reference::device::BlockFillRandomUniform(
    block.get(), block.size(), seed, scope_max, scope_min, 0);
}

void initialize(const Options &options) {

  stride_A = cutlass::make_cute_packed_stride(StrideA{}, {options.m, options.k, 1});
  stride_B = cutlass::make_cute_packed_stride(StrideB{}, {options.n, options.k, 1});
  stride_C = cutlass::make_cute_packed_stride(StrideC{}, {options.m, options.n, 1});
  stride_D = cutlass::make_cute_packed_stride(StrideD{}, {options.m, options.n, 1});

  block_A.reset(options.m * options.k);
  block_B.reset(options.k * options.n);
  block_C.reset(options.m * options.n);
  block_D.reset(options.m * options.n);
  block_ref_D.reset(options.m * options.n);

  initialize_block(block_A, seed + 2023);
  initialize_block(block_B, seed + 2022);
  initialize_block(block_C, seed + 2021);
}

/// Populates a Gemm::Arguments structure from the given commandline options.
///
/// The static persistent scheduler needs hw_info (sm_count, max_active_clusters) to compute
/// the launch grid size. When overlapping with another kernel via green context partitioning,
/// the green context stream MUST be passed so that cudaOccupancyMaxActiveClusters returns the
/// partition-scoped value.  The dynamic persistent scheduler does not use hw_info.
///
/// We always set hw_info here for uniformity; it is harmless for the dynamic scheduler.
template <typename Gemm>
typename Gemm::Arguments args_from_options(const Options &options, cudaStream_t stream)
{
  typename Gemm::Arguments arguments{
    cutlass::gemm::GemmUniversalMode::kGemm,
    {options.m, options.n, options.k, 1},
    {block_A.get(), stride_A, block_B.get(), stride_B},
    {{options.alpha, options.beta}, block_C.get(), stride_C, block_D.get(), stride_D}
  };

  arguments.scheduler.max_swizzle_size = options.swizzle;
  arguments.scheduler.raster_order = options.get_raster_order();

  // =====================================================================================
  // IMPORTANT: Static persistent scheduler needs hw_info (sm_count, max_active_clusters)
  // to compute the correct launch grid size.
  //
  // When the static persistent kernel overlaps with other kernel (e.g. via
  // green context partitioning), you MUST pass the green context stream to
  // make_kernel_hardware_info() so that cudaOccupancyMaxActiveClusters queries the max
  // active clusters for that SM partition -- NOT the full device.
  //
  // If the stream is not passed, the query returns the full-device max active clusters,
  // which leads to an oversized persistent grid that exceeds the partition's capacity,
  // causing performance issues (because static scheduler stride to next work with launch grid size)
  // =====================================================================================
  arguments.hw_info = cutlass::KernelHardwareInfo::make_kernel_hardware_info<typename Gemm::GemmKernel>(
      0 /* device_id */, 0 /* sm_count: auto-query */, 0 /* max_active_clusters: auto-query */, stream);

  return arguments;
}

template <typename Gemm>
bool verify(const Options &options) {
  cutlass::TensorRef ref_A(block_A.get(), LayoutA::packed({options.m, options.k}));
  cutlass::TensorRef ref_B(block_B.get(), LayoutB::packed({options.k, options.n}));
  cutlass::TensorRef ref_C(block_C.get(), LayoutC::packed({options.m, options.n}));
  cutlass::TensorRef ref_D(block_ref_D.get(), LayoutC::packed({options.m, options.n}));

  DeviceGemmReference gemm_reference;

  gemm_reference(
    {options.m, options.n, options.k},
    ElementAccumulator(options.alpha),
    ref_A,
    ref_B,
    ElementAccumulator(options.beta),
    ref_C,
    ref_D);

  CUDA_RUNTIME_CHECK(cudaDeviceSynchronize());

  bool passed = cutlass::reference::device::BlockCompareEqual(block_ref_D.get(), block_D.get(), block_D.size());

  return passed;
}

/// Execute a given example GEMM computation.
/// Stream is REQUIRED -- pass cudaStreamDefault (0) for the full device, or a green context
/// stream for a partitioned launch.
template <typename Gemm>
int run(const Options &options, cudaStream_t stream)
{
  initialize(options);

  Gemm gemm;

  auto arguments = args_from_options<Gemm>(options, stream);

  dim3 grid = Gemm::get_grid_shape(arguments);
  std::cout << "  hw_info: sm_count=" << arguments.hw_info.sm_count
            << ", max_active_clusters=" << arguments.hw_info.max_active_clusters << std::endl;
  std::cout << "  Launch grid: (" << grid.x << ", " << grid.y << ", " << grid.z << ")" << std::endl;

  size_t workspace_size = Gemm::get_workspace_size(arguments);

  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  CUTLASS_CHECK(gemm.can_implement(arguments));

  CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));

  CUTLASS_CHECK(gemm.run(stream));

  CUDA_RUNTIME_CHECK(cudaStreamSynchronize(stream));

  Result result;
  result.passed = verify<Gemm>(options);

  std::cout << "  Disposition: " << (result.passed ? "Passed" : "Failed") << std::endl;

  if (!result.passed) {
    exit(-1);
  }

  if (options.iterations > 0)
  {
    GpuTimer timer;

    if (options.use_cuda_graph) {
      // cudaStreamBeginCapture cannot capture on the legacy default stream (stream 0).
      cudaStream_t capture_stream = (stream == cudaStreamDefault) ? cudaStreamPerThread : stream;

      CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));

      cudaGraph_t graph;
      cudaGraphExec_t graph_exec;
      CUDA_RUNTIME_CHECK(cudaStreamBeginCapture(capture_stream, cudaStreamCaptureModeGlobal));
      CUTLASS_CHECK(gemm.run(capture_stream));
      CUDA_RUNTIME_CHECK(cudaStreamEndCapture(capture_stream, &graph));
      CUDA_RUNTIME_CHECK(cudaGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0));

      std::cout << "  Using CUDA Graph for " << options.iterations << " iterations" << std::endl;

      timer.start(stream);
      for (int iter = 0; iter < options.iterations; ++iter) {
        CUDA_RUNTIME_CHECK(cudaGraphLaunch(graph_exec, stream));
      }
      timer.stop();

      CUDA_RUNTIME_CHECK(cudaGraphExecDestroy(graph_exec));
      CUDA_RUNTIME_CHECK(cudaGraphDestroy(graph));
    }
    else {
      timer.start(stream);
      for (int iter = 0; iter < options.iterations; ++iter) {
        CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
        CUTLASS_CHECK(gemm.run(stream));
      }
      timer.stop();
    }

    float elapsed_ms = timer.elapsed_millis();
    result.avg_runtime_ms = double(elapsed_ms) / double(options.iterations);
    result.gflops = options.gflops(result.avg_runtime_ms / 1000.0);

    std::cout << "  Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << std::endl;
    std::cout << "  Avg runtime: " << result.avg_runtime_ms << " ms" << std::endl;
    std::cout << "  GFLOPS: " << result.gflops << std::endl;
  }

  return 0;
}

/// Dispatches to the correct Gemm type and handles green context setup.
template <typename Gemm>
int dispatch(const Options &options, int current_device_id)
{
  if (options.max_num_sm > 0) {
    //
    // Green Context path: partition SMs and launch kernel on primary partition
    //

    CUDA_DRIVER_CHECK(cuInit(0));

    CUdevice cu_device;
    CUcontext primary_context;
    CUDA_DRIVER_CHECK(cuDeviceGet(&cu_device, current_device_id));
    CUDA_DRIVER_CHECK(cuDevicePrimaryCtxRetain(&primary_context, cu_device));
    CUDA_DRIVER_CHECK(cuCtxSetCurrent(primary_context));

    CUdevResource device_resource;
    CUDA_DRIVER_CHECK(cuDeviceGetDevResource(cu_device, &device_resource, CU_DEV_RESOURCE_TYPE_SM));
    std::cout << "  Device SM count: " << device_resource.sm.smCount << std::endl;

    if (options.max_num_sm >= static_cast<int>(device_resource.sm.smCount)) {
      std::cout << "  --max_num_sm (" << options.max_num_sm
                << ") >= device SM count (" << device_resource.sm.smCount
                << "), no green context split, using a dedicated stream with all SMs" << std::endl;

      cudaStream_t stream;
      CUDA_RUNTIME_CHECK(cudaStreamCreateWithFlags(&stream, cudaStreamNonBlocking));
      int rc = run<Gemm>(options, stream);
      CUDA_RUNTIME_CHECK(cudaStreamDestroy(stream));
      CUDA_DRIVER_CHECK(cuDevicePrimaryCtxRelease(cu_device));
      return rc;
    }

    CUdevResource primary_partition_resource;
    CUdevResource remaining_partition_resource;
    unsigned int num_groups = 1;
#if CUDA_VERSION >= 13000
    unsigned int sm_alignment = device_resource.sm.smCoscheduledAlignment;
    unsigned int aligned_sm = (static_cast<unsigned int>(options.max_num_sm) / sm_alignment) * sm_alignment;
    if (aligned_sm == 0) {
      aligned_sm = sm_alignment;
    }
    std::cout << "  SM coscheduled alignment: " << sm_alignment << std::endl;
    std::cout << "  Requested --max_num_sm: " << options.max_num_sm
              << ", aligned (round down): " << aligned_sm << std::endl;
    CUDA_DRIVER_CHECK(cuDevSmResourceSplitByCount(
        &primary_partition_resource,
        &num_groups,
        &device_resource,
        &remaining_partition_resource,
        0,
        aligned_sm));
#else
    std::cout << "  Requested --max_num_sm: " << options.max_num_sm << std::endl;
    CUDA_DRIVER_CHECK(cuDevSmResourceSplitByCount(
        &primary_partition_resource,
        &num_groups,
        &device_resource,
        &remaining_partition_resource,
        0,
        static_cast<unsigned int>(options.max_num_sm)));
#endif

    std::cout << "  Primary partition SM count (for GEMM): " << primary_partition_resource.sm.smCount << std::endl;
    std::cout << "  Remaining partition SM count: " << remaining_partition_resource.sm.smCount << std::endl;

    CUdevResourceDesc primary_partition_desc;
    CUdevResourceDesc remaining_partition_desc;
    CUDA_DRIVER_CHECK(cuDevResourceGenerateDesc(&primary_partition_desc, &primary_partition_resource, 1));
    CUDA_DRIVER_CHECK(cuDevResourceGenerateDesc(&remaining_partition_desc, &remaining_partition_resource, 1));

    CUgreenCtx primary_partition_green_ctx;
    CUgreenCtx remaining_partition_green_ctx;
    CUDA_DRIVER_CHECK(cuGreenCtxCreate(&primary_partition_green_ctx, primary_partition_desc, cu_device, CU_GREEN_CTX_DEFAULT_STREAM));
    CUDA_DRIVER_CHECK(cuGreenCtxCreate(&remaining_partition_green_ctx, remaining_partition_desc, cu_device, CU_GREEN_CTX_DEFAULT_STREAM));

    // Remaining partition stream is not used in this example but instantiated to show how.
    CUstream primary_partition_cu_stream;
    CUstream remaining_partition_cu_stream;
    CUDA_DRIVER_CHECK(cuGreenCtxStreamCreate(&primary_partition_cu_stream, primary_partition_green_ctx, CU_STREAM_NON_BLOCKING, 0));
    CUDA_DRIVER_CHECK(cuGreenCtxStreamCreate(&remaining_partition_cu_stream, remaining_partition_green_ctx, CU_STREAM_NON_BLOCKING, 0));

    cudaStream_t primary_partition_stream = static_cast<cudaStream_t>(primary_partition_cu_stream);
    int rc = run<Gemm>(options, primary_partition_stream);

    CUDA_DRIVER_CHECK(cuStreamDestroy(primary_partition_cu_stream));
    CUDA_DRIVER_CHECK(cuStreamDestroy(remaining_partition_cu_stream));
    CUDA_DRIVER_CHECK(cuGreenCtxDestroy(primary_partition_green_ctx));
    CUDA_DRIVER_CHECK(cuGreenCtxDestroy(remaining_partition_green_ctx));
    CUDA_DRIVER_CHECK(cuDevicePrimaryCtxRelease(cu_device));

    return rc;
  }
  else {
    return run<Gemm>(options, cudaStreamDefault);
  }
}

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  if (__CUDACC_VER_MAJOR__ < 12 || (__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 9)) {
    std::cerr << "This example requires CUDA 12.9 or newer." << std::endl;
    return 0;
  }

  cudaDeviceProp props;
  int current_device_id;
  CUDA_RUNTIME_CHECK(cudaGetDevice(&current_device_id));
  CUDA_RUNTIME_CHECK(cudaGetDeviceProperties(&props, current_device_id));

  if (props.major != 10 || props.minor != 0) {
    std::cerr << "This example requires a GPU with compute capability 100a." << std::endl;
    return 0;
  }

  Options options;

  options.parse(argc, args);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
  if (options.scheduler == "static") {
    std::cout << "Using StaticPersistentScheduler" << std::endl;
    return dispatch<StaticGemm>(options, current_device_id);
  }
  else if (options.scheduler == "dynamic") {
    std::cout << "Using DynamicPersistentScheduler" << std::endl;
    return dispatch<DynamicGemm>(options, current_device_id);
  }
  else {
    std::cerr << "Unknown scheduler: '" << options.scheduler
              << "'. Use --scheduler=dynamic or --scheduler=static." << std::endl;
    return 1;
  }
#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
