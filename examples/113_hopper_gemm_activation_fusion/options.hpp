/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include <vector>
#include <string>
#include <sstream>
#include <numeric>
#include <stdexcept>
#include <algorithm>
#include <cfloat>

#include "cutlass/util/command_line.h"
#include "cutlass/util/distribution.h"
#include "cutlass/gemm_coord.h"
#include "cutlass/gemm/kernel/tile_scheduler_params.h"

#define OPTIONS_ERROR(...)            \
do {                                  \
  std::stringstream ss;               \
  ss << __VA_ARGS__;                  \
  throw std::runtime_error(ss.str()); \
}                                     \
while (false)

// Command line options parsing
template <class RasterOrderOptions_>
struct GemmOptionsBase {

  using RasterOrderOptions = RasterOrderOptions_;

  bool help = false;
  int iterations = 100;
  int warmup = 100;
  RasterOrderOptions raster = RasterOrderOptions::Heuristic;
  int swizzle = 1;
  int sm_count = 0;
  int device = -1;
  float tolerance = 2e-1f;
  float nonzero_floor = 3e-1f;
  bool verify = true;
  bool verbose = false;
  bool csv = false;
  std::string program_path;

  cutlass::Distribution dist_a;
  cutlass::Distribution dist_b;
  cutlass::Distribution dist_c;

  std::string raster_string() const {
    switch (raster) {
      case RasterOrderOptions::Heuristic: return "Heuristic";
      case RasterOrderOptions::AlongM: return "AlongM";
      case RasterOrderOptions::AlongN: return "AlongN";
    }
    return "Unknown";
  }

  static cutlass::Distribution
  get_distribution(
      cutlass::CommandLine const& cmd,
      char const* arg_name) {

    struct {
      const char *label;
      cutlass::Distribution::Kind kind;
    } distribution_kinds[] = {
      {"uniform", cutlass::Distribution::Uniform},
      {"gaussian", cutlass::Distribution::Gaussian},
      {"sequential", cutlass::Distribution::Sequential},
      {0, cutlass::Distribution::Invalid}
    };

    cutlass::Distribution dist;

    struct {
      char const *label;
      double *member;
    } members[] = {
      {"min", &dist.uniform.min},
      {"max", &dist.uniform.max},
      {"mean", &dist.gaussian.mean},
      {"stddev", &dist.gaussian.stddev},
      {"pnzA", &dist.gaussian.pnzA},
      {"pnzB", &dist.gaussian.pnzB},
      {"pnzC", &dist.gaussian.pnzC},
      {"start", &dist.sequential.start},
      {"delta", &dist.sequential.delta},
      {0, 0}
    };

    using KeyValueVector = std::vector<std::pair<std::string, std::string>>;

    KeyValueVector values;
    cmd.get_cmd_line_argument_pairs(arg_name, values);

    // The parser expects the first token to be a string identifying the distribution type.
    auto it = values.begin();
    if (it != values.end()) {
      for (int i = 0; distribution_kinds[i].label; ++i) {
        if (it->first == distribution_kinds[i].label) {
          dist.kind = distribution_kinds[i].kind;
          break;
        }
      }
      ++it;
    }

    // Default initialization
    switch (dist.kind) {
      case cutlass::Distribution::Uniform:
        dist.set_uniform(-1/*min*/, 1/*max*/, -1/*int_scale*/);
        break;
      case cutlass::Distribution::Gaussian:
        dist.set_gaussian(0/*mean*/, 1/*stddev*/, -1/*int_scale*/);
        break;
      case cutlass::Distribution::Sequential:
        dist.set_sequential(0/*start*/, 1/*delta*/, -1/*int_scale*/);
        break;
      default:
        dist.set_gaussian(0/*mean*/, 1/*stddev*/, -1/*int_scale*/);
        return dist;
    }

    // Subsequent key-value pairs update the named field of the distribution struct.
    for (; it != values.end(); ++it) {
      // Integer scaling factor - if < 0, no integer rounding is performed.
      if ((it->first.compare("scale") == 0) && !it->second.empty()) {
        std::stringstream ss;
        ss << it->second;
        ss >> dist.int_scale;
        continue;  // next token
      }

      // Casts as integer without scaling
      if (it->first.compare("integer") == 0) {
        dist.int_scale = 0;
        continue;  // next token
      }

      // initialize other members
      for (int m = 0; members[m].label; ++m) {
        if (it->first == members[m].label && !it->second.empty()) {
          std::stringstream ss;
          ss << it->second;
          ss >> *(members[m].member);
        }
      }
    }

    return dist;
  }

  // Parses the command line
  void parse(cutlass::CommandLine const& cmd) {
    program_path = cmd.program_path;

    cmd.get_cmd_line_argument("help", help);
    cmd.get_cmd_line_argument("iterations", iterations);
    cmd.get_cmd_line_argument("warmup", warmup);
    cmd.get_cmd_line_argument("sms", sm_count);
    cmd.get_cmd_line_argument("device", device);
    cmd.get_cmd_line_argument("tolerance", tolerance);
    cmd.get_cmd_line_argument("nonzero_floor", nonzero_floor);
    cmd.get_cmd_line_argument("verify", verify);
    cmd.get_cmd_line_argument("verbose", verbose);
    cmd.get_cmd_line_argument("csv", csv);

    char raster_char = 'H';
    cmd.get_cmd_line_argument("raster", raster_char);

    if (std::toupper(raster_char) == 'N') {
      raster = RasterOrderOptions::AlongN;
    }
    else if (std::toupper(raster_char) == 'M') {
      raster = RasterOrderOptions::AlongM;
    }
    else if (std::toupper(raster_char) == 'H') {
      raster = RasterOrderOptions::Heuristic;
    }
    else {
      OPTIONS_ERROR("Invalid raster order: " << raster_char);
    }

    cmd.get_cmd_line_argument("swizzle", swizzle, 1);

    dist_a = get_distribution(cmd, "adist");
    dist_b = get_distribution(cmd, "bdist");
    dist_c = get_distribution(cmd, "cdist");
  }
};

// Command line options parsing
struct GroupedGemmOptions : GemmOptionsBase<typename cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90GroupParams<int>::RasterOrderOptions> {

  using Base = GemmOptionsBase<typename cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90GroupParams<int>::RasterOrderOptions>;

  float alpha = FLT_MAX, beta = FLT_MAX;
  int groups = 10;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes;

  int align_m = 1;
  int align_n = 1;
  int align_k = 1;

  GroupedGemmOptions(
      int align_m = 1,
      int align_n = 1,
      int align_k = 1) 
    : Base(),
      align_m(align_m), 
      align_n(align_n),
      align_k(align_k) {}

  // Parses the command line
  void parse(cutlass::CommandLine const& cmd) {
    Base::parse(cmd);
    cmd.get_cmd_line_argument("alpha", alpha);
    cmd.get_cmd_line_argument("beta", beta);
    cmd.get_cmd_line_argument("groups", groups);
    randomize_problems(cmd);
  }

  template <class T>
  static T 
  read_value(std::string const& s, T default_ = {}) {
    std::istringstream ss(s);
    T val;
    ss >> val;
    if (ss.fail()) {
      val = default_;
    }
    return val;
  }

  // Read from command line a comma-separated list of ranges of the form <min>(:<max>)[,...].
  // If only <min> value specified, set <max>=<min>.
  // If arg_name no present on command line, use default_ as the only value.
  // If num_ranges >= 0, returns exactly num_ranges ranges, truncating the list or extending it
  // by repeating the last value, if necessary.
  template <class T>
  static std::vector<std::pair<T,T>> 
  get_int_ranges(
      cutlass::CommandLine const& cmd,
      char const* arg_name,
      std::pair<T,T> default_,
      int num_ranges = -1) {
    std::vector<std::pair<std::string,std::string>> input;
    cmd.get_cmd_line_argument_pairs(arg_name, input);

    std::vector<std::pair<T,T>> result;
    std::transform(input.begin(), input.end(), std::back_inserter(result),
      [](auto const& range_str) {
        T minval = read_value<T>(range_str.first);
        T maxval = read_value<T>(range_str.second, minval);
        return std::make_pair(minval, maxval);
      });

    if (result.empty()) {
      result.push_back(default_);
    }

    if (num_ranges >= 0) {
      auto last = result.back();
      for (int i = static_cast<int>(result.size()); i < num_ranges; ++i) {
        result.push_back(last);
      }
      result.resize(num_ranges);
    }

    return result;
  }

  void randomize_problems(cutlass::CommandLine const& cmd) {

    auto m_ranges = get_int_ranges<int>(cmd, "m", {10240, 10240}, groups); // Fixed "inter_size" in MoE
    auto n_ranges = get_int_ranges<int>(cmd, "n", { 1024,  2048}, groups); // Variable "token per expert" dimension in MoE, should always vary to test correctness
    auto k_ranges = get_int_ranges<int>(cmd, "k", { 8192,  8192}, groups); // Fixed "hidden_dim" in MoE

    auto random_size = [](auto vmin, auto vmax, auto align, int group, char const * name) {
      auto avmin = (vmin + align - 1) / align;
      auto avmax = vmax / align;
      if (avmax - avmin < 0) {
        OPTIONS_ERROR("Group " << group << ": problem size " << name << " range=[" << vmin << "," << vmax << "], must contain at least one multiple of " << align);
      }
      return align * ((rand() % (avmax - avmin + 1)) + avmin);
    };

    auto check_size = [](auto value, auto align, int group, char const * name) {
      if (value <= 0) {
        OPTIONS_ERROR("Group " << group << ": problem size " << name << "=" << value << ", must be positive");
      }
      if (value % align != 0) {
        OPTIONS_ERROR("Group " << group << ": problem size " << name << "=" << value << ", must be a multiple of " << align);
      }
    };
    
    problem_sizes.reserve(groups);
    for (int i = 0; i < groups; ++i) {
      int M = random_size(m_ranges[i].first, m_ranges[i].second, align_m, i, "M");
      int N = random_size(n_ranges[i].first, n_ranges[i].second, align_n, i, "N");
      int K = random_size(k_ranges[i].first, k_ranges[i].second, align_k, i, "K");
      check_size(M, align_m, i, "M");
      check_size(N, align_n, i, "N");
      check_size(K, align_k, i, "K");
      problem_sizes.emplace_back(M, N, K);
    }
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << program_path << "\n"
           "\n"
           "  Hopper Grouped Dual GEMM using with fused activation.\n"
           "\n"
           "Options:\n"
           "\n"
           "  --help                      Display this usage statement\n"
           "  --m=<int>(:<int>)[,...]     Set the M range of the GEMM for each group (last range used for remaining groups)\n"
           "  --n=<int>(:<int>)[,...]     Set the N range of the GEMM for each group (last range used for remaining groups)\n"
           "  --k=<int>(:<int>)[,...]     Set the K range of the GEMM for each group (last range used for remaining groups)\n"
           "  --groups=<int>              Set the number of individual GEMM problems for Grouped GEMM\n"
           "  --alpha=<f32>               Epilogue scalar alpha\n"
           "  --beta=<f32>                Epilogue scalar beta\n"
           "  --raster=<char>             CTA Rasterization direction (N for along N, M for along M, and H for heuristic)\n"
           "  --swizzle=<int>             CTA Rasterization swizzle\n"
           "  --warmup=<int>              Number of warmup iterations to perform\n"
           "  --iterations=<int>          Number of profiling iterations to perform\n"
           "  --verify=<bool>             Verification (correctness check) on/off\n"
           "  --verbose                   Verbose mode (output detailed verification result)\n"
           "  --sms                       Number of SMs to run the GEMMs on\n"
           "  --device                    Device index\n"
           "\n"
           "Any problem size range can be specifed as a pair <min>:<max> or a single integer (<min>=<max>) for a fixed size.\n"
           "\n"
           "Example:\n"
        << program_path << " --m=5120 --n=1024:2048 --k=4096 --groups=10 --alpha=1 --beta=0\n";

    return out;
  }

  /// Compute number of flops
  uint64_t total_flops() const {
    // Two flops per multiply-add
    return 2 * std::accumulate(problem_sizes.begin(), problem_sizes.end(), 0ULL,
                               [](uint64_t acc, auto p){ return acc + p.product(); });
  }
};

#undef OPTIONS_ERROR
