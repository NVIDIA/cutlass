/***************************************************************************************************
 * Copyright (c) 2025 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

/*! \file
    \brief Blackwell GeForce Dual-GEMM example using CUTLASS 3.0 APIs for the NVIDIA Blackwell SM120 architecture.

    This example is based on example 79a_blackwell_geforce_nvfp4_bf16_gemm.cu but for Dual-GEMM

```
D0 = epilogue0(X @ B0, C0)
D1 = epilogue1(X @ B1, C1)
D2 = element_wise(D0, D1)
```    
    Usage:

      $ ./examples/94_blackwell_geforce_dual_gemm/94_blackwell_geforce_dual_gemm --m=2048 --n=2048 --k=2048
*/

#include <iostream>
#include <vector>

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/tensor_ref.h"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/detail/sm100_blockscaled_layout.hpp"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/kernel/tile_scheduler_params.h"

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/device/gemm.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/gett.hpp"
#include "cutlass/util/reference/host/tensor_norm.h"
#include "cutlass/util/reference/host/tensor_compare.h"

#include "helper.h"

#include "collective/dispatch_policy_extra.hpp"
#include "collective/builder.hpp"
#include "kernel/sm90_gemm_tma_warpspecialized_cooperative_dual.hpp"
#include "device/gemm_universal_adapter.h"
#include "collective/builder_epilogue.hpp"
#include "thread/left_silu_and_mul.h"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED)


/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////

// A matrix configuration
using         ElementA    = cutlass::nv_float4_t<cutlass::float_e2m1_t>;    // Element type for A matrix operand
using         LayoutATag  = cutlass::layout::RowMajor;                      // Layout type for A matrix operand
constexpr int AlignmentA  = 32;                                             // Memory access granularity/alignment of A matrix in units of elements (up to 16 bytes)

// B matrix configuration
using         ElementB    = cutlass::nv_float4_t<cutlass::float_e2m1_t>;    // Element type for B matrix operand
using         LayoutB0Tag = cutlass::layout::ColumnMajor;                   // Layout type for B0 matrix operand
using         LayoutB1Tag = cutlass::layout::ColumnMajor;                   // Layout type for B1 matrix operand
constexpr int AlignmentB  = 32;                                             // Memory access granularity/alignment of B matrix in units of elements (up to 16 bytes)

// C/D matrix configuration
using         ElementD    = cutlass::bfloat16_t;                            // Element type for D matrix operand
using         ElementC    = cutlass::bfloat16_t;                            // Element type for C matrix operand
using         LayoutCTag  = cutlass::layout::RowMajor;                      // Layout type for C matrix operand
using         LayoutDTag  = cutlass::layout::RowMajor;                      // Layout type for D matrix operand
constexpr int AlignmentD  = 128 / cutlass::sizeof_bits<ElementD>::value;    // Memory access granularity/alignment of D matrix in units of elements (up to 16 bytes)
constexpr int AlignmentC  = 128 / cutlass::sizeof_bits<ElementC>::value;    // Memory access granularity/alignment of C matrix in units of elements (up to 16 bytes)
// Kernel functional config
using ElementAccumulator  = float;                                          // Element type for internal accumulation
using ArchTag             = cutlass::arch::Sm120;                           // Tag indicating the minimum SM that supports the intended feature
using OperatorClass       = cutlass::arch::OpClassBlockScaledTensorOp;      // Operator class tag

// Kernel Perf config
using ThreadBlockShape    = Shape<_128,_128,_128>;                          // Threadblock's tile size
using ClusterShape        = Shape<_1,_1,_1>;                                // Shape of the threadblocks in a cluster
using KernelSchedule      = cutlass::gemm::DualKernelTmaWarpSpecializedCooperativeBlockScaledSm120<3>;
using EpilogueSchedule    = cutlass::epilogue::DualTmaWarpSpecialized;
using EpilogueTileType    = cutlass::epilogue::collective::EpilogueTileAuto;
using ElementCompute      = float;

using OpLeft  = cutlass::epilogue::fusion::DualLinearCombination<ElementD, float, ElementC, float>;
using OpRight = cutlass::epilogue::fusion::DualLinearCombination<ElementD, float, ElementC, float>;
using DualPairOp = cutlass::epilogue::fusion::DualOpPair<OpLeft, OpRight>;

using CollectiveEpilogue = typename cutlass::epilogue::collective::DualCollectiveBuilder<
    ArchTag, OperatorClass,
    ThreadBlockShape, ClusterShape,
    EpilogueTileType,
    ElementAccumulator, ElementAccumulator,
    ElementC, LayoutCTag, AlignmentC,
    ElementD, LayoutDTag, AlignmentD,
    EpilogueSchedule,
    DualPairOp
  >::CollectiveOp;

using CollectiveMainloop = typename cutlass::gemm::collective::DualCollectiveBuilder<
    ArchTag, OperatorClass,
    ElementA, LayoutATag, AlignmentA,
    ElementB, LayoutB0Tag, LayoutB1Tag, AlignmentB,
    ElementAccumulator,
    ThreadBlockShape, ClusterShape,
    cutlass::gemm::collective::StageCount<3>,
    KernelSchedule                             
  >::CollectiveOp;

using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>,                                                   // Indicates ProblemShape
    CollectiveMainloop,
    CollectiveEpilogue,
    void>;

using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

// Reference device GEMM implementation type
using StrideA   = typename Gemm::GemmKernel::StrideA;
using LayoutA   = decltype(cute::make_layout(make_shape(0,0,0), StrideA{}));
using LayoutSFA = typename Gemm::GemmKernel::CollectiveMainloop::LayoutSFA;      // Scale Factor tensors have an interleaved layout. Bring Layout instead of stride.
using StrideB0   = typename Gemm::GemmKernel::StrideB0;
using LayoutB0   = decltype(cute::make_layout(make_shape(0,0,0), StrideB0{}));
using LayoutSFB0 = typename Gemm::GemmKernel::CollectiveMainloop::LayoutSFB0;    // Scale Factor tensors have an interleaved layout. Bring Layout instead of stride.
using StrideB1   = typename Gemm::GemmKernel::StrideB1;
using LayoutB1   = decltype(cute::make_layout(make_shape(0,0,0), StrideB1{}));
using LayoutSFB1 = typename Gemm::GemmKernel::CollectiveMainloop::LayoutSFB1;    // Scale Factor tensors have an interleaved layout. Bring Layout instead of stride.
using StrideC   = typename Gemm::GemmKernel::StrideC;
using LayoutC   = decltype(cute::make_layout(make_shape(0,0,0), StrideC{}));
using StrideD   = typename Gemm::GemmKernel::StrideD;
using LayoutD   = decltype(cute::make_layout(make_shape(0,0,0), StrideD{}));

//
// Data members
//

/// Initialization
StrideA stride_A;
LayoutA layout_A;
LayoutSFA layout_SFA;
StrideB0 stride_B0;
LayoutB0 layout_B0;
LayoutSFB0 layout_SFB0;
StrideB1 stride_B1;
LayoutB1 layout_B1;
LayoutSFB1 layout_SFB1;
StrideC stride_C;
LayoutC layout_C;
StrideD stride_D;
LayoutD layout_D;
uint64_t seed;

// The HostTensors are only used for allocating memory on host and device, and transferring data between host and device
// Use cute::Tensor and cute::Layout for iterating thru the matrix elements
cutlass::HostTensor<ElementA::DataType, cutlass::layout::PackedVectorLayout> block_A;
cutlass::HostTensor<ElementA::ScaleFactorType, cutlass::layout::PackedVectorLayout> block_SFA;
cutlass::HostTensor<ElementB::DataType, cutlass::layout::PackedVectorLayout> block_B0;
cutlass::HostTensor<ElementB::DataType, cutlass::layout::PackedVectorLayout> block_B1;
cutlass::HostTensor<ElementB::ScaleFactorType, cutlass::layout::PackedVectorLayout> block_SFB0;
cutlass::HostTensor<ElementB::ScaleFactorType, cutlass::layout::PackedVectorLayout> block_SFB1;
cutlass::HostTensor<ElementC, cutlass::layout::PackedVectorLayout> block_C;
// Output Tensor
cutlass::HostTensor<ElementD, cutlass::layout::PackedVectorLayout> block_D;
// Reference Output Tensor
cutlass::HostTensor<ElementD, cutlass::layout::PackedVectorLayout> block_reference_D;
#endif // defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED)

template <typename T>
auto make_iterator(T* ptr) {
  return cute::recast_ptr<T>(ptr);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help;

  float alpha, beta;
  int iterations;
  int m, n, k;

  Options():
    help(false),
    m(1024), n(1024), k(1024),
    alpha(1.f), beta(0.f),
    iterations(10)
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
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "94_blackwell_geforce_dual_gemm\n\n"
      << "  Blackwell NVFP4 Dual-GEMM using a Warp Specialized kernel.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --alpha=<f32>               Epilogue scalar alpha\n"
      << "  --beta=<f32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n";

    out << "\n\nExamples:\n\n"
      << "$ " << "./examples/94_blackwell_geforce_dual_gemm/94_blackwell_geforce_dual_gemm.cu" << " --m=1024 --n=512 --k=1024 --alpha=2 --beta=0.707 \n\n";

    return out;
  }

  /// Compute performance in GFLOP/s
  double gflops(double runtime_s) const
  {
    // Two flops per multiply-add x2 for dual gemm
    uint64_t flop = uint64_t(4) * m * n * k;
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

#if defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to initialize a block of device data
template <typename Element, typename Layout>
bool initialize_block(
  cutlass::TensorView<Element, Layout> view,
  uint64_t seed) {

  double scope_max, scope_min;
  constexpr int bits_input = cutlass::sizeof_bits<Element>::value;

  if constexpr (bits_input == 1) {
    scope_max = 2;
    scope_min = 0;
  }
  else if constexpr (bits_input <= 6) {
    scope_max = 2;
    scope_min = -2;
  }
  else if constexpr (bits_input <= 8) {
    if constexpr (cute::is_same_v<Element, cutlass::float_ue8m0_t>) {
      scope_max = 4;
      scope_min = 1;
    }
    else {
      scope_max = 1;
      scope_min = -1;
    }
  }
  else{
    scope_max = 4;
    scope_min = -4;
  }
  cutlass::reference::host::TensorFillRandomUniform(
    view, seed, scope_max, scope_min, 0);

  return true;
}

/// Initialize operands to be used in the GEMM and reference GEMM
void initialize(const Options &options) {
  using namespace cute;
  // For SFA and SFB tensors layouts
  using Sm1xxBlkScaledConfig =  typename Gemm::GemmKernel::CollectiveMainloop::Sm1xxBlkScaledConfig;

  stride_A  = cutlass::make_cute_packed_stride(StrideA{}, {options.m, options.k, 1});
  stride_B0 = cutlass::make_cute_packed_stride(StrideB0{}, {options.n, options.k, 1});
  stride_B1 = cutlass::make_cute_packed_stride(StrideB1{}, {options.n, options.k, 1});
  stride_C  = cutlass::make_cute_packed_stride(StrideC{}, {options.m, options.n, 1});
  stride_D  = cutlass::make_cute_packed_stride(StrideD{}, {options.m, options.n, 1});

  layout_A  = make_layout(make_shape(options.m, options.k, 1), stride_A);
  layout_B0 = make_layout(make_shape(options.n, options.k, 1), stride_B0);
  layout_B1 = make_layout(make_shape(options.n, options.k, 1), stride_B1);
  layout_C  = make_layout(make_shape(options.m, options.n, 1), stride_C);
  layout_D  = make_layout(make_shape(options.m, options.n, 1), stride_D);
  layout_SFA  = Sm1xxBlkScaledConfig::tile_atom_to_shape_SFA(cute::make_shape(options.m, options.n, options.k, 1));
  layout_SFB0 = Sm1xxBlkScaledConfig::tile_atom_to_shape_SFB(cute::make_shape(options.m, options.n, options.k, 1));
  layout_SFB1 = Sm1xxBlkScaledConfig::tile_atom_to_shape_SFB(cute::make_shape(options.m, options.n, options.k, 1));

  block_A.reset(cutlass::make_Coord(size(layout_A)));
  block_B0.reset(cutlass::make_Coord(size(layout_B0)));
  block_B1.reset(cutlass::make_Coord(size(layout_B1)));
  block_C.reset(cutlass::make_Coord(size(layout_C)));
  block_D.reset(cutlass::make_Coord(size(layout_D)));
  block_reference_D.reset(cutlass::make_Coord(size(layout_D)));
  block_SFA.reset(cutlass::make_Coord(size(filter_zeros(layout_SFA))));
  block_SFB0.reset(cutlass::make_Coord(size(filter_zeros(layout_SFB0))));
  block_SFB1.reset(cutlass::make_Coord(size(filter_zeros(layout_SFB1))));

  initialize_block(block_A.host_view(), seed + 2021);
  initialize_block(block_B0.host_view(), seed + 2022);
  initialize_block(block_B1.host_view(), seed + 3022);
  initialize_block(block_C.host_view(), seed + 2023);
  initialize_block(block_SFA.host_view(), seed + 2024);
  initialize_block(block_SFB0.host_view(), seed + 2025);
  initialize_block(block_SFB1.host_view(), seed + 3025);

  block_A.sync_device();
  block_B0.sync_device();
  block_B1.sync_device();
  block_C.sync_device();
  block_SFA.sync_device();
  block_SFB0.sync_device();
  block_SFB1.sync_device();
}

// Populates a Gemm::Arguments structure from the given commandline options
typename Gemm::Arguments args_from_options(const Options &options)
{
  typename Gemm::Arguments arguments {
    cutlass::gemm::GemmUniversalMode::kGemm,
    {options.m, options.n, options.k, 1},
    { // Mainloop arguments
      block_A.device_data(), stride_A,
      block_B0.device_data(), stride_B0,
      block_B1.device_data(), stride_B1,
      block_SFA.device_data(), layout_SFA,
      block_SFB0.device_data(), layout_SFB0,
      block_SFB1.device_data(), layout_SFB1
    },
    { // Epilogue arguments
      {
        { options.alpha, options.beta },   // op0
        { options.alpha, options.beta }    // op1
      },
      block_C.device_data(), stride_C,
      block_D.device_data(), stride_D
    }
  };

  return arguments;
}

bool verify(const Options &options) {
  using namespace cute;
  // Create the arguments for host reference implementation
  Tensor tensor_A = make_tensor(make_iterator(block_A.host_data()), layout_A);
  Tensor tensor_SFA = make_tensor(block_SFA.host_data(), layout_SFA);
  Tensor tensor_B0 = make_tensor(make_iterator(block_B0.host_data()), layout_B0);
  Tensor tensor_SFB0 = make_tensor(block_SFB0.host_data(), layout_SFB0);
  Tensor tensor_B1 = make_tensor(make_iterator(block_B1.host_data()), layout_B1);
  Tensor tensor_SFB1 = make_tensor(block_SFB1.host_data(), layout_SFB1);

  // Prepare host buffers for two separate GEMM outputs:
  cutlass::HostTensor<ElementD, cutlass::layout::PackedVectorLayout> block_reference_D0;
  cutlass::HostTensor<ElementD, cutlass::layout::PackedVectorLayout> block_reference_D1;
  block_reference_D0.reset(cutlass::make_Coord(size(layout_D)));
  block_reference_D1.reset(cutlass::make_Coord(size(layout_D)));

  auto tensor_C  = cute::make_tensor(make_iterator(block_C.host_data()), layout_C);
  auto tensor_D0 = cute::make_tensor(make_iterator(block_reference_D0.host_data()), layout_D);
  auto tensor_D1 = cute::make_tensor(make_iterator(block_reference_D1.host_data()), layout_D);

  // First GEMM: D0 = alpha * (A @ B0) + beta * C  (linear combination epilogue)
  cutlass::reference::host::GettBlockScalingMainloopParams<
      ElementAccumulator,                 // ElementAccumulator
      decltype(tensor_A),                 // TensorA
      decltype(tensor_SFA),               // TensorSfA
      decltype(tensor_B0),                // TensorB0
      decltype(tensor_SFB0)               // TensorSfB0
    > mainloop_params0{tensor_A, tensor_SFA, tensor_B0, tensor_SFB0};

  cutlass::reference::host::GettBlockScalingEpilogueParams<
      ElementAccumulator,                 // ElementScalar
      ElementAccumulator,                 // ElementAccumulator
      ElementAccumulator,                 // ElementCompute
      decltype(tensor_C),                 // TensorC
      decltype(tensor_D0)                 // TensorD0
    > epilogue_params0{options.alpha, options.beta, tensor_C, tensor_D0};

  cutlass::reference::host::Gemm3x(mainloop_params0, epilogue_params0);

  // Second GEMM: D1 = alpha * (A @ B1) + beta * C  (linear combination epilogue)
  cutlass::reference::host::GettBlockScalingMainloopParams<
      ElementAccumulator,
      decltype(tensor_A),
      decltype(tensor_SFA),
      decltype(tensor_B1),
      decltype(tensor_SFB1)
    > mainloop_params1{tensor_A, tensor_SFA, tensor_B1, tensor_SFB1};

  cutlass::reference::host::GettBlockScalingEpilogueParams<
      ElementAccumulator,
      ElementAccumulator,
      ElementAccumulator,
      decltype(tensor_C),
      decltype(tensor_D1)
    > epilogue_params1{options.alpha, options.beta, tensor_C, tensor_D1};

  cutlass::reference::host::Gemm3x(mainloop_params1, epilogue_params1);

  // Compute final D2_ref = LeftSiLUAndMul(D0_ref, D1_ref) 
  int64_t total_elems = static_cast<int64_t>(options.m) * static_cast<int64_t>(options.n);

  using LeftOp = cutlass::epilogue::thread::LeftSiLUAndMul<
      ElementD,                     // ElementOutput (store as ElementD)
      1,                            // Count: scalar path
      ElementAccumulator,           // ElementAccumulator (accum type)
      ElementAccumulator,           // ElementCompute (compute type)
      cutlass::FloatRoundStyle::round_to_nearest
    >;

  LeftOp leftop(typename LeftOp::Params{}); // Params is empty struct

  // elementwise loop (host)
  ElementD *d0_ptr = block_reference_D0.host_data();
  ElementD *d1_ptr = block_reference_D1.host_data();
  ElementD *d2_ptr = block_reference_D.host_data(); 

  for (int64_t i = 0; i < total_elems; ++i) {
    ElementAccumulator lhs_acc = ElementAccumulator(d0_ptr[i]);
    ElementAccumulator rhs_acc = ElementAccumulator(d1_ptr[i]);

    d2_ptr[i] = leftop(lhs_acc, rhs_acc);
  }

  // Comparison
  block_D.sync_host();
  bool passed = cutlass::reference::host::TensorEquals(block_reference_D.host_view(), block_D.host_view());
  passed &= (cutlass::reference::host::TensorNorm(block_reference_D.host_view()) > 0);
  passed &= (cutlass::reference::host::TensorNorm(block_D.host_view()) > 0);

  return passed;
}

/// Execute a given example GEMM computation
template <typename Gemm>
int run(Options &options)
{
  initialize(options);

  // Instantiate CUTLASS kernel depending on templates
  Gemm gemm;

  // Create a structure of gemm kernel arguments suitable for invoking an instance of Gemm
  auto arguments = args_from_options(options);

  // Using the arguments, query for extra workspace required for matrix multiplication computation
  size_t workspace_size = Gemm::get_workspace_size(arguments);

  // Allocate workspace memory
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

  // Check if the problem size is supported or not
  CUTLASS_CHECK(gemm.can_implement(arguments));

  // Initialize CUTLASS kernel with arguments and workspace pointer
  CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));

  // Correctness / Warmup iteration
  CUTLASS_CHECK(gemm.run());

  cudaDeviceSynchronize();

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
    timer.start();
    for (int iter = 0; iter < options.iterations; ++iter) {
      CUTLASS_CHECK(gemm.initialize(arguments, workspace.get()));
      CUTLASS_CHECK(gemm.run());
    }
    timer.stop();

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

#endif // defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // CUTLASS must be compiled with CUDA 12.8 or higher Toolkit to run this example
  // and must have compute capability at least 100.
  if (__CUDACC_VER_MAJOR__ < 12 || (__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 8)) {
    std::cerr << "This example requires CUDA 12.8 or newer." << std::endl;
    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));

  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));

  if (!(props.major == 12 && props.minor == 0)) {
    std::cerr << "This example requires a GPU of NVIDIA's Blackwell architecture (compute capability 120)." << std::endl;
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
#if defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED)
  run<Gemm>(options);
#endif // defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED)

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
