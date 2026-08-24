/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 *modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *this list of conditions and the following disclaimer in the documentation
 *and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *may be used to endorse or promote products derived from this software without
 *specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 *FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 *SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 *OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **************************************************************************************************/

/*! \file
    \brief Example of the reusable SM120/SM121 NVFP4 W4A16 device API.
*/

#include <cuda_runtime.h>

#include "cutlass/float_subbyte.h"
#include "cutlass/gemm/device/sm120_nvfp4_w4a16_gemm.h"
#include "cutlass/half.h"
#include "cutlass/layout/nvfp4_w4a16.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <limits>
#include <string>
#include <vector>

namespace {

using ElementA = cutlass::half_t;
using ElementB = cutlass::float_e2m1_t;
using ElementScale = cutlass::float_ue4m3_t;
using ElementD = float;
using WeightLayout = cutlass::layout::Nvfp4W4a16Weight;

struct Options {
  int m = 128;
  int n = 128;
  int k = 512;
  int iterations = 100;
  bool verify = true;
  bool help = false;
};

bool check_cuda(cudaError_t status, char const *operation) {
  if (status == cudaSuccess) {
    return true;
  }
  std::cerr << operation << " failed: " << cudaGetErrorString(status) << "\n";
  return false;
}

bool parse_positive_integer(char const *arg, char const *name, int &value) {
  std::string const prefix = std::string("--") + name + "=";
  std::string const text(arg);
  if (text.rfind(prefix, 0) != 0) {
    return false;
  }
  char *end = nullptr;
  long const parsed = std::strtol(text.c_str() + prefix.size(), &end, 10);
  if (*end != '\0' || parsed <= 0 || parsed > std::numeric_limits<int>::max()) {
    std::cerr << "Invalid value for --" << name << ": "
              << text.substr(prefix.size()) << "\n";
    std::exit(EXIT_FAILURE);
  }
  value = static_cast<int>(parsed);
  return true;
}

Options parse_options(int argc, char const **argv) {
  Options options;
  for (int i = 1; i < argc; ++i) {
    std::string const arg(argv[i]);
    if (arg == "--help" || arg == "-h") {
      options.help = true;
    } else if (arg == "--no-verify") {
      options.verify = false;
    } else if (parse_positive_integer(argv[i], "m", options.m) ||
               parse_positive_integer(argv[i], "n", options.n) ||
               parse_positive_integer(argv[i], "k", options.k) ||
               parse_positive_integer(argv[i], "iterations",
                                      options.iterations)) {
    } else {
      std::cerr << "Unknown option: " << arg << "\n";
      std::exit(EXIT_FAILURE);
    }
  }
  return options;
}

void print_usage(char const *executable) {
  std::cout << "SM120/SM121 FP16 x block-scaled NVFP4 GEMM\n\n"
            << "Usage: " << executable
            << " [--m=<16 or multiple of 64>] [--n=<multiple of 128>]"
            << " [--k=<multiple of 64>] [--iterations=<positive integer>] "
               "[--no-verify]\n";
}

template <class T> class DeviceAllocation {
public:
  DeviceAllocation() = default;
  DeviceAllocation(DeviceAllocation const &) = delete;
  DeviceAllocation &operator=(DeviceAllocation const &) = delete;

  ~DeviceAllocation() {
    if (ptr_ != nullptr) {
      cudaFree(ptr_);
    }
  }

  bool allocate(size_t count) {
    count_ = count;
    return check_cuda(
        cudaMalloc(reinterpret_cast<void **>(&ptr_), count * sizeof(T)),
        "cudaMalloc");
  }

  bool copy_from(std::vector<T> const &source) {
    return source.size() == count_ &&
           check_cuda(cudaMemcpy(ptr_, source.data(), count_ * sizeof(T),
                                 cudaMemcpyHostToDevice),
                      "cudaMemcpy host to device");
  }

  bool copy_to(std::vector<T> &destination) const {
    return destination.size() == count_ &&
           check_cuda(cudaMemcpy(destination.data(), ptr_, count_ * sizeof(T),
                                 cudaMemcpyDeviceToHost),
                      "cudaMemcpy device to host");
  }

  T *get() const { return ptr_; }

private:
  T *ptr_ = nullptr;
  size_t count_ = 0;
};

float fp16_product(float lhs, float rhs) {
  ElementA const lhs_half(lhs);
  ElementA const rhs_half(rhs);
  return static_cast<float>(lhs_half * rhs_half);
}

void initialize_problem(Options const &options, std::vector<ElementA> &a,
                        std::vector<uint8_t> &packed_b,
                        std::vector<ElementScale> &scales_b,
                        std::vector<float> &logical_b) {
  for (int row = 0; row < options.m; ++row) {
    for (int k_value = 0; k_value < options.k; ++k_value) {
      int const centered = (row * 17 + k_value * 13 + 3) % 23 - 11;
      a[static_cast<size_t>(row) * options.k + k_value] =
          ElementA(static_cast<float>(centered) / 16.0f);
    }
  }

  constexpr float scale_candidates[] = {0.5f, 0.75f, 1.0f, 1.5f, 2.0f};
  constexpr float weight_candidates[] = {
      -6.0f, -4.0f, -3.0f, -2.0f, -1.5f, -1.0f, -0.5f, 0.0f,
      0.5f,  1.0f,  1.5f,  2.0f,  3.0f,  4.0f,  6.0f,  0.0f};

  int const scale_blocks =
      static_cast<int>(WeightLayout::scale_blocks(options.k));
  for (int column = 0; column < options.n; ++column) {
    for (int scale_block = 0; scale_block < scale_blocks; ++scale_block) {
      float const requested_scale =
          scale_candidates[(column * 3 + scale_block * 7) % 5];
      scales_b[WeightLayout::scale_offset(column, scale_block, scale_blocks)] =
          ElementScale(requested_scale);
    }
  }

  for (int column = 0; column < options.n; ++column) {
    for (int k_value = 0; k_value < options.k; k_value += 2) {
      ElementB const low(weight_candidates[(column * 5 + k_value * 3) % 16]);
      ElementB const high(
          weight_candidates[(column * 11 + (k_value + 1) * 7) % 16]);
      packed_b[WeightLayout::packed_value_offset(column, k_value, options.k)] =
          static_cast<uint8_t>((low.raw() & 0x0f) | ((high.raw() & 0x0f) << 4));

      int const scale_block = k_value / WeightLayout::kScaleGranularityK;
      float const scale =
          static_cast<float>(scales_b[WeightLayout::scale_offset(
              column, scale_block, scale_blocks)]);
      logical_b[static_cast<size_t>(k_value) * options.n + column] =
          fp16_product(static_cast<float>(low), scale);
      logical_b[static_cast<size_t>(k_value + 1) * options.n + column] =
          fp16_product(static_cast<float>(high), scale);
    }
  }
}

std::vector<float> reference_gemm(Options const &options,
                                  std::vector<ElementA> const &a,
                                  std::vector<float> const &b) {
  std::vector<float> reference(static_cast<size_t>(options.m) * options.n,
                               0.0f);
  for (int row = 0; row < options.m; ++row) {
    for (int column = 0; column < options.n; ++column) {
      float accumulator = 0.0f;
      for (int k_value = 0; k_value < options.k; ++k_value) {
        accumulator += static_cast<float>(
                           a[static_cast<size_t>(row) * options.k + k_value]) *
                       b[static_cast<size_t>(k_value) * options.n + column];
      }
      reference[static_cast<size_t>(row) * options.n + column] = accumulator;
    }
  }
  return reference;
}

bool compare_results(std::vector<float> const &result,
                     std::vector<float> const &reference) {
  constexpr float absolute_tolerance = 0.05f;
  constexpr float relative_tolerance = 0.002f;
  float max_absolute_error = 0.0f;
  float max_relative_error = 0.0f;
  size_t worst_index = 0;
  int failures = 0;

  for (size_t i = 0; i < result.size(); ++i) {
    float const absolute_error = std::abs(result[i] - reference[i]);
    float const relative_error =
        absolute_error / std::max(std::abs(reference[i]), 1.0f);
    if (absolute_error > max_absolute_error) {
      max_absolute_error = absolute_error;
      worst_index = i;
    }
    max_relative_error = std::max(max_relative_error, relative_error);
    if (absolute_error >
        absolute_tolerance + relative_tolerance * std::abs(reference[i])) {
      ++failures;
    }
  }

  std::cout << std::fixed << std::setprecision(6)
            << "Max absolute error: " << max_absolute_error << "\n"
            << "Max relative error: " << max_relative_error << "\n";
  if (failures != 0) {
    std::cerr << "FAILED: " << failures
              << " values exceeded tolerance; worst index " << worst_index
              << " has GPU=" << result[worst_index]
              << " CPU=" << reference[worst_index] << "\n";
    return false;
  }
  return true;
}

template <int TileM>
cutlass::Status launch_kernel_t(Options const &options, ElementA const *a,
                                uint8_t const *packed_b,
                                ElementScale const *scales_b, ElementD *d,
                                cudaStream_t stream = nullptr) {
  using Gemm = cutlass::gemm::device::Sm120Nvfp4W4a16Gemm<TileM>;
  using Mainloop = typename Gemm::CollectiveMainloop;
  typename Mainloop::StrideA stride_a{int64_t(options.k), cute::_1{},
                                      int64_t(options.m) * options.k};
  typename Mainloop::StrideB stride_b{int64_t(options.k), cute::_1{},
                                      int64_t(options.n) * options.k};
  auto scale_layout = WeightLayout::make_scale_layout(options.n, options.k);
  typename Gemm::GemmKernel::StrideC stride_c{int64_t(options.n), cute::_1{},
                                              int64_t(options.m) * options.n};
  typename Gemm::GemmKernel::StrideD stride_d{int64_t(options.n), cute::_1{},
                                              int64_t(options.m) * options.n};
  typename Gemm::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      {options.m, options.n, options.k, 1},
      {a, stride_a,
       reinterpret_cast<typename Mainloop::ElementB const *>(packed_b),
       stride_b, scales_b, scale_layout},
      {{1.0f, 0.0f}, nullptr, stride_c, d, stride_d},
      {}};
  return Gemm{}(arguments, nullptr, stream);
}

cutlass::Status launch_kernel(Options const &options, ElementA const *a,
                              uint8_t const *packed_b,
                              ElementScale const *scales_b, ElementD *d,
                              cudaStream_t stream = nullptr) {
  return options.m == 16
             ? launch_kernel_t<16>(options, a, packed_b, scales_b, d, stream)
             : launch_kernel_t<64>(options, a, packed_b, scales_b, d, stream);
}

bool benchmark_kernel(Options const &options, ElementA const *a,
                      uint8_t const *packed_b, ElementScale const *scales_b,
                      ElementD *d) {
  for (int i = 0; i < 10; ++i) {
    if (launch_kernel(options, a, packed_b, scales_b, d) !=
        cutlass::Status::kSuccess) {
      return false;
    }
  }
  if (!check_cuda(cudaDeviceSynchronize(), "benchmark warmup")) {
    return false;
  }

  cudaEvent_t start = nullptr;
  cudaEvent_t stop = nullptr;
  if (!check_cuda(cudaEventCreate(&start), "cudaEventCreate(start)") ||
      !check_cuda(cudaEventCreate(&stop), "cudaEventCreate(stop)")) {
    return false;
  }
  bool passed = check_cuda(cudaEventRecord(start), "cudaEventRecord(start)");
  for (int i = 0; passed && i < options.iterations; ++i) {
    passed = launch_kernel(options, a, packed_b, scales_b, d) ==
             cutlass::Status::kSuccess;
  }
  passed = passed && check_cuda(cudaEventRecord(stop), "cudaEventRecord(stop)");
  passed = passed &&
           check_cuda(cudaEventSynchronize(stop), "cudaEventSynchronize(stop)");

  float elapsed_ms = 0.0f;
  passed = passed && check_cuda(cudaEventElapsedTime(&elapsed_ms, start, stop),
                                "cudaEventElapsedTime");
  cudaEventDestroy(stop);
  cudaEventDestroy(start);
  if (!passed) {
    return false;
  }

  float const average_ms = elapsed_ms / static_cast<float>(options.iterations);
  double const operations = 2.0 * options.m * options.n * options.k;
  double const tflops = operations / (static_cast<double>(average_ms) * 1.0e9);
  std::cout << std::fixed << std::setprecision(4)
            << "Kernel time: " << average_ms << " ms\n"
            << "Throughput: " << tflops << " TFLOP/s\n";
  return true;
}

} // namespace

int main(int argc, char const **argv) {
  Options const options = parse_options(argc, argv);
  if (options.help) {
    print_usage(argv[0]);
    return EXIT_SUCCESS;
  }
  if ((options.m != 16 && options.m % 64 != 0) || options.n % 128 != 0 ||
      options.k % 64 != 0) {
    std::cerr
        << "M must be 16 or a multiple of 64; N must be a multiple of 128; "
        << "K must be a multiple of 64.\n";
    return EXIT_FAILURE;
  }

  int device = 0;
  cudaDeviceProp properties{};
  if (!check_cuda(cudaGetDevice(&device), "cudaGetDevice") ||
      !check_cuda(cudaGetDeviceProperties(&properties, device),
                  "cudaGetDeviceProperties")) {
    return EXIT_FAILURE;
  }
  if (properties.major != 12 ||
      (properties.minor != 0 && properties.minor != 1)) {
    std::cout << "WAIVED: this example targets SM120/SM121; found SM"
              << properties.major << properties.minor << ".\n";
    return EXIT_SUCCESS;
  }

  size_t const a_elements = static_cast<size_t>(options.m) * options.k;
  size_t const packed_b_bytes =
      WeightLayout::packed_values_bytes(options.n, options.k);
  size_t const scale_elements =
      WeightLayout::scales_bytes(options.n, options.k);
  size_t const d_elements = static_cast<size_t>(options.m) * options.n;

  std::vector<ElementA> host_a(a_elements);
  std::vector<uint8_t> host_packed_b(packed_b_bytes);
  std::vector<ElementScale> host_scales_b(scale_elements);
  std::vector<float> logical_b(static_cast<size_t>(options.k) * options.n);
  std::vector<float> host_d(d_elements, 0.0f);
  initialize_problem(options, host_a, host_packed_b, host_scales_b, logical_b);
  std::vector<float> reference;
  if (options.verify) {
    reference = reference_gemm(options, host_a, logical_b);
  }

  DeviceAllocation<ElementA> device_a;
  DeviceAllocation<uint8_t> device_packed_b;
  DeviceAllocation<ElementScale> device_scales_b;
  DeviceAllocation<ElementD> device_d;
  if (!device_a.allocate(a_elements) ||
      !device_packed_b.allocate(packed_b_bytes) ||
      !device_scales_b.allocate(scale_elements) ||
      !device_d.allocate(d_elements) || !device_a.copy_from(host_a) ||
      !device_packed_b.copy_from(host_packed_b) ||
      !device_scales_b.copy_from(host_scales_b)) {
    return EXIT_FAILURE;
  }

  if (launch_kernel(options, device_a.get(), device_packed_b.get(),
                    device_scales_b.get(),
                    device_d.get()) != cutlass::Status::kSuccess ||
      !check_cuda(cudaDeviceSynchronize(), "NVFP4 W4A16 kernel execution")) {
    return EXIT_FAILURE;
  }
  if (options.verify && !device_d.copy_to(host_d)) {
    return EXIT_FAILURE;
  }

  std::cout << "Device: " << properties.name << " (SM" << properties.major
            << properties.minor << ")\n"
            << "Problem: " << options.m << " x " << options.n << " x "
            << options.k << "\n"
            << "CTA tile: " << (options.m == 16 ? 16 : 64) << " x 128 x 64\n"
            << "Packed values: " << packed_b_bytes
            << " bytes; scales: " << scale_elements << " bytes\n";

  if (options.verify && !compare_results(host_d, reference)) {
    return EXIT_FAILURE;
  }
  if (!benchmark_kernel(options, device_a.get(), device_packed_b.get(),
                        device_scales_b.get(), device_d.get())) {
    return EXIT_FAILURE;
  }

  std::cout << "PASSED\n";
  return EXIT_SUCCESS;
}
