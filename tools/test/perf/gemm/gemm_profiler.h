/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
#pragma once

#include <fstream>
#include <map>
#include <stdexcept>
#include <utility>

#if defined(WIN32)
#include <Windows.h>
#else
// needed for sleep
#include <unistd.h>
#endif

#include <tools/test/perf/gemm/gemm_perf_testbed.h>
#include <tools/test/perf/testbench_options.h>
#include <tools/test/perf/testbench_output.h>

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace perf {

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Performance measuring testbed
template <typename AType,
          typename BType,
          typename CType,
          typename AccumulatorType,
          typename ScalarType>
class GemmProfiler {
 public:
  /// Test environment
  typedef GemmTestbed<AType, BType, CType, AccumulatorType, ScalarType> PerfTestbed;

 private:
  //
  // Data members
  //

  /// Reference to TestbenchOutput instance
  TestbenchOutput &output;

  /// Reference to options object
  TestbenchOptions const &options;

  /// Performance test environment
  PerfTestbed testbed;

  /// Kernel name
  std::string kernel_name;

  /// Timing events
  cudaEvent_t events[2];

 public:
  /// Delays
  static void pause(int seconds) {
#if defined(WIN32)
    Sleep(1000 * seconds);
#else
    sleep(seconds);
#endif
  }

 public:
  //
  // Methods
  //

  /// Constructs performance testebed
  GemmProfiler(TestbenchOutput &_output,
               std::string const &_kernel_name,
               TestbenchOptions const &_options)
      : output(_output),
        options(_options),
        kernel_name(_kernel_name),
        testbed(_options.initial_distribution) {

    for (int i = 0; i < 2; ++i) {
      cudaError_t result = cudaEventCreate(&events[i]);
      if (result != cudaSuccess) {
        throw std::runtime_error("GemmPerfTestbed() failed to create CUDA events");
      }
    }
  }

  ~GemmProfiler() {}

  /// Writes the workspace to text files
  void write_problem(std::string const &kernel_name) {

      std::stringstream base_filename;

      base_filename
        << kernel_name << "_"
        << testbed.M() << "x" << testbed.N() << "x" << testbed.K();

      std::string results_name = base_filename.str() + "_results.txt";
      std::string errors_name = base_filename.str() + "_errors.txt";

      std::ofstream results(results_name.c_str());
      std::ofstream errors(errors_name.c_str());
      testbed.write_problem(results, errors);
  }

  /// Profiles Cutlass
  template <typename CutlassDispatch>
  PerformanceResult execute_cutlass(GemmProblem const &problem, cublasGemmAlgo_t algorithm) {
    PerformanceResult result(kernel_name, problem);

    testbed.compute_reference(algorithm);

    if (cudaDeviceSynchronize() != cudaSuccess) {
      result.disposition = Disposition::NotVerified;
      return result;
    }

    CutlassDispatch dispatch(testbed.M(),
                             testbed.N(),
                             testbed.K(),
                             testbed.alpha(),
                             testbed.ptr_A(),
                             testbed.lda(),
                             testbed.ptr_B(),
                             testbed.ldb(),
                             testbed.beta(),
                             testbed.ptr_C_initial(),
                             testbed.ldc(),
                             testbed.ptr_experimental(),
                             testbed.ldc());

    dispatch();

    if (cudaDeviceSynchronize() != cudaSuccess) {
      result.disposition = Disposition::Failed;
      return result;
    }

    if (testbed.verify_with_reference()) {
      result.disposition = Disposition::Passed;
    } else {
      result.disposition = Disposition::Incorrect;
    }

    if (options.save_workspace(result.disposition == Disposition::Passed)) {
      write_problem(kernel_name);
    }

    if (cudaDeviceSynchronize() != cudaSuccess) {
      result.disposition = Disposition::Failed;
    }

    // warmup launch
    dispatch();

    if (cudaDeviceSynchronize() != cudaSuccess) {
      result.disposition = Disposition::Failed;
      return result;
    }

    if (cudaEventRecord(events[0]) != cudaSuccess) {
      result.disposition = Disposition::Failed;
      return result;
    }

    for (int iter = 0; iter < options.iterations; ++iter) {
      dispatch();
    }

    if (cudaEventRecord(events[1]) != cudaSuccess) {
      result.disposition = Disposition::Failed;
      return result;
    }

    if (cudaEventSynchronize(events[1]) != cudaSuccess) {
      result.disposition = Disposition::Failed;
      return result;
    }

    float average_ms = 0;
    if (cudaEventElapsedTime(&average_ms, events[0], events[1]) != cudaSuccess) {
      result.disposition = Disposition::Failed;
      return result;
    }

    result.runtime = double(average_ms) / double(options.iterations);
    result.gflops = testbed.GFLOPs_per_sec(result.runtime);

    if (result.disposition != Disposition::Passed) {
      std::cout << kernel_name << " failed with disposition: " << result.disposition;
    }

    return result;
  }

  /// Executes all kernels for this problem size
  template <typename CutlassDispatch>
  std::vector<PerformanceResult> execute(GemmProblem const &problem) {

    // New problem size
    output.begin_problem();

    cublasGemmAlgo_t algorithm =
        (CutlassDispatch::kThreadMultiplyAdd ? CUBLAS_GEMM_DEFAULT : CUBLAS_GEMM_DEFAULT_TENSOR_OP);

    testbed.resize(problem);

    std::vector<PerformanceResult> results;

    results.push_back(execute_cutlass<CutlassDispatch>(problem, algorithm));

    // cool-down period
    pause(2);

    return results;
  }

  /// Runs the test and collects performance for all results
  template <typename CutlassDispatch>
  void schmoo(Range const &M, Range const &N, Range const &K) {
    for (int m = M.start; m <= M.end; m += M.increment) {
      for (int n = N.start; n <= N.end; n += N.increment) {
        for (int k = K.start; k <= K.end; k += K.increment) {

          // Avoid evaluating problem if problem size does not satisfy alignment
          if (!CutlassDispatch::is_problem_aligned(m, n, k)) {
            continue;
          }

          std::vector<PerformanceResult> results =
              execute<CutlassDispatch>(GemmProblem(m,
                                                   n,
                                                   k,
                                                   CutlassDispatch::kLayoutA,
                                                   CutlassDispatch::kLayoutB,
                                                   options.alpha,
                                                   options.beta));

          for (std::vector<PerformanceResult>::const_iterator it = results.begin();
               it != results.end();
               ++it) {
            output.append(*it);
          }
        }
      }
    }
  }

  /// Runs the test over the problem space and reports only the best performance
  template <typename CutlassDispatch>
  void peak(Range const &M, Range const &N, Range const &K) {

    PerformanceResult max_perf;
    bool first_result = true;

    for (int m = M.start; m <= M.end; m += M.increment) {
      for (int n = N.start; n <= N.end; n += N.increment) {
        for (int k = K.start; k <= K.end; k += K.increment) {

          // Avoid evaluating problem if problem size does not satisfy alignment
          if (!CutlassDispatch::is_problem_aligned(m, n, k)) {
            continue;
          }

          std::vector<PerformanceResult> results =
              execute<CutlassDispatch>(GemmProblem(m,
                                                   n,
                                                   k,
                                                   CutlassDispatch::kLayoutA,
                                                   CutlassDispatch::kLayoutB,
                                                   options.alpha,
                                                   options.beta));

          for (std::vector<PerformanceResult>::const_iterator it = results.begin();
               it != results.end();
               ++it) {

            /// Writes the output without appending it
            output.pretty_print(*it);

            /// Updates maximum performing kernel
            if (first_result || max_perf.gflops > it->gflops) {
              max_perf = *it;
            }
            first_result = false;
          }
        }
      }
    }

    output.append(max_perf);
  }
};

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Dispatches to GEMM performance profiler
template <typename Dispatch, typename GemmProfiler>
int profile_gemm(TestbenchOutput &output,
                 std::string const &kernel,
                 TestbenchOptions const &options) {
  if (options.kernel_enabled(kernel)) {
    GemmProfiler perf(output, kernel, options);
    if (options.peak_performance) {
      perf.template peak<Dispatch>(
          options.problem_range.M, options.problem_range.N, options.problem_range.K);
    } else {
      perf.template schmoo<Dispatch>(
          options.problem_range.M, options.problem_range.N, options.problem_range.K);
    }
  }

  return 0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace perf
