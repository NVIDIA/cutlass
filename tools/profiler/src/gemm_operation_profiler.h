/***************************************************************************************************
 * Copyright (c) 2017-2021, NVIDIA CORPORATION.  All rights reserved.
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
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/* \file
   \brief Defines a math function
*/

#pragma once

#include <vector>
#include <string>
#include <memory>
#include <algorithm>
#include <unordered_map>

// CUTLASS Library includes
#include "cutlass/library/library.h"
#include "cutlass/library/util.h"
#include "cutlass/library/manifest.h"

// Profiler includes
#include "options.h"
#include "device_context.h"
#include "operation_profiler.h"
#include "performance_result.h"
#include "problem_space.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace profiler {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Abstract base class for each math function
class GemmOperationProfiler : public OperationProfiler {
public:

  /// Problem structure obtained from problem space
  struct GemmProblem {

    cutlass::library::GemmUniversalMode mode; 
    int64_t m;
    int64_t n;
    int64_t k;
    int64_t lda;
    int64_t ldb;
    int64_t ldc;
    std::vector<uint8_t> alpha;
    std::vector<uint8_t> beta;
    int split_k_slices;
    int batch_count;

    //
    // Methods
    //

    GemmProblem(): 
      mode(library::GemmUniversalMode::kGemm),
      m(16), n(16), k(16), lda(0), ldb(0), ldc(0), split_k_slices(1), batch_count(1) { }

    /// Parses the problem
    Status parse(
      library::GemmDescription const &operation_desc,
      ProblemSpace const &problem_space,
      ProblemSpace::Problem const &problem);

    /// Total number of bytes loaded
    int64_t bytes(library::GemmDescription const &operation_desc) const;

    /// Total number of flops computed
    int64_t flops(library::GemmDescription const &operation_desc) const;

    /// Initializes a performance result
    void initialize_result(
      PerformanceResult &result,
      library::GemmDescription const &operation_desc,
      ProblemSpace const &problem_space);
  };

  /// Workspace used 
  struct GemmWorkspace {

    DeviceAllocation *A;
    DeviceAllocation *B;
    DeviceAllocation *C;
    DeviceAllocation *Computed;
    DeviceAllocation *Reference;

    /// Number of copies of the problem workspace which are visited sequentially during
    /// profiling to avoid camping in the last level cache.
    int problem_count;

    library::GemmUniversalConfiguration configuration;
    library::GemmUniversalArguments arguments;

    /// Buffer used for the operation's host workspace
    std::vector<uint8_t> host_workspace;

    /// Buffer used for the operations' device workspace
    DeviceAllocation device_workspace;

    //
    // Methods
    //

    GemmWorkspace(): 
      A(nullptr), B(nullptr), C(nullptr), Computed(nullptr), Reference(nullptr), problem_count(1) { }
  };

protected:

  //
  // Data members
  //

  /// GEMM problem obtained from problem space
  GemmProblem problem_;

  /// Device memory allocations 
  GemmWorkspace gemm_workspace_;


public:
  //
  // Methods
  //

  /// Ctor
  GemmOperationProfiler(Options const &options);

  /// Destructor
  virtual ~GemmOperationProfiler();

  /// Prints usage statement for the math function
  virtual void print_usage(std::ostream &out) const;

  /// Prints examples
  virtual void print_examples(std::ostream &out) const;

  /// Extracts the problem dimensions
  virtual Status initialize_configuration(
    Options const &options, 
    PerformanceReport &report, 
    DeviceContext &device_context,
    library::Operation const *operation,
    ProblemSpace const &problem_space,
    ProblemSpace::Problem const &problem);

  /// Initializes workspace
  virtual Status initialize_workspace(
    Options const &options, 
    PerformanceReport &report, 
    DeviceContext &device_context,
    library::Operation const *operation,
    ProblemSpace const &problem_space,
    ProblemSpace::Problem const &problem);

  /// Verifies CUTLASS against references
  virtual bool verify_cutlass(
    Options const &options,  
    PerformanceReport &report,
    DeviceContext &device_context,
    library::Operation const *operation,
    ProblemSpace const &problem_space,
    ProblemSpace::Problem const &problem);

  /// Measures performance results
  virtual bool profile(
    Options const &options, 
    PerformanceReport &report, 
    DeviceContext &device_context,
    library::Operation const *operation,
    ProblemSpace const &problem_space,
    ProblemSpace::Problem const &problem);

protected:

  /// Initializes the performance result
  void initialize_result_(
    PerformanceResult &result,
    Options const &options,  
    library::GemmDescription const &operation_desc,
    ProblemSpace const &problem_space);

  /// Verifies CUTLASS against references
  bool verify_with_cublas_(
    Options const &options,  
    PerformanceReport &report,
    DeviceContext &device_context,
    library::Operation const *operation,
    ProblemSpace const &problem_space,
    ProblemSpace::Problem const &problem);

  /// Verifies CUTLASS against host and device references
  bool verify_with_reference_(
    Options const &options,  
    PerformanceReport &report,
    DeviceContext &device_context,
    library::Operation const *operation,
    ProblemSpace const &problem_space,
    ProblemSpace::Problem const &problem);

  /// Method to profile a CUTLASS Operation
  Status profile_cutlass_(
    double &runtime,
    Options const &options,
    library::Operation const *operation,
    void *arguments,
    void *host_workspace,
    void *device_workspace);

};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace profiler
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////

