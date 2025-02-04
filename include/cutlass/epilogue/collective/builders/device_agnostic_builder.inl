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

#pragma once

#include <cutlass/arch/arch.h>
#include <cute/arch/copy.hpp>

#include "cutlass/epilogue/collective/default_epilogue.hpp"


namespace cutlass::epilogue::collective {

template<
  class TileShape_MNK,
  class ElementAccumulator_,
  class ElementCompute_,
  class ElementC_,
  class GmemLayoutTagC_,
  int AlignmentC_,
  class ElementD_,
  class GmemLayoutTagD_,
  int AlignmentD_,
  class FusionOpOrCallbacks
>
struct CollectiveBuilder<
  arch::Agnostic,
  arch::OpMultiplyAdd,
  TileShape_MNK,
  Shape<_1, _1, _1>,
  EpilogueTileAuto,
  ElementAccumulator_,
  ElementCompute_,
  ElementC_,
  GmemLayoutTagC_,
  AlignmentC_,
  ElementD_,
  GmemLayoutTagD_,
  AlignmentD_,
  EpilogueScheduleAuto,
  FusionOpOrCallbacks,
  cute::enable_if_t<
    (cute::is_same_v<FusionOpOrCallbacks,
       cutlass::epilogue::fusion::LinearCombination<ElementD_, ElementCompute_, ElementC_, ElementCompute_>>)
  >
> {
  using ElementC = ElementC_;
  using ElementD = ElementD_;
  using ElementOutput = ElementD_;
  using ElementCompute = ElementCompute_;
  using ElementAccumulator = ElementAccumulator_;

  static constexpr int FragmentSize = 1;
  using ThreadOp = thread::LinearCombination<
    ElementD, FragmentSize, ElementAccumulator, ElementCompute>;

  using CollectiveOp = cutlass::epilogue::collective::DefaultEpilogue<
          ElementC,
          cutlass::detail::TagToStrideC_t<GmemLayoutTagC_>,
          cutlass::detail::TagToStrideC_t<GmemLayoutTagD_>,
          ThreadOp,
          cutlass::gemm::EpilogueDefault>;
};

} // namespace cutlass::epilogue::collective
