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


/*! \file
  \brief Fusion callbacks specializations for the SM120 TMA warp-specialized (ws) epilogue
*/

#pragma once

#include "cutlass/cutlass.h"

#include "cute/tensor.hpp"

#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/fusion/sm100_callbacks_tma_warpspecialized.hpp"
#include "cutlass/epilogue/fusion/sm120_visitor_store_tma_warpspecialized.hpp"
#include "callbacks.hpp"
#include "../fusion/sm90_callbacks_tma_warpspecialized_dual.hpp"
#include "../collective/dispatch_policy_extra.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::fusion {

/////////////////////////////////////////////////////////////////////////////////////////////////

// Sm120 Tma warp specialized callbacks just alias to their sm90 counterpart
// ... existing includes ...

// Generic forwarder (ALL operations, including single-op) – keep Args...
template <
  int StagesC, int StagesD, int FragmentSize,
  bool ReuseSmemC, bool DelayTmaStore,
  class Operation,
  class CtaTileShapeMNK,
  class EpilogueTile,
  class... Args
>
struct DualFusionCallbacks<
    epilogue::DualSm120TmaWarpSpecialized<StagesC,StagesD,FragmentSize,ReuseSmemC,DelayTmaStore>,
    Operation,
    CtaTileShapeMNK,
    EpilogueTile,
    Args...
> : DualFusionCallbacks<
      epilogue::DualSm90TmaWarpSpecialized<StagesC,StagesD,FragmentSize,ReuseSmemC,DelayTmaStore>,
      Operation,
      CtaTileShapeMNK,
      EpilogueTile,
      Args...> {
  using Base = DualFusionCallbacks<
      epilogue::DualSm90TmaWarpSpecialized<StagesC,StagesD,FragmentSize,ReuseSmemC,DelayTmaStore>,
      Operation,
      CtaTileShapeMNK,
      EpilogueTile,
      Args...>;
  using Base::Base;
};

// DualOpPair specific forwarder (preserves Args...) to ensure dual visit0/visit1 path propagates
template <
  int StagesC, int StagesD, int FragmentSize,
  bool ReuseSmemC, bool DelayTmaStore,
  class Op0, class Op1,
  class CtaTileShapeMNK,
  class EpilogueTile,
  class... Args
>
struct DualFusionCallbacks<
    epilogue::DualSm120TmaWarpSpecialized<StagesC,StagesD,FragmentSize,ReuseSmemC,DelayTmaStore>,
    DualOpPair<Op0,Op1>,
    CtaTileShapeMNK,
    EpilogueTile,
    Args...
> : DualFusionCallbacks<
      epilogue::DualSm90TmaWarpSpecialized<StagesC,StagesD,FragmentSize,ReuseSmemC,DelayTmaStore>,
      DualOpPair<Op0,Op1>,
      CtaTileShapeMNK,
      EpilogueTile,
      Args...> {
  using Base = DualFusionCallbacks<
      epilogue::DualSm90TmaWarpSpecialized<StagesC,StagesD,FragmentSize,ReuseSmemC,DelayTmaStore>,
      DualOpPair<Op0,Op1>,
      CtaTileShapeMNK,
      EpilogueTile,
      Args...>;
  using Base::Base;
};

} // namespace cutlass::epilogue::fusion

/////////////////////////////////////////////////////////////////////////////////////////////////
