/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of
 * conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of
 * conditions and the following disclaimer in the documentation and/or other materials provided
 * with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to
 * endorse or promote products derived from this software without specific prior written
 * permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **************************************************************************************************/

/*! \file
    \brief Phase-1 NVFP4 W4A16 GEMM proof of concept for Blackwell GeForce GPUs.
*/

#include <cuda_runtime.h>
#include <mma.h>

#include "cutlass/array.h"
#include "cutlass/array_subbyte.h"
#include "cutlass/float_subbyte.h"
#include "cutlass/half.h"
#include "cutlass/numeric_conversion.h"

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

constexpr int kTileM = 16;
constexpr int kTileN = 16;
constexpr int kTileK = 16;
constexpr int kWarpSize = 32;

using ElementA = cutlass::half_t;
using ElementB = cutlass::float_e2m1_t;
using ElementScale = cutlass::float_ue4m3_t;
using ElementC = float;
using PackedPair = cutlass::Array<ElementB, 2>;

static_assert(sizeof(PackedPair) == 1, "Two E2M1 values must occupy one byte");
static_assert(sizeof(ElementScale) == 1, "A UE4M3 scale must occupy one byte");
static_assert(sizeof(ElementA) == sizeof(__half), "CUTLASS and CUDA FP16 storage must match");

struct Options {
  int m = 64;
  int n = 64;
  int k = 256;
  bool help = false;
};

bool parse_positive_multiple(char const* arg, char const* name, int& value) {
  std::string prefix = std::string("--") + name + "=";
  std::string text(arg);
  if (text.rfind(prefix, 0) != 0) {
    return false;
  }

  char* end = nullptr;
  long parsed = std::strtol(text.c_str() + prefix.size(), &end, 10);
  if (*end != '\0' || parsed <= 0 || parsed > std::numeric_limits<int>::max()) {
    std::cerr << "Invalid value for --" << name << ": " << text.substr(prefix.size()) << "\n";
    std::exit(EXIT_FAILURE);
  }
  value = static_cast<int>(parsed);
  return true;
}

Options parse_options(int argc, char const** argv) {
  Options options;
  for (int i = 1; i < argc; ++i) {
    std::string arg(argv[i]);
    if (arg == "--help" || arg == "-h") {
      options.help = true;
    }
    else if (parse_positive_multiple(argv[i], "m", options.m) ||
             parse_positive_multiple(argv[i], "n", options.n) ||
             parse_positive_multiple(argv[i], "k", options.k)) {
    }
    else {
      std::cerr << "Unknown option: " << arg << "\n";
      std::exit(EXIT_FAILURE);
    }
  }
  return options;
}

void print_usage(char const* executable) {
  std::cout
    << "SM120/SM121 NVFP4 W4A16 GEMM phase-1 proof of concept\n\n"
    << "Usage: " << executable << " [--m=<multiple of 16>] [--n=<multiple of 16>]"
    << " [--k=<multiple of 16>]\n";
}

bool check_cuda(cudaError_t status, char const* operation) {
  if (status == cudaSuccess) {
    return true;
  }
  std::cerr << operation << " failed: " << cudaGetErrorString(status) << "\n";
  return false;
}

template <typename T>
class DeviceAllocation {
public:
  DeviceAllocation() = default;
  DeviceAllocation(DeviceAllocation const&) = delete;
  DeviceAllocation& operator=(DeviceAllocation const&) = delete;

  ~DeviceAllocation() {
    if (ptr_) {
      cudaFree(ptr_);
    }
  }

  bool allocate(size_t count) {
    count_ = count;
    return check_cuda(cudaMalloc(reinterpret_cast<void**>(&ptr_), count * sizeof(T)), "cudaMalloc");
  }

  bool copy_from(std::vector<T> const& source) {
    if (source.size() != count_) {
      std::cerr << "Host/device allocation size mismatch\n";
      return false;
    }
    return check_cuda(
      cudaMemcpy(ptr_, source.data(), count_ * sizeof(T), cudaMemcpyHostToDevice),
      "cudaMemcpy host to device");
  }

  bool copy_to(std::vector<T>& destination) const {
    if (destination.size() != count_) {
      std::cerr << "Host/device allocation size mismatch\n";
      return false;
    }
    return check_cuda(
      cudaMemcpy(destination.data(), ptr_, count_ * sizeof(T), cudaMemcpyDeviceToHost),
      "cudaMemcpy device to host");
  }

  T* get() const { return ptr_; }

private:
  T* ptr_ = nullptr;
  size_t count_ = 0;
};

// B is logically KxN. Each output column stores K values contiguously, two E2M1 values per byte.
// Each UE4M3 scale applies to one consecutive group of 16 K values in one output column.
__global__ void nvfp4_w4a16_gemm_kernel(
    ElementA const* a,
    uint8_t const* packed_b,
    ElementScale const* scales_b,
    ElementC* c,
    int m,
    int n,
    int k) {

  int const lane = threadIdx.x;
  int const row_base = static_cast<int>(blockIdx.y) * kTileM;
  int const column_base = static_cast<int>(blockIdx.x) * kTileN;

  __shared__ __align__(16) ElementA shared_a[kTileM * kTileK];
  __shared__ __align__(16) ElementA shared_b[kTileK * kTileN];

  using namespace nvcuda;
  wmma::fragment<wmma::matrix_a, kTileM, kTileN, kTileK, __half, wmma::row_major> fragment_a;
  wmma::fragment<wmma::matrix_b, kTileM, kTileN, kTileK, __half, wmma::col_major> fragment_b;
  wmma::fragment<wmma::accumulator, kTileM, kTileN, kTileK, float> accumulator;
  wmma::fill_fragment(accumulator, 0.0f);

  using WeightConverter = cutlass::NumericArrayConverter<
    ElementA, ElementB, 2, cutlass::FloatRoundStyle::round_to_nearest>;
  using ScaleConverter = cutlass::NumericConverter<
    ElementA, ElementScale, cutlass::FloatRoundStyle::round_to_nearest>;

  for (int k_base = 0; k_base < k; k_base += kTileK) {
    for (int linear = lane; linear < kTileM * kTileK; linear += kWarpSize) {
      int const row = linear / kTileK;
      int const k_local = linear % kTileK;
      shared_a[linear] = a[(row_base + row) * k + k_base + k_local];
    }

    // A 16x16 B tile contains 128 packed bytes. Each lane expands four pairs.
    for (int pair_linear = lane; pair_linear < kTileN * (kTileK / 2); pair_linear += kWarpSize) {
      int const column_local = pair_linear / (kTileK / 2);
      int const pair_k = pair_linear % (kTileK / 2);
      int const column = column_base + column_local;
      int const packed_offset = column * (k / 2) + k_base / 2 + pair_k;
      int const scale_offset = column * (k / kTileK) + k_base / kTileK;

      PackedPair packed_pair;
      *reinterpret_cast<uint8_t*>(&packed_pair) = packed_b[packed_offset];
      auto converted_pair = WeightConverter::convert(packed_pair);
      ElementA scale = ScaleConverter{}(scales_b[scale_offset]);

      int const shared_offset = column_local * kTileK + 2 * pair_k;
      shared_b[shared_offset] = converted_pair[0] * scale;
      shared_b[shared_offset + 1] = converted_pair[1] * scale;
    }

    __syncwarp();
    wmma::load_matrix_sync(
      fragment_a, reinterpret_cast<__half const*>(shared_a), kTileK);
    wmma::load_matrix_sync(
      fragment_b, reinterpret_cast<__half const*>(shared_b), kTileK);
    wmma::mma_sync(accumulator, fragment_a, fragment_b, accumulator);
    __syncwarp();
  }

  wmma::store_matrix_sync(
    c + row_base * n + column_base, accumulator, n, wmma::mem_row_major);
}

float fp16_product(float lhs, float rhs) {
  ElementA lhs_half(lhs);
  ElementA rhs_half(rhs);
  return static_cast<float>(lhs_half * rhs_half);
}

void initialize_problem(
    Options const& options,
    std::vector<ElementA>& a,
    std::vector<uint8_t>& packed_b,
    std::vector<ElementScale>& scales_b,
    std::vector<float>& logical_b) {

  for (int row = 0; row < options.m; ++row) {
    for (int column = 0; column < options.k; ++column) {
      int centered = (row * 17 + column * 13 + 3) % 23 - 11;
      a[row * options.k + column] = ElementA(static_cast<float>(centered) / 16.0f);
    }
  }

  constexpr float scale_candidates[] = {0.5f, 0.75f, 1.0f, 1.5f, 2.0f};
  constexpr float weight_candidates[] = {
    -6.0f, -4.0f, -3.0f, -2.0f, -1.5f, -1.0f, -0.5f, 0.0f,
     0.5f,  1.0f,  1.5f,  2.0f,  3.0f,  4.0f,  6.0f, 0.0f
  };

  for (int column = 0; column < options.n; ++column) {
    for (int block_k = 0; block_k < options.k / kTileK; ++block_k) {
      float requested_scale = scale_candidates[(column * 3 + block_k * 7) % 5];
      scales_b[column * (options.k / kTileK) + block_k] = ElementScale(requested_scale);
    }

    for (int k_value = 0; k_value < options.k; k_value += 2) {
      ElementB low(weight_candidates[(column * 5 + k_value * 3) % 16]);
      ElementB high(weight_candidates[(column * 11 + (k_value + 1) * 7) % 16]);
      packed_b[column * (options.k / 2) + k_value / 2] =
        static_cast<uint8_t>((low.raw() & 0x0f) | ((high.raw() & 0x0f) << 4));

      float scale = static_cast<float>(
        scales_b[column * (options.k / kTileK) + k_value / kTileK]);
      logical_b[k_value * options.n + column] =
        fp16_product(static_cast<float>(low), scale);
      logical_b[(k_value + 1) * options.n + column] =
        fp16_product(static_cast<float>(high), scale);
    }
  }
}

std::vector<float> reference_gemm(
    Options const& options,
    std::vector<ElementA> const& a,
    std::vector<float> const& b) {

  std::vector<float> reference(static_cast<size_t>(options.m) * options.n, 0.0f);
  for (int row = 0; row < options.m; ++row) {
    for (int column = 0; column < options.n; ++column) {
      float accumulator = 0.0f;
      for (int k_value = 0; k_value < options.k; ++k_value) {
        accumulator += static_cast<float>(a[row * options.k + k_value]) *
                       b[k_value * options.n + column];
      }
      reference[row * options.n + column] = accumulator;
    }
  }
  return reference;
}

bool compare_results(std::vector<float> const& result, std::vector<float> const& reference) {
  constexpr float absolute_tolerance = 0.05f;
  constexpr float relative_tolerance = 0.002f;
  float max_absolute_error = 0.0f;
  float max_relative_error = 0.0f;
  size_t worst_index = 0;
  int failures = 0;

  for (size_t i = 0; i < result.size(); ++i) {
    float absolute_error = std::abs(result[i] - reference[i]);
    float relative_error = absolute_error / std::max(std::abs(reference[i]), 1.0f);
    if (absolute_error > max_absolute_error) {
      max_absolute_error = absolute_error;
      worst_index = i;
    }
    max_relative_error = std::max(max_relative_error, relative_error);
    if (absolute_error > absolute_tolerance + relative_tolerance * std::abs(reference[i])) {
      ++failures;
    }
  }

  std::cout << std::fixed << std::setprecision(6)
            << "Max absolute error: " << max_absolute_error << "\n"
            << "Max relative error: " << max_relative_error << "\n";
  if (failures != 0) {
    std::cerr << "FAILED: " << failures << " values exceeded tolerance; worst index "
              << worst_index << " has GPU=" << result[worst_index]
              << " CPU=" << reference[worst_index] << "\n";
    return false;
  }
  return true;
}

} // namespace

int main(int argc, char const** argv) {
  Options options = parse_options(argc, argv);
  if (options.help) {
    print_usage(argv[0]);
    return EXIT_SUCCESS;
  }
  if (options.m % kTileM != 0 || options.n % kTileN != 0 || options.k % kTileK != 0) {
    std::cerr << "M, N, and K must all be positive multiples of 16 in phase 1.\n";
    return EXIT_FAILURE;
  }

  int device = 0;
  cudaDeviceProp properties{};
  if (!check_cuda(cudaGetDevice(&device), "cudaGetDevice") ||
      !check_cuda(cudaGetDeviceProperties(&properties, device), "cudaGetDeviceProperties")) {
    return EXIT_FAILURE;
  }
  if (properties.major < 12) {
    std::cout << "WAIVED: this proof of concept targets SM120/SM121; found SM"
              << properties.major << properties.minor << ".\n";
    return EXIT_SUCCESS;
  }

  size_t const a_elements = static_cast<size_t>(options.m) * options.k;
  size_t const packed_b_bytes = static_cast<size_t>(options.n) * options.k / 2;
  size_t const scale_elements = static_cast<size_t>(options.n) * options.k / kTileK;
  size_t const c_elements = static_cast<size_t>(options.m) * options.n;

  std::vector<ElementA> host_a(a_elements);
  std::vector<uint8_t> host_packed_b(packed_b_bytes);
  std::vector<ElementScale> host_scales_b(scale_elements);
  std::vector<float> logical_b(static_cast<size_t>(options.k) * options.n);
  std::vector<float> host_c(c_elements, 0.0f);
  initialize_problem(options, host_a, host_packed_b, host_scales_b, logical_b);
  std::vector<float> reference = reference_gemm(options, host_a, logical_b);

  DeviceAllocation<ElementA> device_a;
  DeviceAllocation<uint8_t> device_packed_b;
  DeviceAllocation<ElementScale> device_scales_b;
  DeviceAllocation<ElementC> device_c;
  if (!device_a.allocate(a_elements) ||
      !device_packed_b.allocate(packed_b_bytes) ||
      !device_scales_b.allocate(scale_elements) ||
      !device_c.allocate(c_elements) ||
      !device_a.copy_from(host_a) ||
      !device_packed_b.copy_from(host_packed_b) ||
      !device_scales_b.copy_from(host_scales_b)) {
    return EXIT_FAILURE;
  }

  dim3 block(kWarpSize);
  dim3 grid(options.n / kTileN, options.m / kTileM);
  nvfp4_w4a16_gemm_kernel<<<grid, block>>>(
    device_a.get(), device_packed_b.get(), device_scales_b.get(), device_c.get(),
    options.m, options.n, options.k);
  if (!check_cuda(cudaGetLastError(), "NVFP4 W4A16 kernel launch") ||
      !check_cuda(cudaDeviceSynchronize(), "NVFP4 W4A16 kernel execution") ||
      !device_c.copy_to(host_c)) {
    return EXIT_FAILURE;
  }

  std::cout << "Device: " << properties.name << " (SM" << properties.major << properties.minor << ")\n"
            << "Problem: " << options.m << " x " << options.n << " x " << options.k << "\n"
            << "Packed B: " << packed_b_bytes << " bytes; scales: " << scale_elements << " bytes\n";

  if (!compare_results(host_c, reference)) {
    return EXIT_FAILURE;
  }

  std::cout << "PASSED: fused tile-local NVFP4 decode + FP16 MMA + FP32 accumulation.\n"
            << "Phase 1 is a correctness proof; it makes no performance claim.\n";
  return EXIT_SUCCESS;
}
