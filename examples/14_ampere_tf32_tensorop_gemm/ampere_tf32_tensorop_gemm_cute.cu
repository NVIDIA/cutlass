/***************************************************************************************************
 * Copyright (c) 2017 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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
    \brief Simple GEMM example using Cute and CUTLASS 3.x APIs for NVIDIA Ampere architecture

    This example demonstrate how to instantiate and run a TF32 GEMM using the Cute and
    CUTLASS 3.x APIs on NVIDIA Ampere architecture. Please check example 07 and 08 for
    the basics of tensor op gemm kernels. On NVIDIA Ampere architecture, most concept
    still holds. The two main differences are:

      (1) NVIDIA Ampere architecture introduces a new series of tensor core instructions
          (see include/cute/arch/mma_sm80.hpp) which are more efficient on Ampere.
      (2) NVIDIA Ampere architecture uses CP_ASYNC (see include/cute/arch/copy_sm80.hpp)
          to build a multistage software pipeline to better hide latency (see
          include/cutlass/gemm/collective/sm80_mma_multistage.hpp).

    Moreover, NVIDIA Ampere architecture starts supporting tfloat32 (see include/cutlass/tfloat32.h)
    data types in tensor cores.  One big advantage is that we can load in fp32 data and convert
    them implicitly to tf32 inside the GEMM kernel which means no change is needed to accelerate
    traditional fp32 data by using NVIDIA Ampere architecture.

    Examples:

      $ ./examples/14_ampere_tf32_tensorop_gemm/14_ampere_tf32_tensorop_gemm_cute

*/

#include <iostream>

#include "cutlass/cutlass.h"
#include "cutlass/gemm/device/gemm.h"
#include "cutlass/gemm/device/gemm_universal.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/epilogue/collective/default_epilogue.hpp"

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#if defined(CUTLASS_ENABLE_SYCL)
#include "cutlass/util/reference/device/sycl_tensor_fill.h"
#else
#include "cutlass/util/reference/device/tensor_fill.h"
#endif
#include "helper.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

using namespace cute;

/// Result structure
struct Result {

  double avg_runtime_ms;
  double gflops;
  bool passed;

  //
  // Methods
  //

  Result(
    double avg_runtime_ms = 0,
    double gflops = 0)
  :
    avg_runtime_ms(avg_runtime_ms), gflops(gflops), passed(false)
  {}
};

///////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help;

  int m, n, k, l;
  float alpha, beta;
  int iterations;

  Options():
    help(false),
    m(5120), n(4096), k(4096), l(1),
    alpha(1), beta(0),
    iterations(100)
  { }

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("m", m, 5120);
    cmd.get_cmd_line_argument("n", n, 4096);
    cmd.get_cmd_line_argument("k", k, 4096);
    cmd.get_cmd_line_argument("l", l, 1);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("iterations", iterations);

  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "14_ampere_tf32_tensorop_gemm_cute example\n\n"
      << "  This example uses the CUTLASS Library to execute TF32 tensorop GEMM computations.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement.\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --l=<int>                   Sets the L extent (batch count) of the GEMM\n"
      << "  --alpha=<f32>               Epilogue scalar alpha\n"
      << "  --beta=<f32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n";

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

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to initialize a block of device data
template <class Element>
bool initialize_block(
        cutlass::DeviceAllocation<Element>& block,
        uint64_t seed=2023) {

  Element scope_max, scope_min;
  int bits_input = cutlass::sizeof_bits<Element>::value;

  if (bits_input == 1) {
    scope_max = 2;
    scope_min = 0;
  } else if (bits_input <= 8) {
    scope_max = 2;
    scope_min = -2;
  } else {
    scope_max = 8;
    scope_min = -8;
  }

  cutlass::reference::device::BlockFillRandomUniform(
        block.get(), block.size(), seed, scope_max, scope_min, 0);
  return true;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Wrapper to run and verify a GEMM.
template <
        class Gemm
>
struct ExampleRunner {

  using StrideA = typename Gemm::GemmKernel::StrideA;
  using StrideB = typename Gemm::GemmKernel::StrideB;
  using StrideC = typename Gemm::GemmKernel::StrideC;
  using StrideD = typename Gemm::GemmKernel::StrideD;

  using LayoutA = typename Gemm::LayoutA;
  using LayoutB = typename Gemm::LayoutB;
  using LayoutC = typename Gemm::LayoutC;
  using LayoutD = typename Gemm::LayoutD;

  using ElementA = typename Gemm::ElementA;
  using ElementB = typename Gemm::ElementB;
  using ElementAcc = typename Gemm::ElementAccumulator;

  using CollectiveEpilogue = typename Gemm::CollectiveEpilogue;
  using ElementC = typename Gemm::ElementC;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementCompute = typename CollectiveEpilogue::ElementCompute;
  using ElementAccumulator = typename CollectiveEpilogue::ElementAccumulator;

  using ProblemShapeType = typename Gemm::GemmKernel::ProblemShape;

  //
  // Data members
  //

  /// Initialization
  StrideA stride_A;
  StrideB stride_B;
  StrideC stride_C;
  StrideD stride_D;
  uint64_t seed = 0;

  cutlass::DeviceAllocation<ElementA> block_A;
  cutlass::DeviceAllocation<ElementB> block_B;
  cutlass::DeviceAllocation<ElementC> block_C;
  cutlass::DeviceAllocation<ElementOutput> block_D;
  cutlass::DeviceAllocation<ElementOutput> block_ref_D;

  //
  // Methods
  //

  bool verify(const ProblemShapeType& problem_size, ElementOutput alpha, ElementOutput beta) {
    auto [M, N, K, L] = problem_size;

    cutlass::TensorRef ref_A(block_A.get(), LayoutA::packed({M, K}));
    cutlass::TensorRef ref_B(block_B.get(), LayoutB::packed({K, N}));
    cutlass::TensorRef ref_C(block_C.get(), LayoutC::packed({M, N}));
    cutlass::TensorRef ref_D(block_ref_D.get(), LayoutD::packed({M, N}));

    cutlass::reference::device::GemmComplex(
            {M, N, K},
            ElementCompute(alpha),
            ref_A,
            cutlass::ComplexTransform::kNone,
            ref_B,
            cutlass::ComplexTransform::kNone,
            ElementCompute(beta),
            ref_C,
            ref_D,
            ElementAccumulator(0),
            L,     // batch_count
            M * K, // batch_stride_A
            K * N, // batch_stride_B
            M * N, // batch_stride_C
            M * N  // batch_stride_D
    );

#if defined(CUTLASS_ENABLE_SYCL)
    syclcompat::wait_and_throw();
#else
    cudaError_t result = cudaDeviceSynchronize();
    if (result != cudaSuccess) {
      std::cerr << "Reference kernel failed. Last CUDA error: "
                << cudaGetErrorString(result) << std::endl;
      return false;
    }
#endif

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    bool passed = cutlass::reference::device::BlockCompareEqual(block_ref_D.get(), block_D.get(), block_D.size());

    return passed;
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(const ProblemShapeType& problem_size) {
    auto problem_shape_MNKL = cute::append<4>(problem_size, 1);
    auto [M, N, K, L] = problem_shape_MNKL;

    stride_A = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(M, K, L));
    stride_B = cutlass::make_cute_packed_stride(StrideB{}, cute::make_shape(N, K, L));
    stride_C = cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(M, N, L));
    stride_D = cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(M, N, L));

    block_A.reset(M * K * L);
    block_B.reset(K * N * L);
    block_C.reset(M * N * L);
    block_D.reset(M * N * L);
    block_ref_D.reset(M * N * L);

    initialize_block(block_A, seed + 2023);
    initialize_block(block_B, seed + 2022);
    initialize_block(block_C, seed + 2021);
  }

  void run(const Options& options, const cutlass::KernelHardwareInfo& hw_info) {
    ProblemShapeType problem_size = ProblemShapeType{options.m, options.n, options.k, options.l};

    initialize(problem_size);

    typename Gemm::GemmKernel::Arguments arguments{
            cutlass::gemm::GemmUniversalMode::kGemm,
            problem_size,
            {block_A.get(), stride_A, block_B.get(), stride_B},
            {{options.alpha, options.beta}, block_C.get(), stride_C, block_D.get(), stride_D},
            hw_info
    };

    Gemm gemm_op;

    size_t workspace_size = Gemm::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    CUTLASS_CHECK(gemm_op.can_implement(arguments));

    CUTLASS_CHECK(gemm_op.initialize(arguments, workspace.get()));

    // Run the GEMM
    CUTLASS_CHECK(gemm_op.run());

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    Result result;
    result.passed = verify(problem_size, options.alpha, options.beta);

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
        CUTLASS_CHECK(gemm_op.run());
      }
      timer.stop();

      // Compute average runtime and GFLOPs.
      float elapsed_ms = timer.elapsed_millis();
      result.avg_runtime_ms = double(elapsed_ms) / double(options.iterations);
      result.gflops = options.gflops(result.avg_runtime_ms / 1000.0);

      std::cout << "  Problem Size: " << options.m << 'x' << options.n << 'x'
                << options.k << 'x' << options.l << std::endl;
      std::cout << "  Avg runtime: " << result.avg_runtime_ms << " ms" << std::endl;
      std::cout << "  GFLOPS: " << result.gflops << std::endl;
    }
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // Ampere Tensor Core operations exposed with mma.sync and ldmatrix are first available
  // in CUDA 11.0.
  //
  // CUTLASS must be compiled with CUDA 11.0 Toolkit to run these examples.
#if !defined(CUTLASS_ENABLE_SYCL)
  if (!(__CUDACC_VER_MAJOR__ >= 11)) {
    std::cerr << "Ampere Tensor Core operations must be compiled with CUDA 11.0 Toolkit or later." << std::endl;
    return 0;
  }

  cudaDeviceProp props;

  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (error != cudaSuccess) {
    std::cerr << "cudaGetDeviceProperties() returned an error: " << cudaGetErrorString(error) << std::endl;
    return -1;
  }

  if (!((props.major * 10 + props.minor) >= 80)) {
    std::cerr << "Ampere Tensor Core operations must be run on a machine with compute capability at least 80."
              << std::endl;
    return 0;
  }
#endif

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
  // Run examples
  //

  // The KernelHardwareInfo struct holds the number of SMs on the GPU with a given device ID.
  // This information is used by the underlying kernel.
  cutlass::KernelHardwareInfo hw_info;

  // Change device_id to another value if you are running on a machine with multiple GPUs and wish
  // to use a GPU other than that with device ID 0.
  hw_info.device_id = 0;
  hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  // Problem configuration
  using ElementA = float;
  using ElementB = float;
  using ElementAcc = float;
  using ElementOutput = float;

  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using LayoutD = cutlass::layout::ColumnMajor;

  // Tiling configuration selection
  using TileShape = Shape<_128,_128,_32>;

  //
  // Assembling the CollectiveMainloop type
  //

  // Number of pipelines you want to use
  constexpr int PipelineStages = 4;

  using DispatchPolicy = cutlass::gemm::MainloopSm80CpAsync<PipelineStages>;

  // This code section describes the MMA op and the tile size a warp will compute
  using TiledMma = TiledMMA<
    MMA_Atom<SM80_16x8x8_F32TF32TF32F32_TN>,
    Layout<Shape<_2,_2,_1>, Stride<_2,_1,_1>>, // 2x2x1 thread group
    Tile<_32,_32,_8>>;                         // 32x32x8 MMA for LDSM, 1x2x1 value group

  // Define the copy layout and atom for device memory copy.
  using GmemTiledCopyA = decltype(
          make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<cute::uint128_t>, float>{},
                          Layout<Shape<_16,_8>, Stride<_1,_16>>{},
                          Layout<Shape<_4,_1>>{}));

  using GmemTiledCopyB = decltype(
          make_tiled_copy(Copy_Atom<SM80_CP_ASYNC_CACHEGLOBAL<cute::uint128_t>, float>{},
                          Layout<Shape<_16,_8>, Stride<_8,_1>>{},
                          Layout<Shape<_1,_4>>{}));

  // Define the copy layout and atom for shared memory copy.
  using SmemLayoutAtomA = decltype(composition(Swizzle<2,3,2>{}, Layout<Shape <_32,_8>, Stride< _1,_32>>{}));
  using SmemCopyAtomA = Copy_Atom<UniversalCopy<float>, float>;

  using SmemLayoutAtomB = decltype(composition(Swizzle<3,2,3>{}, Layout<Shape <_8,_32>, Stride<_32, _1>>{}));
  using SmemCopyAtomB = Copy_Atom<SM75_U32x4_LDSM_N, float>;

  // Mainloop
  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
          DispatchPolicy,
          TileShape,
          ElementA,
          cutlass::detail::TagToStrideA_t<LayoutA>,
          ElementB,
          cutlass::detail::TagToStrideB_t<LayoutB>,
          TiledMma,
          GmemTiledCopyA, SmemLayoutAtomA, SmemCopyAtomA, cute::identity,  // A
          GmemTiledCopyB, SmemLayoutAtomB, SmemCopyAtomB, cute::identity   // B
  >;

  //
  // Assembling the Collective Epilogue Type
  //

  using EpilogueOp = cutlass::epilogue::thread::LinearCombination<
          ElementOutput,                                     // <- data type of output matrix
          128 / cutlass::sizeof_bits<ElementOutput>::value,  // <- the number of elements per vectorized
                                                             // memory access. For a byte, it's 16
                                                             // elements. This becomes the vector width of
                                                             // math instructions in the epilogue too
          ElementAcc,                                        // <- data type of accumulator
          ElementOutput>;  // <- data type for alpha/beta in linear combination function

  using CollectiveEpilogue = cutlass::epilogue::collective::DefaultEpilogue<
          cutlass::detail::TagToStrideC_t<LayoutC>,
          cutlass::detail::TagToStrideC_t<LayoutD>,
          EpilogueOp,
          cutlass::gemm::EpilogueDefault>;

  //
  // Assembling the GemmKernel
  //

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
          Shape<int,int,int,int>,
          CollectiveMainloop,
          CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  ExampleRunner<Gemm> runner;

  runner.run(options, hw_info);

  return 0;
}
