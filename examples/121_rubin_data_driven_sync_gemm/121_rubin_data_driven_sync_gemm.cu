/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Rubin back-to-back GEMMs with PDL vs Data-Driven Synchronization.

           PDL reference only launches consumer kernels with PDL, meaning they can occupy SMs before
           consumers flush their writes, and consumers use the standard wait_on_dependent_grids()
           ahead of all tensor loads.

           Data-driven sync consumer kernels do not use wait_on_dependent_grids() and instead use the
           new TMA report valid feature in Rubin to wait for valid data to appear in the tile being loaded,
           and this is done for a specific input tensor (either A or B.)
           When invalid data is loaded, the new retry warp reissues the TMA load, and as soon as
           valid data is loaded, the corresponding MMA stage is unblocked.
           NOTE: it is a strict hardware requirement that the producer kernels always write in
           16-byte chunks.

           GEMM instantiations are defined in gemms.hpp.
           You can use macros RUN_2CTA_GEMM and USE_CLC_SCHEDULER to toggle between the default 1CTA
           and 2CTA Gemms, and dynamic persistent (CLC) vs static persistent schedulers in the
           kernels.

           In this example, since we always run > 1 GEMM, and both the numerical and performance
           baselines are also device-side GEMMs, memory management for tensors and workspaces is
           organized under MemoryPool, defined in memory.hpp.
           The current design does NOT support using different GEMM configurations for different steps,
           and assumes all GEMMs have identical workspace memory requirements.

           Command line options are organized under options.hpp.
*/


#define RUN_2CTA_GEMM
// #define USE_CLC_SCHEDULER

#include <algorithm>
#include <iostream>
#include <vector>

#include "cutlass/kernel_hardware_info.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/tensor_compare.h"

#include "helper.h"

#include "gemms.hpp"
#include "memory.hpp"
#include "options.hpp"

using namespace cute;

#if defined(ARCH_MMA_SUPPORTED) && defined(CUDA_HOST_SUPPORTED)

using TensorMemoryPool = MemoryPool<GemmReference>;

template <typename Gemm>
auto gemm_args_for_step(int i, TensorMemoryPool &pool, Options const &options, int chunk = 0) {
  auto problem = options.get_gemm_shape(i);
  auto stride_A = cutlass::make_cute_packed_stride(
    typename Gemm::GemmKernel::StrideA{}, cute::select<0, 2, 3>(problem));
  auto stride_B = cutlass::make_cute_packed_stride(
    typename Gemm::GemmKernel::StrideB{}, cute::select<1, 2, 3>(problem));
  auto stride_D = cutlass::make_cute_packed_stride(
    typename Gemm::GemmKernel::StrideD{}, cute::select<0, 1, 3>(problem));

  return typename Gemm::Arguments{
    cutlass::gemm::GemmUniversalMode::kGemm,
    problem,
    {pool.ptr_A(i, chunk), stride_A,
     pool.ptr_B(i, chunk), stride_B},
    {
      {}, // epilogue params
      nullptr, stride_D,
      pool.ptr_D(i, chunk), stride_D
    },
    cutlass::KernelHardwareInfo::make_kernel_hardware_info<typename Gemm::GemmKernel>(0)
  };
}

/// Visit the runtime-selected Gemm of each step: `fn(i, gemm)`. The reference chain
/// instantiates this with GemmA == GemmB (and GemmALast == GemmBLast), making the
/// dependency dispatch a no-op.
template <typename GemmFirst, typename GemmA, typename GemmB,
          typename GemmALast, typename GemmBLast, typename Fn>
void for_each_selected_gemm(GemmFirst &gemm_first,
                            std::vector<GemmA> &gemms_a,
                            std::vector<GemmB> &gemms_b,
                            GemmALast &gemm_a_last,
                            GemmBLast &gemm_b_last,
                            Options const &options, Fn &&fn) {
  fn(0, gemm_first);
  int const last = options.num_gemms() - 1;
  for (int i = 1; i < last; ++i) {
    if (options.deps[i - 1] == Dependency::A) {
      fn(i, gemms_a[i - 1]);
    } else {
      fn(i, gemms_b[i - 1]);
    }
  }
  if (options.deps[last - 1] == Dependency::A) {
    fn(last, gemm_a_last);
  } else {
    fn(last, gemm_b_last);
  }
}

template <typename GemmFirst, typename GemmA, typename GemmB,
          typename GemmALast, typename GemmBLast>
std::vector<size_t> compute_workspace_sizes(GemmFirst &gemm_first,
                                            std::vector<GemmA> &gemms_a,
                                            std::vector<GemmB> &gemms_b,
                                            GemmALast &gemm_a_last,
                                            GemmBLast &gemm_b_last,
                                            TensorMemoryPool &pool, Options const &options) {
  std::vector<size_t> sizes(options.num_gemms());
  for_each_selected_gemm(gemm_first, gemms_a, gemms_b, gemm_a_last, gemm_b_last, options,
                         [&](int i, auto &gemm) {
    using Gemm = std::remove_reference_t<decltype(gemm)>;
    auto args = gemm_args_for_step<Gemm>(i, pool, options);
    CUTLASS_CHECK(Gemm::can_implement(args));
    sizes[i] = Gemm::get_workspace_size(args);
  });
  return sizes;
}

template <typename GemmFirst, typename GemmA, typename GemmB,
          typename GemmALast, typename GemmBLast>
void initialize_gemms(GemmFirst &gemm_first,
                      std::vector<GemmA> &gemms_a,
                      std::vector<GemmB> &gemms_b,
                      GemmALast &gemm_a_last,
                      GemmBLast &gemm_b_last,
                      TensorMemoryPool &pool, Options const &options, int chunk = 0) {
  for_each_selected_gemm(gemm_first, gemms_a, gemms_b, gemm_a_last, gemm_b_last, options,
                         [&](int i, auto &gemm) {
    using Gemm = std::remove_reference_t<decltype(gemm)>;
    auto args = gemm_args_for_step<Gemm>(i, pool, options, chunk);
    CUTLASS_CHECK(gemm.initialize(args, pool.workspace_ptr(i)));
  });
}

template <typename GemmFirst, typename GemmA, typename GemmB,
          typename GemmALast, typename GemmBLast>
cutlass::Status run_gemms(GemmFirst &gemm_first,
                          std::vector<GemmA> &gemms_a,
                          std::vector<GemmB> &gemms_b,
                          GemmALast &gemm_a_last,
                          GemmBLast &gemm_b_last,
                          Options const &options, cudaStream_t stream) {
  cutlass::Status status = cutlass::Status::kSuccess;
  for_each_selected_gemm(gemm_first, gemms_a, gemms_b, gemm_a_last, gemm_b_last, options,
                         [&](int i, auto &gemm) {
    if (status == cutlass::Status::kSuccess) {
      status = gemm.run(stream, /*cuda_adapter=*/nullptr, /*launch_with_pdl=*/i > 0);
    }
  });
  return status;
}

template <class InitFn, class Fn>
double profile(cudaStream_t stream, int warmup_iterations, int iterations, int num_chunks,
               InitFn &&init_fn, Fn &&run_chunks) {
  CUDA_CHECK(cudaStreamSynchronize(stream));

  cudaEvent_t start_event, stop_event;
  CUDA_CHECK(cudaEventCreate(&start_event));
  CUDA_CHECK(cudaEventCreate(&stop_event));

  for (int done = 0; done < warmup_iterations; done += num_chunks) {
    init_fn(stream);
    run_chunks(stream, std::min(num_chunks, warmup_iterations - done));
  }
  CUDA_CHECK(cudaStreamSynchronize(stream));

  float elapsed_ms = 0.f;
  for (int done = 0; done < iterations; done += num_chunks) {
    init_fn(stream);
    CUDA_CHECK(cudaEventRecord(start_event, stream));
    run_chunks(stream, std::min(num_chunks, iterations - done));
    CUDA_CHECK(cudaEventRecord(stop_event, stream));
    CUDA_CHECK(cudaEventSynchronize(stop_event));
    float elapsed_ms_ = 0.f;
    CUDA_CHECK(cudaEventElapsedTime(&elapsed_ms_, start_event, stop_event));
    elapsed_ms += elapsed_ms_;
  }

  CUDA_CHECK(cudaEventDestroy(start_event));
  CUDA_CHECK(cudaEventDestroy(stop_event));

  return double(elapsed_ms) / double(iterations);
}

bool verify(TensorMemoryPool &pool_ref, TensorMemoryPool &pool,
            Options const &options, cudaStream_t stream) {
  using E = typename TensorMemoryPool::ElementD;
  bool all_ok = true;
  for (int i = 0; i < options.num_gemms(); ++i) {
    auto shape_D = cute::select<0, 1, 3>(options.get_gemm_shape(i));
    size_t cap = static_cast<size_t>(cute::size(shape_D));
    bool allclose;
    if (options.eps == 0.f) {
      allclose = cutlass::reference::device::BlockCompareEqual<E>(
        pool_ref.ptr_D(i), pool.ptr_D(i), cap, 0, 0, stream);
    } else {
      allclose = cutlass::reference::device::BlockCompareRelativelyEqual<E>(
        pool_ref.ptr_D(i), pool.ptr_D(i), cap,
        static_cast<E>(options.eps), static_cast<E>(0),
        0, 0, stream);
    }
    if (allclose) {
      std::cout << "  GEMM " << i << " D output matches reference (" << cap << " elements)\n";
    } else {
      std::cerr << "  GEMM " << i << " D output mismatch vs reference\n";
      all_ok = false;
    }
  }
  return all_ok;
}

int run(Options &options) {

  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));
  if (props.major != 10 || (props.minor != 7 && props.minor != 9)) {
    std::cerr
      << "This example requires a GPU of NVIDIA's Rubin Architecture "
      << "(compute capability 107 or 109)." << std::endl;
    return 0;
  }

  std::cout << "  Runtime SM arch: SM" << props.major << props.minor << std::endl;

  cudaStream_t stream = nullptr;
  CUDA_CHECK(cudaStreamCreate(&stream));

  // Verification runs on single-chunk pools; profiling below reallocates with
  // options.num_chunks, freeing these.
  TensorMemoryPool memory_pool;
  TensorMemoryPool memory_pool_ref;
  memory_pool.allocate_tensors(options);
  memory_pool_ref.allocate_tensors(options);

  GemmReferenceFirst gemm_ref_first;
  GemmReferenceLast gemm_ref_last;
  std::vector<GemmReference> gemms_ref(options.num_gemms() - 2);

  GemmDataDrivenSyncProducer gemm_target_first;
  GemmDataDrivenSyncConsumerALast gemm_target_a_last;
  GemmDataDrivenSyncConsumerBLast gemm_target_b_last;
  std::vector<GemmDataDrivenSyncConsumerA> gemms_target_a(options.num_gemms() - 2);
  std::vector<GemmDataDrivenSyncConsumerB> gemms_target_b(options.num_gemms() - 2);

  auto workspace_sizes_ref = compute_workspace_sizes(
    gemm_ref_first, gemms_ref, gemms_ref, gemm_ref_last, gemm_ref_last,
    memory_pool_ref, options);
  auto workspace_sizes_target = compute_workspace_sizes(
    gemm_target_first, gemms_target_a, gemms_target_b, gemm_target_a_last, gemm_target_b_last,
    memory_pool, options);

  memory_pool_ref.allocate_workspaces(workspace_sizes_ref);
  memory_pool.allocate_workspaces(workspace_sizes_target);

  memory_pool_ref.init_inputs(options.seed, stream);
  memory_pool.init_inputs(options.seed, stream);

  initialize_gemms(gemm_ref_first, gemms_ref, gemms_ref, gemm_ref_last, gemm_ref_last,
                   memory_pool_ref, options);
  initialize_gemms(gemm_target_first, gemms_target_a, gemms_target_b,
                   gemm_target_a_last, gemm_target_b_last, memory_pool, options);

  CUDA_CHECK(cudaDeviceSynchronize());

  // Verification run
  std::cout << std::endl << "  running " << options.num_gemms() << " GEMMs (reference)..." << std::endl;
  CUTLASS_CHECK(run_gemms(gemm_ref_first, gemms_ref, gemms_ref, gemm_ref_last, gemm_ref_last,
                          options, stream));
  CUDA_CHECK(cudaStreamSynchronize(stream));

  std::cout << "  running " << options.num_gemms() << " GEMMs (target)..." << std::endl;
  memory_pool.init_sentinel(stream);
  CUTLASS_CHECK(run_gemms(gemm_target_first, gemms_target_a, gemms_target_b,
                          gemm_target_a_last, gemm_target_b_last, options, stream));
  CUDA_CHECK(cudaStreamSynchronize(stream));

  std::cout << "  finished without runtime errors" << std::endl;

  auto passed = verify(memory_pool_ref, memory_pool, options, stream);

  std::cout << std::endl << "  Disposition (eps: " << options.eps << "): " <<
    (passed ? "Passed" : "Failed") << std::endl;

  if (not passed) {
    exit(-1);
  }

  // Profiling
  if (options.iterations > 0) {
    memory_pool_ref.allocate_tensors(options, options.num_chunks);
    memory_pool.allocate_tensors(options, options.num_chunks);
    memory_pool_ref.init_inputs(options.seed, stream);
    memory_pool.init_inputs(options.seed, stream);

    std::cout << std::endl
              << "  Warmup: " << options.warmup_iterations
              << ", profile: " << options.iterations << " iterations"
              << " (" << options.num_chunks << " chunks per timed run)." << std::endl;

    double runtime_ms_ref = profile(stream, options.warmup_iterations, options.iterations,
        options.num_chunks,
        [](cudaStream_t) {},  // reference: no sentinel fill
        [&](cudaStream_t s, int n) {
          for (int c = 0; c < n; ++c) {
            initialize_gemms(gemm_ref_first, gemms_ref, gemms_ref, gemm_ref_last, gemm_ref_last,
                             memory_pool_ref, options, c);
            CUTLASS_CHECK(run_gemms(gemm_ref_first, gemms_ref, gemms_ref, gemm_ref_last,
                                    gemm_ref_last, options, s));
          }
        });

    double runtime_ms = profile(stream, options.warmup_iterations, options.iterations,
        options.num_chunks,
        [&](cudaStream_t s) { memory_pool.init_sentinel(s); },  // sentinel-fill all chunks
        [&](cudaStream_t s, int n) {
          for (int c = 0; c < n; ++c) {
            initialize_gemms(gemm_target_first, gemms_target_a, gemms_target_b,
                             gemm_target_a_last, gemm_target_b_last, memory_pool, options, c);
            CUTLASS_CHECK(run_gemms(gemm_target_first, gemms_target_a, gemms_target_b,
                                    gemm_target_a_last, gemm_target_b_last, options, s));
          }
        });

    double runtime_s_ref = runtime_ms_ref / 1000.0;
    double runtime_s     = runtime_ms     / 1000.0;
    double tflops_ref    = options.tflops(runtime_s_ref);
    double tflops_test   = options.tflops(runtime_s);

    std::cout << std::endl;
    std::cout << "  Number of GEMMs: " << options.num_gemms() << std::endl;
    for (int i = 0; i < options.num_gemms(); ++i) {
      auto problem_shape = options.get_gemm_shape(i);
      std::cout << "  GEMM " << i << " problem (M, N, K, L): " <<
        cute::get<0>(problem_shape) << " x " <<
        cute::get<1>(problem_shape) << " x " <<
        cute::get<2>(problem_shape) << " x " <<
        cute::get<3>(problem_shape) << std::endl;
    }
    std::cout << "  Reference  | runtime: " << runtime_ms_ref << " ms"
              << " | TFLOPS: " << tflops_ref << std::endl;
    std::cout << "  Target     | runtime: " << runtime_ms     << " ms"
              << " | TFLOPS: " << tflops_test << std::endl;

    double speedup = runtime_ms_ref / runtime_ms;
    std::cout << "  Speedup (reference / target): "
              << speedup << std::endl;
  }

  std::cout << std::endl << std::endl;
  CUDA_CHECK(cudaStreamDestroy(stream));

  return 0;
}

#endif // defined(ARCH_MMA_SUPPORTED) && defined(CUDA_HOST_SUPPORTED)

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

#if !defined(CUDA_HOST_SUPPORTED)
  std::cerr << "This example requires a newer CUDA Toolkit." << std::endl;
  return 0;
#endif

  // Parse options
  Options options;
  options.parse(argc, args);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

#if defined(ARCH_MMA_SUPPORTED) && defined(CUDA_HOST_SUPPORTED)
  run(options);
#else
    std::cerr
      << "This example must be compiled with a supported architecture (see ARCH_MMA_SUPPORTED "
      << "in gemms.hpp) and a supported CUDA Toolkit (see CUDA_HOST_SUPPORTED)." << std::endl;
#endif

  return 0;
}
