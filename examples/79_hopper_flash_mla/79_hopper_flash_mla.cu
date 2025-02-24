/***************************************************************************************************
 * Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

/*! \file
    \brief A Hopper CUTLASS example for Flash MLA.
*/

#include <cassert>

#include "flash_fwd_mla_kernel.h"
#include "flash_mla.h"

#include <thrust/universal_vector.h>
#include <thrust/device_vector.h>
#include <thrust/host_vector.h>

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/distribution.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/tensor_norm.h"
#include "cutlass/util/reference/device/tensor_fill.h"

#include <cuda_runtime.h>

/////////////////////////////////////////////////////////////////////////////////////////////////

#define CUDA_CHECK(status)                                                                 \
    {                                                                                      \
        cudaError_t error = status;                                                       \
        if (error != cudaSuccess) {                                                       \
            std::cerr << "CUDA error: " << cudaGetErrorString(error) << " at " <<        \
                __FILE__ << ":" << __LINE__ << std::endl;                                 \
            exit(EXIT_FAILURE);                                                           \
        }                                                                                 \
    }

/////////////////////////////////////////////////////////////////////////////////////////////////
/// Testbed utility types
/////////////////////////////////////////////////////////////////////////////////////////////////

// Command line options parsing
struct Options {

  bool help;

  int iterations;
  int b, s, h_q, s_q;
  int h_kv, d, dv;
  float softmax_scale;
  bool varlen;
  bool causal;

  static constexpr int block_size = 64;

  Options():
    help(false),
    b(128), s(4096), h_q(16), s_q(1),
    h_kv(1), d(576), dv(512),
    varlen(false),
    causal(true),
    iterations(10)
  { }

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    cmd.get_cmd_line_argument("b", b);
    cmd.get_cmd_line_argument("s", s);
    cmd.get_cmd_line_argument("h_q", h_q);
    cmd.get_cmd_line_argument("s_q", s_q);
    cmd.get_cmd_line_argument("h_kv", h_kv);
    cmd.get_cmd_line_argument("d", d);
    cmd.get_cmd_line_argument("dv", dv);

    if (cmd.check_cmd_line_flag("varlen")) {
      varlen = true;
    }

    cmd.get_cmd_line_argument("iterations", iterations);

    softmax_scale = 1 / std::sqrt(d);
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "79_hopper_flash_mla\n\n"
      << "  Hopper Flash MLA kernel.\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --b=<int>                   Sets the batch size\n"
      << "  --s=<int>                   Sets the sequence length\n"
      << "  --h_q=<int>                 Sets the number of heads\n"
      << "  --s_q=<int>                 Sets the sequence length of the query\n"
      << "  --varlen                    Sets the varlen as true or false\n"
      << "  --iterations=<int>          Number of profiling iterations to perform.\n\n";

    return out;
  }

  /// TOOD:Compute performance in GFLOP/s
  double gflops(double runtime_s) const
  {
    // Two flops per multiply-add
    // uint64_t flop = uint64_t(2) * m * n * k;
    // double gflop = double(flop) / double(1.0e9);
    // return gflop / runtime_s;
  }
};

/// Helper to initialize a block of device data
template <typename Element>
static void
initialize_values(
    thrust::universal_vector<Element>& dst_ptr,
    cutlass::Distribution::Kind dist_kind,
    uint64_t seed,
    Element var = Element(1.f)) {
  if (cutlass::Distribution::Uniform == dist_kind) {
    int scope = 2;
    cutlass::reference::host::BlockFillRandomUniform(
        dst_ptr.data().get(), dst_ptr.size(), seed, scope, -scope, 0);
  }
  else if (cutlass::Distribution::AllZeros == dist_kind) {
    cutlass::reference::host::BlockFillRandomUniform(
        dst_ptr.data().get(), dst_ptr.size(), seed, 0, 0, 0);
  }
  else if (cutlass::Distribution::AllOnes == dist_kind) {
    cutlass::reference::host::BlockFillRandomUniform(
        dst_ptr.data().get(), dst_ptr.size(), seed, 1, 1, 0);
  } 
  else if (cutlass::Distribution::Gaussian == dist_kind) {
    cutlass::reference::device::BlockFillRandomGaussian(
      dst_ptr.data().get(), dst_ptr.size(), seed, (Element) 0, var);
  }
  else if (cutlass::Distribution::Sequential == dist_kind) {
    cutlass::reference::host::BlockFillSequential(dst_ptr.data().get(), dst_ptr.size());
  }
  else {
    std::cerr << "Invalid distribution kind!\n.";
    exit(1);
  }
}

void initialize_varlen(thrust::universal_vector<int32_t>& block_C, const Options &options) {
  
  block_C.resize(options.b);

  std::vector<int32_t> cache_seqlens(options.b, options.s);

  std::random_device rd;
  std::mt19937 gen(rd());

  std::normal_distribution<float> distribution(options.s, options.s / 2.0f);

  for (int i = 0; i < options.b; ++i) {
    if (options.varlen) {
      float random_length = distribution(gen);
      cache_seqlens[i] = std::max(static_cast<int32_t>(random_length), options.s_q);
    } else {
      cache_seqlens[i] = options.s;
    }
  }

  cutlass::DeviceAllocation<int32_t> d_cache_seqlens(options.b);
  CUDA_CHECK(cudaMemcpy(
      block_C.data().get(),
      cache_seqlens.data(),
      options.b * sizeof(int32_t),
      cudaMemcpyHostToDevice
  ));
}

auto initialize_metadata(
  thrust::universal_vector<int32_t> &block_C,
  thrust::universal_vector<int32_t> &block_MD, thrust::universal_vector<int32_t> &block_S,
  int& num_sm_parts,
  const Options &options) {

  // This should match the logic in the MLA kernel.
  static constexpr int block_size_m = 64;
  static constexpr int block_size_n = 64;
  static constexpr int fixed_overhead_num_blocks = 5;
  
  cudaDeviceProp props;
  int current_device;
  CUDA_CHECK(cudaGetDevice(&current_device));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device));

  auto batch_size = options.b;
  int sm_count = props.multiProcessorCount;
  num_sm_parts = sm_count / options.h_kv / cutlass::ceil_div(options.h_kv, block_size_m);

  block_MD.resize(num_sm_parts * TileSchedulerMetaDataSize);
  block_S.resize(num_sm_parts);

  Mla_metadata_params params{};
  params.seqlens_k_ptr = block_C.data().get();
  params.tile_scheduler_metadata_ptr = block_MD.data().get();
  params.num_splits_ptr = block_S.data().get();
  params.batch_size = batch_size;
  params.block_size_n = block_size_n;
  params.fixed_overhead_num_blocks = fixed_overhead_num_blocks;
  params.num_sm_parts = num_sm_parts;

  cudaStream_t stream{nullptr};

  get_mla_metadata_func(params, stream);
}

using Element = cutlass::bfloat16_t;
using ElementAcc = float;

thrust::universal_vector<Element> block_Q;     // query
thrust::universal_vector<Element> block_K;     // blocked key
thrust::universal_vector<int32_t> block_T;     // block table
thrust::universal_vector<int32_t> block_C;     // cache seqlens
// TODO: block_V is not used in the example
// thrust::universal_vector<Element> block_V;     // dv
thrust::universal_vector<int32_t> block_MD;    // mla metadata
thrust::universal_vector<int32_t> block_S;     // num splits
thrust::universal_vector<ElementAcc> block_O;    // output
thrust::universal_vector<ElementAcc> block_LSE;  // lse

/// Initialize operands to be used in the GEMM and reference GEMM
void initialize(
  const Options &options,
  int& total_blocks, int& blocks_per_seq, int& max_seqlen_pad, int& num_sm_parts,
  uint64_t seed = 2025) {

  initialize_varlen(block_C, options);
  
  thrust::device_ptr<int32_t> d_ptr(block_C.data().get());
  
  int64_t total_seqlens = thrust::reduce(d_ptr, d_ptr + options.b);
  float sum = static_cast<float>(total_seqlens);
  int32_t mean_seqlens = static_cast<int32_t>(sum / options.b);
  int32_t max_seqlen = thrust::reduce(d_ptr, d_ptr + options.b, 
                                      0, 
                                      thrust::maximum<int32_t>());
  max_seqlen_pad = ((max_seqlen + 255) / 256) * 256;

  blocks_per_seq = max_seqlen_pad / options.block_size;
  total_blocks = options.b * blocks_per_seq;

  block_Q.resize(options.b * options.s_q * options.h_q * options.d);
  block_T.resize(total_blocks);
  block_K.resize(total_blocks * options.block_size * options.h_kv * options.d);

  initialize_values(block_Q, cutlass::Distribution::Gaussian, seed + 1);
  initialize_values(block_T, cutlass::Distribution::Sequential, seed + 3);
  initialize_values(block_K, cutlass::Distribution::Gaussian, seed + 5);

  // TODO: Set the exceeding part to NaN

  initialize_metadata(block_C, block_MD, block_S, num_sm_parts, options);

  auto softmax_lse_size = (options.b + num_sm_parts) * options.s_q * options.h_q;
  auto out_accum_size = (options.b + num_sm_parts) * options.s_q * options.h_q * options.dv;

  block_LSE.resize(softmax_lse_size);
  block_O.resize(out_accum_size);
}

/// Execute a given example Flash MLA computation
int run(Options &options)
{
  cudaDeviceProp props;
  int current_device;
  CUDA_CHECK(cudaGetDevice(&current_device));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device));

  // TODO: use vcache which is None in the example

  auto& cache = block_K;
  auto batch_size = options.b;
  auto seqlen_q_ori = options.s_q;
  auto num_heads_ori = options.h_q;
  auto head_size = options.d;
  auto head_size_v = options.dv;
  auto num_heads_k = options.h_kv;
  int total_blocks, max_num_blocks_per_seq, page_block_size;
  int num_sm_parts;

  assert(head_size % 8 == 0);
  assert(head_size_v % 32 == 0);

  initialize(options, total_blocks, max_num_blocks_per_seq, page_block_size, num_sm_parts);

  assert(batch_size > 0);
  assert(num_heads_ori % num_heads_k == 0);

  bool is_causal = seqlen_q_ori == 1 ? false : options.causal;

  int ngroups = num_heads_ori / num_heads_k;
  int seqlen_q = seqlen_q_ori * ngroups;
  int num_heads = num_heads_k;

  cudaStream_t stream{nullptr};

  // set the parameters
  Flash_fwd_mla_params kernel_params{};

  kernel_params.b = options.b;
  kernel_params.seqlen_q = options.s_q;
  kernel_params.d = options.d;
  kernel_params.d_v = options.dv;
  kernel_params.h = options.h_q;
  kernel_params.h_h_k_ratio = num_heads_ori / num_heads_k;
  kernel_params.ngroups = ngroups;

  kernel_params.q_ptr = block_Q.data().get();
  kernel_params.k_ptr = block_K.data().get();
  // TODO: block_V is not used in the example
  kernel_params.v_ptr = block_K.data().get();
  kernel_params.o_ptr = block_O.data().get();
  kernel_params.softmax_lse_ptr = block_LSE.data().get();

  kernel_params.q_batch_stride = options.s_q * options.h_q * options.d;
  kernel_params.k_batch_stride = page_block_size * options.h_kv * options.d;
  kernel_params.v_batch_stride = page_block_size * options.h_kv * options.dv;
  kernel_params.o_batch_stride = options.s_q * options.h_q * options.dv;

  kernel_params.q_row_stride = options.h_q * options.d;
  kernel_params.k_row_stride = options.h_kv * options.d;
  kernel_params.v_row_stride = options.h_kv * options.dv;
  kernel_params.o_row_stride = options.h_q * options.dv;

  kernel_params.q_head_stride = options.d;
  kernel_params.k_head_stride = options.d;
  kernel_params.v_head_stride = options.dv;
  kernel_params.o_head_stride = options.dv; 

  kernel_params.block_table = block_T.data().get();
  kernel_params.block_table_batch_stride = max_num_blocks_per_seq;
  kernel_params.page_block_size = page_block_size;

  kernel_params.tile_scheduler_metadata_ptr = block_MD.data().get();
  kernel_params.num_splits_ptr = block_S.data().get(); 

  kernel_params.softmax_lseaccum_ptr = block_LSE.data().get();
  kernel_params.oaccum_ptr = block_O.data().get();

  kernel_params.is_causal = is_causal;
  kernel_params.scale_softmax = options.softmax_scale;
  kernel_params.scale_softmax_log2 = std::log2(options.softmax_scale);

  kernel_params.cu_seqlens_k = block_C.data().get();

  assert(head_size == 576);
  run_mha_fwd_splitkv_mla<cutlass::bfloat16_t, 576>(kernel_params, stream);

  // TODO: reference check
}

///////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc, char const **args) {

  // CUTLASS must be compiled with CUDA 12.0 Toolkit to run this example
  // and must have compute capability at least 100a.
  if (__CUDACC_VER_MAJOR__ < 12 || (__CUDACC_VER_MAJOR__ == 12 && __CUDACC_VER_MINOR__ < 8)) {
    std::cerr << "This example requires CUDA 12.8 or newer." << std::endl;
    // Returning zero so this test passes on older Toolkits. Its actions are no-op.
    return 0;
  }

  cudaDeviceProp props;
  int current_device_id;
  CUDA_CHECK(cudaGetDevice(&current_device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&props, current_device_id));
  cudaError_t error = cudaGetDeviceProperties(&props, 0);
  if (props.major != 9 || props.minor != 0) {
    std::cerr << "This example requires a GPU with compute capability 90)." << std::endl;
    return 0;
  }
  
  //
  // Parse options
  //

  Options options;

  options.parse(argc, args);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  //
  // Evaluate CUTLASS kernels
  //
  run(options);

  return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
