/***************************************************************************************************
 * Copyright (c) 2025 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include <iostream>

#include "cutlass/cutlass.h"
#include "cute/tensor.hpp"
#include "cute/atom/mma_atom.hpp"

#include "cutlass/numeric_types.h"

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/dispatch_policy.hpp"

#include "../../../common/cutlass_unit_test.h"

#include "../gemm_testbed_3x.hpp"

#if (defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED) || defined(CUTLASS_ARCH_MMA_SM121_SUPPORTED))

using namespace cute;

///////////////////////////////////////////////////////////////////////////////

// D = relu(alpha * accum + beta * C + per-col bias)
// C: bf16
// Bias: bf16
// Acc: fp32
// Scale (alpha, beta): fp32
// D: bf16
namespace kernel_1 {
  using ElementA = cutlass::float_e2m1_t;
  using ElementB = cutlass::float_e2m1_t;
  using ElementC = cutlass::bfloat16_t;
  using ElementD = cutlass::bfloat16_t;
  using ElementAccumulator = float;
  using ElementCompute = float;
  using ElementSF = cutlass::float_ue4m3_t;
  using ElementBias = cutlass::bfloat16_t;

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using LayoutD = cutlass::layout::ColumnMajor;

  using ElementPairA = cutlass::nv_float4_t<cutlass::float_e2m1_t>;
  using ElementPairB = cutlass::nv_float4_t<cutlass::float_e2m1_t>;

  static constexpr int AlignmentA = 16 * 8 / cutlass::sizeof_bits<ElementA>::value; // Align to 16 bytes.
  static constexpr int AlignmentB = 16 * 8 / cutlass::sizeof_bits<ElementB>::value; // Align to 16 bytes.
  static constexpr int AlignmentC = 128 / cutlass::sizeof_bits<ElementC>::value;
  static constexpr int AlignmentD = 128 / cutlass::sizeof_bits<ElementD>::value;

  using TileShape = Shape<_128,_128,_256>;
  using ClusterShape = Shape<_1,_1,_1>;

  using FusionOperation = cutlass::epilogue::fusion::LinCombPerColBiasEltAct<
      cutlass::epilogue::thread::ReLU, ElementD, ElementCompute, ElementBias, ElementAccumulator, ElementCompute>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm120, cutlass::arch::OpClassTensorOp,
      TileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementCompute,
      ElementC, LayoutC, AlignmentC,
      ElementD, LayoutD, AlignmentD,
      cutlass::epilogue::TmaWarpSpecializedCooperative,
      FusionOperation
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm120, cutlass::arch::OpClassBlockScaledTensorOp,
      ElementPairA, LayoutA, AlignmentA,
      ElementPairB, LayoutB, AlignmentB,
      ElementAccumulator,
      TileShape, ClusterShape,
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      cutlass::gemm::KernelTmaWarpSpecializedNvf4Sm120
    >::CollectiveOp;

  template <typename T>
  struct dummy {
    using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
        Shape<int,int,int,int>,
        CollectiveMainloop,
        CollectiveEpilogue>;
    using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  };
  using GemmKernel = typename dummy<void>::GemmKernel;
  using Gemm = typename dummy<void>::Gemm;


} // kernel_1

// D = gelu(alpha * accum + beta * C + per-col bias)
// C: bf16
// Bias: bf16
// Acc: fp32
// Scale (alpha, beta): fp32
// D: bf16
namespace kernel_2 {
  using ElementA = cutlass::float_e2m1_t;
  using ElementB = cutlass::float_e2m1_t;
  using ElementC = cutlass::bfloat16_t;
  using ElementD = cutlass::bfloat16_t;
  using ElementAccumulator = float;
  using ElementCompute = float;
  using ElementSF = cutlass::float_ue4m3_t;
  using ElementBias = cutlass::bfloat16_t;

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using LayoutD = cutlass::layout::ColumnMajor;

  using ElementPairA = cutlass::nv_float4_t<cutlass::float_e2m1_t>;
  using ElementPairB = cutlass::nv_float4_t<cutlass::float_e2m1_t>;

  static constexpr int AlignmentA = 16 * 8 / cutlass::sizeof_bits<ElementA>::value; // Align to 16 bytes.
  static constexpr int AlignmentB = 16 * 8 / cutlass::sizeof_bits<ElementB>::value; // Align to 16 bytes.
  static constexpr int AlignmentC = 128 / cutlass::sizeof_bits<ElementC>::value;
  static constexpr int AlignmentD = 128 / cutlass::sizeof_bits<ElementD>::value;

  using TileShape = Shape<_128,_128,_256>;
  using ClusterShape = Shape<_1,_1,_1>;

  using FusionOperation = cutlass::epilogue::fusion::LinCombPerColBiasEltAct<
      cutlass::epilogue::thread::GELU, ElementD, ElementCompute, ElementBias, ElementAccumulator, ElementCompute>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm120, cutlass::arch::OpClassTensorOp,
      TileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementCompute,
      ElementC, LayoutC, AlignmentC,
      ElementD, LayoutD, AlignmentD,
      cutlass::epilogue::TmaWarpSpecializedCooperative,
      FusionOperation
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm120, cutlass::arch::OpClassBlockScaledTensorOp,
      ElementPairA, LayoutA, AlignmentA,
      ElementPairB, LayoutB, AlignmentB,
      ElementAccumulator,
      TileShape, ClusterShape,
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      cutlass::gemm::KernelTmaWarpSpecializedNvf4Sm120
    >::CollectiveOp;

  template <typename T>
  struct dummy {
    using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
        Shape<int,int,int,int>,
        CollectiveMainloop,
        CollectiveEpilogue>;
    using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  };
  using GemmKernel = typename dummy<void>::GemmKernel;
  using Gemm = typename dummy<void>::Gemm;


} // kernel_2

// D = relu(alpha * accum + beta * C + per-row bias)
// C: bf16
// Bias: bf16
// Acc: fp32
// Scale (alpha, beta): fp32
// D: bf16
namespace kernel_3 {
  using ElementA = cutlass::float_e2m1_t;
  using ElementB = cutlass::float_e2m1_t;
  using ElementC = cutlass::bfloat16_t;
  using ElementD = cutlass::bfloat16_t;
  using ElementAccumulator = float;
  using ElementCompute = float;
  using ElementSF = cutlass::float_ue4m3_t;
  using ElementBias = cutlass::bfloat16_t;

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using ElementPairA = cutlass::nv_float4_t<cutlass::float_e2m1_t>;
  using ElementPairB = cutlass::nv_float4_t<cutlass::float_e2m1_t>;

  static constexpr int AlignmentA = 16 * 8 / cutlass::sizeof_bits<ElementA>::value; // Align to 16 bytes.
  static constexpr int AlignmentB = 16 * 8 / cutlass::sizeof_bits<ElementB>::value; // Align to 16 bytes.
  static constexpr int AlignmentC = 128 / cutlass::sizeof_bits<ElementC>::value;
  static constexpr int AlignmentD = 128 / cutlass::sizeof_bits<ElementD>::value;

  using TileShape = Shape<_128,_128,_256>;
  using ClusterShape = Shape<_1,_1,_1>;

  using FusionOperation = cutlass::epilogue::fusion::LinCombPerRowBiasEltAct<
      cutlass::epilogue::thread::ReLu, ElementD, ElementCompute, ElementBias, ElementAccumulator, ElementCompute>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm120, cutlass::arch::OpClassTensorOp,
      TileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementCompute,
      ElementC, LayoutC, AlignmentC,
      ElementD, LayoutD, AlignmentD,
      cutlass::epilogue::TmaWarpSpecializedCooperative,
      FusionOperation
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm120, cutlass::arch::OpClassBlockScaledTensorOp,
      ElementPairA, LayoutA, AlignmentA,
      ElementPairB, LayoutB, AlignmentB,
      ElementAccumulator,
      TileShape, ClusterShape,
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      cutlass::gemm::KernelTmaWarpSpecializedNvf4Sm120
    >::CollectiveOp;

  template <typename T>
  struct dummy {
    using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
        Shape<int,int,int,int>,
        CollectiveMainloop,
        CollectiveEpilogue>;
    using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  };
  using GemmKernel = typename dummy<void>::GemmKernel;
  using Gemm = typename dummy<void>::Gemm;


} // kernel_3

// Aux = alpha * accum + beta * C + per-row bias
// D = gelu(Aux)
// C: bf16
// Bias: bf16
// Acc: fp32
// Scale (alpha, beta): fp32
// D: bf16
namespace kernel_4 {
  using ElementA = cutlass::float_e2m1_t;
  using ElementB = cutlass::float_e2m1_t;
  using ElementC = cutlass::bfloat16_t;
  using ElementD = cutlass::bfloat16_t;
  using ElementAccumulator = float;
  using ElementCompute = float;
  using ElementSF = cutlass::float_ue4m3_t;
  using ElementBias = cutlass::bfloat16_t;
  using ElementAux = cutlass::bfloat16_t;

  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;
  using LayoutC = cutlass::layout::ColumnMajor;
  using LayoutD = cutlass::layout::ColumnMajor;

  using ElementPairA = cutlass::nv_float4_t<cutlass::float_e2m1_t>;
  using ElementPairB = cutlass::nv_float4_t<cutlass::float_e2m1_t>;

  static constexpr int AlignmentA = 16 * 8 / cutlass::sizeof_bits<ElementA>::value; // Align to 16 bytes.
  static constexpr int AlignmentB = 16 * 8 / cutlass::sizeof_bits<ElementB>::value; // Align to 16 bytes.
  static constexpr int AlignmentC = 128 / cutlass::sizeof_bits<ElementC>::value;
  static constexpr int AlignmentD = 128 / cutlass::sizeof_bits<ElementD>::value;

  using TileShape = Shape<_128,_128,_256>;
  using ClusterShape = Shape<_1,_1,_1>;

  using FusionOperation = cutlass::epilogue::fusion::LinCombPerRowBiasEltActAux<
                LayoutC, cutlass::epilogue::thread::GELU, ElementD, ElementCompute, ElementAux, ElementBias, ElementAccumulator, ElementCompute>;

  using CollectiveEpilogue = typename cutlass::epilogue::collective::CollectiveBuilder<
      cutlass::arch::Sm120, cutlass::arch::OpClassTensorOp,
      TileShape, ClusterShape,
      cutlass::epilogue::collective::EpilogueTileAuto,
      ElementAccumulator, ElementCompute,
      ElementC, LayoutC, AlignmentC,
      ElementD, LayoutD, AlignmentD,
      cutlass::epilogue::TmaWarpSpecializedCooperative,
      FusionOperation
    >::CollectiveOp;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm120, cutlass::arch::OpClassBlockScaledTensorOp,
      ElementPairA, LayoutA, AlignmentA,
      ElementPairB, LayoutB, AlignmentB,
      ElementAccumulator,
      TileShape, ClusterShape,
      cutlass::gemm::collective::StageCountAutoCarveout<static_cast<int>(sizeof(typename CollectiveEpilogue::SharedStorage))>,
      cutlass::gemm::KernelTmaWarpSpecializedNvf4Sm120
    >::CollectiveOp;

  template <typename T>
  struct dummy {
    using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
        Shape<int,int,int,int>,
        CollectiveMainloop,
        CollectiveEpilogue>;
    using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  };
  using GemmKernel = typename dummy<void>::GemmKernel;
  using Gemm = typename dummy<void>::Gemm;


} // kernel_4

// D = relu(alpha * accum + beta * C + per-col bias)
// C: bf16
// Bias: bf16
// Acc: fp32
// Scale (alpha, beta): fp32
// D: bf16
TEST(SM120_Device_Blockscaled_Gemm_fe2m1t_fe2m1n_bf16n_vs16_tensor_op_f32_f32_epilogue, 128x128x256_alpha_beta_per_col_bias_relu) {
  bool result = test::gemm::device::TestSmallFusion<kernel_1::Gemm, false, false>(1.0, 0.5);
  EXPECT_TRUE(result);
}

// D = gelu(alpha * accum + beta * C + per-col bias)
// C: bf16
// Bias: bf16
// Acc: fp32
// Scale (alpha, beta): fp32
// D: bf16
TEST(SM120_Device_Blockscaled_Gemm_fe2m1t_fe2m1n_bf16n_vs16_tensor_op_f32_f32_epilogue, 128x128x256_alpha_beta_per_col_bias_gelu) {
  bool result = test::gemm::device::TestSmallFusion<kernel_2::Gemm, false, false>(1.0, 0.5);
  EXPECT_TRUE(result);
}

// D = relu(alpha * accum + beta * C + per-row bias)
// C: bf16
// Bias: bf16
// Acc: fp32
// Scale (alpha, beta): fp32
// D: bf16
TEST(SM120_Device_Blockscaled_Gemm_fe2m1t_fe2m1n_bf16n_vs16_tensor_op_f32_f32_epilogue, 128x128x256_alpha_beta_per_row_bias_relu) {
  bool result = test::gemm::device::TestSmallFusion<kernel_3::Gemm, false, false>(1.0, 0.5);
  EXPECT_TRUE(result);
}

// Aux = alpha * accum + beta * C + per-row bias
// D = gelu(Aux)
// C: bf16
// Bias: bf16
// Acc: fp32
// Scale (alpha, beta): fp32
// D: bf16
TEST(SM120_Device_Blockscaled_Gemm_fe2m1t_fe2m1n_bf16n_vs16_tensor_op_f32_f32_epilogue, 128x128x256_alpha_beta_per_row_bias_gelu) {
  bool result = test::gemm::device::TestSmallFusion<kernel_4::Gemm, false, false>(1.0, 0.5);
  EXPECT_TRUE(result);
}

#endif // (defined(CUTLASS_ARCH_MMA_SM120_SUPPORTED) || defined(CUTLASS_ARCH_MMA_SM121_SUPPORTED))
