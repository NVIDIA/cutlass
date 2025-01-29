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
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/fusion/xe_callbacks.hpp"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "pvc_flash_attn_gemm_universal.hpp"
#include "pvc_flash_attn_epilogue.hpp"
#include "cutlass/util/GPU_Clock.hpp"
#include "cutlass/util/sycl_event_manager.hpp"

#include <cute/tensor.hpp>
#include <random>

#include "cutlass/util/command_line.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/packed_stride.hpp"
#include "cutlass/util/reference/device/gemm_complex.h"
#include "cutlass/util/reference/device/tensor_compare.h"
#include "../common.hpp"

using namespace cute;

// Command line options parsing
struct Options {

  bool help;
  bool error;
  bool is_causal;

  int batch, num_heads, seq_len, head_size, iterations;
  float softmax_scale;

  Options():
    help(false),
    error(false),
    is_causal(false),
    batch(32), num_heads(16), seq_len(512), head_size(128), iterations(100),
    softmax_scale(1.f)
  { }

  // Parses the command line
  void parse(int argc, char const **args) {
    cutlass::CommandLine cmd(argc, args);

    if (cmd.check_cmd_line_flag("help")) {
      help = true;
      return;
    }

    if (cmd.check_cmd_line_flag("is_causal")) {
      is_causal = true;
    }

    cmd.get_cmd_line_argument("batch", batch, 32);
    cmd.get_cmd_line_argument("num_heads", num_heads, 16);
    cmd.get_cmd_line_argument("seq_len", seq_len, 512);
    cmd.get_cmd_line_argument("head_size", head_size, 128);
    cmd.get_cmd_line_argument("iterations", iterations, 100);

    softmax_scale = 1 / sqrt(static_cast<float>(head_size));
  }

  /// Prints the usage statement.
  std::ostream & print_usage(std::ostream &out) const {

    out << "PVC Flash Attention v2 Example\n\n"
      << "Options:\n\n"
      << "  --help                      If specified, displays this usage statement\n\n"
      << "  --is_causal                 Apply Causal Mask to the output of first Matmul\n"
      << "  --batch=<int>               Sets the Batch Size of the Multi-Head Self Attention module\n"
      << "  --num_heads=<int>           Sets the Number of Attention Heads of the Multi-Head Self Attention module\n"
      << "  --seq_len=<int>             Sets the Sequence length of the Multi-Head Self Attention module\n"
      << "  --head_size=<int>           Sets the Attention Head dimension of the Multi-Head Self Attention module\n"
      << "  --iterations=<int>          Iterations\n\n";

    return out;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////


  using LayoutQ = cutlass::layout::RowMajor;
  using LayoutK = cutlass::layout::ColumnMajor;
  using LayoutV = cutlass::layout::RowMajor;
  using LayoutO = cutlass::layout::RowMajor;
  using LayoutLSE = cutlass::layout::RowMajor;

template <
  class GemmKernel
>
struct ExampleRunner {

  using StrideQ = typename GemmKernel::StrideQ;
  using StrideK = typename GemmKernel::StrideK;
  using StrideV = typename GemmKernel::StrideV;
  using StrideO = typename GemmKernel::StrideO;

  using ElementQ = typename GemmKernel::ElementQ;
  using ElementK = typename GemmKernel::ElementK;
  using ElementV = typename GemmKernel::ElementV;
  using ElementAcc = typename GemmKernel::ElementAccumulator;

  using CollectiveEpilogue = typename GemmKernel::CollectiveEpilogue;
  using ElementOutput = typename CollectiveEpilogue::ElementOutput;
  using ElementCompute = typename CollectiveEpilogue::ElementCompute;
  using ElementAccumulator = typename CollectiveEpilogue::ElementAccumulator;

  using ProblemShapeType = typename GemmKernel::ProblemShape;

  //
  // Data members
  //

  /// Initialization
  StrideQ stride_Q;
  StrideK stride_K;
  StrideV stride_V;
  StrideO stride_O;
  uint64_t seed = 0;

  cutlass::DeviceAllocation<ElementQ> block_Q;
  cutlass::DeviceAllocation<ElementK> block_K;
  cutlass::DeviceAllocation<ElementV> block_V;
  cutlass::DeviceAllocation<ElementOutput> block_O;
  cutlass::DeviceAllocation<ElementOutput> block_lse;
  cutlass::DeviceAllocation<ElementOutput> block_ref_O;

  //
  // Methods
  //

  bool verify(const ProblemShapeType& problem_size, bool is_causal) {
    auto [batch, num_heads, seq_len, head_size] = problem_size;

    int batch_size = batch * num_heads;

    // loop over the batch dimension to compute the output
    // to avoid the risk of running out of device memory
    for(int b = 0, offset = 0; b < batch_size; b++, offset += seq_len * head_size) {

      cutlass::DeviceAllocation<ElementOutput> block_S;
      block_S.reset(seq_len * seq_len);

      cutlass::TensorRef ref_Q(block_Q.get() + offset, LayoutQ::packed({seq_len, head_size}));
      cutlass::TensorRef ref_K(block_K.get() + offset, LayoutK::packed({head_size, seq_len}));
      cutlass::TensorRef ref_V(block_V.get() + offset, LayoutV::packed({seq_len, head_size}));
      cutlass::TensorRef ref_S(block_S.get(), LayoutQ::packed({seq_len, seq_len}));
      cutlass::TensorRef ref_O(block_ref_O.get() + offset, LayoutO::packed({seq_len, head_size}));

      cutlass::reference::device::GemmComplex(
            {seq_len, seq_len, head_size},
            1.f,
            ref_Q,
            cutlass::ComplexTransform::kNone,
            ref_K,
            cutlass::ComplexTransform::kNone,
            0.f,
            ref_S,
            ref_S,
            ElementAccumulator(0),
            1,     // batch_count
            seq_len * head_size, // batch_stride_Q
            seq_len * head_size, // batch_stride_K
            seq_len * seq_len, // batch_stride_S
            seq_len * seq_len  // batch_stride_S
          );

      syclcompat::wait();

      std::vector<ElementOutput> host_S(seq_len * seq_len);
      syclcompat::memcpy<ElementOutput>(host_S.data(), block_S.get(), host_S.size());
      syclcompat::wait();

      // delete this memory as it is no longer needed
      block_S.reset();

      if(is_causal) {
        // apply mask to S
        for (int row = 0; row < seq_len; row++) {
          for (int col = 0; col < seq_len; col++) {
            if (col > row)
              host_S[col + row * seq_len] = -INFINITY;
          }
        }
      }

      // compute max element per row of S
      std::vector<ElementOutput> max_vec(seq_len, -INFINITY);
      for (int row = 0; row < seq_len; row++) {
        int idx = row * seq_len;
        int max_idx = row;
        max_vec[max_idx] = host_S[idx++];
        for (int col = 1; col < seq_len; col++, idx++) {
          if (max_vec[max_idx] < host_S[idx])
            max_vec[max_idx] = host_S[idx];
        }
      }

      // compute exp of S
      for (int row = 0; row < seq_len; row++) {
        int idx = row * seq_len;
        int max_idx = row;
        for (int col = 0; col < seq_len; col++, idx++) {
          host_S[idx] = expf((host_S[idx] - max_vec[max_idx]) / sqrt(static_cast<ElementOutput>((head_size))));
        }
      }

      // compute sum per row of S
      std::vector<ElementOutput> sum_vec(seq_len, ElementOutput{0});
      for (int row = 0; row < seq_len; row++) {
        int idx = row * seq_len;
        int sum_idx = row;
        for (int col = 0; col < seq_len; col++, idx++) {
          sum_vec[sum_idx] += host_S[idx];
        }

        //scale each row with the sum to compute softmax
        idx = row * seq_len;
        sum_idx = row;
        for (int col = 0; col < seq_len; col++, idx++) {
          host_S[idx] /= sum_vec[sum_idx];
        }
      }

      std::vector<ElementV> host_P(host_S.size());
      for(int p = 0; p < host_P.size(); p++) host_P[p] = static_cast<ElementV>(host_S[p]);

      cutlass::DeviceAllocation<ElementV> block_P;
      block_P.reset(host_P.size());

      syclcompat::memcpy<ElementV>(block_P.get(), host_P.data(), host_P.size());
      syclcompat::wait();

      cutlass::TensorRef ref_P(block_P.get(), LayoutQ::packed({seq_len, seq_len}));

      cutlass::reference::device::GemmComplex(
            {seq_len, head_size, seq_len},
            1.f,
            ref_P,
            cutlass::ComplexTransform::kNone,
            ref_V,
            cutlass::ComplexTransform::kNone,
            0.f,
            ref_O,
            ref_O,
            ElementAccumulator(0),
            1,     // batch_count
            seq_len * seq_len, // batch_stride_P
            seq_len * head_size, // batch_stride_V
            seq_len * head_size, // batch_stride_O
            seq_len * head_size  // batch_stride_O
          );

      syclcompat::wait();
      // delete this memory as it is no longer needed
      block_P.reset();

    }

    syclcompat::wait();

    // Check if output from CUTLASS kernel and reference kernel are equal or not
    bool passed = cutlass::reference::device::BlockCompareRelativelyEqual(
      block_ref_O.get(), block_O.get(), block_O.size(), 0.5f, 0.5f);

    return passed;
  }

  /// Initialize operands to be used in the GEMM and reference GEMM
  void initialize(const ProblemShapeType& problem_size) {
    // auto problem_shape = cute::append<4>(problem_size, 1);
    auto [batch, num_heads, seq_len, head_size] = problem_size;

    stride_Q = cutlass::make_cute_packed_stride(StrideQ{}, cute::make_shape(seq_len, head_size, batch * num_heads));
    stride_K = cutlass::make_cute_packed_stride(StrideK{}, cute::make_shape(seq_len, head_size, batch * num_heads));
    stride_V = cutlass::make_cute_packed_stride(StrideV{}, cute::make_shape(head_size, seq_len, batch * num_heads));
    stride_O = cutlass::make_cute_packed_stride(StrideO{}, cute::make_shape(seq_len, head_size, batch * num_heads));

    auto count = batch * num_heads * seq_len * head_size;
    block_Q.reset(count);
    block_K.reset(count);
    block_V.reset(count);
    block_O.reset(count);
    block_ref_O.reset(count);
    block_lse.reset(count);

    initialize_block(block_Q, seed + 2023);
    initialize_block(block_K, seed + 2022); //assume K is already transposed
    initialize_block(block_V, seed + 2021);

  }

  static void run(typename GemmKernel::Params params) {
    dim3 const block = GemmKernel::get_block_shape();
    dim3 const grid = GemmKernel::get_grid_shape(params);

    // configure smem size and carveout
    int smem_size = GemmKernel::SharedStorageSize;

    const auto sycl_block = syclcompat::dim3(block.x, block.y, block.z);
    const auto sycl_grid = syclcompat::dim3(grid.x, grid.y, grid.z);

    using namespace syclcompat::experimental;
    auto event = launch<cutlass::device_kernel<GemmKernel>>(launch_policy{
      sycl_grid, sycl_block, local_mem_size{static_cast<std::size_t>(smem_size)}, 
      kernel_properties{sycl_exp::sub_group_size<GemmKernel::DispatchPolicy::SubgroupSize>}
    }, params);

    EventManager::getInstance().addEvent(event);
  }

  void run(const Options& options, const cutlass::KernelHardwareInfo& hw_info) {
    ProblemShapeType problem_size = ProblemShapeType{options.batch, options.num_heads, options.seq_len, options.head_size};

    initialize(problem_size);

    typename GemmKernel::Arguments arguments{
      cutlass::gemm::GemmUniversalMode::kGemm,
      problem_size,
      {block_Q.get(), stride_Q, block_K.get(), stride_K, block_V.get(), stride_V},
      {options.softmax_scale},
      {block_O.get(), stride_O, block_lse.get()},
      hw_info
    };

    // GemmKernel gemm_op;

    size_t workspace_size = GemmKernel::get_workspace_size(arguments);
    cutlass::device_memory::allocation<uint8_t> workspace(workspace_size);

    GemmKernel::can_implement(arguments);

    // Initialize the workspace
    auto status = GemmKernel::initialize_workspace(arguments, workspace.get());
    if (status != cutlass::Status::kSuccess) {
      return;
    }

    typename GemmKernel::Params params = GemmKernel::to_underlying_arguments(arguments, workspace.get());

    // Run the GEMM
    run(params);

    syclcompat::wait();

    // Verify that the result is correct
    bool passed =  verify(problem_size, options.is_causal);
    std::cout << "Disposition: " << (passed ? "Passed" : "Failed") << std::endl;

     if (passed && options.iterations > 0) 
     {
        GPU_Clock timer;
        timer.start();
        for (int i = 0; i < options.iterations; ++i) {
          run(params);
        }
        syclcompat::wait();

        float cute_time = timer.seconds() / options.iterations;
        double flops_qk = 2.0 * options.batch * options.num_heads * options.seq_len * options.seq_len * options.head_size;
        double flops_pv = 2.0 * options.batch * options.num_heads * options.seq_len * options.head_size * options.seq_len;
        double tflops = ((flops_qk + flops_pv) * 1e-12)/cute_time;
        double gbps = options.batch * options.num_heads * (options.seq_len * options.head_size + options.seq_len * options.head_size) * 2 * 2 * (1e-9) / (cute_time);
        std::cout << "Problem Size: " << options.batch << 'x' << options.num_heads << 'x' << options.seq_len << 'x' << options.head_size << std::endl;
        printf("Cutlass Flash Attention Performance:   %4.3f  GB/s   ,    %4.3f  TFlop/s   ,   %6.4f  ms\n", gbps, tflops, cute_time * 1000);    
      } 
      
    return;
  }

};

int main(int argc, const char** argv)
{
  //
  // Parse options
  //

  Options options;

  options.parse(argc, argv);

  if (options.help) {
    options.print_usage(std::cout) << std::endl;
    return 0;
  }

  if (options.error) {
    std::cerr << "Aborting execution." << std::endl;
    return -1;
  }

  //
  // Run examples
  //

  // The KernelHardwareInfo struct holds the number of EUs on the GPU with a given device ID. This
  // information is used by the underlying kernel.
  cutlass::KernelHardwareInfo hw_info;

  // Change device_id to another value if you are running on a machine with multiple GPUs and wish
  // to use a GPU other than that with device ID 0.
  hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  bool passed;

  // The code section below describes datatype for input, output matrices and computation between
  // elements in input matrices.
  using ElementAccumulator = float;                   // <- data type of accumulator
  using ElementComputeEpilogue = float;  // <- data type of epilogue operations
  using ElementInputQ = bfloat16_t;                        // <- data type of elements in input matrix A
  using ElementInputKV = bfloat16_t;                        // <- data type of elements in input matrix B
  using ElementOutput = float;                        // <- data type of elements in output matrix D

  // Workgroup-level tile
  using TileShape = Shape<_128, _64, _32>;

  using TiledMma =
      TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
               Layout<Shape<_4, _2, _1>, Stride<_2, _1, _0>>,
               Tile<Layout<Shape<_8, _4, _4>, Stride<_1, _32, _8>>,
                    Layout<Shape<_16, _2, _2>, Stride<_1, _32, _16>>, _32>>;

  constexpr int PipelineStages = 2;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelPVC<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelPVCEpilogue;

  using CollectiveEpilogue = cutlass::epilogue::collective::CollectiveEpilogueAttention<
          EpilogueDispatchPolicy,
          TileShape,
          ElementAccumulator,
          cutlass::gemm::TagToStrideC_t<LayoutO>,
          ElementOutput,
          XE_2D_U32x8x16_ST_N>;

  if(options.is_causal) {
    using GmemTiledCopyQ = XE_2D_U16x32x32_LD_N;
    using GmemTiledCopyK = XE_2D_U16x16x16_LD_T;
    using GmemTiledCopyV = XE_2D_U16x16x32_LD_V;
    // Mainloop
    using CollectiveMainloop = cutlass::gemm::collective::CollectiveMmaAttention<
            GEMMDispatchPolicy,
            TileShape,
            ElementInputQ,
            cutlass::gemm::TagToStrideA_t<LayoutQ>,
            ElementInputKV,
            cutlass::gemm::TagToStrideB_t<LayoutK>,
            ElementInputKV,
            cutlass::gemm::TagToStrideB_t<LayoutV>,
            TiledMma,
            GmemTiledCopyQ,  // Q
            GmemTiledCopyK,  // K
            GmemTiledCopyV,  // V,
            true
    >;

    using GemmKernel = cutlass::gemm::kernel::GemmUniversalAttention<
    Shape<int, int, int, int>,
    CollectiveMainloop,
    CollectiveEpilogue
    >;

    ExampleRunner<GemmKernel> runner;

    runner.run(options, hw_info);
  } else {
    using GmemTiledCopyQ = XE_2D_U16x32x32_LD_N;
    using GmemTiledCopyK = XE_2D_U16x16x16_LD_T;
    using GmemTiledCopyV = XE_2D_U16x16x32_LD_V;
    // Mainloop
    using CollectiveMainloop = cutlass::gemm::collective::CollectiveMmaAttention<
            GEMMDispatchPolicy,
            TileShape,
            ElementInputQ,
            cutlass::gemm::TagToStrideA_t<LayoutQ>,
            ElementInputKV,
            cutlass::gemm::TagToStrideB_t<LayoutK>,
            ElementInputKV,
            cutlass::gemm::TagToStrideB_t<LayoutV>,
            TiledMma,
            GmemTiledCopyQ,  // Q
            GmemTiledCopyK,  // K
            GmemTiledCopyV,  // V,
            false
    >;

    using GemmKernel = cutlass::gemm::kernel::GemmUniversalAttention<
    Shape<int, int, int, int>,
    CollectiveMainloop,
    CollectiveEpilogue
    >;

    ExampleRunner<GemmKernel> runner;

    runner.run(options, hw_info);
  }

  return 0;
}
