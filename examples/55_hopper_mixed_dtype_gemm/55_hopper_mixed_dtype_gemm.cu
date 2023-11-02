/***************************************************************************************************
 * Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Hopper GEMM example with different data types using CUTLASS 3.0 APIs for NVIDIA Hopper architecture

    This example shows how to perform GEMM where the input tensors A and B have different element types. CUTLASS currently supports upcasting
    from a narrower (fewer bits) to a wider (more bits) type and utilizing the tensor core instruction for the wider type. For instance, when doing
    INT8 x FP16, CUTLASS will convert INT8 -> FP16 and do math using FP16 tensor cores. Similarly, for INT4 x INT8, it will upcast to INT8 and issue math 
    using INT8 tensor cores.

    The narrower type always passes through the register file. Therefore, in cases where the narrower type is operand B, the collective will implicitly swap 
    A and B in the main loop. Consequently, it is essential to consider this when constructing the epilogue, as illustrated in this example.

    Limitations:
      1) Only supported combinations are 16-bit x {8-bit, 4-bit, 2-bit} and {8-bit} x {4-bit, 2-bit}.
      2) The narrow type must always be in K-major format.
      3) When dealing with 8-bit x {4-bit, 2-bit}, both inputs must be in K-major format.
      4) Currently, TMA epilogues cannot be used when the narrow type is the B operand. This limitation arises because the implementation always swaps the 
         operands to ensure the narrow type passes through the register file, and TMA epilogues do not currently support swap + transpose operations. 
         We plan to address this limitation in the future.

    Examples:

      $ ./examples/55_hopper_mixed_dtype_gemm/55_hopper_mixed_dtype_gemm --m=2048 --n=2048 --k=2048 --l=2
*/

#include <iostream>

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"
#include "cutlass/tensor_ref.h"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_norm.h"
#include "cutlass/util/reference/host/gett.hpp"

#include "helper.h"
#include "unfused_weight_dequantize.h"

using namespace cute;

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM kernel configurations
/////////////////////////////////////////////////////////////////////////////////////////////////
using MmaType = cutlass::half_t;
using QuantType = int8_t;

// A matrix configuration
using         ElementA    = MmaType;                                // Element type for A matrix operand
using         LayoutA     = cutlass::layout::RowMajor;                      // Layout type for A matrix operand
constexpr int AlignmentA  = 128 / cutlass::sizeof_bits<ElementA>::value;    // Memory access granularity/alignment of A matrix in units of elements (up to 16 bytes)

// B matrix configuration
using         ElementB    = QuantType;                                      // Element type for B matrix operand
using         LayoutB     = cutlass::layout::ColumnMajor;                   // Layout type for B matrix operand
constexpr int AlignmentB  = 128 / cutlass::sizeof_bits<ElementB>::value;    // Memory access granularity/alignment of B matrix in units of elements (up to 16 bytes)

// C/D matrix configuration
using         ElementC    = cutlass::half_t;                                // Element type for C and D matrix operands
using         LayoutC     = cutlass::layout::RowMajor;                      // Layout type for C and D matrix operands
constexpr int AlignmentC  = 128 / cutlass::sizeof_bits<ElementC>::value;    // Memory access granularity/alignment of C matrix in units of elements (up to 16 bytes)

// D matrix configuration
using         ElementD    = ElementC;
using         LayoutD     = LayoutC;

// Core kernel configurations
using ElementAccumulator  = float;                                          // Element type for internal accumulation
using ElementCompute      = float;                                          // Element type for epilogue computation
using ArchTag             = cutlass::arch::Sm90;                            // Tag indicating the minimum SM that supports the intended feature
using OperatorClass       = cutlass::arch::OpClassTensorOp;                 // Operator class tag
using TileShape           = Shape<_128,_256,_64>;                           // Threadblock-level tile size
using ClusterShape        = Shape<_2,_1,_1>;                                // Shape of the threadblocks in a cluster
using StageCountType = cutlass::gemm::collective::StageCountAuto;           // Stage count maximized based on the tile size
using KernelSchedule = cutlass::gemm::collective::KernelScheduleAuto;       // Kernel to launch based on the default setting in the Collective Builder 


using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
    ArchTag, OperatorClass,
    ElementA, LayoutA, AlignmentA,
    ElementB, LayoutB, AlignmentB,
    ElementAccumulator,
    TileShape, ClusterShape,
    cutlass::gemm::collective::StageCountAuto,
    cutlass::gemm::collective::KernelScheduleAuto
  >::CollectiveOp;

using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
    cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
    TileShape, ClusterShape,
    cutlass::epilogue::collective::EpilogueTileAuto,
    ElementAccumulator, ElementAccumulator,
    // Lie here about layout of C and D since we do swap and transpose trick
    ElementC, typename cutlass::layout::LayoutTranspose<LayoutC>::type, AlignmentC,
    ElementC, typename cutlass::layout::LayoutTranspose<LayoutC>::type, AlignmentC,
    cutlass::epilogue::NoSmemWarpSpecialized // This is the only epi supporting the required swap + transpose.
  >::CollectiveOp;

using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    Shape<int,int,int,int>, // Indicates ProblemShape
    CollectiveMainloop,
    CollectiveEpilogue
>;

using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

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
uint64_t seed;

// Initialization functions don't handle sub-byte types so we use uint8 to initialize and a separate
// kernel to pack the data if it is necessary.
using InitializationType = cute::conditional_t<cute::sizeof_bits_v<QuantType> < 8, uint8_t, QuantType>;

cutlass::HostTensor<typename Gemm::ElementA, LayoutA> tensor_A;
cutlass::HostTensor<InitializationType, LayoutB> tensor_B_init;
cutlass::HostTensor<typename Gemm::ElementB, LayoutB> tensor_B;
cutlass::HostTensor<typename Gemm::ElementA, LayoutB> tensor_B_dq;
cutlass::HostTensor<typename Gemm::ElementC, LayoutC> tensor_C;
cutlass::HostTensor<typename Gemm::EpilogueOutputOp::ElementOutput, LayoutD> tensor_D;
cutlass::HostTensor<typename Gemm::EpilogueOutputOp::ElementOutput, LayoutD> tensor_ref_D;

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help = false;

  float alpha = 1.0f;
  float beta = 0.0f;
  int iterations = 1000;
  int m = 5120, n = 4096, k = 4096;
  int l = 1;

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
    cmd.get_cmd_line_argument("l", l);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("iterations", iterations);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "55_hopper_warp_specialized_gemm\n\n"
      << "  Hopper FP32 GEMM using a Warp Specialized kernel.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --l=<int>                   The number of independent gemm problems with mnk shape\n"
      << "  --alpha=<f32>               Epilogue scalar alpha\n"
      << "  --beta=<f32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n";

    out
      << "\n\nExamples:\n\n"
      << "$ " << "55_hopper_warp_specialized_gemm" << " --m=1024 --n=512 --k=1024 --l=10 --alpha=2 --beta=0.707 \n\n";

    return out;
  }

  /// Compute performance in GFLOP/s
  double gflops(double runtime_s) const
  {
    // Two flops per multiply-add
    uint64_t flop = uint64_t(2) * m * n * k * l;
    double gflop = double(flop) / double(1.0e9);
    return gflop / runtime_s;
  }
};

/// Result structure
struct Result
{
  double avg_runtime_ms = 0.0;
  double gflops = 0.0;
  cutlass::Status status = cutlass::Status::kSuccess;
  cudaError_t error = cudaSuccess;
  bool passed = false;

};

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to initialize a block of device data
template <class Element, class Layout>
bool initialize_tensor(
  cutlass::TensorView<Element, Layout> view,
  uint64_t seed=2023) {

  double scope_max, scope_min;
  int bits_input = cutlass::sizeof_bits<Element>::value;
  int bits_output = cutlass::sizeof_bits<Element>::value;

  if (bits_input == 1) {
    scope_max = 2;
    scope_min = 0;
  }
  else if (bits_input <= 8) {
    scope_max = 2;
    scope_min = -2;
  }
  else if (bits_output == 16) {
    scope_max = 5;
    scope_min = -5;
  }
  else {
    scope_max = 8;
    scope_min = -8;
  }
  cutlass::reference::host::TensorFillRandomUniform(
    view, seed, scope_max, scope_min, 0);

  return true;
}

template <class QuantElement, typename Element, typename Layout>
bool initialize_quant_tensor(
  cutlass::TensorView<Element, Layout> view,
  uint64_t seed=2023) {
  
  Element scope_max, scope_min;
  constexpr int bits_input = cute::sizeof_bits_v<QuantElement>;
  static_assert(bits_input <= 8, "Quantization type can be at most 8 bits");

  if constexpr (bits_input == 8) {
    // Directly init 1-byte types
    static_assert(cute::is_same_v<QuantElement, Element>, "Init type should equal quant type for 1 byte types");
    scope_max = std::numeric_limits<QuantElement>::max();
    scope_min = std::numeric_limits<QuantElement>::min();
  } else {
    static_assert(cute::is_same_v<uint8_t, Element>, "Init type should be uint8_t for sub-byte types");
    scope_max = (1 << bits_input);
    scope_min = 0;
  }

  cutlass::reference::host::TensorFillRandomUniform(
    view, seed, scope_max, scope_min, 0);

  return true;
}

template <class Element, class Layout>
bool initialize_with_one(
  cutlass::TensorView<Element, Layout> view) {
  cutlass::reference::host::TensorFill(view, Element(1.0f));
  return true;
}

template <class ElementDst, class ElementSrc, class Layout, class L>
void prepare_packed_data(cutlass::HostTensor<ElementDst, Layout> view_dst_data,
                         cutlass::HostTensor<ElementSrc, Layout> view_src_data,
                         const L& cute_layout) {
  if constexpr (cute::is_same_v<ElementSrc, ElementDst>) {
    view_dst_data.copy_in_device_to_device(view_src_data.device_data());
  } 
  else {
    pack_data(view_dst_data.device_data(), view_src_data.device_data(), cute_layout);
  }
}

/// Initialize operands to be used in the GEMM and reference GEMM
void initialize(const Options &options) {

  auto shape_b = cute::make_shape(options.n, options.k, options.l);
  stride_A = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(options.m, options.k, options.l));
  stride_B = cutlass::make_cute_packed_stride(StrideB{}, shape_b);
  stride_C = cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(options.n, options.m, options.l));
  stride_D = cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(options.n, options.m, options.l));

  auto a_coord = cutlass::make_Coord(options.m * options.l, options.k);
  auto b_coord = cutlass::make_Coord(options.k, options.n * options.l);
  auto c_coord = cutlass::make_Coord(options.m * options.l, options.n);

  tensor_A.resize(a_coord);
  tensor_B_init.resize(b_coord);
  tensor_B.resize(b_coord);
  tensor_B_dq.resize(b_coord);
  tensor_C.resize(c_coord);
  tensor_D.resize(c_coord);
  tensor_ref_D.resize(c_coord);

  // We need scales since the "dequantize" kernels expects them. We just set them to 1 so the values get converted
  // to the mma type.
  cutlass::HostTensor<MmaType, cutlass::layout::RowMajor> tensor_scale;
  tensor_scale.resize({1 * options.l, options.n});

  initialize_tensor(tensor_A.host_view(), seed + 2022);
  initialize_quant_tensor<QuantType>(tensor_B_init.host_view(), seed + 2021);
  initialize_tensor(tensor_C.host_view(), seed + 2020);
  initialize_with_one(tensor_scale.host_view());

  tensor_A.sync_device();
  tensor_B_init.sync_device();
  tensor_C.sync_device();
  tensor_scale.sync_device();

  auto layout_B = make_layout(shape_b, stride_B);
  prepare_packed_data(tensor_B, tensor_B_init, layout_B);

  auto shape_scale = cute::make_shape(options.n, 1, options.l);
  auto layout_scale = make_layout(shape_scale);
  dequantize_weight(tensor_B_dq.device_data(), tensor_B.device_data(), layout_B, tensor_scale.device_data(), layout_scale);

  tensor_B.sync_host();
  tensor_B_dq.sync_host();
}

/// Populates a Gemm::Arguments structure from the given commandline options
typename Gemm::Arguments args_from_options(const Options &options)
{
  typename Gemm::Arguments arguments{
    cutlass::gemm::GemmUniversalMode::kGemm,
    {options.m, options.n, options.k, options.l},
    {tensor_A.device_data(), stride_A, tensor_B.device_data(), stride_B},
    {{options.alpha, options.beta}, tensor_C.device_data(), stride_C, tensor_D.device_data(), stride_D}
  };

  return arguments;
}

bool verify(const Options &options) {
  //
  // Compute reference output
  //

  // Create instantiation for device reference gemm kernel
  auto A = cute::make_tensor(tensor_A.host_data(),
      cute::make_layout(cute::make_shape(options.m, options.k, options.l), stride_A));
  auto B = cute::make_tensor(tensor_B_dq.host_data(),
      cute::make_layout(cute::make_shape(options.n, options.k, options.l), stride_B));
  auto C = cute::make_tensor(tensor_C.host_data(),
      cute::make_layout(cute::make_shape(options.m, options.n, options.l), stride_C));
  auto D = cute::make_tensor(tensor_ref_D.host_data(),
      cute::make_layout(cute::make_shape(options.m, options.n, options.l), stride_D));

  using unused_t = decltype(D);

  cutlass::reference::host::GettMainloopParams<ElementAccumulator, decltype(A), decltype(B)> mainloop_params{A, B};

  cutlass::reference::host::GettEpilogueParams<
      typename Gemm::EpilogueOutputOp::ElementScalar,
      typename Gemm::EpilogueOutputOp::ElementScalar,
      ElementAccumulator,
      ElementCompute,
      decltype(C),
      decltype(D),
      unused_t, // bias
      unused_t, // aux
      unused_t, // valpha
      unused_t  // vbeta
  > epilogue_params;

  epilogue_params.C = C;
  epilogue_params.D = D;
  epilogue_params.alpha = options.alpha;
  epilogue_params.beta = options.beta;

  // get reference result
  cutlass::reference::host::Gemm3x(mainloop_params, epilogue_params);

  // compare_reference
  tensor_D.sync_host();
  bool passed = cutlass::reference::host::TensorEquals(tensor_ref_D.host_view(), tensor_D.host_view());
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
      CUTLASS_CHECK(gemm.run());
    }
    timer.stop();

    // Compute average runtime and GFLOPs.
    float elapsed_ms = timer.elapsed_millis();
    result.avg_runtime_ms = double(elapsed_ms) / double(options.iterations);
    result.gflops = options.gflops(result.avg_runtime_ms / 1000.0);

    std::cout << "  Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l << std::endl;
    std::cout << "  Avg runtime: " << result.avg_runtime_ms << " ms" << std::endl;
    std::cout << "  GFLOPS: " << result.gflops << std::endl;
  }

  return 0;
}

#endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // CUTLASS must be compiled with CUDA 12.0 Toolkit to run this example
  // and must have compute capability at least 90.
  if (__CUDACC_VER_MAJOR__ < 12) {
    std::cerr << "This example requires CUDA 12 or newer.\n";
    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));
  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (props.major < 9) {
    std::cerr
      << "This example requires a GPU of NVIDIA's Hopper Architecture or "
      << "later (compute capability 90 or greater).\n";
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

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)
  run<Gemm>(options);
#endif

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
