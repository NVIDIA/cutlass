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

#pragma once


#include <cstdint>
#include <algorithm>
#include <ostream>
#include <stdexcept>
#include <string>
#include <vector>

#include <cuda_runtime.h>

#include "cute/tensor.hpp"
#include "cutlass/cutlass.h"
#include "cutlass/util/command_line.h"

#define VALIDATE_SIZE(name, value)                                      \
  if ((value) < 0) {                                                    \
    throw std::invalid_argument(                                        \
      "Invalid value for --" + std::string(name) +                      \
      ", expected non-negative integer, got " + std::to_string(value) + \
      ".");                                                             \
  }

#define VALIDATE_EPS(value)                                             \
  if ((value) < 0.f) {                                                  \
    throw std::invalid_argument(                                        \
      "Invalid value for --eps, expected non-negative float, got " +    \
      std::to_string(value) + ".");                                     \
  }

enum class Dependency { A, B };

/// Command-line options
struct Options {

  bool help = false;

  int iterations = 0;
  int warmup_iterations = 100;

  // Number of tensor-space copies (chunks) the memory pool rotates through.
  int num_chunks = 100;

  // Per-GEMM problem shapes. Default M=N=K=512,512
  std::vector<int> m = std::vector<int>(2, 512);
  std::vector<int> n = std::vector<int>(2, 512);
  std::vector<int> k = std::vector<int>(2, 512);
  int l = 1;  // shared batch extent across all GEMMs

  float eps = 0.f;
  uint64_t seed = 42;

  // Per-consumer GEMM dependency.
  std::vector<Dependency> deps = std::vector<Dependency>(1, Dependency::B);

  int num_gemms() const { return static_cast<int>(m.size()); }

  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_arguments("m", m);
    cmd.get_cmd_line_arguments("n", n);
    cmd.get_cmd_line_arguments("k", k);
    cmd.get_cmd_line_argument("l", l);
    cmd.get_cmd_line_argument("iterations", iterations);
    cmd.get_cmd_line_argument("warmup-iterations", warmup_iterations);
    cmd.get_cmd_line_argument("num-chunks", num_chunks);
    cmd.get_cmd_line_argument("eps", eps);
    cmd.get_cmd_line_argument("seed", seed);

    int const num_gemms = static_cast<int>(m.size());
    if (static_cast<int>(n.size()) != num_gemms || static_cast<int>(k.size()) != num_gemms) {
      throw std::runtime_error("--m, --n, --k must all list the same number of GEMMs.");
    }
    if (num_gemms < 2) {
      throw std::runtime_error(
        "Number of GEMMs (length of --m) must be at least 2, got " +
        std::to_string(num_gemms) + ".");
    }

    std::vector<std::string> dep_strs;
    cmd.get_cmd_line_arguments("dep", dep_strs);
    deps.assign(num_gemms - 1, Dependency::B);
    if (not dep_strs.empty()) {
      if (static_cast<int>(dep_strs.size()) != num_gemms - 1) {
        throw std::runtime_error("--dep must list exactly (num GEMMs - 1) entries.");
      }
      for (int j = 0; j < num_gemms - 1; ++j) {
        deps[j] = parse_dependency(dep_strs[j]);
      }
    }

    for (int i = 0; i < num_gemms; ++i) {
      VALIDATE_SIZE("m", m[i]);
      VALIDATE_SIZE("n", n[i]);
      VALIDATE_SIZE("k", k[i]);
    }
    VALIDATE_SIZE("l", l);

    iterations = std::max(iterations, 0);
    warmup_iterations = std::max(warmup_iterations, 0);

    if (num_chunks < 1) {
      throw std::runtime_error("--num-chunks must be at least 1.");
    }
    // More chunks than the longest phase can rotate through just waste memory.
    num_chunks = std::min(num_chunks, std::max({iterations, warmup_iterations, 1}));

    VALIDATE_EPS(eps);

    for (int i = 1; i < num_gemms; ++i) {
      validate_dependency_shapes(i);
    }
  }

  std::ostream & print_usage(std::ostream &out) const {

    out << "121_rubin_data_driven_sync_gemm\n\n"
      << "  Back-to-back GEMMs with Rubin's HW-accelerated Data-Driven Synchronization.\n"
      << "  The number of GEMMs run is the length of the --m / --n / --k lists (at least 2).\n"
      << "  GEMM i has shape (m[i], n[i], k[i], l) and produces D of shape (m[i], n[i]).\n"
      << "  --dep wires which operand of GEMM i is fed by GEMM i-1's D output.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int,...>               Per-GEMM M extents (comma list, at least 2 entries)\n"
      << "  --n=<int,...>               Per-GEMM N extents (same length as --m)\n"
      << "  --k=<int,...>               Per-GEMM K extents (same length as --m)\n"
      << "  --l=<int>                   Shared L extent (batch) across all GEMMs (default: 1)\n"
      << "  --iterations=<int>          Number of profiling iterations to perform (default: 0)\n"
      << "  --warmup-iterations=<int>   Number of warmup iterations prior to profiling (default: 100)\n"
      << "  --num-chunks=<int>          Number of tensor-space copies rotated through so each\n"
      << "                              iteration runs on cold addresses. Clipped to\n"
      << "                              max(--iterations, --warmup-iterations) (default: 100)\n"
      << "  --seed=<int>                Init seed\n"
      << "  --dep=<X,...>               Per-step dependency (comma list of (num GEMMs - 1) values).\n"
      << "                              X = A or B (C is not supported yet).\n"
      << "                              A: D[i-1] feeds A[i] (MK dependency).\n"
      << "                              B: D[i-1] feeds B[i] (NK dependency, default).\n"
      << "                              Aliased dims must match GEMM i-1's D = (m[i-1], n[i-1]):\n"
      << "                                A -> m[i]==m[i-1], k[i]==n[i-1]\n"
      << "                                B -> n[i]==n[i-1], k[i]==m[i-1]\n"
      << "  --eps=<f32>                 Threshold for error compared to reference "
      << "GEMM (default: 0.0)\n\n";

    out
      << "\n\nExamples:\n\n"
      << "$ " << "121_rubin_data_driven_sync_gemm" << " --m=512,512 --n=512,512 --k=512,512 --dep=B\n\n"
      << "$ " << "121_rubin_data_driven_sync_gemm"
      << " --m=512,512,512 --n=512,512,512 --k=512,512,512 --dep=B,B\n\n";

    return out;
  }

  /// Aggregate FLOP/s across all GEMMs (2*M*N*K*L per GEMM).
  double tflops(double runtime_s) const {
    uint64_t flop = 0;
    for (int i = 0; i < num_gemms(); ++i) {
      flop += uint64_t(2) * uint64_t(l) * uint64_t(m[i]) * uint64_t(n[i]) * uint64_t(k[i]);
    }
    return double(flop) / 1.0e12 / runtime_s;
  }

  /// Per-step problem shape (M, N, K, L) for GEMM `i`.
  cute::Shape<int, int, int, int> get_gemm_shape(int i) const {
    return cute::make_shape(m[i], n[i], k[i], l);
  }

private:
  static Dependency parse_dependency(std::string const &s) {
    if (s == "A") return Dependency::A;
    if (s == "B") return Dependency::B;
    throw std::runtime_error("Invalid --dep entry '" + s + "'. Must be A or B.");
  }

  void validate_dependency_shapes(int i) const {
    auto fail = [&](char const *msg) {
      throw std::runtime_error(
        "GEMM " + std::to_string(i) + " dependency shape mismatch: " + msg);
    };
    switch (deps[i - 1]) {
      case Dependency::A:
        if (m[i] != m[i - 1]) fail("--dep=A requires m[i] == m[i-1].");
        if (k[i] != n[i - 1]) fail("--dep=A requires k[i] == n[i-1].");
        break;
      case Dependency::B:
        if (n[i] != n[i - 1]) fail("--dep=B requires n[i] == n[i-1].");
        if (k[i] != m[i - 1]) fail("--dep=B requires k[i] == m[i-1].");
        break;
    }
  }
};
