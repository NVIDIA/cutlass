/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
/// Maps the selected collective policies to runtime GEMM schedule metadata.
#pragma once

#include <stdexcept>
#include "cutlass/library/descriptions.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/epilogue/dispatch_policy.hpp"

namespace cutlass::library {

// Inspect the resolved schedule, not the builder's input tag (which may be Auto).
template <class Schedule>
struct KernelScheduleMap {
  template <class Base>
  static constexpr bool derives = cute::is_base_of_v<Base, Schedule>;

  template <template <int...> class Tag>
  static constexpr bool is_tag = cutlass::detail::is_kernel_tag_of_v<Schedule, Tag>;

  static constexpr bool kSm100Tma =
      is_tag<gemm::KernelTmaWarpSpecializedSm100> ||
      is_tag<gemm::KernelPtrArrayTmaWarpSpecializedSm100> ||
      is_tag<gemm::KernelTmaWarpSpecializedBlockScaledSm100> ||
      is_tag<gemm::KernelPtrArrayTmaWarpSpecializedBlockScaledSm100> ||
      is_tag<gemm::KernelTmaWarpSpecializedMmaTransformSm100> ||
      is_tag<gemm::KernelPtrArrayTmaWarpSpecializedMmaTransformSm100> ||
      is_tag<gemm::KernelSparseTmaWarpSpecializedSm100> ||
      is_tag<gemm::KernelSparseTmaWarpSpecializedBlockScaledSm100> ||
      is_tag<gemm::KernelTmaWarpSpecializedInputTransformSm100> ||
      is_tag<gemm::KernelPtrArrayTmaWarpSpecializedInputTransformSm100> ||
      is_tag<gemm::KernelTmaWarpSpecializedMixedInputTransformSm100> ||
      is_tag<gemm::KernelTmaWarpSpecializedBlockScaledSm103> ||
      is_tag<gemm::KernelPtrArrayTmaWarpSpecializedBlockScaledSm103>;
  static constexpr bool kSm100CpAsync = is_tag<gemm::KernelWarpSpecializedSm100>;
  static constexpr bool kSm100Mixed = is_tag<gemm::KernelMixedTmaCpAsyncWarpSpecializedSm100>;
  static constexpr bool kSm100 = kSm100Tma || kSm100CpAsync || kSm100Mixed;

  static constexpr bool kCpAsync =
      derives<gemm::KernelCpAsyncWarpSpecialized> ||
      derives<gemm::KernelCpAsyncWarpSpecializedPingpong> ||
      derives<gemm::KernelCpAsyncWarpSpecializedCooperative>;
  static constexpr bool kCooperative =
      derives<gemm::KernelCpAsyncWarpSpecializedCooperative> ||
      derives<gemm::KernelTmaWarpSpecializedCooperative> ||
      derives<gemm::KernelPtrArrayTmaWarpSpecializedCooperative> ||
      cutlass::detail::is_asymmetric_dma_kernel_tag_of_v<Schedule, gemm::KernelTmaWarpSpecializedCooperativeSparseSm120> ||
      cutlass::detail::is_asymmetric_dma_kernel_tag_of_v<Schedule, gemm::KernelTmaWarpSpecializedCooperativeSparseBlockScaledSm120>;
  static constexpr bool kPingpong =
      derives<gemm::KernelCpAsyncWarpSpecializedPingpong> ||
      derives<gemm::KernelTmaWarpSpecializedPingpong> ||
      derives<gemm::KernelPtrArrayTmaWarpSpecializedPingpong>;
  static constexpr bool kWarpSpecialized =
      derives<gemm::KernelCpAsyncWarpSpecialized> || derives<gemm::KernelTmaWarpSpecialized>;
  static constexpr bool kMultistage =
      derives<gemm::KernelMultistage> || derives<gemm::KernelPtrArrayMultistage>;

  static constexpr MainloopScheduleKind kSchedule =
      kCooperative ? MainloopScheduleKind::kWarpSpecializedCooperative :
      kPingpong ? MainloopScheduleKind::kWarpSpecializedPingpong :
      (kWarpSpecialized || kSm100) ? MainloopScheduleKind::kWarpSpecialized :
      kMultistage ? MainloopScheduleKind::kMultistage :
      derives<gemm::KernelTma> ? MainloopScheduleKind::kTma : MainloopScheduleKind::kUnknown;

  // KernelMultistage is shared by synchronous SM70 and cp.async SM80 mainloops.
  // Its load kind cannot be determined from the schedule tag alone.
  static constexpr MainloopLoadKind kLoad =
      kSm100Mixed ? MainloopLoadKind::kMixedTmaCpAsync :
      (kCpAsync || kSm100CpAsync) ? MainloopLoadKind::kCpAsync :
      (kCooperative || kPingpong || kWarpSpecialized || kSm100Tma || derives<gemm::KernelTma>) ?
          MainloopLoadKind::kTma : MainloopLoadKind::kUnknown;

  static constexpr bool kFastAccum =
      derives<gemm::KernelTmaWarpSpecializedFP8FastAccum> ||
      derives<gemm::KernelTmaWarpSpecializedPingpongFP8FastAccum> ||
      derives<gemm::KernelTmaWarpSpecializedCooperativeFP8FastAccum> ||
      derives<gemm::KernelPtrArrayTmaWarpSpecializedCooperativeFP8FastAccum> ||
      derives<gemm::KernelPtrArrayTmaWarpSpecializedPingpongFP8FastAccum>;
  static constexpr AccumulationKind kAccumulation =
      kFastAccum ? AccumulationKind::kFastAccum :
      kSchedule != MainloopScheduleKind::kUnknown ? AccumulationKind::kDefault : AccumulationKind::kUnknown;
};

// Epilogue builder tags are not retained by all collectives. Use DispatchPolicy.
template <class Policy>
struct EpilogueScheduleMap {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kUnknown;
};

template <>
struct EpilogueScheduleMap<epilogue::NoSmemWarpSpecialized> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

template <>
struct EpilogueScheduleMap<epilogue::PtrArrayNoSmemWarpSpecialized> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

template <>
struct EpilogueScheduleMap<epilogue::PtrArrayNoSmemWarpSpecializedTransposed> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

template <>
struct EpilogueScheduleMap<epilogue::Sm100NoSmem> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

template <>
struct EpilogueScheduleMap<epilogue::Sm100NoSmemWarpSpecialized> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

template <>
struct EpilogueScheduleMap<epilogue::Sm100PtrArrayNoSmem> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

template <>
struct EpilogueScheduleMap<epilogue::Sm100PtrArrayNoSmemWarpSpecialized> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

template <>
struct EpilogueScheduleMap<epilogue::Sm100PtrArrayPlanarComplexNoSmem> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

template <>
struct EpilogueScheduleMap<epilogue::Sm100PtrArrayPlanarComplexNoSmemWarpSpecialized> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

template <int C, int D, int F, bool Reuse, bool Delay>
struct EpilogueScheduleMap<epilogue::Sm90TmaWarpSpecialized<C, D, F, Reuse, Delay>> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kTma;
};

template <int C, int D, int F, bool Reuse, bool Delay>
struct EpilogueScheduleMap<epilogue::Sm100TmaWarpSpecialized<C, D, F, Reuse, Delay>> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kTma;
};

template <int C, int D, int F, bool Reuse, bool Delay>
struct EpilogueScheduleMap<epilogue::Sm100PtrArrayTmaWarpSpecialized<C, D, F, Reuse, Delay>> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kTma;
};

template <int C, int D, int F, bool Reuse, bool Delay>
struct EpilogueScheduleMap<epilogue::Sm100PlanarComplexTmaWarpSpecialized<C, D, F, Reuse, Delay>> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kTma;
};

template <int C, int D, int F, bool Reuse, bool Delay>
struct EpilogueScheduleMap<epilogue::Sm100PtrArrayPlanarComplexTmaWarpSpecialized<C, D, F, Reuse, Delay>> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kTma;
};

template <int C, int D, int F, bool Reuse, bool Delay>
struct EpilogueScheduleMap<epilogue::Sm120TmaWarpSpecialized<C, D, F, Reuse, Delay>> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kTma;
};

template <int C, int D, int F, bool Reuse, bool Delay, int WarpGroups>
struct EpilogueScheduleMap<epilogue::Sm90PtrArrayTmaWarpSpecialized<C, D, F, Reuse, Delay, WarpGroups>> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kTma;
};

template <int C, int D, int F, bool Reuse, bool Delay, int WarpGroups>
struct EpilogueScheduleMap<epilogue::Sm120PtrArrayTmaWarpSpecialized<C, D, F, Reuse, Delay, WarpGroups>> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kTma;
};

// The Hopper no-smem builder wraps DefaultEpilogue in a TMA-compatible adapter.
// Its dispatch policy remains EpilogueDefault, despite the adapter's name.
template <>
struct EpilogueScheduleMap<gemm::EpilogueDefault> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

template <>
struct EpilogueScheduleMap<gemm::EpilogueTransposed> {
  static constexpr EpilogueScheduleKind kId = EpilogueScheduleKind::kNoSmem;
};

// Custom epilogues need not expose a dispatch policy.
template <class Collective, class = void>
struct CollectiveEpilogueScheduleMap : EpilogueScheduleMap<void> {};

template <class Collective>
struct CollectiveEpilogueScheduleMap<Collective, cute::void_t<typename Collective::DispatchPolicy>>
    : EpilogueScheduleMap<typename Collective::DispatchPolicy> {};

template <class Operator, class Description>
void initialize_gemm_schedule_description(Description& description) {
  using Mainloop = typename Operator::CollectiveMainloop;
  using Map = KernelScheduleMap<typename Mainloop::DispatchPolicy::Schedule>;
  description.mainloop_schedule = Map::kSchedule;
  description.mainloop_load = Map::kLoad;
  description.accumulation_kind = Map::kAccumulation;
  description.epilogue_schedule = CollectiveEpilogueScheduleMap<typename Operator::CollectiveEpilogue>::kId;

  // SM100's resolved kernel tag is shared by 1-SM and 2-SM kernels. The MMA
  // atom's thread-ID layout retains the actual CTA group size after Auto dispatch.
  if constexpr (Map::kSm100) {
    constexpr int cta_group_size = cute::size(typename Mainloop::TiledMma::AtomThrID{});
    description.mainloop_schedule = cta_group_size == 1 ? MainloopScheduleKind::kWarpSpecialized1Sm :
                                    cta_group_size == 2 ? MainloopScheduleKind::kWarpSpecialized2Sm :
                                    MainloopScheduleKind::kUnknown;
  }
}

} // namespace cutlass::library
