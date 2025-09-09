/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software CORPORATION & AFFILIATES. All rights reserved.
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

#include "cute/atom/mma_atom.hpp"
#include "cute/atom/copy_atom.hpp"

#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/arch/arch.h"
#include "cutlass/arch/mma.h"
#include "cutlass/layout/layout.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"

#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"

namespace cutlass {
namespace gemm {
namespace device {
using namespace cute;

template<
  class OperatorClass, class ArchTag,
  class ElementA, class LayoutA,
  class ElementB, class LayoutB,
  class ElementC, class LayoutC,
  class ElementAccumulator>
struct DefaultGemmGroupConfiguration {
  static_assert(sizeof(ElementA) == 0, "No valid DefaultGemmGroupConfiguration configuration exists.");
};


// Intel XE MMA f16s8f32
template <typename ElementA, typename LayoutA, typename ElementB, typename LayoutB, typename LayoutC, typename ElementOutput>
struct DefaultGemmGroupConfiguration<
    arch::OpClassTensorOp, arch::IntelXe,
    ElementA, LayoutA,
    ElementB, LayoutB,
    float, LayoutC,
    ElementOutput>
{

  static_assert(cute::is_any_of_v<ElementA, bfloat16_t, half_t, int8_t, float_e5m2_t, float_e4m3_t>, "ElementA needs to be of 16 or 8 bit type");
  static_assert(cute::is_any_of_v<ElementB, bfloat16_t, half_t, int8_t, float_e5m2_t, float_e4m3_t, uint4_t>, "ElementB needs to be of 16, 8 or 4 bit type");
  using TileShape = Shape<_256, _256, _32>;

  using CollectiveMainloop = typename gemm::collective::CollectiveBuilder<
    arch::IntelXe, arch::OpClassTensorOp,
    ElementA, LayoutA, 1,
    ElementB, LayoutB, 1,
    float,
    TileShape, Shape<_1, _1, _1>,
    gemm::collective::StageCountAuto,
    gemm::KernelXePtrArrayCooperative
  >::CollectiveOp;

  using TiledMma = typename CollectiveMainloop::TiledMma;

  using EpilogueOp = epilogue::fusion::LinearCombination<float, float>;

  using FusionCallBacks = epilogue::fusion::FusionCallbacks<
    epilogue::IntelXeXMX16Group,
    EpilogueOp,
    TileShape,
    decltype(tile_shape(TiledMma()))
  >;

  using CollectiveEpilogue = typename epilogue::collective::CollectiveBuilder<
      arch::IntelXe, arch::OpClassTensorOp,
      TileShape, Shape<_1, _1, _1>,
      epilogue::collective::EpilogueTileAuto,
      float, float,
      float, LayoutC, 1,
      ElementOutput, LayoutC, 1,
      epilogue::IntelXeXMX16Group,
      EpilogueOp
    >::CollectiveOp;
};


} // namespace device
} // namespace gemm
} // namespace cutlass
