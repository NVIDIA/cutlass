/***************************************************************************************************
 * Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Grouped scale Hopper FP8 GEMM example using CUTLASS 3.0 APIs for NVIDIA Hopper architecture
    This example demonstrate a grouped scaled FP8 GEMM using the new CUTLASS 3.0.
    APIs on NVIDIA Hopper architecture. New features that will be showcased in this example are as follows:
    1. NVIDIA Hopper architecture introduces a new series of tensor core instructions (GMMA)
    which are more efficient than the Ampere tensor core instructions.
    2. NVIDIA Hopper architecture includes new Tensor Memory Accelerator (TMA) unit to transfer large
    blocks of data efficiently between global memory and shared memory. TMA also supports asynchronous
    copies between thread blocks in a cluster.
    3. This example uses the Warp Specialized kernel design (see /media/docs/efficient_gemm.md for details).
    4. This example shows all important fusions used by FP8 gemm kernels, i.e., grouped scale factor along M for
    A, blocked scale factor along K for A tensor, blocked scale factor for B tensor, the abs_max value of D tensor.
    5. A simple way to tune the CTA rasterization direction and swizzle pattern of Hopper kernels. Both the
    CTA rasterization direction and swizzle pattern impact cross-CTA locality of accesses. By tuning we can
    improve performance.
    Examples:
      $ ./examples/67_hopper_fp8_warp_specialized_gemm_with_blockwise_scaling/67_hopper_fp8_deepgemm  \
        --m=4096 --iterations=1000
*/

#include <iostream>

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/host/tensor_fill.h"
// #include "cutlass/util/reference/host/tensor_copy.h"
// #include "cutlass/util/reference/host/tensor_compare.h"
// #include "cutlass/util/reference/host/tensor_norm.h"

// Includes from examples directory
#include "helper.h"
// #include "reference/host/gemm_with_groupwise_scaling.h"

#include "deep_gemm/fp8_gemm.cuh"

// using namespace cute;
using namespace deep_gemm;

// #define CUTLASS_ARCH_MMA_SM90_SUPPORTED

#if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)


// Command line options parsing
struct Options {
  bool help;
  int iterations;
  int m, n, k;

  Options():
    help(false),
    m(4096),
    n(4096),
    k(4096),
    iterations(10)
  { }

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);
    Options defaults;

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("m", m, defaults.m);

    cmd.get_cmd_line_argument("iterations", iterations, defaults.iterations);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "67_hopper_fp8_deepgemm\n\n"
      << "  Hopper FP8 DeepGEMM kernel.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the m size\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n";

    return out;
  }

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

constexpr int cdiv(int a, int b) {
  return (a + b - 1) / b;
}


// #if defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

/////////////////////////////////////////////////////////////////////////////////////////////////
/// GEMM setup and evaluation
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to initialize a block of device data
template <typename Element, typename Layout>
bool initialize_tensor(
  cutlass::TensorView<Element, Layout> view,
  cutlass::Distribution::Kind dist_kind,
  uint64_t seed) {

  if (dist_kind == cutlass::Distribution::Uniform) {

    double scope_max, scope_min;
    int bits_input = cutlass::sizeof_bits<Element>::value;
    int bits_output = cutlass::sizeof_bits<Element>::value;

    if (bits_input == 1) {
      scope_max = 2;
      scope_min = 0;
    } else if (bits_input <= 8) {
      scope_max = 2;
      scope_min = -2;
    } else if (bits_output == 16) {
      scope_max = 5;
      scope_min = -5;
    } else {
      scope_max = 8;
      scope_min = -8;
    }

    cutlass::reference::host::TensorFillRandomUniform(
      view, seed, scope_max, scope_min, 0);
  }
  else if (dist_kind == cutlass::Distribution::AllZeros) {
    cutlass::reference::host::TensorFill(view);
  }
  else if (dist_kind == cutlass::Distribution::Identity) {

    cutlass::reference::host::TensorFillIdentity(view);
  }
  else if (dist_kind == cutlass::Distribution::Gaussian) {

    cutlass::reference::host::TensorFillRandomGaussian(view, seed, 0, 0.5);
  }
  else if (dist_kind == cutlass::Distribution::Sequential) {
    cutlass::reference::host::BlockFillSequential(view.data(), view.capacity());
  }
  else {
    throw std::runtime_error("Not implementated.");
  }

  return true;
}

/// Helper to initialize a block of device data (scale_tensors)
template <typename Element, typename Layout>
bool initialize_scale_tensor(
  cutlass::TensorView<Element, Layout> view,
  cutlass::Distribution::Kind dist_kind,
  uint64_t seed) {

  if (dist_kind == cutlass::Distribution::Uniform) {

    double scope_max, scope_min;

    scope_min = -1;
    scope_max = 1;

    cutlass::reference::host::TensorFillRandomUniform(
      view, seed, scope_max, scope_min, 0);
  }
  else if (dist_kind == cutlass::Distribution::AllZeros) {
    cutlass::reference::host::TensorFill(view);
  }
  else if (dist_kind == cutlass::Distribution::Identity) {

    cutlass::reference::host::TensorFillIdentity(view);
  }
  else if (dist_kind == cutlass::Distribution::Gaussian) {

    cutlass::reference::host::TensorFillRandomGaussian(view, seed, 0, 0.5);
  }
  else if (dist_kind == cutlass::Distribution::Sequential) {
    cutlass::reference::host::BlockFillSequential(view.data(), view.capacity());
  }
  else {
    throw std::runtime_error("Not implementated.");
  }

  return true;
}


/// Todo: add reference check
bool verify(const Options &options) {
  //
  // Compute reference output
  //
  return true;
}

struct TestBed {
  using Element = cutlass::float_e4m3_t;
  using ElementScale = float;
  using ElementAcc = float;
  using ElementOut = cutlass::bfloat16_t;

  cutlass::HostTensor<Element, cutlass::layout::RowMajor> Tensor_lhs;
  cutlass::HostTensor<Element, cutlass::layout::RowMajor> Tensor_rhs;
  cutlass::HostTensor<ElementScale, cutlass::layout::ColumnMajor> Tensor_lhs_scale;
  cutlass::HostTensor<ElementScale, cutlass::layout::RowMajor> Tensor_rhs_scale;
  cutlass::HostTensor<ElementOut, cutlass::layout::RowMajor> Tensor_out;


  /// Initialize operands to be used in the GEMM
  void initialize(
    const Options &options,
    uint64_t seed = 2025) {

    Tensor_lhs.resize({options.m, options.k}); //[m, k]
    Tensor_rhs.resize({options.n, options.k}); //[n, k]
    Tensor_lhs_scale.resize({options.m, cdiv(options.k, 128)}); // [m, cdiv(k, 128)] column major
    Tensor_rhs_scale.resize({cdiv(options.n, 128), cdiv(options.k, 128)}); // [cdiv(n, 128), cdiv(k, 128)]
    Tensor_out.resize({options.m, options.n}); // [m, n]

    initialize_tensor(Tensor_lhs.host_view(), cutlass::Distribution::Uniform, seed + 1);
    initialize_tensor(Tensor_rhs.host_view(), cutlass::Distribution::Uniform, seed + 2);
    initialize_scale_tensor(Tensor_lhs_scale.host_view(), cutlass::Distribution::Uniform, seed + 3);
    initialize_scale_tensor(Tensor_rhs_scale.host_view(), cutlass::Distribution::Uniform, seed + 4);

    Tensor_lhs.sync_device();
    Tensor_rhs.sync_device();
    Tensor_lhs_scale.sync_device();
    Tensor_rhs_scale.sync_device();
    Tensor_out.sync_device();

  }

  void run(Options &options)
  {
    cudaDeviceProp props;
    int current_device;
    CUDA_CHECK(cudaGetDevice(&current_device));
    CUDA_CHECK(cudaGetDeviceProperties(&props, current_device));

    initialize(options);

    cudaStream_t stream{nullptr};
    constexpr auto N = 4096;
    constexpr auto K = 4096;
    constexpr auto BLOCK_M = 128;
    constexpr auto BLOCK_N = 128;
    constexpr auto kNumStages = 5;
    constexpr auto kNumTMAMulticast = 2;
    const int num_sms = 132; // for H100 
    const int best_smem_size = 199376; 

    // Make a templated GEMM
    using GemmKernel = Gemm<N, K, BLOCK_M, BLOCK_N, 128, 1, kNumStages, kNumTMAMulticast, GemmType::Normal>;

    int m = options.m;
    // DeepGEMM requires __nv_fp8_e4m3 input and __nv_bfloat16 output
    __nv_fp8_e4m3* lhs = reinterpret_cast<__nv_fp8_e4m3*>(Tensor_lhs.device_data());
    __nv_fp8_e4m3* rhs = reinterpret_cast<__nv_fp8_e4m3*>(Tensor_rhs.device_data());
    float* lhs_scales = Tensor_lhs_scale.device_data();
    float* rhs_scales = Tensor_rhs_scale.device_data();
    __nv_bfloat16* out = reinterpret_cast<__nv_bfloat16*>(Tensor_out.device_data());

    // Launch kernel
    auto tma_a_desc = GemmKernel::make_2d_tma_a_desc(lhs, m);
    auto tma_b_desc = GemmKernel::make_2d_tma_b_desc(rhs);
    auto tma_scales_a_desc = GemmKernel::make_2d_tma_scales_a_desc(lhs_scales, m);
    auto tma_d_desc = GemmKernel::make_2d_tma_d_desc(out, m);
    GemmKernel::run(out, rhs_scales, nullptr,
                  m,
                  tma_a_desc, tma_b_desc, tma_scales_a_desc, tma_d_desc,
                  stream, num_sms, best_smem_size);

    CUDA_CHECK(cudaStreamSynchronize(stream));

    CUDA_CHECK(cudaDeviceSynchronize());

    std::cout << "run done\n";
    // TODO: reference check
    Result result;
    // result.passed = verify(options, ScaleMsPerTile, ScaleNsPerTile);

    // std::cout << "  Disposition: " << (result.passed ? "Passed" : "Failed") << std::endl;

    // if (!result.passed) {
    //  exit(-1);
    // }

    // Run profiling loop
    if (options.iterations > 0)
    {
      GpuTimer timer;
      timer.start();
      for (int iter = 0; iter < options.iterations; ++iter) {
        // initialize(options);
        GemmKernel::run(out, rhs_scales, nullptr,
                    m,
                    tma_a_desc, tma_b_desc, tma_scales_a_desc, tma_d_desc,
                    stream, num_sms, best_smem_size);
      }
      timer.stop();

      // Compute average runtime and GFLOPs.
      float elapsed_ms = timer.elapsed_millis();
      result.avg_runtime_ms = double(elapsed_ms) / double(options.iterations);
      result.gflops = options.gflops(result.avg_runtime_ms / 1000.0);

      std::cout << "  Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << std::endl;
      std::cout << "  Tile shape (M, N, K): (128, 128, 128)" << std::endl;
      std::cout << "  ScaleGranularityM: 1 (ScaleMsPerTile: 128)" << std::endl;
      std::cout << "  ScaleGranularityN: 128 (ScaleNsPerTile: 1)" << std::endl;
      std::cout << "  Avg runtime: " << result.avg_runtime_ms << " ms" << std::endl;
      std::cout << "  GFLOPS: " << result.gflops << std::endl;
      fflush(stdout);
    }
  }
};

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
  if (props.major != 9) {
    std::cerr
      << "This example requires a GPU of NVIDIA's Hopper Architecture or "
      << "later (compute capability 90 or greater).\n";
    return 0;
  }
  //
  // Parse options
  //
  #if defined (CUTLASS_ARCH_MMA_SM90_SUPPORTED)

  Options options;

  options.parse(argc, args);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  TestBed testbed{};
  testbed.run(options);

  #endif // defined(CUTLASS_ARCH_MMA_SM90_SUPPORTED)

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
