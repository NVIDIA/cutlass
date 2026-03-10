/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief An FP8 blockwise scaled GEMM example for the NVIDIA Ada SM89 architecture using CUTLASS.
*/


#include "cutlass/arch/arch.h"
#include "cutlass/cutlass.h"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/device/gemm_blockwise.h"
#include "cutlass/gemm/threadblock/mma_multistage_blockwise.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/numeric_types.h"
#include "cutlass/tensor_ref.h"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/reference/host/gemm.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/tensor_norm.h"
#include "helper.h"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cuda_runtime.h>
#include <iostream>
#include <random>
#include <vector>
#include "cutlass/util/command_line.h"

using cutlass::ceil_div;

using ElementA = cutlass::float_e4m3_t;
using ElementB = cutlass::float_e4m3_t;
using ElementOutput = cutlass::bfloat16_t;
using ElementAccumulator = float;
using ElementScale = float;

using LayoutA = cutlass::layout::RowMajor;
using LayoutB = cutlass::layout::ColumnMajor;
using LayoutC = cutlass::layout::RowMajor; // Currently only RowMajor is supported
using LayoutScale = cutlass::layout::RowMajor; // Currently only RowMajor is supported

static int const AlignmentA = 16;
static int const AlignmentB = 16;
static int const Stages = 3;
static int const BlockSize = 128;

constexpr float epsilon = 0.51f;
constexpr float floor_val = 1.0f;

// -----------------------------------------------------------------------------
// Command line options structure
// -----------------------------------------------------------------------------
struct Options {
  bool help = false;
  int m = 1024;
  int n = 1024;
  int k = 1024;
  float alpha = 1.f;
  float beta  = 0.f;
  bool verify = true;
  int iterations = 1000;
  int warmup = 1000;

  // Parse command line arguments using CUTLASS helper
  void parse(int argc, char const **argv) {
    cutlass::CommandLine cmd(argc, argv);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("m", m);
    cmd.get_cmd_line_argument("n", n);
    cmd.get_cmd_line_argument("k", k);
    cmd.get_cmd_line_argument("alpha", alpha, alpha);
    cmd.get_cmd_line_argument("beta",  beta, beta);
    cmd.get_cmd_line_argument("verify", verify);
    cmd.get_cmd_line_argument("iterations", iterations);
    cmd.get_cmd_line_argument("warmup", warmup);
  }

  std::ostream &print_usage(std::ostream &out) const {
    out << "94_ada_fp8_blockwise\n\n"
        << "  FP8 GEMM with blockwise scaling (Ada, Sm89).\n\n"
        << "Options:\n\n"
        << "  --help                 Display this help string\n"
        << "  --m=<int>              GEMM M dimension (default 1024)\n"
        << "  --n=<int>              GEMM N dimension (default 1024)\n"
        << "  --k=<int>              GEMM K dimension (default 1024)\n"
        << "  --alpha=<f32>          Epilogue alpha (default 1.0)\n"
        << "  --beta=<f32>           Epilogue beta  (default 0.0)\n"
        << "  --verify=<bool>        Verify the results (default true)\n"
        << "  --iterations=<int>     Number of timing iterations (default 1000)\n"
        << "  --warmup=<int>         Number of warmup iterations (default 1000)\n";
    return out;
  }

  double gflops(double runtime_s) const {
    uint64_t flop = uint64_t(2) * m * n * k;
    double gflop = double(flop) / double(1.0e9);
    return gflop / runtime_s;
  }
};

using EpilogueOutputOp = cutlass::epilogue::thread::LinearCombination<
    ElementOutput, 8, ElementAccumulator, ElementAccumulator>;

using Gemm = cutlass::gemm::device::GemmBlockwise<
    ElementA, LayoutA, ElementB, LayoutB, ElementOutput, LayoutC,
    ElementAccumulator, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm89,
    cutlass::gemm::GemmShape<64, 128, 128>,
    cutlass::gemm::GemmShape<64, 64, 128>, cutlass::gemm::GemmShape<16, 8, 32>,
    ElementScale, LayoutScale, BlockSize, EpilogueOutputOp,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>, Stages,
    AlignmentA, AlignmentB, false, cutlass::arch::OpMultiplyAdd>;

// Host-side verification
static bool verify_gemm(int M, int N, int K, ElementA const *A,
                        ElementB const *B, ElementOutput const *C,
                        ElementOutput const *D, ElementScale const *scale_A,
                        ElementScale const *scale_B, float alpha, float beta) {
  std::vector<ElementA> A_fp8_host(M * K);
  std::vector<ElementB> B_fp8_host(K * N);
  std::vector<ElementOutput> C_bf16_host(M * N);
  std::vector<ElementOutput> D_bf16_host(M * N);

  int kBlocks = ceil_div(K, BlockSize);
  int mBlocks = ceil_div(M, BlockSize);
  int nBlocks = ceil_div(N, BlockSize);

  std::vector<float> ScaleA(mBlocks * kBlocks);
  std::vector<float> ScaleB(nBlocks * kBlocks);

  CUDA_CHECK(
    cudaMemcpy(A_fp8_host.data(), A,
               sizeof(ElementA) * A_fp8_host.size(),
               cudaMemcpyDeviceToHost));

  CUDA_CHECK(
    cudaMemcpy(B_fp8_host.data(), B,
               sizeof(ElementB) * B_fp8_host.size(),
               cudaMemcpyDeviceToHost));

  CUDA_CHECK(
    cudaMemcpy(C_bf16_host.data(), C,
               sizeof(ElementOutput) * C_bf16_host.size(),
               cudaMemcpyDeviceToHost));

  CUDA_CHECK(
    cudaMemcpy(D_bf16_host.data(), D,
               sizeof(ElementOutput) * D_bf16_host.size(),
               cudaMemcpyDeviceToHost));

  CUDA_CHECK(
    cudaMemcpy(ScaleA.data(), scale_A,
               sizeof(ElementScale) * ScaleA.size(),
               cudaMemcpyDeviceToHost));

  CUDA_CHECK(
    cudaMemcpy(ScaleB.data(), scale_B,
               sizeof(ElementScale) * ScaleB.size(),
               cudaMemcpyDeviceToHost));

  // --------------------------------------------------------------------
  // De-quantize A and B into FP32 using blockwise scales
  // --------------------------------------------------------------------
  std::vector<float> A_f32(M * K);
  for (int m = 0; m < M; ++m) {
    int blk_m = m / BlockSize;
    for (int k = 0; k < K; ++k) {
      int blk_k = k / BlockSize;
      float sA = ScaleA[blk_m * kBlocks + blk_k];
      A_f32[m * K + k] = static_cast<float>(A_fp8_host[m * K + k]) * sA;
    }
  }

  std::vector<float> B_f32(K * N);
  for (int n = 0; n < N; ++n) {
    int blk_n = n / BlockSize;
    for (int k = 0; k < K; ++k) {
      int blk_k = k / BlockSize;
      float sB = ScaleB[blk_n * kBlocks + blk_k];
      B_f32[k + n * K] = static_cast<float>(B_fp8_host[k + n * K]) * sB;
    }
  }

  // --------------------------------------------------------------------
  // Prepare tensor refs and run reference GEMM
  // --------------------------------------------------------------------
  cutlass::TensorRef<float, LayoutA> A_ref(A_f32.data(), K);
  cutlass::TensorRef<float, LayoutB> B_ref(B_f32.data(), K);

  // Convert C (BF16) to FP32 once
  std::vector<float> C_f32(M * N);
  cutlass::NumericConverter<float, ElementOutput> bf16_to_f32;
  std::transform(C_bf16_host.begin(), C_bf16_host.end(), C_f32.begin(),
                 [&](ElementOutput x) { return bf16_to_f32(x); });
  cutlass::TensorRef<float, LayoutC> C_ref(C_f32.data(), N);

  // Output buffer in FP32 (will later hold ReLU result)
  std::vector<float> D_ref_f32(M * N, 0.0f);
  cutlass::TensorRef<float, LayoutC> D_ref_tensor(D_ref_f32.data(), N);

  cutlass::gemm::GemmCoord problem{M, N, K};

  cutlass::reference::host::Gemm<float, LayoutA, float, LayoutB, float,
                                 LayoutC, float, float,
                                 cutlass::arch::OpMultiplyAdd>
      gemm_ref;

  gemm_ref(problem, alpha, A_ref, B_ref,
           beta, C_ref, D_ref_tensor, 0.0f);

  // Build tensor views for relative comparison
  cutlass::TensorView<float, LayoutC> ref_view(D_ref_f32.data(), LayoutC(N), {M, N});

  // Convert device output (BF16) to float for comparison
  std::vector<float> kernel_output(M * N);
  cutlass::TensorView<float, LayoutC> kernel_output_view(kernel_output.data(), LayoutC(N), {M, N});
  cutlass::TensorView<ElementOutput, LayoutC> d_bf16_view(D_bf16_host.data(), LayoutC(N), {M, N});
  cutlass::reference::host::TensorCopy(kernel_output_view, d_bf16_view);

  bool result = cutlass::reference::host::TensorRelativelyEquals(
      ref_view, kernel_output_view, epsilon, floor_val);

//  std::cout << "ref:\n" << ref_view << "\n\n\n";
//  std::cout << "compute:\n" << kernel_output_view << "\n\n\n";

  // Compute error metrics
  double mse = cutlass::reference::host::TensorMSE(kernel_output_view, ref_view);
  double mre = cutlass::reference::host::TensorMRE(kernel_output_view, ref_view);
  double max_error = cutlass::reference::host::TensorGreatestError(kernel_output_view, ref_view);

  std::cout << "  Result MSE: " << mse << ", MRE: " << mre << ", greatest error: " << max_error << std::endl;
  std::cout << "GEMM Verification result is " << (result ? "PASS" : "FAIL")
            << std::endl;

  return result;
}

static void initialize_tensors(
    int M, int N, int K, cutlass::HostTensor<ElementA, LayoutA> &tensor_A,
    cutlass::HostTensor<ElementB, LayoutB> &tensor_B,
    cutlass::HostTensor<ElementOutput, LayoutC> &tensor_C,
    cutlass::HostTensor<ElementOutput, LayoutC> &tensor_D,
    cutlass::HostTensor<float, Gemm::LayoutScale> &tensor_ScaleA,
    cutlass::HostTensor<float, Gemm::LayoutScale> &tensor_ScaleB) {
  int mBlocks = ceil_div(M, BlockSize);
  int nBlocks = ceil_div(N, BlockSize);
  int kBlocks = ceil_div(K, BlockSize);

  uint64_t seed = 2024;

  // Resize tensors ------------------------------------------------------
  tensor_A.resize({M, K});
  tensor_B.resize({K, N});
  tensor_C.resize({M, N});
  tensor_D.resize({M, N});

  tensor_ScaleA.resize({mBlocks, kBlocks});
  tensor_ScaleB.resize({nBlocks, kBlocks});

  // Fill A and B with random uniform values in [-2, 2]
  cutlass::reference::host::TensorFillRandomUniform(
      tensor_A.host_view(), seed + 1, 2.0, -2.0);
  cutlass::reference::host::TensorFillRandomUniform(
      tensor_B.host_view(), seed + 2, 2.0, -2.0);

  // Fill C and D with random uniform values in [-2, 2]
  cutlass::reference::host::TensorFillRandomUniform(
      tensor_C.host_view(), seed + 3, 2.0, -2.0);
  cutlass::reference::host::TensorFillRandomUniform(
      tensor_D.host_view(), seed + 4, 2.0, -2.0);

  // Fill scale tensors with random uniform values in [-1, 1]
  cutlass::reference::host::TensorFillRandomUniform(
      tensor_ScaleA.host_view(), seed + 5, 1.0, -1.0);
  cutlass::reference::host::TensorFillRandomUniform(
      tensor_ScaleB.host_view(), seed + 6, 1.0, -1.0);

  tensor_A.sync_device();
  tensor_B.sync_device();
  tensor_C.sync_device();
  tensor_D.sync_device();
  tensor_ScaleA.sync_device();
  tensor_ScaleB.sync_device();
}

// This example requires CUDA 12.4 or greater and sm89 or higher
bool sufficient() {

    if (__CUDACC_VER_MAJOR__ < 12 || (__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 4)) {
      std::cerr << "This example requires CUDA 12.4 or greater." << std::endl;
      return false;
    }

    size_t smem_size = sizeof(typename Gemm::GemmKernel::SharedStorage);

    cudaDeviceProp properties;
    int device_idx;
    cudaError_t result = cudaGetDevice(&device_idx);

    if (result != cudaSuccess) {
      std::cerr << "cudaGetDevice() failed with error: " << cudaGetErrorString(result) << std::endl;
      return false;
    }

    result = cudaGetDeviceProperties(&properties, device_idx);

    if (result != cudaSuccess) {
      std::cerr << "cudaGetDeviceProperties() failed with error: " << cudaGetErrorString(result) << std::endl;
      return false;
    }

    if (properties.major < 8 || (properties.major == 8 && properties.minor < 9)) {
      std::cerr << "CUTLASS's Ada FP8 BlockwiseGEMM example requires a device of compute capability 89 or higher.\n" << std::endl;
      return false;
    }

    if (properties.sharedMemPerBlockOptin < smem_size) {
      std::cerr << "Insufficient shared memory. Need " << smem_size
                << ", but device only has " << properties.sharedMemPerBlockOptin << std::endl;
      return false;
    }

    return true;
}


int main(int argc, char const **args) {
  // ---------------------------------------------------------------------------
  // Parse command-line options
  // ---------------------------------------------------------------------------

  Options options;
  options.parse(argc, args);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  // Problem dimensions
  const int M = options.m;
  const int N = options.n;
  const int K = options.k;

  // Waive test if insufficient CUDA device
  if (!sufficient()) {
    std::cerr << "Insufficient resources to run the kernel." << std::endl;
    return 0;
  }

  cutlass::HostTensor<ElementA, LayoutA> tensor_A;
  cutlass::HostTensor<ElementB, LayoutB> tensor_B;
  cutlass::HostTensor<ElementOutput, LayoutC> tensor_C;
  cutlass::HostTensor<ElementOutput, LayoutC> tensor_D;
  cutlass::HostTensor<float, Gemm::LayoutScale> tensor_ScaleA;
  cutlass::HostTensor<float, Gemm::LayoutScale> tensor_ScaleB;


  initialize_tensors(M, N, K, tensor_A, tensor_B, tensor_C, tensor_D, tensor_ScaleA, tensor_ScaleB);

  ElementA const *ptr_A = tensor_A.device_data();
  ElementB const *ptr_B = tensor_B.device_data();
  ElementOutput const *ptr_C = tensor_C.device_data();
  ElementOutput *ptr_D = tensor_D.device_data();

  float *a_ptr = tensor_ScaleA.device_data();
  float *b_ptr = tensor_ScaleB.device_data();

  typename Gemm::EpilogueOutputOp::Params epilogue_params(options.alpha, options.beta);

  int kBlocks = ceil_div(K, BlockSize);
  int ldA = kBlocks;
  int ldB = kBlocks;

  using LayoutScale = Gemm::LayoutScale;
  using TensorRefScale = Gemm::TensorRefScale;

  LayoutScale layout_A(ldA);
  LayoutScale layout_B(ldB);
  TensorRefScale ref_scale_A(a_ptr, layout_A);
  TensorRefScale ref_scale_B(b_ptr, layout_B);

  // Construct the argument list ----------------------------------------
  typename Gemm::Arguments arguments(
      /* problem_size         */ {M, N, K},
      /* A                    */ {ptr_A, K},
      /* B                    */ {ptr_B, K},
      /* C                    */ {ptr_C, N},
      /* D                    */ {ptr_D, N},
      /* scale_A tensor ref   */ ref_scale_A,
      /* scale_B tensor ref   */ ref_scale_B,
      /* epilogue params      */ epilogue_params,
      /* split-k slices       */ 1,
      /* gather A indices     */ nullptr,
      /* gather B indices     */ nullptr,
      /* scatter D indices    */ nullptr);

  Gemm gemm_op;

  cutlass::Status status = gemm_op.can_implement(arguments);
  if (status != cutlass::Status::kSuccess) {
    std::cerr << "GEMM cannot implement the given problem." << std::endl;
    return -1;
  }

  size_t workspace_bytes = Gemm::get_workspace_size(arguments);
  cutlass::device_memory::allocation<uint8_t> workspace(workspace_bytes);

  status = gemm_op.initialize(arguments, workspace.get());
  if (status != cutlass::Status::kSuccess) {
    std::cerr << "GEMM initialization failed." << std::endl;
    return -1;
  }

  status = gemm_op();
  if (status != cutlass::Status::kSuccess) {
    std::cerr << "GEMM execution failed." << std::endl;
    return -1;
  }

  // Verification
  if (options.verify) {
    std::cout << "Verifying GEMM" << std::endl;
    bool ok = verify_gemm(M, N, K, ptr_A, ptr_B, ptr_C, ptr_D, a_ptr, b_ptr, 
                         options.alpha, options.beta);
    if (!ok) {
      std::cerr << "Verification failed." << std::endl;
      return -1;
    }
  }

  // Profiling loop 
  if (options.iterations > 0) {
    GpuTimer timer;
    for (int iter = 0; iter < options.warmup + options.iterations; ++iter) {
      if (iter == options.warmup)
        timer.start();
      CUTLASS_CHECK(gemm_op.run());
    }
    timer.stop();

    float elapsed_ms = timer.elapsed_millis();
    double avg_runtime_ms = double(elapsed_ms) / double(options.iterations);
    double gflops = options.gflops(avg_runtime_ms / 1000.0);
    std::cout << "Avg runtime: " << avg_runtime_ms << " ms" << std::endl;
    std::cout << "GFLOPS: " << gflops << std::endl;
    fflush(stdout);
  }

  return 0;
}
