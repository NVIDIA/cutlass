/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/cutlass.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/util/command_line.h"
#include "cutlass/util/reference/device/tensor_fill.h"
#include "cutlass/util/reference/device/tensor_compare.h"

#include "cute/tensor.hpp"

#include <cuda.h>
#include <numeric>
#include "helper.h"

enum MixedDtypeGemmMode {
  ConvertOnly,
  ScaleOnly,
  ScaleWithZeroPoint
};

/// Command line options parsing
struct MixedDtypeOptions {

  bool help = false;

  float alpha = 1.0f;
  float beta = 0.0f;
  int iterations = 1000;
  int warmup = 1000;
  int mode = 1;
  int m = 5120, n = 4096, k = 4096;
  int g = 128;
  int l = 1;

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("m", m);
    cmd.get_cmd_line_argument("n", n);
    cmd.get_cmd_line_argument("k", k);
    cmd.get_cmd_line_argument("l", l);
    cmd.get_cmd_line_argument("g", g);
    cmd.get_cmd_line_argument("mode", mode);
    cmd.get_cmd_line_argument("alpha", alpha, 1.f);
    cmd.get_cmd_line_argument("beta", beta, 0.f);
    cmd.get_cmd_line_argument("iterations", iterations);
    cmd.get_cmd_line_argument("warmup", warmup);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "55_hopper_mixed_dtype_gemm\n\n"
      << "  Hopper Mixed Data Type GEMM using a Warp Specialized kernel.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --m=<int>                   Sets the M extent of the GEMM\n"
      << "  --n=<int>                   Sets the N extent of the GEMM\n"
      << "  --k=<int>                   Sets the K extent of the GEMM\n"
      << "  --l=<int>                   The number of independent gemm problems with mnk shape\n"
      << "  --g=<int>                   The size of each group for the scales and zeros. To broadcast a vector of scales or zeros, set the group size to K.\n"
      << "  --mode=<int>                The mode to run the gemm. 0 does (A @ B), 1 means A @ (scale * B), 2 means A @ (scale * B + zero-point).\n"
      << "  --alpha=<f32>               Epilogue scalar alpha\n"
      << "  --beta=<f32>                Epilogue scalar beta\n\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n"
      << "  --warmup=<int>              Number of warmup iterations to perform.\n\n";

    out
      << "\n\nExamples:\n\n"
      << "$ " << "55_hopper_mixed_dtype_gemm" << " --m=1024 --n=512 --k=1024 -g=1024 --l=10 --alpha=2 --mode=2 --beta=0.707 \n\n";

    return out;
  }

  /// Compute performance in GFLOP/s
  double gflops(double runtime_s) const
  {
    // Two flops per multiply-add
    uint64_t flop = uint64_t(2) * m * n * k * l;
    double gflop = double(flop) / double(1.0e9);
    return gflop / runtime_s;
  }
};

/// Result structure
struct MixedDtypeResult
{
  double avg_runtime_ms = 0.0;
  double gflops = 0.0;
  cutlass::Status status = cutlass::Status::kSuccess;
  cudaError_t error = cudaSuccess;
  bool passed = false;

};

/// Profiling Loop
template <class Gemm>
void mixed_dtype_profiling(
  Gemm& gemm,
  MixedDtypeOptions const& options,
  MixedDtypeResult& result) {

  if (options.iterations <= 0) return;

  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  std::vector<float> runtimes;
  runtimes.reserve(options.iterations);

  for (int iter = 0; iter < options.warmup + options.iterations; ++iter) {
    cudaEventRecord(start);
    CUTLASS_CHECK(gemm.run());
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    if (iter >= options.warmup) {
        float milliseconds = 0;
        cudaEventElapsedTime(&milliseconds, start, stop);
        runtimes.push_back(milliseconds);
    }
  }

  cudaEventDestroy(start);
  cudaEventDestroy(stop);

  // Compute average setup and runtime and GFLOPs.
  result.avg_runtime_ms = std::accumulate(runtimes.begin(), runtimes.end(), 0.0f) / runtimes.size();
  result.gflops = options.gflops(result.avg_runtime_ms / 1000.0);

  std::cout << "  Problem Size: " << options.m << 'x' << options.n << 'x' << options.k << 'x' << options.l << std::endl;
  std::cout << "  Avg runtime: " << result.avg_runtime_ms << " ms" << std::endl;
  std::cout << "  GFLOPS: " << result.gflops << std::endl;
  
}

/// Helpers to initialize a block of device data
template <class Element>
bool initialize_tensor(
  cutlass::DeviceAllocation<Element>& block,
  uint64_t seed = 2023) {

  double scope_max, scope_min;
  int bits_input = cutlass::sizeof_bits<Element>::value;
  int bits_output = cutlass::sizeof_bits<Element>::value;

  if (bits_input == 1) {
    scope_max = 2;
    scope_min = 0;
  }
  else if (bits_input <= 8) {
    scope_max = 2;
    scope_min = -2;
  }
  else if (bits_output == 16) {
    scope_max = 5;
    scope_min = -5;
  }
  else {
    scope_max = 8;
    scope_min = -8;
  }
  cutlass::reference::device::BlockFillRandomUniform(
      block.get(), block.size(), seed, Element(scope_max), Element(scope_min));

  return true;
}

template <typename Element>
bool initialize_quant_tensor(
  cutlass::DeviceAllocation<Element>& block,
  uint64_t seed = 2023) {
  
  float scope_min = float(cutlass::platform::numeric_limits<Element>::lowest());
  float scope_max = float(cutlass::platform::numeric_limits<Element>::max());

  cutlass::reference::device::BlockFillRandomUniform(
    block.get(), block.size(), seed, Element(scope_max), Element(scope_min));

  return true;
}

template <class Element>
bool initialize_scale(
  cutlass::DeviceAllocation<Element>& block, 
  MixedDtypeOptions const& options,
  uint64_t seed = 2023) {
  
  if (options.mode == MixedDtypeGemmMode::ConvertOnly) {
    // No scales, so just initialize with 1 so we can use the same kernel to dequantize the data.
    std::vector<Element> stage(block.size(), Element(1.0f));
    block.copy_from_host(stage.data());
  } 
  else {
    float elt_max_f = float(cutlass::platform::numeric_limits<Element>::max());
    const float max_dequant_val = 4.f;
    const float min_dequant_val = 0.5f;

    float scope_max(max_dequant_val / elt_max_f);
    float scope_min(min_dequant_val / elt_max_f);

    cutlass::reference::device::BlockFillRandomUniform(
      block.get(), block.size(), seed, Element(scope_max), Element(scope_min));
  }
  return true;
}

template <class Element>
bool initialize_zero(
  cutlass::DeviceAllocation<Element>& block,
  MixedDtypeOptions const& options,
  uint64_t seed = 2023) {
  
  if (options.mode == MixedDtypeGemmMode::ScaleWithZeroPoint) {
    cutlass::reference::device::BlockFillRandomUniform(
      block.get(), block.size(), seed, Element(2.0f), Element(-2.0f));
  } else {
    // No bias, so just initialize with 1 so we can use the same kernel to dequantize the data.
    std::vector<Element> stage(block.size(), Element(0.0f));
    block.copy_from_host(stage.data());
  }
  return true;
}

/// Dequantize the weights for verification

template <class QuantizedElement, 
          class DequantizedElement,
          class OperandLayout,
          class ElementScale,
          class ElementZero,
          class ScaleBroadCastLayout,
          class ThrLayout>
__global__ void dequantize_weight_kernel(DequantizedElement* dq_buffer,
                                         QuantizedElement const* q_buffer,
                                         OperandLayout const operand_layout,
                                         ElementScale const* scale_buffer,
                                         ElementZero const* zero_buffer,
                                         ScaleBroadCastLayout const broadcasted_scale_layout,
                                         ThrLayout thr_layout) {
  using namespace cute;

  // Represent the full tensors to gmem elements. 
  // These are expected to have shape [MN, K, L]
  cute::Tensor gmem_op_dq = cute::make_tensor(cute::make_gmem_ptr(dq_buffer), operand_layout);
  auto init_quantized_iterator = [&]() {
    if constexpr (cute::sizeof_bits_v<QuantizedElement> >= 8) {
      return cute::make_gmem_ptr(q_buffer);
    } else {
      return cute::subbyte_iterator<const QuantizedElement>(q_buffer);
    }
  };
  cute::Tensor gmem_op_q  = cute::make_tensor(init_quantized_iterator(), operand_layout);
  // While the scales are expected to have shape [MN, G, L] but with a stride to allow broadcasting
  // It is expected that K % G == 0
  cute::Tensor gmem_scale_broadcasted = cute::make_tensor(make_gmem_ptr(scale_buffer), broadcasted_scale_layout);
  cute::Tensor gmem_zero_broadcasted = cute::make_tensor(make_gmem_ptr(zero_buffer), broadcasted_scale_layout);

  // Assign 1 thread per element in the thread block
  auto blk_shape = make_shape(size<0>(thr_layout), _1{}, _1{}); // 
  auto blk_coord = make_coord(_, blockIdx.x, blockIdx.y);  // (MN, K, L)

  // Tile across the block
  auto gOp_dq = cute::local_tile(gmem_op_dq, blk_shape, blk_coord);
  auto gScale = cute::local_tile(gmem_scale_broadcasted, blk_shape, blk_coord);
  auto gZero  = cute::local_tile(gmem_zero_broadcasted,  blk_shape, blk_coord);
  auto gOp_q  = cute::local_tile(gmem_op_q, blk_shape, blk_coord);
  
  auto tOpDq_gOpDq = cute::local_partition(gOp_dq, thr_layout, threadIdx.x);
  auto tScale_gScale = cute::local_partition(gScale, thr_layout, threadIdx.x);
  auto tZero_gZero = cute::local_partition(gZero, thr_layout, threadIdx.x);
  auto tOpQ_gOpQ = cute::local_partition(gOp_q, thr_layout, threadIdx.x);

  // Make a fragment of registers to hold gmem loads
  cute::Tensor rmem_op_q = cute::make_fragment_like(tOpQ_gOpQ(_, _, _, 0));
  cute::Tensor rmem_scale = cute::make_fragment_like(tScale_gScale(_, _, _, 0));
  cute::Tensor rmem_zero = cute::make_fragment_like(tZero_gZero(_, _, _, 0));
  cute::Tensor rmem_op_dq = cute::make_fragment_like(tOpDq_gOpDq(_, _, _, 0));
  cute::Tensor rmem_op_scaled = cute::make_fragment_like<ElementScale>(rmem_op_dq);
  cute::Tensor rmem_zero_buf = cute::make_fragment_like<ElementScale>(rmem_zero);

  cute::Tensor pred_id = cute::make_identity_tensor(shape(operand_layout));
  auto pred_blk_tile = cute::local_tile(pred_id, blk_shape, blk_coord);
  auto pred_thr_partition = cute::local_partition(pred_blk_tile, thr_layout, threadIdx.x);

  const auto num_iters = cute::size<3>(tOpDq_gOpDq);
  
  for (int ii = 0; ii < num_iters; ++ii) {
    const auto thread_offset = cute::get<0>(pred_thr_partition(0, 0, 0, ii));
    if (thread_offset < cute::size<0>(operand_layout)) {
      cute::copy(tOpQ_gOpQ(_, _, _, ii), rmem_op_q);
      cute::copy(tScale_gScale(_, _, _, ii), rmem_scale);
      cute::copy(tZero_gZero(_, _, _, ii), rmem_zero);
      cute::transform(rmem_op_q, rmem_op_scaled, [] (const QuantizedElement& elt) { return ElementScale(elt); } );
      cute::transform(rmem_zero, rmem_zero_buf, [] (const ElementZero& elt) { return ElementScale(elt); } );
      cute::transform(rmem_op_scaled, rmem_scale, rmem_op_scaled, multiplies{});
      cute::transform(rmem_op_scaled, rmem_zero_buf, rmem_op_scaled, plus{});
      cute::transform(rmem_op_scaled, rmem_op_dq, [] (const ElementScale& elt) { return DequantizedElement(elt); } );
      cute::copy(rmem_op_dq, tOpDq_gOpDq(_, _, _, ii));
    }
  }
}

template <class QuantizedElement, 
          class DequantizedElement,
          class OperandLayout,
          class ElementScale,
          class ElementZero,
          class ScaleLayout>
void dequantize_weight(DequantizedElement* dq_buffer,
                       QuantizedElement const* q_buffer,
                       OperandLayout const operand_layout,
                       ElementScale const* scale_buffer,
                       ElementZero const* zero_buffer,
                       ScaleLayout const scale_layout,
                       int const group_size) {
  
  using namespace cute;

  constexpr int tpb = 128;
  auto thr_layout = make_layout(make_shape(Int<tpb>{}));

  const auto num_rows = get<0>(shape(operand_layout));
  const auto gemm_k = get<1>(shape(operand_layout));   // [MN, K, L]
  const auto batches = get<2>(shape(operand_layout));  // [MN, K, L]
  const auto scale_k = get<1>(shape(scale_layout));    // [MN, Scale_K, L]

  if (num_rows != size<0>(scale_layout)) {
    std::cerr << "Invalid first dimension for scales. Must match first dim for weights."
              << " But got shapes " << shape(operand_layout) << " " << shape(scale_layout) 
              << std::endl;
    exit(-1);
  }

  const auto scale_stride0 = get<0>(stride(scale_layout));
  const auto scale_stride1 = get<1>(stride(scale_layout));
  const auto scale_stride2 = get<2>(stride(scale_layout));

  auto scale_shape_bcast = make_shape(num_rows, make_shape(group_size, scale_k), batches);
  auto scale_stride_bcast = make_stride(scale_stride0, make_stride(0, scale_stride1), scale_stride2);
  auto scale_layout_bcast = make_layout(scale_shape_bcast, scale_stride_bcast);

  const auto blocks_x = gemm_k;
  const auto blocks_y = batches;

  dim3 blocks(blocks_x, blocks_y, 1);
  dequantize_weight_kernel<<<blocks, tpb>>>(dq_buffer, q_buffer, operand_layout, scale_buffer, zero_buffer, scale_layout_bcast, thr_layout);
  CUDA_CHECK(cudaDeviceSynchronize());
}
