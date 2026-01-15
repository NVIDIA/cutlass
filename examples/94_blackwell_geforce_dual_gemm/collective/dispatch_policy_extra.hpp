/***************************************************************************************************
 * Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/arch/arch.h"

namespace cutlass::gemm {

struct DualKernelTmaWarpSpecializedCooperative { 
  static constexpr int SchedulerPipelineStageCount = 0;
};

template<
  int Stages_,
  int SchedulerPipelineStageCount_,
  class ClusterShape_,
  class KernelSchedule_
>
struct DualMainloopSm120TmaWarpSpecializedBlockScaled {
  constexpr static int Stages = Stages_;
  constexpr static int SchedulerPipelineStageCount = SchedulerPipelineStageCount_;
  using ClusterShape = ClusterShape_;
  using Schedule = KernelSchedule_;
  constexpr static int PipelineAsyncMmaStages = 0;
  using ArchTag = arch::Sm120;
};

template<int SchedulerPipelineStageCount_>
struct DualKernelTmaWarpSpecializedCooperativeBlockScaledSm120 : DualKernelTmaWarpSpecializedCooperative { 
  static constexpr int SchedulerPipelineStageCount = SchedulerPipelineStageCount_;
};

} // namespace cutlass::gemm

namespace cutlass::epilogue {

struct DualTmaWarpSpecialized {};

template<
  int StagesC_,
  int StagesD_,
  int FragmentSize_,
  bool ReuseSmemC_,
  bool DelayTmaStore_
>
struct DualSm90TmaWarpSpecialized {
  constexpr static int StagesC = StagesC_;
  constexpr static int StagesD = StagesD_;
  constexpr static int FragmentSize = FragmentSize_;
  constexpr static bool ReuseSmemC = ReuseSmemC_;
  constexpr static bool DelayTmaStore = DelayTmaStore_;
};

template<
  int StagesC_,
  int StagesD_,
  int FragmentSize_,
  bool ReuseSmemC_,
  bool DelayTmaStore_
>
struct DualSm120TmaWarpSpecialized {
  constexpr static int StagesC = StagesC_;
  constexpr static int StagesD = StagesD_;
  constexpr static int FragmentSize = FragmentSize_;
  constexpr static bool ReuseSmemC = ReuseSmemC_;
  constexpr static bool DelayTmaStore = DelayTmaStore_;
};

} // namespace cutlass::epilogue