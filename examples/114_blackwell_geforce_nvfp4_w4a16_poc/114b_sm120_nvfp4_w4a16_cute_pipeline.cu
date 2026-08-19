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
    \brief CuTe and cp.async NVFP4 W4A16 GEMM proof of concept for SM120/SM121.
*/

#include <cuda_runtime.h>

#include "cute/arch/copy_sm75.hpp"
#include "cute/arch/copy_sm80.hpp"
#include "cute/arch/mma_sm80.hpp"
#include "cute/tensor.hpp"
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

constexpr int kTileM = 64;
constexpr int kTileN = 32;
constexpr int kTileK = 64;
constexpr int kScaleBlockK = 16;
constexpr int kScaleBlocksPerTile = kTileK / kScaleBlockK;
constexpr int kStages = 2;
constexpr int kThreads = 128;

using ElementA = cutlass::half_t;
using ElementB = cutlass::float_e2m1_t;
using ElementScale = cutlass::float_ue4m3_t;
using ElementC = float;
using PackedPair = cutlass::Array<ElementB, 2>;

using TiledMma = cute::TiledMMA<
  cute::MMA_Atom<cute::SM80_16x8x16_F32F16F16F32_TN>,
  cute::Layout<
    cute::Shape<cute::_2, cute::_2, cute::_1>,
    cute::Stride<cute::_1, cute::_2, cute::_0>>,
  cute::Tile<cute::_64, cute::_32, cute::_64>>;

// CUTLASS's Ampere K=64 LDSM-compatible XOR swizzle. Each eight-half K vector remains contiguous
// for 128-bit cp.async while adjacent row groups rotate through shared-memory banks.
using SmemLayoutAtom = decltype(cute::composition(
  cute::Swizzle<3, 3, 3>{},
  cute::Layout<
    cute::Shape<cute::_8, cute::_64>,
    cute::Stride<cute::_64, cute::_1>>{}));
using SmemLayoutA = decltype(cute::tile_to_shape(
  SmemLayoutAtom{},
  cute::make_shape(cute::Int<kTileM>{}, cute::Int<kTileK>{})));
using SmemLayoutB = decltype(cute::tile_to_shape(
  SmemLayoutAtom{},
  cute::make_shape(cute::Int<kTileN>{}, cute::Int<kTileK>{})));

static_assert(sizeof(PackedPair) == 1, "Two E2M1 values must occupy one byte");
static_assert(sizeof(ElementScale) == 1, "A UE4M3 scale must occupy one byte");
static_assert(sizeof(ElementA) == 2, "FP16 storage must occupy two bytes");
static_assert(kTileK % kScaleBlockK == 0, "A K tile must contain complete NVFP4 scale blocks");
static_assert(kTileK % 32 == 0, "Packed B tiles must support aligned 128-bit copies");
static_assert(kTileN % 4 == 0, "Scale tiles must support aligned 32-bit copies");

struct Options {
  int m = 128;
  int n = 128;
  int k = 512;
  int iterations = 100;
  bool verify = true;
  bool help = false;
};

struct SharedStorage {
  alignas(16) ElementA a[kStages][cute::cosize_v<SmemLayoutA>];
  alignas(16) uint8_t packed_b[kStages][kTileN * kTileK / 2];
  alignas(16) ElementScale scales_b[kStages][kScaleBlocksPerTile * kTileN];
  alignas(16) ElementA b[kStages][cute::cosize_v<SmemLayoutB>];
};

bool parse_positive_integer(char const* arg, char const* name, int& value) {
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
    else if (arg == "--no-verify") {
      options.verify = false;
    }
    else if (parse_positive_integer(argv[i], "m", options.m) ||
             parse_positive_integer(argv[i], "n", options.n) ||
             parse_positive_integer(argv[i], "k", options.k) ||
             parse_positive_integer(argv[i], "iterations", options.iterations)) {
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
    << "SM120/SM121 NVFP4 W4A16 CuTe pipeline proof of concept\n\n"
    << "Usage: " << executable
    << " [--m=<multiple of 64>] [--n=<multiple of 32>] [--k=<multiple of 64>]"
    << " [--iterations=<positive integer>] [--no-verify]\n";
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

CUTE_DEVICE void issue_async_stage(
    SharedStorage& storage,
    int stage,
    int tile_k,
    ElementA const* a,
    uint8_t const* packed_b,
    ElementScale const* scales_b,
    int row_base,
    int column_base,
    int n,
    int k) {

  int const thread = static_cast<int>(threadIdx.x);
  int const k_base = tile_k * kTileK;
  SmemLayoutA layout_a;

  // A tile: cooperatively move naturally aligned 16-byte vectors.
  constexpr int kAVectorsPerRow = kTileK / 8;
  constexpr int kAVectorCopies = kTileM * kAVectorsPerRow;
  for (int copy_linear = thread; copy_linear < kAVectorCopies; copy_linear += kThreads) {
    int const row = copy_linear / kAVectorsPerRow;
    int const vector = copy_linear % kAVectorsPerRow;
    auto const& source = *reinterpret_cast<cute::uint128_t const*>(
      a + (row_base + row) * k + k_base + vector * 8);
    auto& destination = *reinterpret_cast<cute::uint128_t*>(
      storage.a[stage] + layout_a(row, vector * 8));
    cute::SM80_CP_ASYNC_CACHEALWAYS<cute::uint128_t>::copy(source, destination);
  }

  // Packed B tile: move aligned 16-byte vectors from each output column.
  constexpr int kBPackedVectorsPerColumn = kTileK / 32;
  constexpr int kBPackedVectorCopies = kTileN * kBPackedVectorsPerColumn;
  for (int copy_linear = thread; copy_linear < kBPackedVectorCopies; copy_linear += kThreads) {
    int const column = copy_linear / kBPackedVectorsPerColumn;
    int const vector = copy_linear % kBPackedVectorsPerColumn;
    auto const& source = *reinterpret_cast<cute::uint128_t const*>(
      packed_b + (column_base + column) * (k / 2) + k_base / 2 + vector * 16);
    auto& destination = *reinterpret_cast<cute::uint128_t*>(
      storage.packed_b[stage] + column * (kTileK / 2) + vector * 16);
    cute::SM80_CP_ASYNC_CACHEALWAYS<cute::uint128_t>::copy(source, destination);
  }

  // Scales are K-block-major. Load all block-16 scale rows covered by this K tile.
  constexpr int kScaleVectorCopies = kScaleBlocksPerTile * kTileN / 4;
  if (thread < kScaleVectorCopies) {
    int const scale_block = thread / (kTileN / 4);
    int const vector = thread % (kTileN / 4);
    auto const& source = *reinterpret_cast<uint32_t const*>(
      scales_b + (tile_k * kScaleBlocksPerTile + scale_block) * n + column_base + vector * 4);
    auto& destination = *reinterpret_cast<uint32_t*>(
      storage.scales_b[stage] + scale_block * kTileN + vector * 4);
    cute::SM80_CP_ASYNC_CACHEALWAYS<uint32_t>::copy(source, destination);
  }

  cute::cp_async_fence();
}

CUTE_DEVICE void decode_weight_stage(SharedStorage& storage, int stage) {
  using WeightConverter = cutlass::NumericArrayConverter<
    ElementA, ElementB, 2, cutlass::FloatRoundStyle::round_to_nearest>;
  using ScaleConverter = cutlass::NumericConverter<
    ElementA, ElementScale, cutlass::FloatRoundStyle::round_to_nearest>;

  int const thread = static_cast<int>(threadIdx.x);
  constexpr int kPackedPairs = kTileN * kTileK / 2;
  SmemLayoutB layout_b;

  for (int pair_linear = thread; pair_linear < kPackedPairs; pair_linear += kThreads) {
    int const column = pair_linear / (kTileK / 2);
    int const pair_k = pair_linear % (kTileK / 2);

    PackedPair packed_pair;
    *reinterpret_cast<uint8_t*>(&packed_pair) = storage.packed_b[stage][pair_linear];
    auto converted_pair = WeightConverter::convert(packed_pair);
    int const scale_block = pair_k * 2 / kScaleBlockK;
    ElementA scale = ScaleConverter{}(
      storage.scales_b[stage][scale_block * kTileN + column]);

    storage.b[stage][layout_b(column, pair_k * 2)] = converted_pair[0] * scale;
    storage.b[stage][layout_b(column, pair_k * 2 + 1)] = converted_pair[1] * scale;
  }
}

__global__ void nvfp4_w4a16_cute_pipeline_kernel(
    ElementA const* a,
    uint8_t const* packed_b,
    ElementScale const* scales_b,
    ElementC* c,
    int n,
    int k) {

  int const row_base = static_cast<int>(blockIdx.y) * kTileM;
  int const column_base = static_cast<int>(blockIdx.x) * kTileN;
  int const tile_count = k / kTileK;
  __shared__ SharedStorage storage;

  TiledMma tiled_mma;
  auto thread_mma = tiled_mma.get_slice(threadIdx.x);
  auto output_layout = cute::make_layout(
    cute::make_shape(cute::Int<kTileM>{}, cute::Int<kTileN>{}),
    cute::make_stride(n, cute::_1{}));
  auto output = cute::make_tensor(
    cute::make_gmem_ptr(c + row_base * n + column_base), output_layout);
  auto thread_output = thread_mma.partition_C(output);
  auto accumulators = thread_mma.make_fragment_C(thread_output);
  cute::clear(accumulators);

  auto tiled_copy_a = cute::make_tiled_copy_A(
    cute::Copy_Atom<cute::SM75_U32x4_LDSM_N, ElementA>{}, thread_mma);
  auto thread_copy_a = tiled_copy_a.get_thread_slice(threadIdx.x);
  auto tiled_copy_b = cute::make_tiled_copy_B(
    cute::Copy_Atom<cute::SM75_U32x2_LDSM_N, ElementA>{}, thread_mma);
  auto thread_copy_b = tiled_copy_b.get_thread_slice(threadIdx.x);

  issue_async_stage(
    storage, 0, 0, a, packed_b, scales_b, row_base, column_base, n, k);
  if (tile_count > 1) {
    issue_async_stage(
      storage, 1, 1, a, packed_b, scales_b, row_base, column_base, n, k);
  }

  for (int tile_k = 0; tile_k < tile_count; ++tile_k) {
    int const stage = tile_k % kStages;
    if (tile_k + 1 < tile_count) {
      cute::cp_async_wait<1>();
    }
    else {
      cute::cp_async_wait<0>();
    }
    __syncthreads();

    decode_weight_stage(storage, stage);
    __syncthreads();

    auto shared_a = cute::make_tensor(cute::make_smem_ptr(storage.a[stage]), SmemLayoutA{});
    auto shared_b = cute::make_tensor(cute::make_smem_ptr(storage.b[stage]), SmemLayoutB{});

    auto fragment_a = thread_mma.partition_fragment_A(shared_a);
    auto fragment_b = thread_mma.partition_fragment_B(shared_b);
    auto copy_source_a = thread_copy_a.partition_S(shared_a);
    auto copy_source_b = thread_copy_b.partition_S(shared_b);
    auto copy_destination_a = thread_copy_a.retile_D(fragment_a);
    auto copy_destination_b = thread_copy_b.retile_D(fragment_b);
    cute::copy(tiled_copy_a, copy_source_a, copy_destination_a);
    cute::copy(tiled_copy_b, copy_source_b, copy_destination_b);
    cute::gemm(tiled_mma, fragment_a, fragment_b, accumulators);
    __syncthreads();

    int const next_tile = tile_k + kStages;
    if (next_tile < tile_count) {
      issue_async_stage(
        storage, stage, next_tile, a, packed_b, scales_b,
        row_base, column_base, n, k);
    }
  }

  cute::copy(accumulators, thread_output);
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

  for (int block_k = 0; block_k < options.k / kScaleBlockK; ++block_k) {
    for (int column = 0; column < options.n; ++column) {
      float requested_scale = scale_candidates[(column * 3 + block_k * 7) % 5];
      scales_b[block_k * options.n + column] = ElementScale(requested_scale);
    }
  }

  for (int column = 0; column < options.n; ++column) {
    for (int k_value = 0; k_value < options.k; k_value += 2) {
      ElementB low(weight_candidates[(column * 5 + k_value * 3) % 16]);
      ElementB high(weight_candidates[(column * 11 + (k_value + 1) * 7) % 16]);
      packed_b[column * (options.k / 2) + k_value / 2] =
        static_cast<uint8_t>((low.raw() & 0x0f) | ((high.raw() & 0x0f) << 4));

      float scale = static_cast<float>(
        scales_b[(k_value / kScaleBlockK) * options.n + column]);
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

void launch_kernel(
    Options const& options,
    ElementA const* a,
    uint8_t const* packed_b,
    ElementScale const* scales_b,
    ElementC* c) {
  dim3 block(kThreads);
  dim3 grid(options.n / kTileN, options.m / kTileM);
  nvfp4_w4a16_cute_pipeline_kernel<<<grid, block>>>(
    a, packed_b, scales_b, c, options.n, options.k);
}

bool benchmark_kernel(
    Options const& options,
    ElementA const* a,
    uint8_t const* packed_b,
    ElementScale const* scales_b,
    ElementC* c) {

  for (int i = 0; i < 10; ++i) {
    launch_kernel(options, a, packed_b, scales_b, c);
  }
  if (!check_cuda(cudaDeviceSynchronize(), "benchmark warmup")) {
    return false;
  }

  cudaEvent_t start = nullptr;
  cudaEvent_t stop = nullptr;
  if (!check_cuda(cudaEventCreate(&start), "cudaEventCreate(start)") ||
      !check_cuda(cudaEventCreate(&stop), "cudaEventCreate(stop)")) {
    if (start) cudaEventDestroy(start);
    if (stop) cudaEventDestroy(stop);
    return false;
  }

  bool passed = check_cuda(cudaEventRecord(start), "cudaEventRecord(start)");
  for (int i = 0; passed && i < options.iterations; ++i) {
    launch_kernel(options, a, packed_b, scales_b, c);
  }
  passed = passed && check_cuda(cudaEventRecord(stop), "cudaEventRecord(stop)");
  passed = passed && check_cuda(cudaEventSynchronize(stop), "cudaEventSynchronize(stop)");

  float elapsed_ms = 0.0f;
  passed = passed && check_cuda(cudaEventElapsedTime(&elapsed_ms, start, stop), "cudaEventElapsedTime");
  cudaEventDestroy(stop);
  cudaEventDestroy(start);
  if (!passed) {
    return false;
  }

  float average_ms = elapsed_ms / static_cast<float>(options.iterations);
  double operations = 2.0 * options.m * options.n * options.k;
  double tflops = operations / (static_cast<double>(average_ms) * 1.0e9);
  std::cout << std::fixed << std::setprecision(4)
            << "Kernel time: " << average_ms << " ms\n"
            << "Prototype throughput: " << tflops << " TFLOP/s\n";
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
    std::cerr << "M and K must be multiples of 64; N must be a multiple of 32.\n";
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
  size_t const scale_elements = static_cast<size_t>(options.n) * options.k / kScaleBlockK;
  size_t const c_elements = static_cast<size_t>(options.m) * options.n;

  std::vector<ElementA> host_a(a_elements);
  std::vector<uint8_t> host_packed_b(packed_b_bytes);
  std::vector<ElementScale> host_scales_b(scale_elements);
  std::vector<float> logical_b(static_cast<size_t>(options.k) * options.n);
  std::vector<float> host_c(c_elements, 0.0f);
  initialize_problem(options, host_a, host_packed_b, host_scales_b, logical_b);
  std::vector<float> reference;
  if (options.verify) {
    reference = reference_gemm(options, host_a, logical_b);
  }

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

  launch_kernel(
    options, device_a.get(), device_packed_b.get(), device_scales_b.get(), device_c.get());
  if (!check_cuda(cudaGetLastError(), "NVFP4 W4A16 CuTe kernel launch") ||
      !check_cuda(cudaDeviceSynchronize(), "NVFP4 W4A16 CuTe kernel execution")) {
    return EXIT_FAILURE;
  }
  if (options.verify && !device_c.copy_to(host_c)) {
    return EXIT_FAILURE;
  }

  std::cout << "Device: " << properties.name << " (SM" << properties.major << properties.minor << ")\n"
            << "Problem: " << options.m << " x " << options.n << " x " << options.k << "\n"
            << "CTA tile: " << kTileM << " x " << kTileN << " x " << kTileK
            << "; stages: " << kStages << "\n"
            << "Packed B: " << packed_b_bytes << " bytes; scales: " << scale_elements << " bytes\n";

  if (options.verify && !compare_results(host_c, reference)) {
    return EXIT_FAILURE;
  }
  if (!options.verify) {
    std::cout << "CPU verification: skipped\n";
  }
  if (!benchmark_kernel(
        options, device_a.get(), device_packed_b.get(), device_scales_b.get(), device_c.get())) {
    return EXIT_FAILURE;
  }

  std::cout << "PASSED: CuTe MMA with double-buffered async A/B/scale tile loading.\n"
            << "This remains a prototype; throughput is not a production performance claim.\n";
  return EXIT_SUCCESS;
}
