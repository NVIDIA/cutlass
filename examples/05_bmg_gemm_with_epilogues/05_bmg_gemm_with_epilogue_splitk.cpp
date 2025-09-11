/***************************************************************************************************
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
- * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/

#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/collective/xe_epilogue.hpp"
#include "cutlass/epilogue/fusion/xe_callbacks.hpp"
#include "cutlass/gemm/device/gemm_universal.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/util/GPU_Clock.hpp"

#include <cute/tensor.hpp>
#include <random>

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"

#include "sycl_common.hpp"
#include "helper.h"

using namespace cute;
///////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help;
  bool error;

  int m, n, k, l, num_head, nope_dim, rope_dim, iterations;
  float alpha, beta;

  Options():
    help(false),
    error(false),
    m(5120), n(4096), k(4096), l(1),
    num_head(128), nope_dim(128), rope_dim(64),
    iterations(100), alpha(1.f), beta(0.f)
  { }

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("m", m, 512);
    cmd.get_cmd_line_argument("n", n, 24576);
    cmd.get_cmd_line_argument("k", k, 1536);
    cmd.get_cmd_line_argument("l", l, 1);
    cmd.get_cmd_line_argument("num-head", num_head, 128);
    cmd.get_cmd_line_argument("nope-dim", nope_dim, 128);
    cmd.get_cmd_line_argument("rope-dim", rope_dim, 64);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("iterations", iterations, 100);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "PVC GEMM Example\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --l=<int>                   Sets the L extent (batch count) of the GEMM\n"
      << "  --num-head=<int>            Sets the num_head for splitk fusion\n"
      << "  --nope-dim=<int>            Sets the nope_dim for splitk fusion\n"
      << "  --rope-dim=<int>            Sets the rope_dim for splitk fusion\n"
      << "  --alpha=<s32>               Epilogue scalar alpha\n"
      << "  --beta=<s32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Iterations\n\n";

    return out;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

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
  cutlass::DeviceAllocation<ElementOutput> block_D1;
  cutlass::DeviceAllocation<ElementOutput> block_D2;
  cutlass::DeviceAllocation<ElementOutput> block_ref_D;

  //
  // Methods
  //

  template <typename Element>
  static void print_error(int b, int i, int j, int k, Element expect, Element val) {
    std::cout << "(" << b << ", " << i << ", " << j << ", " << k
        << "): " << "host: " << expect
        << "   and device: " << val << std::endl;
  }

  template <typename Element>
  static void print_error(int b, int i, int j, Element expect, Element val) {
    std::cout << "(" << b << ", " << i << ", " << j
              << "): " << "host: " << expect << "   and device: " << val
              << std::endl;
  }


  bool verify(const ProblemShapeType& problem_size, const ProblemShapeType &splitk_size, ElementCompute alpha, ElementCompute beta) {
    auto [M, N, K, L] = problem_size;
    auto [NUM_HEAD, NOPE_DIM, ROPE_DIM, _] = splitk_size;
    cutlass::TensorRef ref_A(block_A.get(), LayoutA::packed({M, K}));
    cutlass::TensorRef ref_B(block_B.get(), LayoutB::packed({K, N}));
    cutlass::TensorRef ref_C(block_C.get(), LayoutC::packed({M, N}));
    cutlass::TensorRef ref_D(block_ref_D.get(), LayoutD::packed({M, N}));

    cutlass::reference::device::GemmComplex(
          {M, N, K},
          alpha,
          ref_A,
          cutlass::ComplexTransform::kNone,
          ref_B,
          cutlass::ComplexTransform::kNone,
          beta,
          ref_C,
          ref_D,
          ElementAccumulator(0),
          L,     // batch_count
          M * K, // batch_stride_A
          K * N, // batch_stride_B
          M * N, // batch_stride_C
          M * N  // batch_stride_D
        );

    syclcompat::wait();

    auto D_shape = make_shape(M, N, L);
    auto D1_shape = make_shape(M, NUM_HEAD, NOPE_DIM, L);
    auto D2_shape = make_shape(M, NUM_HEAD, ROPE_DIM, L);

    auto D = std::vector<ElementOutput>(size(D_shape));
    // 256x128x64
    auto D1 = std::vector<ElementOutput>(size(D1_shape));
    // 256x128x128
    auto D2 = std::vector<ElementOutput>(size(D2_shape));
    syclcompat::memcpy<ElementOutput>(D.data(), block_ref_D.get(), size(D_shape));
    syclcompat::wait();

    for (int l = 0; l < L; l++) {
      for (int i = 0; i < M; i++) {
        for (int j = 0; j < NUM_HEAD; j++) {
          for (int k = 0; k < NOPE_DIM + ROPE_DIM; ++k) {
            if (k < NOPE_DIM) {
              D1[l * M * NUM_HEAD * NOPE_DIM + i * NUM_HEAD * NOPE_DIM + j * NOPE_DIM + k] =
                  D[l * M * N + i * N + j * (NOPE_DIM + ROPE_DIM) + k];
            } else {
              D2[l * M * NUM_HEAD * ROPE_DIM + i * NUM_HEAD * ROPE_DIM + j * ROPE_DIM + k - NOPE_DIM] =
                  D[l * M * N + i * N + j * (NOPE_DIM + ROPE_DIM) + k];
            }
          }
        }
      }
    }

    auto test_D = std::vector<ElementOutput>(size(D_shape));
    syclcompat::memcpy<ElementOutput>(test_D.data(), block_D.get(), size(D_shape));

    // 256x128x64
    auto test_D1 = std::vector<ElementOutput>(size(D1_shape));
    // 256x128x128
    auto test_D2 = std::vector<ElementOutput>(size(D2_shape));
    syclcompat::memcpy<ElementOutput>(test_D1.data(), block_D1.get(), size(D1_shape));
    syclcompat::memcpy<ElementOutput>(test_D2.data(), block_D2.get(), size(D2_shape));
    syclcompat::wait();

    uint32_t err_cnt = 0;
    constexpr float atol = 1e-4;
    constexpr float rtol = 1e-4;

    // check d1
    for (int b = 0; b < L; b++) {
      for (int i = 0; i < M; i++) {
        for (int j = 0; j < NUM_HEAD; j++) {
          for (int k = 0; k < NOPE_DIM; ++k) {
            int idx = b * M * NUM_HEAD * NOPE_DIM + i * NUM_HEAD * NOPE_DIM + j * NOPE_DIM + k;
            auto expect = D1[idx];
            auto val = test_D1[idx];
            if (not (std::isinf(val) || std::isnan(val))) {
              if (not is_close(val, expect, atol, rtol)) {
                print_error(b, i, j, k, expect, val);
                err_cnt++;
              }
            } else {
              print_error(b, i, j, expect, val);
              err_cnt++;
            }
          }
        }
      }
    }
    // check d2
    for (int b = 0; b < L; b++) {
      for (int i = 0; i < M; i++) {
        for (int j = 0; j < NUM_HEAD; j++) {
          for (int k = 0; k < ROPE_DIM; ++k) {
            int idx = b * M * NUM_HEAD * ROPE_DIM + i * NUM_HEAD * ROPE_DIM + j * ROPE_DIM + k;
            auto expect = D2[idx];
            auto val = test_D2[idx];
            if (not (std::isinf(val) || std::isnan(val))) {
              if (not is_close(val, expect, atol, rtol)) {
                print_error(b, i, j, k, expect, val);
                err_cnt++;
              }
            } else {
              print_error(b, i, j, expect, val);
              err_cnt++;
            }
          }
        }
      }
    }

    std::cout << "err count: " << err_cnt
              << ", pass rate: " << 100 - (100 * err_cnt / (M * N * L)) << "%"
              << std::endl;
    return err_cnt == 0;
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(const ProblemShapeType& problem_size, const ProblemShapeType &splitk_size) {
    auto problem_shape_MNKL = cute::append<4>(problem_size, 1);
    auto [M, N, K, L] = problem_shape_MNKL;
    auto [NUM_HEAD, NOPE_DIM, ROPE_DIM, _] = splitk_size;
    assert((NOPE_DIM % 32 == 0) && (NOPE_DIM / 32>0) && "NOPE_DIM should be divisible by 32");
    assert((ROPE_DIM % 32 == 0) && (ROPE_DIM / 32>0) && "ROPE_DIM should be divisible by 32");
    stride_A = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(M, K, L));
    stride_B = cutlass::make_cute_packed_stride(StrideB{}, cute::make_shape(N, K, L));
    stride_C = cutlass::make_cute_packed_stride(StrideC{}, cute::make_shape(M, N, L));
    stride_D = cutlass::make_cute_packed_stride(StrideD{}, cute::make_shape(M, N, L));

    block_A.reset(M * K * L);
    block_B.reset(K * N * L);
    block_C.reset(M * N * L);
    block_D.reset(M * N * L);
    block_D1.reset(M * NUM_HEAD * NOPE_DIM * L);
    block_D2.reset(M * NUM_HEAD * ROPE_DIM * L);
    block_ref_D.reset(M * N * L);

    initialize_block(block_A, seed + 2023, -1.0, 1.0);
    initialize_block(block_B, seed + 2022, -1.0, 1.0);
    initialize_block(block_C, seed + 2021, -1.0, 1.0);
  }

  cutlass::Status run(const Options& options, const cutlass::KernelHardwareInfo& hw_info) {
    ProblemShapeType problem_size = ProblemShapeType{options.m, options.n, options.k, options.l};
    ProblemShapeType splitk_size = ProblemShapeType{options.num_head, options.nope_dim, options.rope_dim, 1};

    initialize(problem_size, splitk_size);
    using EpilogueArguments = typename Gemm::GemmKernel::EpilogueArguments;
    EpilogueArguments epilogue_arguments{
      {options.alpha, options.beta}, block_C.get(), stride_C, block_D.get(), stride_D};
    epilogue_arguments.thread.output_ptr = block_D.get();
    epilogue_arguments.thread.output_ptr1 = block_D1.get();
    epilogue_arguments.thread.output_ptr2 = block_D2.get();
    epilogue_arguments.thread.NUM_HEAD = options.num_head;
    epilogue_arguments.thread.NOPE_DIM = options.nope_dim;
    epilogue_arguments.thread.ROPE_DIM = options.rope_dim;

    typename Gemm::GemmKernel::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      problem_size,
      {block_A.get(), stride_A, block_B.get(), stride_B},
      epilogue_arguments,
      hw_info
    };

    Gemm gemm_op;

    size_t workspace_size = Gemm::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    gemm_op.can_implement(arguments);

    gemm_op.initialize(arguments, workspace.get());

    // Run the GEMM
    gemm_op.run();

    syclcompat::wait();

    // Verify that the result is correct
    bool passed = verify(problem_size, splitk_size, options.alpha, options.beta);
    std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;
    if (!passed) return cutlass::Status::kErrorInternal;

    if (passed && options.iterations > 0) {
      GPU_Clock timer;
      timer.start();
      for (int i = 0; i < options.iterations; ++i) {
        gemm_op.run();
      }
      float cute_time = timer.seconds() / options.iterations;
      double io =
        options.l *
        (options.m * options.k * sizeof(ElementA) + options.k * options.n * sizeof(ElementB) +
         options.m * options.n * sizeof(ElementOutput)) *
        1e-9;
      double tflops = 2.0 * options.m * options.n * options.k * options.l * 1e-12;
      std::cout << "Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l << std::endl;
      printf("Cutlass GEMM Performance:     [%4.3f]GB/s,   [%4.3f]TF/s, [%6.4f]ms\n", io / cute_time, tflops/cute_time,  cute_time*1000);
    }

    return cutlass::Status::kSuccess;
  }

};

int main(int argc, const char** argv)
{
  //
  // Parse options
  //

  Options options;

  options.parse(argc, argv);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  if (options.error) {
    std::cerr << "Aborting execution." << std::endl;
    return -1;
  }

  //
  // Run examples
  //

  // The KernelHardwareInfo struct holds the number of EUs on the GPU with a given device ID. This
  // information is used by the underlying kernel.
  cutlass::KernelHardwareInfo hw_info;

  // Change device_id to another value if you are running on a machine with multiple GPUs and wish
  // to use a GPU other than that with device ID 0.
  hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  bool passed;

  // The code section below describes datatype for input, output matrices and computation between
  // elements in input matrices.
  using ElementAccumulator = float;                   // <- data type of accumulator
  using ElementComputeEpilogue = float;  // <- data type of epilogue operations
  using ElementInputA = bfloat16_t;                        // <- data type of elements in input matrix A
  using ElementInputB = bfloat16_t;                        // <- data type of elements in input matrix B
  using ElementOutput = float;                        // <- data type of elements in output matrix D

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using GmemTiledCopyA = XE_2D_U16x8x16_LD_N;
  using GmemTiledCopyB = XE_2D_U16x16x16_LD_V;

  // Workgroup-level tile
  using TileShape = Shape<_32, _512, _32>;

  using TiledMma =
      typename TiledMMAHelper<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, Layout<TileShape>,
                                    Layout<Shape<_2, _16, _1>, Stride<_16, _1, _0>>>::TiledMMA;

  using EpilogueTile = Shape<_16, _32>;
  constexpr int PipelineStages = 3;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

  using EpilogueOp = cutlass::epilogue::fusion::LinCombSplitK<ElementOutput,
          ElementComputeEpilogue, XE_2D_U32x8x16_ST_N, ElementAccumulator, ElementAccumulator, cutlass::FloatRoundStyle::round_to_nearest>;

  using FusionCallBacks = cutlass::epilogue::fusion::FusionCallbacks<EpilogueDispatchPolicy, EpilogueOp, TileShape,
          EpilogueTile>;
  using CollectiveEpilogue = cutlass::epilogue::collective::CollectiveEpilogue<
          EpilogueDispatchPolicy,
          TileShape,
          ElementAccumulator,
          cutlass::gemm::TagToStrideC_t<LayoutC>,
          ElementOutput,
          cutlass::gemm::TagToStrideC_t<LayoutD>,
          FusionCallBacks,
          XE_2D_U32x8x16_LD_N,
          void, void,
          void,
          void, void>;

// Mainloop
  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
          GEMMDispatchPolicy,
          TileShape,
          ElementInputA,
          cutlass::gemm::TagToStrideA_t<LayoutA>,
          ElementInputB,
          cutlass::gemm::TagToStrideB_t<LayoutB>,
          TiledMma,
          GmemTiledCopyA, void, void, cute::identity,  // A
          GmemTiledCopyB, void, void, cute::identity   // B
  >;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
  Shape<int, int, int, int>,
  CollectiveMainloop,
  CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;

  ExampleRunner<Gemm> runner;

  CUTLASS_CHECK(runner.run(options, hw_info));

  return 0;
}
