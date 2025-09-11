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
    \brief CUTLASS Intel BMG Grouped Gemm with mixed input types

  This example demonstrates how to dispatch a mixed precision GEMM (int8 and bfloat16 | half_t) on BMG, with
  optional dequantization. The GemmMode enum describes the 3 modes of operation:

  - ConvertOnly:                   Narrower type is simply converted to the wider type before MMA
  - ConvertAndScale:               Narrower type is converted to wider type, then scaled
  - ConvertAndScaleWithZeroPoint:  Narrower type is converted to wider type, scaled and offset

  - Requirements:
      - dequantization group size (options.g) must be multiple of k-block size
      - scales & zeros must be MN-major

  The MMA operation itself takes bfloat16 input for both A and B, and so the narrower type is first
  upcasted (inside the mainloop) prior to being passed into the MMA atom.

  Verification for this example is performed against a standard reference GEMM in the wider type.
  The narrow-type input data are upcasted (or dequantized) externally before executing the
  reference GEMM.

  Note: due to a bug in the IGC compiler, it's currently necessary to build this example with the
  following environment variable set (CMake handles this for AOT compilation; for JIT, please set
  this in your environment):

    export IGC_allowDecompose2DBlockFuncs=0

  To build & run this example (from your build dir):

    $ ninja 10_bmg_grouped_gemm_bf16_s8
    $ ./examples/sycl/10_bmg_grouped_gemm_mixed_dtype/10_bmg_grouped_gemm_bf16_s8
    $ ninja 10_bmg_grouped_gemm_f16_s8_tensorwise
    $ ./examples/sycl/10_bmg_grouped_gemm_mixed_dtype/10_bmg_grouped_gemm_f16_s8_tensorwise

  Call with `--help` for information about available options
*/

#include "bmg_grouped_gemm_mixed_dtype_runner.hpp"

///////////////////////////////////////////////////////////////////////////////////////////////////

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

  // The code section below describes datatype for input, output matrices and computation between
  // elements in input matrices.
  using ElementAccumulator = float;      // <- data type of accumulator
  using ElementComputeEpilogue = float;  // <- data type of epilogue operations
  using ElementInputA = cutlass::QUANT_TYPE;       // <- data type of elements in input matrix A
  using ElementInputB = cutlass::MMA_TYPE;         // <- data type of elements in input matrix B
  using ElementOutput = float;           // <- data type of elements in output matrix D

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using ElementZero = cutlass::MMA_TYPE;
  using ElementScale = cutlass::MMA_TYPE;
  using StrideScale = cute::Stride<_1, int64_t, int64_t>;
  using StrideZero = StrideScale;

  using GmemTiledCopyA = XE_2D_U8x32x32_LD_N;  // U8  (1-byte) block copy for A (narrower type)
  using GmemTiledCopyB = XE_2D_U16x32x32_LD_V; // U16 (2-byte) block copy for B (wider type)
  static_assert(sizeof(ElementInputA) == 1, "ElementA width must match GmemTiledCopyA U8");

  // Workgroup-level tile
  using TileShape = Shape<_256, _256, _32>;

  // Although this is a mixed type example, the actual MMA accepts bf16 input for both A and B:
  using TiledMma =                    // M=8,N=16,K=16, D=f32,A=bf16,B=bf16,C=f32
      typename TiledMMAHelper<MMA_Atom<typename helpers::MMAOp<cutlass::MMA_TYPE>::type>, Layout<TileShape>,
                                    Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>>::TiledMMA;

  constexpr int PipelineStages = 3; // prefetch 3 iters of data for A and B
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16GroupMixedPrecision<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16Group;

  // Default (Linear Combination) epilogue
  using EpilogueOp = cutlass::epilogue::fusion::LinearCombination<ElementOutput, ElementComputeEpilogue,
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
          XE_2D_U32x8x16_ST_N,
          void, void>;

  // Use the helpers to avoid template arg repetition
  using GemmAdapterBuilder = helpers::MixedGemmUniversalAdapterBuilder<ProblemShape, CollectiveEpilogue>;

  using MixedBuilderQuantA =
      helpers::MixedCollectiveMmaBuilder<GEMMDispatchPolicy, TileShape,
                                cutlass::gemm::TagToStrideA_t<LayoutA*>,
                                cutlass::gemm::TagToStrideB_t<LayoutB*>,
                                TiledMma, GmemTiledCopyA, GmemTiledCopyB>;

  using MixedBuilderQuantB =
      helpers::MixedCollectiveMmaBuilder<GEMMDispatchPolicy, TileShape,
                                cutlass::gemm::TagToStrideA_t<LayoutA*>,
                                cutlass::gemm::TagToStrideB_t<LayoutB*>,
                                TiledMma, GmemTiledCopyB, GmemTiledCopyA>;

  // A-narrow Mainloop & GemmUniversalAdapter
  using MainloopAConvertOnly =
      MixedBuilderQuantA::CollectiveMma<cute::tuple<ElementInputA>,
                                        ElementInputB>;
  using GemmAConvertOnly =
      GemmAdapterBuilder::GemmUniversalAdapter<MainloopAConvertOnly>;

  using MainloopAConvertAndScale = MixedBuilderQuantA::CollectiveMma<
      cute::tuple<ElementInputA, ElementScale, StrideScale*>, ElementInputB>;
  using GemmAConvertAndScale =
      GemmAdapterBuilder::GemmUniversalAdapter<MainloopAConvertAndScale>;

  using MainloopAConvertAndScaleWithZeroPoint =
      MixedBuilderQuantA::CollectiveMma<
          cute::tuple<ElementInputA, ElementScale, StrideScale*, ElementZero, StrideZero*>, ElementInputB>;
  using GemmAConvertAndScaleWithZeroPoint =
      GemmAdapterBuilder::GemmUniversalAdapter<
          MainloopAConvertAndScaleWithZeroPoint>;

  // B-narrow Mainloop & GemmUniversalAdapter
  using MainloopBConvertOnly =
      MixedBuilderQuantB::CollectiveMma<ElementInputB,
                                        cute::tuple<ElementInputA>>;
  using GemmBConvertOnly =
      GemmAdapterBuilder::GemmUniversalAdapter<MainloopBConvertOnly>;

  using MainloopBConvertAndScale = MixedBuilderQuantB::CollectiveMma<
      ElementInputB, cute::tuple<ElementInputA, ElementScale, StrideScale*>>;
  using GemmBConvertAndScale =
      GemmAdapterBuilder::GemmUniversalAdapter<MainloopBConvertAndScale>;

  using MainloopBConvertAndScaleWithZeroPoint =
      MixedBuilderQuantB::CollectiveMma<
          ElementInputB, cute::tuple<ElementInputA, ElementScale, StrideScale*, ElementZero, StrideZero*>>;
  using GemmBConvertAndScaleWithZeroPoint =
      GemmAdapterBuilder::GemmUniversalAdapter<
          MainloopBConvertAndScaleWithZeroPoint>;

  if(options.a_narrower){
    std::cout << "Setting A as narrower type" << std::endl;
    if(options.mode ==  GemmMode::ConvertOnly) {
      std::cout << "Running in ConvertOnly mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmAConvertOnly>{}.run(options, hw_info));
    } else if(options.mode == GemmMode::ConvertAndScale){
      std::cout << "Running in ConvertAndScale mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmAConvertAndScale>{}.run(options, hw_info));
    } else {
      std::cout << "Running in ConvertAndScaleWithZeroPoint mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmAConvertAndScaleWithZeroPoint>{}.run(options, hw_info));
    }
  } else {
    std::cout << "Setting B as narrower type" << std::endl;
    if(options.mode ==  GemmMode::ConvertOnly) {
      std::cout << "Running in ConvertOnly mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmBConvertOnly>{}.run(options, hw_info));
    } else if(options.mode == GemmMode::ConvertAndScale){
      std::cout << "Running in ConvertAndScale mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmBConvertAndScale>{}.run(options, hw_info));
    } else {
      std::cout << "Running in ConvertAndScaleWithZeroPoint mode." << std::endl;
      CUTLASS_CHECK(ExampleRunner<GemmBConvertAndScaleWithZeroPoint>{}.run(options, hw_info));
    }
  }

  return 0;
}
