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
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/

#include "cutlass/gemm/device/gemm.h"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/gemm/device/gemm_universal.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/util/GPU_Clock.hpp"

#include "cutlass/util/host_tensor.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cute/tensor.hpp"

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "cutlass/util/print_error.hpp"

template <typename T>
static void fill_matrix(std::vector<T> &M)
{
  std::generate(std::begin(M), std::end(M), [&]
  { return static_cast<T>( (rand() / double(RAND_MAX)) ); });
}

using namespace cute;

///////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

    bool help;
    bool error;

    int m, n, k, l, iterations;
    float alpha, beta;

    Options():
            help(false),
            error(false),
            m(4096), n(4096), k(4096), l(1), iterations(100),
            alpha(1.f), beta(0.f)
    { }

    // Parses the command line
    void parse(int argc, char const **args) {
      cutlass::CommandLine cmd(argc, args);

      if (cmd.check_cmd_line_flag("help")) {
        help = true;
        return;
      }

      cmd.get_cmd_line_argument("m", m, 4096);
      cmd.get_cmd_line_argument("n", n, 4096);
      cmd.get_cmd_line_argument("k", k, 4096);
      cmd.get_cmd_line_argument("l", l, 1);
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
          << "  --alpha=<s32>               Epilogue scalar alpha\n"
          << "  --beta=<s32>                Epilogue scalar beta\n\n"
          << "  --iterations=<int>          Iterations\n\n";

      return out;
    }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <class Gemm>
struct BenchmarkRunner {

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

    cutlass::DeviceAllocation<ElementA> block_A;
    cutlass::DeviceAllocation<ElementB> block_B;
    cutlass::DeviceAllocation<ElementC> block_C;
    cutlass::DeviceAllocation<ElementOutput> block_D;
    cutlass::DeviceAllocation<ElementOutput> block_ref_D;

    //
    // Methods
    //

    bool verify(const ProblemShapeType& problem_size, ElementCompute alpha, ElementCompute beta) {
      auto [M, N, K, L] = problem_size;

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

#if defined(CUTLASS_ENABLE_SYCL)
      syclcompat::wait();
#else
      cudaDeviceSynchronize();
#endif

      // Check if output from CUTLASS kernel and reference kernel are relatively equal or not
      // need to set a larger error margin for comparison to succeed
      auto epsilon = static_cast<ElementOutput>(0.1f);
      auto nonzero_floor = static_cast<ElementOutput>(0.1f);

      bool passed = cutlass::reference::device::BlockCompareRelativelyEqual(
              block_ref_D.get(), block_D.get(), block_D.size(),
              epsilon, nonzero_floor);

      return passed;
    }

    /// Initialize operands to be used in the GEMM and reference GEMM
    virtual void initialize(const ProblemShapeType& problem_size) {
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

      // TODO: Enable initialization on device directly once RNG is
      // available through SYCL.
      std::vector<ElementA> a(K * M * L);
      std::vector<ElementB> b(K * N * L);
      std::vector<ElementC> c(M * N * L);
      std::vector<ElementC> d(M * N * L, ElementC{-1});
      std::vector<ElementC> ref_d(M * N * L, ElementC{-2});

      fill_matrix(a);
      fill_matrix(b);
      fill_matrix(c);

      block_A.copy_from_host(a.data(), a.size());
      block_B.copy_from_host(b.data(), b.size());
      block_C.copy_from_host(c.data(), c.size());
      block_D.copy_from_host(d.data(), d.size());
      block_ref_D.copy_from_host(ref_d.data(), d.size());
    }

    virtual void run(const Options& options, const cutlass::KernelHardwareInfo& hw_info) {
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

      gemm_op.can_implement(arguments);

      gemm_op.initialize(arguments, workspace.get());

      // Run the GEMM
      gemm_op.run();

#if defined(CUTLASS_ENABLE_SYCL)
      syclcompat::wait();
#else
      cudaDeviceSynchronize();
#endif

      // Verify that the result is correct
      bool passed = verify(problem_size, options.alpha, options.beta);
      std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;

      if (passed && options.iterations > 0) {
        GPU_Clock timer;
        timer.start();
        for (int i = 0; i < options.iterations; ++i) {
          gemm_op.run();
        }

        float cute_time = timer.seconds() / options.iterations;
        double tflops = (2.0 * options.m * options.n * options.k * options.l) * 1e-12;
        std::cout << "Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l
                  << std::endl;
        printf("Cutlass GEMM Performance:     [%4.3f]TFlop/s  (%6.4f)ms\n", tflops / cute_time, cute_time * 1000);
      }
    }
};

template <class Gemm>
struct PvcBenchmarkRunner : BenchmarkRunner<Gemm> {
    using Base = BenchmarkRunner<Gemm>;

    using ElementB = typename Base::ElementB;

    using ProblemShapeType = typename Base::ProblemShapeType;

    cutlass::DeviceAllocation<ElementB> block_B_vnni;

    template <typename T>
    void vnni_matrix(
            T* dst, const T* src,
            int batch, int numRows, int numCols, int factor)
    {
      for (int b = 0; b < batch; b++) {
        for (int r = 0; r < numRows / factor; r++) {
          for (int c = 0; c < numCols; c++) {
            for (int k = 0; k < factor; k++) {
              dst[((b * (numRows / factor) + r) * numCols + c) * factor + k] =
                      src[((b * (numRows / factor) + r) * factor + k) * numCols + c];
            }
          }
        }
      }
    }

    void initialize(const ProblemShapeType& problem_size) override {
      Base::initialize(problem_size);

      auto problem_shape_MNKL = cute::append<4>(problem_size, 1);
      auto [M, N, K, L] = problem_shape_MNKL;

      block_B_vnni.reset(Base::block_B.size());

      std::vector<ElementB> b(K * N * L);
      std::vector<ElementB> b_vnni(b.size());

      Base::block_B.copy_to_host(b.data());
      vnni_matrix(b_vnni.data(), b.data(), L, K, N, 2);

      block_B_vnni.copy_from_host(b_vnni.data());
    }

    void run(const Options& options, const cutlass::KernelHardwareInfo& hw_info) override {
      ProblemShapeType problem_size = ProblemShapeType{options.m, options.n, options.k, options.l};

      initialize(problem_size);

      typename Gemm::GemmKernel::Arguments arguments{
              cutlass::gemm::GemmUniversalMode::kGemm,
              problem_size,
              {Base::block_A.get(), Base::stride_A, block_B_vnni.get(), Base::stride_B},
              {
                {options.alpha, options.beta},
                Base::block_C.get(), Base::stride_C, Base::block_D.get(), Base::stride_D
              },
              hw_info
      };

      Gemm gemm_op;

      size_t workspace_size = Gemm::get_workspace_size(arguments);
      cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

      gemm_op.can_implement(arguments);

      gemm_op.initialize(arguments, workspace.get());

      // Run the GEMM
      gemm_op.run();

#if defined(CUTLASS_ENABLE_SYCL)
      syclcompat::wait();
#else
      cudaDeviceSynchronize();
#endif

      // Verify that the result is correct
      bool passed = Base::verify(problem_size, options.alpha, options.beta);
      std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;

      if (passed && options.iterations > 0) {
        GPU_Clock timer;
        timer.start();
        for (int i = 0; i < options.iterations; ++i) {
          gemm_op.run();
        }

        float cute_time = timer.seconds() / options.iterations;
        double tflops = (2.0 * options.m * options.n * options.k * options.l) * 1e-12;
        std::cout << "Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l << std::endl;
        printf("Cutlass GEMM Performance:     [%4.3f]TFlop/s  (%6.4f)ms\n", tflops / cute_time, cute_time*1000);
      }
    }
};

