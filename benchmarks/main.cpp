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

#include "cutlass/cutlass.h"
#include "cutlass/kernel_hardware_info.h"
#include "cutlass/util/command_line.h"

#include "benchmark_runner.hpp"
#if defined(SYCL_NVIDIA_TARGET) || !defined(CUTLASS_ENABLE_SYCL)
#include "ampere/benchmarks.hpp"
#elif defined(SYCL_INTEL_TARGET)
#include "pvc/benchmarks.hpp"
#include "pvc/flash_attention_v2/benchmarks.hpp"
#endif

#include <benchmark/benchmark.h>
#include <iostream>
#include <sstream>
#include <fstream>

///////////////////////////////////////////////////////////////////////////////////////////////////


// Command line options parsing
struct BenckmarkOptions {

  bool help;
  bool error;
  std::string config_file;

  BenckmarkOptions():
          help(false),
          error(false)
  { }

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("config_file", config_file);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "Benchmark\n\n"
        << "Options:\n\n"
        << "  --config_file               Configuration file\n\n";

    return out;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

template <typename BenchOptions>
auto benchmark_main(int argc, const char **argv) -> int {
  BenchOptions options;

  options.parse(argc, argv);

  if (options.error) {
    std::cerr << "Aborting execution." << std::endl;
    return -1;
  }

  cutlass::KernelHardwareInfo hw_info;
  hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);
  const auto benchmark_config = argv[0];
  auto runner = cutlass::benchmark::BenchmarkRegistry<BenchOptions>::get_benchmark(benchmark_config);

  std::stringstream benchmark_name;
  benchmark_name << benchmark_config << "/" << options.benchmark_name();
  ::benchmark::RegisterBenchmark(benchmark_name.str(), runner, options, hw_info)->UseManualTime();
  return 0;
}

int main(int argc, const char** argv) {

  BenckmarkOptions options;

  options.parse(argc, argv);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  if (options.config_file.empty()) {
    std::cerr << "Benchmark configuration file not found." << std::endl;
    options.error = true;
  }

  if (options.error) {
    std::cerr << "Aborting execution." << std::endl;
    return -1;
  }

  std::ifstream file(options.config_file);

  if (!file.is_open()) {
    std::cerr << "Failed to open configuration file: " << options.config_file << std::endl;
    return 1;
  }

  register_benchmarks();

  std::string line;
  while (std::getline(file, line)) {
    if (!line.empty() && line.find("#") != 0) {
      // Split the line into arguments
      std::istringstream iss(line);
      std::vector<std::string> args;
      std::string arg;

      while (iss >> arg) {
        args.push_back(arg);
      }

      // Prepare argc and argv for secondary_main
      int line_argc = static_cast<int>(args.size());
      std::vector<const char*> line_argv(line_argc);

      for (int i = 0; i < line_argc; ++i) {
        line_argv[i] = &args[i][0]; // Convert std::string to char*
      }

      std::string const& benchmark_config = line_argv.data()[0];

      // Call the secondary main function with the parsed arguments
      if(benchmark_config.find("Gemm") != std::string::npos) {
        benchmark_main<cutlass::benchmark::GEMMOptions>(line_argc, line_argv.data());
      } else {
#if defined SYCL_INTEL_TARGET
        benchmark_main<cutlass::benchmark::FMHAOptions>(line_argc, line_argv.data());
#endif
      }
    }
  }
  file.close();

  int argc_bm = 0;
  ::benchmark::SetDefaultTimeUnit(::benchmark::kMillisecond);
  ::benchmark::Initialize(&argc_bm, nullptr);

  ::benchmark::RunSpecifiedBenchmarks();
  ::benchmark::Shutdown();

  return 0;
}
