/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

/// Panic wrapper for unwinding CUDA Driver API errors (CUresult).
/// Note: CUDA_CHECK (defined in helper.h) is for CUDA Runtime API errors (cudaError_t).
#define CU_DRIVER_CHECK(status)                                         \
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

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass3x_sm100_gemm_af16_bf16_accf32_cf32_df32_epif32_2sm_ctatile256x128x64_clusterp2x2x1_static_rcc_namespace {

  using namespace cute;

  // A matrix configuration
  using         ElementA    = half_t;                                         // Element type for A matrix operand
  using         LayoutA     = cutlass::layout::RowMajor;                      // Layout type for A matrix operand
  constexpr int AlignmentA  = 128 / cutlass::sizeof_bits<ElementA>::value;    // Memory access granularity/alignment of A matrix in units of elements (up to 16 bytes)

  // B matrix configuration
  using         ElementB    = half_t;                                         // Element type for B matrix operand
  using         LayoutB     = cutlass::layout::ColumnMajor;                   // Layout type for B matrix operand
  constexpr int AlignmentB  = 128 / cutlass::sizeof_bits<ElementB>::value;    // Memory access granularity/alignment of B matrix in units of elements (up to 16 bytes)

  // C/D matrix configuration
  using         ElementC    = float;                                          // Element type for C and D matrix operands
  using         LayoutC     = cutlass::layout::ColumnMajor;                   // Layout type for C and D matrix operands
  constexpr int AlignmentC  = 128 / cutlass::sizeof_bits<ElementC>::value;    // Memory access granularity/alignment of C matrix in units of elements (up to 16 bytes)

  // Kernel functional config
  using ElementAccumulator  = float;                                          // Element type for internal accumulation
  using ArchTag             = cutlass::arch::Sm100;                           // Tag indicating the minimum SM that supports the intended feature
  using OperatorClass       = cutlass::arch::OpClassTensorOp;                 // Operator class tag

  // MMA and Cluster Tile Shapes
  // Shape of the tile computed by tcgen05 MMA, across 2 SMs (256 = 128 per SM)
  using MmaTileShape_MNK = Shape<_256,_128,_64>;
  // Static cluster shape 2x2x1
  using ClusterShape_MNK = Shape<_2,_2,_1>;

  // Explicit schedule types for 2SM kernel with static persistent scheduling
  using EpilogueScheduleType = cutlass::epilogue::TmaWarpSpecialized2Sm;
  using KernelScheduleType   = cutlass::gemm::KernelTmaWarpSpecialized2SmSm100;
  using TileScheduler        = cutlass::gemm::StaticPersistentScheduler;

  // Build the epilogue
  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      ArchTag, OperatorClass, 
      MmaTileShape_MNK, ClusterShape_MNK,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementAccumulator,
      ElementC, LayoutC, AlignmentC,
      ElementC, LayoutC, AlignmentC,
      EpilogueScheduleType
    >::CollectiveOp;

  // Build the mainloop
  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      ArchTag, OperatorClass,
      ElementA, LayoutA, AlignmentA,
      ElementB, LayoutB, AlignmentB,
      ElementAccumulator,
      MmaTileShape_MNK, ClusterShape_MNK,
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      KernelScheduleType
    >::CollectiveOp;

  // Compose into a kernel with explicit StaticPersistentScheduler
  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int,int,int, int>, // Indicates ProblemShape
      CollectiveMainloop,
      CollectiveEpilogue,
      TileScheduler>;          // StaticPersistentScheduler: static persistent tile scheduler

} // namespace cutlass3x_sm100_gemm_af16_bf16_accf32_cf32_df32_epif32_2sm_ctatile256x128x64_clusterp2x2x1_static_rcc_namespace

using namespace cutlass3x_sm100_gemm_af16_bf16_accf32_cf32_df32_epif32_2sm_ctatile256x128x64_clusterp2x2x1_static_rcc_namespace;

using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

// Reference device GEMM implementation type
using DeviceGemmReference = cutlass::reference::device::Gemm<
  ElementA,
  LayoutA,
  ElementB,
  LayoutB,
  ElementC,
  LayoutC,
  ElementAccumulator,
  ElementAccumulator>;

using StrideA = typename Gemm::GemmKernel::StrideA;
using StrideB = typename Gemm::GemmKernel::StrideB;
using StrideC = typename Gemm::GemmKernel::StrideC;
using StrideD = typename Gemm::GemmKernel::StrideD;

//
// Data members
//

/// Initialization
StrideA stride_A;
StrideB stride_B;
StrideC stride_C;
StrideD stride_D;
uint64_t seed = 0;

cutlass::DeviceAllocation<typename Gemm::ElementA> block_A;
cutlass::DeviceAllocation<typename Gemm::ElementB> block_B;
cutlass::DeviceAllocation<typename Gemm::ElementC> block_C;
cutlass::DeviceAllocation<typename Gemm::EpilogueOutputOp::ElementOutput> block_D;
cutlass::DeviceAllocation<typename Gemm::EpilogueOutputOp::ElementOutput> block_ref_D;

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help;
  bool use_cuda_graph;
  int m, n, k;
  float alpha, beta;
  int iterations;
  int swizzle;
  int max_num_sm;
  std::string raster_order;

  Options():
    help(false),
    use_cuda_graph(false),
    m(8192), n(8192), k(8192),
    alpha(1.f), beta(0.f),
    iterations(30),
    swizzle(0),
    max_num_sm(0),
    raster_order("heuristic")
  { }

  // Parses the command line
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
    use_cuda_graph = cmd.check_cmd_line_flag("use_cuda_graph");
  }

  /// Get the RasterOrderOptions enum from string
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

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "95_blackwell_static_persistent_gemm_green_context\n\n"
      << "  Blackwell FP16 GEMM using a Static Persistent kernel.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
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
      << "  # Run on all SMs (no green context)\n"
      << "  $ 95_blackwell_static_persistent_gemm_green_context --m=8192 --n=8192 --k=8192\n\n"
      << "  # Run on a 120-SM green context partition\n"
      << "  $ 95_blackwell_static_persistent_gemm_green_context --m=8192 --n=8192 --k=8192 --max_num_sm=120\n\n";

    return out;
  }

  /// Compute performance in GFLOP/s
  double gflops(double runtime_s) const
  {
    // Two flops per multiply-add
    uint64_t flop = uint64_t(2) * m * n * k;
    double gflop = double(flop) / double(1.0e9);
    return gflop / runtime_s;
  }
};

/// Result structure
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

/// Helper to initialize a block of device data
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

/// Initialize operands to be used in the GEMM and reference GEMM
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
/// The stream parameter is REQUIRED (no default) because passing the correct stream is critical
/// for the static persistent scheduler: it determines max_active_clusters via
/// cudaOccupancyMaxActiveClusters, which must be scoped to the green context partition when one
/// is active. Pass cudaStreamDefault (0) when running on the full device (no green context),
/// or a green context stream for a partitioned launch.
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
  // to compute the launch grid size.
  //
  // When the static persistent kernel will be overlapped with another kernel (e.g. via
  // green context partitioning), you MUST pass the green context stream to
  // make_kernel_hardware_info() so that cudaOccupancyMaxActiveClusters queries the max
  // active clusters for that SM partition -- NOT the full device.
  //
  // If the stream is not passed, the query returns the full-device max active clusters,
  // which leads to an oversized persistent grid that exceeds the partition's capacity,
  // causing correctness or performance issues.
  //
  // Example:
  //   arguments.hw_info = cutlass::KernelHardwareInfo::make_kernel_hardware_info<GemmKernel>(
  //       current_device_id, partition_sm_count, 0 /* auto-query */, green_ctx_stream);
  // =====================================================================================
  arguments.hw_info = cutlass::KernelHardwareInfo::make_kernel_hardware_info<GemmKernel>(
      0 /* device_id */, 0 /* sm_count: auto-query */, 0 /* max_active_clusters: auto-query */, stream);

  return arguments;
}

bool verify(const Options &options) {
  cutlass::TensorRef ref_A(block_A.get(), Gemm::LayoutA::packed({options.m, options.k}));
  cutlass::TensorRef ref_B(block_B.get(), Gemm::LayoutB::packed({options.k, options.n}));
  cutlass::TensorRef ref_C(block_C.get(), Gemm::LayoutC::packed({options.m, options.n}));
  cutlass::TensorRef ref_D(block_ref_D.get(), Gemm::LayoutD::packed({options.m, options.n}));

  //
  // Compute reference output
  //

  // Create instantiation for device reference gemm kernel
  DeviceGemmReference gemm_reference;

  // Launch device reference gemm kernel
  gemm_reference(
    {options.m, options.n, options.k},
    ElementAccumulator(options.alpha),
    ref_A,
    ref_B,
    ElementAccumulator(options.beta),
    ref_C,
    ref_D);

  // Wait for kernel to finish
  CUDA_CHECK(cudaDeviceSynchronize());

  // Check if output from CUTLASS kernel and reference kernel are equal or not
  bool passed = cutlass::reference::device::BlockCompareEqual(block_ref_D.get(), block_D.get(), block_D.size());

  return passed;
}

/// Execute a given example GEMM computation.
/// The stream parameter is REQUIRED (no default) -- pass cudaStreamDefault (0) for the full
/// device, or a green context stream for a partitioned launch. This ensures callers always
/// consider which stream/partition the kernel will run on.
template <typename Gemm>
int run(const Options &options, cudaStream_t stream)
{
  initialize(options);

  // Instantiate CUTLASS kernel depending on templates
  Gemm gemm;

  // Create a structure of gemm kernel arguments suitable for invoking an instance of Gemm.
  // Pass stream so that hw_info queries (max_active_clusters) are scoped to the green context partition.
  auto arguments = args_from_options(options, stream);

  // Print hw_info and launch grid for the static persistent scheduler
  dim3 grid = Gemm::get_grid_shape(arguments);
  std::cout << "  hw_info: sm_count=" << arguments.hw_info.sm_count
            << ", max_active_clusters=" << arguments.hw_info.max_active_clusters << std::endl;
  std::cout << "  Launch grid: (" << grid.x << ", " << grid.y << ", " << grid.z << ")" << std::endl;

  // Using the arguments, query for extra workspace required for matrix multiplication computation
  size_t workspace_size = Gemm::get_workspace_size(arguments);

  // Allocate workspace memory
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  // Check if the problem size is supported or not
  CUTLASS_CHECK(gemm.can_implement(arguments));

  // Initialize CUTLASS kernel with arguments and workspace pointer
  CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));

  // Correctness / Warmup iteration
  CUTLASS_CHECK(gemm.run(stream));

  // Wait for kernel to finish
  CUDA_CHECK(cudaStreamSynchronize(stream));

  // Check if output from CUTLASS kernel and reference kernel are equal or not
  Result result;
  result.passed = verify(options);

  std::cout << "  Disposition: " << (result.passed ? "Passed" : "Failed") << std::endl;

  if (!result.passed) {
    exit(-1);
  }

  // Run profiling loop
  if (options.iterations > 0)
  {
    GpuTimer timer;

    if (options.use_cuda_graph) {
      //
      // CUDA Graph capture and replay path
      //
      // cudaStreamBeginCapture cannot capture on the legacy default stream (stream 0).
      // Use cudaStreamPerThread as the capture stream when running on the default stream.
      cudaStream_t capture_stream = (stream == cudaStreamDefault) ? cudaStreamPerThread : stream;

      CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));

      // Capture the kernel launch into a CUDA graph
      cudaGraph_t graph;
      cudaGraphExec_t graph_exec;
      CUDA_CHECK(cudaStreamBeginCapture(capture_stream, cudaStreamCaptureModeGlobal));
      CUTLASS_CHECK(gemm.run(capture_stream));
      CUDA_CHECK(cudaStreamEndCapture(capture_stream, &graph));
      CUDA_CHECK(cudaGraphInstantiate(&graph_exec, graph, nullptr, nullptr, 0));

      std::cout << "  Using CUDA Graph for " << options.iterations << " iterations" << std::endl;

      // Replay the graph for profiling
      timer.start(stream);
      for (int iter = 0; iter < options.iterations; ++iter) {
        CUDA_CHECK(cudaGraphLaunch(graph_exec, stream));
      }
      timer.stop();

      // Cleanup graph resources
      CUDA_CHECK(cudaGraphExecDestroy(graph_exec));
      CUDA_CHECK(cudaGraphDestroy(graph));
    }
    else {
      //
      // Standard profiling path (no CUDA graph)
      //
      timer.start(stream);
      for (int iter = 0; iter < options.iterations; ++iter) {
        CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
        CUTLASS_CHECK(gemm.run(stream));
      }
      timer.stop();
    }

    // Compute average runtime and GFLOPs.
    float elapsed_ms = timer.elapsed_millis();
    result.avg_runtime_ms = double(elapsed_ms) / double(options.iterations);
    result.gflops = options.gflops(result.avg_runtime_ms / 1000.0);

    std::cout << "  Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << std::endl;
    std::cout << "  Avg runtime: " << result.avg_runtime_ms << " ms" << std::endl;
    std::cout << "  GFLOPS: " << result.gflops << std::endl;
  }

  return 0;
}

#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // CUTLASS must be compiled with CUDA 12.8 Toolkit to run this example
  // and must have compute capability at least 100a.

  if (__CUDACC_VER_MAJOR__ < 12 || (__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 8)) {
    std::cerr << "This example requires CUDA 12.8 or newer." << std::endl;
    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));

  if (props.major != 10 || props.minor != 0) {
    std::cerr << "This example requires a GPU with compute capability 100a." << std::endl;
    return 0;
  }

  //
  // Parse options
  //

  Options options;

  options.parse(argc, args);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  //
  // Evaluate CUTLASS kernels
  //
#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)
  if (options.max_num_sm > 0) {
    //
    // Green Context path: partition SMs and launch kernel on primary partition
    //

    // Initialize CUDA Driver API
    CU_DRIVER_CHECK(cuInit(0));

    // Get device and retain primary context
    CUdevice cu_device;
    CUcontext primary_context;
    CU_DRIVER_CHECK(cuDeviceGet(&cu_device, current_device_id));
    CU_DRIVER_CHECK(cuDevicePrimaryCtxRetain(&primary_context, cu_device));
    CU_DRIVER_CHECK(cuCtxSetCurrent(primary_context));

    // Step 1: Query SM resources
    CUdevResource device_resource;
    CU_DRIVER_CHECK(cuDeviceGetDevResource(cu_device, &device_resource, CU_DEV_RESOURCE_TYPE_SM));
    std::cout << "  Device SM count: " << device_resource.sm.smCount << std::endl;

    if (options.max_num_sm >= static_cast<int>(device_resource.sm.smCount)) {
      std::cout << "  --max_num_sm (" << options.max_num_sm
                << ") >= device SM count (" << device_resource.sm.smCount
                << "), no green context split, using default stream" << std::endl;
      CU_DRIVER_CHECK(cuDevicePrimaryCtxRelease(cu_device));
      run<Gemm>(options, cudaStreamDefault /* full device, no green context */);
      return 0;
    }

    // Step 2: Split SM resources into primary and remaining partitions.
    // cuDevSmResourceSplitByCount treats the last arg as a MINIMUM SM count and rounds UP
    // to the smCoscheduledAlignment boundary. To ensure the primary partition does NOT
    // exceed the user's --max_num_sm, read the alignment from the device resource and
    // round DOWN the requested SM count.
    unsigned int sm_alignment = device_resource.sm.smCoscheduledAlignment;
    unsigned int aligned_sm = (static_cast<unsigned int>(options.max_num_sm) / sm_alignment) * sm_alignment;
    if (aligned_sm == 0) {
      aligned_sm = sm_alignment;  // at least one alignment unit
    }

    std::cout << "  SM coscheduled alignment: " << sm_alignment << std::endl;
    std::cout << "  Requested --max_num_sm: " << options.max_num_sm
              << ", aligned (round down): " << aligned_sm << std::endl;

    CUdevResource primary_partition_resource;
    CUdevResource remaining_partition_resource;
    unsigned int num_groups = 1;
    CU_DRIVER_CHECK(cuDevSmResourceSplitByCount(
        &primary_partition_resource,
        &num_groups,
        &device_resource,
        &remaining_partition_resource,
        0,  // default partition flag
        aligned_sm));

    std::cout << "  Primary partition SM count (for GEMM): " << primary_partition_resource.sm.smCount << std::endl;
    std::cout << "  Remaining partition SM count: " << remaining_partition_resource.sm.smCount << std::endl;

    // Step 3: Create resource descriptors
    CUdevResourceDesc primary_partition_desc;
    CUdevResourceDesc remaining_partition_desc;
    CU_DRIVER_CHECK(cuDevResourceGenerateDesc(&primary_partition_desc, &primary_partition_resource, 1));
    CU_DRIVER_CHECK(cuDevResourceGenerateDesc(&remaining_partition_desc, &remaining_partition_resource, 1));

    // Step 4: Create green contexts
    CUgreenCtx primary_partition_green_ctx;
    CUgreenCtx remaining_partition_green_ctx;
    CU_DRIVER_CHECK(cuGreenCtxCreate(&primary_partition_green_ctx, primary_partition_desc, cu_device, CU_GREEN_CTX_DEFAULT_STREAM));
    CU_DRIVER_CHECK(cuGreenCtxCreate(&remaining_partition_green_ctx, remaining_partition_desc, cu_device, CU_GREEN_CTX_DEFAULT_STREAM));

    // Step 5: Create streams on green contexts
    CUstream primary_partition_cu_stream;
    CUstream remaining_partition_cu_stream;
    CU_DRIVER_CHECK(cuGreenCtxStreamCreate(&primary_partition_cu_stream, primary_partition_green_ctx, CU_STREAM_NON_BLOCKING, 0));
    CU_DRIVER_CHECK(cuGreenCtxStreamCreate(&remaining_partition_cu_stream, remaining_partition_green_ctx, CU_STREAM_NON_BLOCKING, 0));

    // Run GEMM on the primary partition stream
    cudaStream_t primary_stream = static_cast<cudaStream_t>(primary_partition_cu_stream);
    run<Gemm>(options, primary_stream);

    // Cleanup: destroy streams, green contexts, release primary context
    CU_DRIVER_CHECK(cuStreamDestroy(primary_partition_cu_stream));
    CU_DRIVER_CHECK(cuStreamDestroy(remaining_partition_cu_stream));
    CU_DRIVER_CHECK(cuGreenCtxDestroy(primary_partition_green_ctx));
    CU_DRIVER_CHECK(cuGreenCtxDestroy(remaining_partition_green_ctx));
    CU_DRIVER_CHECK(cuDevicePrimaryCtxRelease(cu_device));
  }
  else {
    // No green context: run on default stream with all SMs
    run<Gemm>(options, cudaStreamDefault /* full device, no green context */);
  }
#endif // defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED)

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
