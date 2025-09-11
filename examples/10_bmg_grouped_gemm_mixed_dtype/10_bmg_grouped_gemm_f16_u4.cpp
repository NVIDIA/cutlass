/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
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
    \brief Mixed Precision BMG Grouped Gemm Example

 This example demonstrates how to dispatch a mixed precision Grouped GEMM on BMG, with optional dequantization.
 The GemmMode enum describes the 3 modes of operation:

 - ConvertOnly: Narrower type is simply converted to the wider type before MMA
 - ConvertAndScale:   Narrower type is converted to wider type, then scaled
 - ConvertAndScaleWithZeroPoint:   Narrower type is converted to wider type, then scaled and shifted by zero point
 - Limitations:
    - group must be multiple of k-block size
    - scales & zeros must be MN-major

 Note: due to a bug in the IGC compiler, it's currently necessary to build this example with the following
 environment variable set:
   export IGC_allowDecompose2DBlockFuncs=0
 To build & run this example (from your build dir):

    $ ninja 10_bmg_grouped_gemm_f16_u4
    $ ./examples/sycl/10_bmg_grouped_gemm_mixed_dtype/10_bmg_grouped_gemm_f16_u4

  Call with `--help` for information about available options
*/

#include "bmg_grouped_gemm_mixed_dtype_runner.hpp"

int main(int argc, const char** argv) {
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

  // The KernelHardwareInfo struct holds the number of EUs on the GPU with a given device ID. This
  // information is used by the underlying kernel.
  cutlass::KernelHardwareInfo hw_info;

  // Change device_id to another value if you are running on a machine with multiple GPUs and wish
  // to use a GPU other than that with device ID 0.
  hw_info.sm_count = cutlass::KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);

  // The code section below describes datatype for input, output matrices and computation between
  // elements in input matrices.
  using ElementAccumulator = float;      // <- data type of accumulator
  using ElementComputeEpilogue = float;  // <- data type of epilogue operations
  using ElementInputA = uint4_t;         // <- data type of elements in input matrix A
  using ElementInputB = half_t;          // <- data type of elements in input matrix B
  using ElementOutput = half_t;          // <- data type of elements in output matrix D

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using ElementZero = int4_t;
  using ElementScale = half_t;

  using StrideScale = cute::Stride<_1, int64_t, int64_t>;
  using StrideZero = cute::Stride<_8, cute::Stride<_1, int64_t>, int64_t>; // int4_t zero point packed 8 elements along K dimension and then along N dimension

  using GmemTiledCopyA = XE_2D_U4x32x16_LD_T;
  using GmemTiledCopyB = XE_2D_U16x16x32_LD_N;

  // Workgroup-level tile
  using TileShape = Shape<_16, _64, _64>;

  using TiledMma =
      typename TiledMMAHelper<MMA_Atom<typename helpers::MMAOp<half_t>::type>, Layout<TileShape>,
                                    Layout<Shape<_1, _2, _1>, Stride<_2, _1, _0>>>::TiledMMA;

  constexpr int PipelineStages = 3;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16GroupMixedPrecision<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16Group;

  using EpilogueOp = cutlass::epilogue::fusion::LinearCombination<ElementAccumulator, ElementComputeEpilogue,
          ElementAccumulator, ElementAccumulator, cutlass::FloatRoundStyle::round_to_nearest>;

  using FusionCallBacks = cutlass::epilogue::fusion::FusionCallbacks<EpilogueDispatchPolicy, EpilogueOp, TileShape,
          decltype(tile_shape(TiledMma()))>;
  using CollectiveEpilogue = cutlass::epilogue::collective::CollectiveEpilogue<
          EpilogueDispatchPolicy,
          TileShape,
          ElementAccumulator,
          cutlass::gemm::TagToStrideC_t<LayoutC*>,
          ElementOutput,
          cutlass::gemm::TagToStrideC_t<LayoutD*>,
          FusionCallBacks,
          XE_2D_U32x8x16_LD_N,
          void, void,
          XE_2D_U16x8x16_ST_N,
          void, void>;

  // Use the helpers to avoid template arg repetition
  using GemmAdapterBuilder = typename helpers::MixedGemmUniversalAdapterBuilder<ProblemShape, CollectiveEpilogue>;

  if(options.a_narrower){
    // TODO: this feature not support now
    std::cout << "Not support setting A as narrower type for int4 now." << std::endl;
  } else {
    std::cout << "Setting B as narrower type" << std::endl;
    using MixedBuilderQuant = helpers::MixedCollectiveMmaBuilder<GEMMDispatchPolicy, TileShape,
                                  cutlass::gemm::TagToStrideA_t<LayoutA*>,
                                  cutlass::gemm::TagToStrideB_t<LayoutB*>,
                                  TiledMma, GmemTiledCopyB, GmemTiledCopyA>;
    if(options.mode ==  GemmMode::ConvertOnly) {
      std::cout << "Running in ConvertOnly mode." << std::endl;
      using MainloopConvertOnly = MixedBuilderQuant::template CollectiveMma<ElementInputB, cute::tuple<ElementInputA>>;
      using GemmConvertOnly = GemmAdapterBuilder::template GemmUniversalAdapter<MainloopConvertOnly>;
      CUTLASS_CHECK(ExampleRunner<GemmConvertOnly>{}.run(options, hw_info));
    }else if(options.mode == GemmMode::ConvertAndScale){
      std::cout << "Running in ConvertAndScale mode." << std::endl;
      using MainloopConvertAndScale = MixedBuilderQuant::template CollectiveMma<
            ElementInputB, cute::tuple<ElementInputA, ElementScale, StrideScale*>>;
      using GemmConvertAndScale = GemmAdapterBuilder::template GemmUniversalAdapter<MainloopConvertAndScale>;
      CUTLASS_CHECK(ExampleRunner<GemmConvertAndScale>{}.run(options, hw_info));
    }else{
      std::cout << "Running in ConvertAndScaleWithZeroPoint mode." << std::endl;
      using MainloopConvertAndScaleWithZeroPoint = MixedBuilderQuant::template CollectiveMma<
            ElementInputB, cute::tuple<ElementInputA, ElementScale, StrideScale*, ElementZero, StrideZero*>>;
      using GemmConvertAndScaleWithZeroPoint = GemmAdapterBuilder::template GemmUniversalAdapter<MainloopConvertAndScaleWithZeroPoint>;
      CUTLASS_CHECK(ExampleRunner<GemmConvertAndScaleWithZeroPoint>{}.run(options, hw_info));
    }
  }
}
