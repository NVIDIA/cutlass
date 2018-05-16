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

/** \file
    \brief CUTLASS Performance Tests
*/

#include <tools/test/perf/testbench_options.h>
#include <tools/test/perf/testbench_output.h>

//
// Profiling entry points defined in corresponding .cu files
//
namespace perf {

int profile_sgemm(TestbenchOutput &output, TestbenchOptions const &options);
int profile_dgemm(TestbenchOutput &output, TestbenchOptions const &options);
int profile_hgemm(TestbenchOutput &output, TestbenchOptions const &options);
int profile_igemm(TestbenchOutput &output, TestbenchOptions const &options);
int profile_wmma_gemm(TestbenchOutput &output, TestbenchOptions const &options);

}  // namespace perf

//
// Executes profiling functionality
//

/// Entry point to CUTLASS performance test
int main(int argc, const char **argv) {
  cutlass::CommandLine args(argc, argv);
  perf::TestbenchOptions options(args);

  if (args.check_cmd_line_flag("help")) {
    perf::TestbenchOptions::usage(std::cout);
    return 0;
  }

  perf::TestbenchOutput output(options);

  int (*profile_gemm[])(perf::TestbenchOutput &, perf::TestbenchOptions const &) = {
      perf::profile_sgemm,
      perf::profile_dgemm,
      perf::profile_hgemm,
      perf::profile_igemm,
      perf::profile_wmma_gemm,
      0};

  int result = 0;
  for (int i = 0; !result && profile_gemm[i]; ++i) {
    result = (profile_gemm[i])(output, options);
  }

  return result;
}
