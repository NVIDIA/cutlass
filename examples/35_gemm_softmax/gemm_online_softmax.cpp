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
    \brief GEMM + Softmax example using Cute and CUTLASS 3.x APIs for NVIDIA Ampere architecture

    This example demonstrate how to instantiate and run a TF32 GEMM using the Cute and
    CUTLASS 3.x APIs on NVIDIA Ampere architecture. Please check example 07 and 08 for
    the basics of tensor op gemm kernels.
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
#include "softmax_epilogue.hpp"
#include "gemm_softmax_adapter.hpp"

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
  float tolerance;

  Options():
    help(false),
    m(5120), n(4096), k(4096), l(1),
    alpha(1), beta(0),
    iterations(100),
    tolerance(1e-5f)
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
    cmd.get_cmd_line_argument("tolerance", tolerance);

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
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n"
      << "  --tolerance <float>         Error tolerance\n";

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
  using StrideTmp = typename Gemm::CollectiveEpilogue::StrideD;

  using LayoutA = typename Gemm::LayoutA;
  using LayoutB = typename Gemm::LayoutB;
  using LayoutC = typename Gemm::LayoutC;
  using LayoutD = typename Gemm::LayoutD;
  using LayoutTmp = typename Gemm::LayoutTmp;

  using ElementA = typename Gemm::ElementA;
  using ElementB = typename Gemm::ElementB;
  using ElementC = typename Gemm::ElementC;
  using ElementD = typename Gemm::ElementD;
  using ElementAcc = typename Gemm::ElementAccumulator;

  using CollectiveEpilogue = typename Gemm::CollectiveEpilogue;
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
  StrideTmp stride_tmp;
  uint64_t seed = 0;

  cutlass::DeviceAllocation<ElementA> block_A;
  cutlass::DeviceAllocation<ElementB> block_B;
  cutlass::DeviceAllocation<ElementC> block_C;
  cutlass::DeviceAllocation<ElementAcc> block_max;
  cutlass::DeviceAllocation<ElementAcc> block_sum;
  cutlass::DeviceAllocation<ElementOutput> block_D;
  cutlass::DeviceAllocation<ElementOutput> block_ref_D;

  //
  // Methods
  //
  template<typename Element>
  bool verify_tensor(std::vector<Element> vector_Input, \
                       std::vector<Element> vector_Input_Ref, const Options& options) {

    auto size = int64_t((vector_Input.size() < vector_Input_Ref.size()) ? vector_Input.size() : vector_Input_Ref.size());
    float abs_tol = options.tolerance;
    float rel_tol = options.tolerance;
    
    for (int64_t i = 0; i < size; ++i) {
      float diff = (float)(vector_Input.at(i) - vector_Input_Ref.at(i));
      float abs_diff = fabs(diff);
      float abs_ref = fabs((float)vector_Input_Ref.at(i));
      float relative_diff = abs_ref > abs_tol ? abs_diff / abs_ref : 0;
      if ( (isnan(abs_diff) || isinf(abs_diff)) ||  (abs_diff > abs_tol && relative_diff > rel_tol)) {
        printf("i = %d diff = %f, {%f, %f}.\n", i, abs_diff, (float)(vector_Input.at(i)), (float)(vector_Input_Ref.at(i)));
        return false;
      }

    }

    return true;
  }

  /// Verifies the reference matches
  bool verify(const Options& options) {
    using ElementSoftmax = ElementD;

    cutlass::gemm::GemmCoord problem_size = cutlass::gemm::GemmCoord{options.m, options.n, options.k};

    int64_t total_elements_A_per_batch = options.m * options.k;
    int64_t total_elements_B_per_batch = options.k * options.n;
    int64_t total_elements_C_per_batch = options.m * options.n;
    int64_t total_elements_D_per_batch = total_elements_C_per_batch;

    int64_t lda = LayoutA::packed({options.m, options.k}).stride(0);
    int64_t ldb = LayoutB::packed({options.k, options.n}).stride(0);
    int64_t ldc = LayoutC::packed({options.m, options.n}).stride(0);

    int64_t ldn = options.m;
    int64_t lds = ldn;

    LayoutA layout_A(lda);
    LayoutB layout_B(ldb);
    LayoutC layout_C(ldc);
    LayoutTmp Layout_N(ldn);
    LayoutTmp Layout_S(lds);

    cutlass::MatrixCoord extent_A{options.m, options.k};
    cutlass::MatrixCoord extent_B{options.k, options.n};
    cutlass::MatrixCoord extent_C{options.m, options.n};
    
    cutlass::HostTensor<ElementSoftmax, LayoutC>     reference_N;
    reference_N.reset({options.m, 1}, false);

    for (int batch_idx = 0; batch_idx < options.l; batch_idx++) {
      cutlass::TensorView<ElementA, LayoutA> view_A(block_A.get() + total_elements_A_per_batch * batch_idx, layout_A, extent_A);
      cutlass::TensorView<ElementB, LayoutB> view_B(block_B.get() + total_elements_B_per_batch * batch_idx, layout_B, extent_B);
      cutlass::TensorView<ElementC, LayoutC> view_C(block_C.get() + total_elements_C_per_batch * batch_idx, layout_C, extent_C);
      cutlass::TensorView<ElementC, LayoutC> view_Ref_device(block_ref_D.get(), layout_C, extent_C);

      cutlass::reference::device::GemmComplex<
          ElementA, LayoutA,
          ElementB, LayoutB,
          ElementC, LayoutC, 
          ElementCompute, ElementCompute, ElementD
      >(
        problem_size,
        options.alpha, 
        view_A,
        cutlass::ComplexTransform::kNone,
        view_B,
        cutlass::ComplexTransform::kNone,
        options.beta, 
        view_C, 
        view_Ref_device, 
        ElementCompute(0)
      );

      // Copy reference results to host memory for verification
      std::vector<ElementD> matrix_D_Ref(layout_C.capacity(extent_C));
      cutlass::device_memory::copy_to_host(matrix_D_Ref.data(), block_ref_D.get(), matrix_D_Ref.size());
      cutlass::TensorView<ElementD, LayoutC> view_D_Ref(matrix_D_Ref.data(), layout_C, extent_C);

      std::vector<ElementSoftmax> matrix_Softmax_Ref(layout_C.capacity(extent_C));
      cutlass::TensorView<ElementSoftmax, LayoutC> view_Softmax_Ref(matrix_Softmax_Ref.data(), layout_C, extent_C);

      // Copy computed results to host memory
      std::vector<ElementD> matrix_D(layout_C.capacity(extent_C));
      cutlass::device_memory::copy_to_host(matrix_D.data(), block_D.get() + total_elements_D_per_batch * batch_idx, matrix_D.size());

      // Compute the norm
      for (int m = 0; m < options.m; ++m) {
        reference_N.at({m, 0}) = view_D_Ref.ref().at({m, 0});
        for (int n = 1; n < options.n; ++n) {
          reference_N.at({m, 0}) = std::max(reference_N.at({m, 0}), ElementSoftmax(view_D_Ref.ref().at({m, n})));
        }
        /*if(m == 3516 && batch_idx == 0){
          std:: cout << "max0: " << reference_N.at({m, 0}) << std::endl;
        }*/
      }

      // Compute softmax
      for (int m = 0; m < options.m; ++m) {
        float sum = 0;
        for (int n = 0; n < options.n; ++n) {
          sum += std::exp( float(view_D_Ref.ref().at({m, n})) - float(reference_N.at({m, 0})) );
        }
        
        /*if(m == 3516 && batch_idx == 0){
          std:: cout << "sum0: " << sum << std::endl;
        }*/

        float inv_sum = float(1.0f / sum);

        for (int n = 0; n < options.n; ++n) {
          view_Softmax_Ref.ref().at({m, n}) = ElementSoftmax(
            std::exp( float(view_D_Ref.ref().at({m, n})) - float(reference_N.at({m, 0})) ) * inv_sum
          );
        }
      }

      bool verified_Softmax = verify_tensor<ElementSoftmax>(matrix_D, matrix_Softmax_Ref, options);
      if (!verified_Softmax) {
        std::cerr << "Verification of Softmax tensor failed\n";
        return false;
      }
    }
    return true;
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(const ProblemShapeType& problem_size) {
    auto problem_shape_MNKL = cute::append<4>(problem_size, 1);
    auto [M, N, K, L] = problem_shape_MNKL;

    auto partials_N = cute::ceil_div(N, cute::shape<1>(typename Gemm::TileShape{}));
    auto tmp_size = M * partials_N * L;

    stride_A = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(M, K, L));
    stride_B = cutlass::make_cute_packed_stride(StrideB{}, cute::make_shape(N, K, L));
    stride_C = cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(M, N, L));
    stride_D = cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(M, N, L));
    stride_tmp = cutlass::make_cute_packed_stride(StrideTmp{}, cute::make_shape(M, partials_N, L));

    block_A.reset(M * K * L);
    block_B.reset(K * N * L);
    block_C.reset(M * N * L);
    block_D.reset(M * N * L);
    block_ref_D.reset(M * N * L);
    block_sum.reset(tmp_size);
    block_max.reset(tmp_size);

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
            {{options.alpha,//static_cast<ElementOutput>(options.alpha), 
             options.beta},//static_cast<ElementOutput>(options.beta)}, 
             block_C.get(), stride_C, 
             block_D.get(), stride_D, 
             block_max.get(), block_sum.get(), stride_tmp},
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
    result.passed = verify(options);

    std::cout << "  Disposition: " << (result.passed ? "Passed" : "Failed") << std::endl;

    if (!result.passed) {
      //exit(-1);
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
  /*using ElementA = cutlass::half_t;
  using ElementB = cutlass::half_t;
  using ElementAcc = float;
  using ElementOutput = cutlass::half_t;*/
  using ElementA = float;
  using ElementB = float;
  using ElementAcc = float;
  using ElementOutput = float;

  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using LayoutD = cutlass::layout::ColumnMajor;
  using LayoutTmp = cutlass::layout::ColumnMajor;

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
          ElementAcc>;  // <- data type for alpha/beta in linear combination function

  using CollectiveEpilogue = cutlass::epilogue::collective::SoftmaxEpilogue<
          cutlass::detail::TagToStrideC_t<LayoutC>,
          cutlass::detail::TagToStrideC_t<LayoutD>,
          cutlass::detail::TagToStrideC_t<LayoutTmp>,
          TileShape,
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

  using Gemm = cutlass::gemm::device::GemmSoftmaxAdapter<GemmKernel>;

  ExampleRunner<Gemm> runner;
  runner.run(options, hw_info);

  return 0;
}
