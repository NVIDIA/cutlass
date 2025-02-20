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
#include "cutlass/gemm/gemm.h"

#include "cute/layout.hpp"
#include "cute/numeric/integral_constant.hpp" // cute::false_type
#include "cute/arch/copy_sm100.hpp" 

//////////////////////////////////////////////////////////////////////////////

namespace cutlass::detail {

template <class T, template <int...> class U>
struct is_kernel_tag_of : cute::false_type {};

template <template <int...> class U, int... Args>
struct is_kernel_tag_of<U<Args...>, U> : cute::true_type {};

template <class T, template <int...> class U>
constexpr bool is_kernel_tag_of_v = is_kernel_tag_of<T, U>::value;

template <class T, template <int,bool> class U>
struct is_asymmetric_dma_kernel_tag_of : cute::false_type {};

template <template <int, bool> class U, int I0, bool B0>
struct is_asymmetric_dma_kernel_tag_of<U<I0, B0>, U> : cute::true_type {};

template <class T, template <int, bool> class U>
constexpr bool is_asymmetric_dma_kernel_tag_of_v = \
                              is_asymmetric_dma_kernel_tag_of<T, U>::value;

}

//////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm {
using namespace cute;

//////////////////////////////////////////////////////////////////////////////

namespace detail {

enum class KernelInputTransformType {
    FastF32,
    InterleavedComplexTF32
};

} // namespace detail

//////////////////////////////////////////////////////////////////////////////

namespace kernel::detail {

// Has_SwapAB<T>::value will be true only if:
//   class T has member SwapAB and T::SwapAB is true
template <typename T, typename = void>
struct Has_SwapAB { static constexpr bool value = false; };

template <typename T>
struct Has_SwapAB <T, CUTE_STL_NAMESPACE::void_t<decltype(T::SwapAB)>>
{ static constexpr bool value = T::SwapAB; };

template <typename T>
static constexpr bool Has_SwapAB_v = Has_SwapAB<T>::value;

} // namespace kernel::detail

//////////////////////////////////////////////////////////////////////////////

//
// Kernel schedule policies (the base class tags, one for each kernel layer file)
//
struct KernelMultistage { };
struct KernelCpAsyncWarpSpecialized { };
struct KernelCpAsyncWarpSpecializedPingpong { };
struct KernelCpAsyncWarpSpecializedCooperative { };
struct KernelTma { };
struct KernelTmaWarpSpecialized { };
struct KernelTmaWarpSpecializedPingpong { 
};
struct KernelTmaWarpSpecializedCooperative { 
};

struct KernelPtrArrayTmaWarpSpecializedCooperative { };
struct KernelPtrArrayTmaWarpSpecializedPingpong { };

// FP8 related policies (including Blocked Scaled Accumulation)
template<
  // `ScaleGranularityM`/`ScaleGranularityN` specifies scaling granularity along M/N, while zero-value
  // `ScaleGranularityM`/`ScaleGranularityN` indicates that scaling granularity is
  // `size<0>(TileShape_MNK{})`/`size<1>(TileShape_MNK{})` along M/N.
  int ScaleGranularityM = 0,
  int ScaleGranularityN = 0
>
struct KernelTmaWarpSpecializedCooperativeFP8BlockScaledAccum: KernelTmaWarpSpecializedCooperative { };

// Policies to opt into mixed type GEMMs
struct KernelTmaWarpSpecializedMixedInput : KernelTmaWarpSpecialized { };
struct KernelTmaWarpSpecializedPingpongMixedInput : KernelTmaWarpSpecializedPingpong { };
struct KernelTmaWarpSpecializedCooperativeMixedInput: KernelTmaWarpSpecializedCooperative { };

//////////////////////////////////////////////////////////////////////////////

//
// Builder dispatch policies (not a part of the main CUTLASS layers, simply used to opt into
// specific collective builder dispatches)
//

// FP8 related policies (including Fast Accumulation)
struct KernelTmaWarpSpecializedFP8FastAccum : KernelTmaWarpSpecialized { };
struct KernelTmaWarpSpecializedPingpongFP8FastAccum : KernelTmaWarpSpecializedPingpong { };
struct KernelTmaWarpSpecializedCooperativeFP8FastAccum: KernelTmaWarpSpecializedCooperative { };
struct KernelPtrArrayTmaWarpSpecializedCooperativeFP8FastAccum : KernelPtrArrayTmaWarpSpecializedCooperative { };
struct KernelPtrArrayTmaWarpSpecializedPingpongFP8FastAccum : KernelPtrArrayTmaWarpSpecializedPingpong { };

//////////////////////////////////////////////////////////////////////////////

// Policies for dispatch of epilogue
struct EpilogueDefault { };
struct EpilogueTransposed { };

//////////////////////////////////////////////////////////////////////////////

//
// Collective Mainloop Policies
//

// 2 stage pipeline through 1 stage in smem, 1 in rmem, WITHOUT predicated gmem loads
struct MainloopSm70TwoStageUnpredicated {
  constexpr static int Stages = 2;
  using ArchTag = arch::Sm70;
  using Schedule = KernelMultistage;
  using ClusterShape = Shape<_1,_1,_1>;
};

// 2 stage pipeline through 1 stage in smem, 1 in rmem, with predicated gmem loads
struct MainloopSm70TwoStage {
  constexpr static int Stages = 2;
  using ArchTag = arch::Sm70;
  using Schedule = KernelMultistage;
  using ClusterShape = Shape<_1,_1,_1>;
};

// n-buffer in smem (cp.async), pipelined with registers, WITHOUT predicated gmem loads
template<int Stages_>
struct MainloopSm80CpAsyncUnpredicated {
  constexpr static int Stages = Stages_;
  using ArchTag = arch::Sm80;
  using Schedule = KernelMultistage;
  using ClusterShape = Shape<_1,_1,_1>;
};

// n-buffer in smem (cp.async), pipelined with registers, with predicated gmem loads
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>
>
struct MainloopSm80CpAsync {
  constexpr static int Stages = Stages_;
  using ArchTag = cute::conditional_t<(size(ClusterShape_{}) > 1), arch::Sm90, arch::Sm80>;
  using Schedule = KernelMultistage;
  using ClusterShape = ClusterShape_;
};

// n-buffer in smem (cp.async), pipelined with Hopper GMMA, with predicated gmem loads, warp specialized dynamic schedule
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelCpAsyncWarpSpecialized
>
struct MainloopSm90CpAsyncGmmaWarpSpecialized {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm90;
  using Schedule = KernelSchedule;
};

// n-buffer in smem (cp.async), pipelined with Hopper GMMA, with predicated gmem loads, warp specialized dynamic schedule
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelCpAsyncWarpSpecialized
>
struct MainloopSm90CpAsyncGmmaRmemAWarpSpecialized {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm90;
  using Schedule = KernelSchedule;
};

// n-buffer in smem (Hopper TMA), pipelined with Hopper GMMA and TMA, static schedule between TMA and GMMA
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  int PipelineAsyncMmaStages_ = 1
>
struct MainloopSm90TmaGmma {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  constexpr static int PipelineAsyncMmaStages = PipelineAsyncMmaStages_;
  using ArchTag = arch::Sm90;
  using Schedule = KernelTma;
};

// n-buffer in smem (Hopper TMA), pipelined with Hopper GMMA and TMA, Warp specialized dynamic schedule
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelTmaWarpSpecializedCooperative
>
struct MainloopSm90TmaGmmaWarpSpecialized {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm90;
  using Schedule = KernelSchedule;
};

// n-buffer in smem (Hopper TMA), pipelined with Hopper GMMA and TMA, Warp specialized dynamic schedule
// With GMMA's A data from registers.
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelTmaWarpSpecialized
>
struct MainloopSm90TmaGmmaRmemAWarpSpecialized {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm90;
  using Schedule = KernelSchedule;
  static_assert(
    cute::is_same_v<Schedule, KernelTmaWarpSpecialized> ||
    cute::is_same_v<Schedule, KernelTmaWarpSpecializedPingpong> ||
    cute::is_same_v<Schedule, KernelTmaWarpSpecializedCooperative>,
    "KernelSchedule must be one of the warp specialized policies");
};


template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelTmaWarpSpecialized
>
struct MainloopSm90TmaGmmaRmemAWarpSpecializedMixedInput {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm90;
  using Schedule = KernelSchedule;
  static_assert(
    cute::is_same_v<Schedule, KernelTmaWarpSpecialized> ||
    cute::is_same_v<Schedule, KernelTmaWarpSpecializedPingpong> ||
    cute::is_same_v<Schedule, KernelTmaWarpSpecializedCooperative>,
    "KernelSchedule must be one of the warp specialized policies");
};

// n-buffer in smem (Hopper TMA), pipelined with Hopper GMMA and TMA, Warp specialized dynamic schedule
// For FP8 kernels
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelTmaWarpSpecialized
>
struct MainloopSm90TmaGmmaWarpSpecializedFP8
  : MainloopSm90TmaGmmaWarpSpecialized<Stages_, ClusterShape_, KernelSchedule> {
  static_assert(
    cute::is_same_v<KernelSchedule, KernelTmaWarpSpecialized> ||
    cute::is_same_v<KernelSchedule, KernelTmaWarpSpecializedPingpong> ||
    cute::is_same_v<KernelSchedule, KernelTmaWarpSpecializedCooperative>,
    "KernelSchedule must be one of the warp specialized policies");
};


// n-buffer in smem (Hopper TMA), pipelined with Hopper GMMA and TMA, Warp specialized dynamic schedule
// For FP8 kernels with Block Scaling
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelTmaWarpSpecialized,
  // `ScaleGranularityM`/`ScaleGranularityN` specifies scaling granularity along M/N, while zero-value
  // `ScaleGranularityM`/`ScaleGranularityN` indicates that scaling granularity is
  // `size<0>(TileShape_MNK{})`/`size<1>(TileShape_MNK{})` along M/N.
  int ScaleGranularityM = 0,
  int ScaleGranularityN = 0
>
struct MainloopSm90TmaGmmaWarpSpecializedBlockScalingFP8
  : MainloopSm90TmaGmmaWarpSpecialized<Stages_, ClusterShape_, KernelSchedule> {
  static_assert(
    cute::is_same_v<KernelSchedule, KernelTmaWarpSpecializedCooperativeFP8BlockScaledAccum<ScaleGranularityM, ScaleGranularityN>>,
    "KernelSchedule must be one of the warp specialized policies");
};

// n-buffer in smem (Hopper TMA), pipelined with Hopper GMMA and TMA, Warp specialized dynamic schedule for Ptr-Array and Grouped Gemm
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelPtrArrayTmaWarpSpecializedCooperative
>
struct MainloopSm90ArrayTmaGmmaWarpSpecialized {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm90;
  using Schedule = KernelSchedule;
  static_assert(
    cute::is_base_of_v<KernelPtrArrayTmaWarpSpecializedCooperative, KernelSchedule> ||
    cute::is_base_of_v<KernelPtrArrayTmaWarpSpecializedPingpong, KernelSchedule>,
    "KernelSchedule must be one of the Ptr-Array or Grouped Gemm TMA Warp Specialized Cooperative or Pingpong policies");
};

// n-buffer in smem (Hopper TMA), pipelined with Hopper GMMA and TMA, Warp specialized dynamic schedule for Ptr-Array and Grouped Gemm
// For FP8 kernels
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelPtrArrayTmaWarpSpecializedCooperative
>
struct MainloopSm90ArrayTmaGmmaWarpSpecializedFP8
  : MainloopSm90ArrayTmaGmmaWarpSpecialized<Stages_, ClusterShape_, KernelSchedule> {
  static_assert(
    cute::is_base_of_v<KernelPtrArrayTmaWarpSpecializedCooperative, KernelSchedule> ||
    cute::is_base_of_v<KernelPtrArrayTmaWarpSpecializedPingpong, KernelSchedule>,
    "KernelSchedule must be one of the Ptr-Array or Grouped Gemm TMA Warp Specialized Cooperative or Pingpong policies");
};

// n-buffer in smem (Hopper TMA), pipelined with Hopper sparse GMMA and TMA, Warp specialized dynamic schedule
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelTmaWarpSpecializedCooperative
>
struct MainloopSm90TmaGmmaWarpSpecializedSparse {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm90;
  using Schedule = KernelSchedule;
};

// For slow-accumulation sparse FP8 kernels
template<
  int Stages,
  class ClusterShape = Shape<_1,_1,_1>,
  class KernelSchedule = KernelTmaWarpSpecializedCooperative
>
struct MainloopSm90TmaGmmaWarpSpecializedSparseFP8 
  : MainloopSm90TmaGmmaWarpSpecializedSparse<Stages, ClusterShape, KernelSchedule> {
};

// Mixed precision version n-buffer in rmem (Hopper TMA), pipelined with Hopper GMMA and TMA, Warp specialized dynamic schedule for Ptr-Array and Grouped Gemm
template<
  int Stages_,
  class ClusterShape_ = Shape<_1,_1,_1>,
  class KernelSchedule = KernelPtrArrayTmaWarpSpecializedCooperative
>
struct MainloopSm90ArrayTmaGmmaWarpSpecializedMixedInput {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm90;
  using Schedule = KernelSchedule;
  static_assert(
    cute::is_same_v<Schedule, KernelPtrArrayTmaWarpSpecializedCooperative> ||
    cute::is_same_v<Schedule, KernelPtrArrayTmaWarpSpecializedPingpong>,
    "KernelSchedule must be one of the Ptr-Array or Grouped Gemm TMA Warp Specialized Cooperative policies");
};


template<
  int SchedulerPipelineStageCount_,
  int AccumulatorPipelineStageCount_
>
struct KernelTmaWarpSpecializedSm100 final {
  static constexpr int SchedulerPipelineStageCount = SchedulerPipelineStageCount_;
  static constexpr int AccumulatorPipelineStageCount = AccumulatorPipelineStageCount_;
};

// Gemm with block scaling factors
template<
  int SchedulerPipelineStageCount_,
  int AccumulatorPipelineStageCount_
>
struct KernelTmaWarpSpecializedBlockScaledSm100 final {
  static constexpr int SchedulerPipelineStageCount = SchedulerPipelineStageCount_;
  static constexpr int AccumulatorPipelineStageCount = AccumulatorPipelineStageCount_;
};



// InputTransform GEMM
template<
  int SchedulerPipelineStageCount_,
  int AccumulatorPipelineStageCount_
>
struct KernelTmaWarpSpecializedInputTransformSm100 final {
  static constexpr int SchedulerPipelineStageCount = SchedulerPipelineStageCount_;
  static constexpr int AccumulatorPipelineStageCount = AccumulatorPipelineStageCount_;
};

// Ptr-Array Dense GEMM: SM100 tensor op policy that applies to both 1SM and 2SM MMA atoms
template<
  int SchedulerPipelineStageCount_,
  int AccumulatorPipelineStageCount_
>
struct KernelPtrArrayTmaWarpSpecializedSm100 final {
  static constexpr int SchedulerPipelineStageCount = SchedulerPipelineStageCount_;
  static constexpr int AccumulatorPipelineStageCount = AccumulatorPipelineStageCount_;
};

// Ptr-Array Block Scaled GEMM
template<
  int SchedulerPipelineStageCount_,
  int AccumulatorPipelineStageCount_
>
struct KernelPtrArrayTmaWarpSpecializedBlockScaledSm100 final {
  static constexpr int SchedulerPipelineStageCount = SchedulerPipelineStageCount_;
  static constexpr int AccumulatorPipelineStageCount = AccumulatorPipelineStageCount_;
};

// Ptr-Array InputTransform GEMM
template<
  int SchedulerPipelineStageCount_,
  int AccumulatorPipelineStageCount_
>
struct KernelPtrArrayTmaWarpSpecializedInputTransformSm100 final {
  static constexpr int SchedulerPipelineStageCount = SchedulerPipelineStageCount_;
  static constexpr int AccumulatorPipelineStageCount = AccumulatorPipelineStageCount_;
};


//////////////////////////////////////////////////////////////////////////////

//
// Collective Builder Tag Property
//

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//          SM100 Dispatch Policies
//
///////////////////////////////////////////////////////////////////////////////////////////////////////

// Base Dispatch Policies
struct KernelSchedule1Sm {};
struct KernelSchedule2Sm {};
struct KernelScheduleSm100 {};

///////////////////////////////////////////////////////////////////////////////////////////////////////
// SM100 Dense GEMM Dispatch Policies
///////////////////////////////////////////////////////////////////////////////////////////////////////
struct KernelScheduleSm100DenseGemm : KernelScheduleSm100 {};   // Base policy
// Dense GEMM: Specialize for 1SM vs 2SM
struct KernelTmaWarpSpecialized1SmSm100 final : KernelSchedule1Sm, KernelScheduleSm100DenseGemm {};  // Use for 1SM Dense GEMM Kernels for Collective Mainloop Builder
struct KernelTmaWarpSpecialized2SmSm100 final : KernelSchedule2Sm, KernelScheduleSm100DenseGemm {};  // Use for 2SM Dense GEMM Kernels for Collective Mainloop Builder
// Dense GEMM + (Ptr Array or Group GEMM)
struct KernelScheduleSm100PtrArrayDenseGemm : KernelScheduleSm100DenseGemm {};
// Ptr-Array Dense GEMM: Specialize for 1SM vs 2SM
struct KernelPtrArrayTmaWarpSpecialized1SmSm100 final : KernelSchedule1Sm, KernelScheduleSm100PtrArrayDenseGemm {};
struct KernelPtrArrayTmaWarpSpecialized2SmSm100 final : KernelSchedule2Sm, KernelScheduleSm100PtrArrayDenseGemm {};

///////////////////////////////////////////////////////////////////////////////////////////////////////
// SM100 Planar Complex GEMM Dispatch Policies
///////////////////////////////////////////////////////////////////////////////////////////////////////
struct KernelScheduleSm100PlanarComplexGemm : KernelScheduleSm100{};
// Planar Complex GEMM: Specialize for 1SM vs 2SM
struct KernelTmaWarpSpecialized1SmPlanarComplexSm100 final : KernelSchedule1Sm, KernelScheduleSm100PlanarComplexGemm { };
struct KernelTmaWarpSpecialized2SmPlanarComplexSm100 final : KernelSchedule2Sm, KernelScheduleSm100PlanarComplexGemm { };
// Planar Complex GEMM + (Ptr Array or Group GEMM)
struct KernelScheduleSm100PtrArrayPlanarComplexGemm : KernelScheduleSm100PlanarComplexGemm {};
struct KernelPtrArrayTmaWarpSpecialized1SmPlanarComplexSm100 final : KernelSchedule1Sm, KernelScheduleSm100PtrArrayPlanarComplexGemm {};
struct KernelPtrArrayTmaWarpSpecialized2SmPlanarComplexSm100 final : KernelSchedule2Sm, KernelScheduleSm100PtrArrayPlanarComplexGemm {};

///////////////////////////////////////////////////////////////////////////////////////////////////////
// SM100 FastF32 (9xBF16) GEMM Dispatch Policies
///////////////////////////////////////////////////////////////////////////////////////////////////////
struct KernelScheduleSm100FastFP32Gemm : KernelScheduleSm100 {};
struct KernelTmaWarpSpecializedFastFP32SmemSm100 : KernelScheduleSm100FastFP32Gemm { };
// Dispatch policies without smem load the A operand from tmem
struct KernelTmaWarpSpecialized1SmFastFP32Sm100 final : KernelSchedule1Sm, KernelScheduleSm100FastFP32Gemm { };
struct KernelTmaWarpSpecialized2SmFastFP32Sm100 final : KernelSchedule2Sm, KernelScheduleSm100FastFP32Gemm { };
// Dispatch policies with smem load the A operand from smem
struct KernelTmaWarpSpecialized1SmFastFP32SmemSm100 final : KernelSchedule1Sm, KernelTmaWarpSpecializedFastFP32SmemSm100 { };
struct KernelTmaWarpSpecialized2SmFastFP32SmemSm100 final : KernelSchedule2Sm, KernelTmaWarpSpecializedFastFP32SmemSm100 { };
// Ptr-Array Transform GEMM: Specialize for 1SM vs 2SM FastF32 GEMM
struct KernelScheduleSm100PtrArrayFastFP32Gemm : KernelScheduleSm100FastFP32Gemm {};
struct KernelTmaWarpSpecializedPtrArrayFastFP32SmemSm100 : KernelScheduleSm100PtrArrayFastFP32Gemm { };
struct KernelPtrArrayTmaWarpSpecialized1SmFastFP32Sm100 final : KernelSchedule1Sm, KernelScheduleSm100PtrArrayFastFP32Gemm { };
struct KernelPtrArrayTmaWarpSpecialized2SmFastFP32Sm100 final : KernelSchedule2Sm, KernelScheduleSm100PtrArrayFastFP32Gemm { };
struct KernelPtrArrayTmaWarpSpecialized1SmFastFP32SmemSm100 final : KernelSchedule1Sm, KernelTmaWarpSpecializedPtrArrayFastFP32SmemSm100 { };
struct KernelPtrArrayTmaWarpSpecialized2SmFastFP32SmemSm100 final : KernelSchedule2Sm, KernelTmaWarpSpecializedPtrArrayFastFP32SmemSm100 { };

///////////////////////////////////////////////////////////////////////////////////////////////////////
// SM100 BlockScaled Dense GEMM Dispatch Policies
///////////////////////////////////////////////////////////////////////////////////////////////////////
struct KernelScheduleBlockScaledGemmSm100 : KernelScheduleSm100 {};                  
struct KernelScheduleMxNvf4Sm100 : KernelScheduleBlockScaledGemmSm100 {};
struct KernelScheduleMxf8f6f4Sm100 : KernelScheduleBlockScaledGemmSm100 {};
// Block Scaled Dense GEMM: Specialize for instruction type, scale factor vector size, and 1SM vs. 2SM
struct KernelTmaWarpSpecialized1SmBlockScaledSm100 final : KernelSchedule1Sm, KernelScheduleBlockScaledGemmSm100 { };
struct KernelTmaWarpSpecialized2SmBlockScaledSm100 final : KernelSchedule2Sm, KernelScheduleBlockScaledGemmSm100 { };
struct KernelTmaWarpSpecialized1SmNvf4Sm100 final : KernelSchedule1Sm, KernelScheduleMxNvf4Sm100 { };
struct KernelTmaWarpSpecialized2SmNvf4Sm100 final : KernelSchedule2Sm, KernelScheduleMxNvf4Sm100 { };
struct KernelTmaWarpSpecialized1SmMxf4Sm100 final : KernelSchedule1Sm, KernelScheduleMxNvf4Sm100 { };
struct KernelTmaWarpSpecialized2SmMxf4Sm100 final : KernelSchedule2Sm, KernelScheduleMxNvf4Sm100 { };
struct KernelTmaWarpSpecialized1SmMxf8f6f4Sm100 final : KernelSchedule1Sm, KernelScheduleMxf8f6f4Sm100 { };
struct KernelTmaWarpSpecialized2SmMxf8f6f4Sm100 final : KernelSchedule2Sm, KernelScheduleMxf8f6f4Sm100 { };
// BlockScaled Dense GEMM + (Ptr Array or Group GEMM)
struct KernelSchedulePtrArrayBlockScaledGemmSm100 : KernelScheduleBlockScaledGemmSm100 {};
struct KernelSchedulePtrArrayMxNvf4Sm100 : KernelSchedulePtrArrayBlockScaledGemmSm100 {};
struct KernelSchedulePtrArrayMxf8f6f4Sm100 : KernelSchedulePtrArrayBlockScaledGemmSm100 {};
// Ptr-Array Block Scaled Dense GEMM: Specialize for instruction type, scale factor vector size, and 1SM vs. 2SM
struct KernelPtrArrayTmaWarpSpecialized1SmBlockScaledSm100 final : KernelSchedule1Sm, KernelSchedulePtrArrayBlockScaledGemmSm100 { };
struct KernelPtrArrayTmaWarpSpecialized2SmBlockScaledSm100 final : KernelSchedule2Sm, KernelSchedulePtrArrayBlockScaledGemmSm100 { };
struct KernelPtrArrayTmaWarpSpecialized1SmNvf4Sm100 final : KernelSchedule1Sm, KernelSchedulePtrArrayMxNvf4Sm100 { };
struct KernelPtrArrayTmaWarpSpecialized2SmNvf4Sm100 final : KernelSchedule2Sm, KernelSchedulePtrArrayMxNvf4Sm100 { };
struct KernelPtrArrayTmaWarpSpecialized1SmMxf4Sm100 final : KernelSchedule1Sm, KernelSchedulePtrArrayMxNvf4Sm100 { };
struct KernelPtrArrayTmaWarpSpecialized2SmMxf4Sm100 final : KernelSchedule2Sm, KernelSchedulePtrArrayMxNvf4Sm100 { };
struct KernelPtrArrayTmaWarpSpecialized1SmMxf8f6f4Sm100 final : KernelSchedule1Sm, KernelSchedulePtrArrayMxf8f6f4Sm100 { };
struct KernelPtrArrayTmaWarpSpecialized2SmMxf8f6f4Sm100 final : KernelSchedule2Sm, KernelSchedulePtrArrayMxf8f6f4Sm100 { };



// n-buffer in smem, pipelined with Blackwell UMMA and TMA, Warp specialized dynamic schedule
template<
  int Stages_,
  int SchedulerPipelineStageCount_,
  int AccumulatorPipelineStageCount_,
  class ClusterShape_ = Shape<_1,_1,_1>
>
struct MainloopSm100TmaUmmaWarpSpecialized {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm100;
  using Schedule = KernelTmaWarpSpecializedSm100<SchedulerPipelineStageCount_, AccumulatorPipelineStageCount_>;
  constexpr static bool IsOverlappingAccum = false;
};



// n-buffer in smem, pipelined with Blackwell UMMA and TMA, Warp specialized dynamic schedule
template<
  int Stages_,
  int SchedulerPipelineStageCount_,
  int AccumulatorPipelineStageCount_,
  class ClusterShape_ = Shape<_1,_1,_1>
>
struct MainloopSm100TmaUmmaWarpSpecializedBlockScaled {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm100;
  constexpr static bool IsOverlappingAccum = AccumulatorPipelineStageCount_ == 1;
  using Schedule = KernelTmaWarpSpecializedBlockScaledSm100<SchedulerPipelineStageCount_, AccumulatorPipelineStageCount_>;
};



// n-buffer in smem, pipelined with Blackwell Fast FP32 kernel with UMMA (HwScaled) and TMA,
// Warp specialized dynamic schedule
template<
  // Number of Pipeline stages for
  // MainloopLoad <-> Conversion <-> MainLoad
  int Load2TransformPipelineStageCount_,
  // Number of Pipeline stages for
  // MainloopLoad <-> Conversion <-> MainLoad
  int Transform2MmaPipelineStageCount_,
  // TileScheduler pipeline depth
  int SchedulerPipelineStageCount_,
  // Accmulator pipeline depth
  int AccumulatorPipelineStageCount_,
  // Number of MMA Bands to be computed in a single FastF32 MMA operation.
  // For BF16 emulation, we have 3 compute matrices, with 9 MMAs forming 5 bands.
  //    We can eliminate bands 4 and/or 5 (up to last 3 MMA operations).
  //    Valid values are 3, 4, 5
  int NumBandsToCompute_,
  // Scaling factor for decomposed matrices (2^ScalingFactor)
  // 8 for BF16, 11 for TF32
  int ScalingFactor_,
  // Number of UMMA instructions emulated a single stage
  // Ex: Staged16 has 1 FastF32 MMA per stage
  // Should be smaller than K-mode of a single ClusterTile
  int AccPromotionInterval_,
  // ClusterShape for the kernel
  class ClusterShape_ = Shape<_1,_1,_1>,
  // The TMEM_LOAD atom to be used for loading local accumulator
  // from TMEM to registers
  class AccumulatorCopyAtom_ = cute::SM100_TMEM_LOAD_32dp32b32x
>
struct MainloopSm100TmaUmmaWarpSpecializedFastF32 {
  constexpr static int Load2TransformPipelineStageCount = Load2TransformPipelineStageCount_;
  constexpr static int Transform2MmaPipelineStageCount = Transform2MmaPipelineStageCount_;
  constexpr static int NumBandsToCompute = NumBandsToCompute_;
  constexpr static int ScalingFactor = ScalingFactor_;
  constexpr static int AccPromotionInterval = AccPromotionInterval_;
  constexpr static detail::KernelInputTransformType InputTransformType = detail::KernelInputTransformType::FastF32;
  using ClusterShape = ClusterShape_;
  using AccumulatorCopyAtom = AccumulatorCopyAtom_;
  using ArchTag = arch::Sm100;
  using Schedule = KernelTmaWarpSpecializedInputTransformSm100<SchedulerPipelineStageCount_, AccumulatorPipelineStageCount_>;

  // For backwards compatibility with GemmUniversalAdapter.
  constexpr static int Stages = Load2TransformPipelineStageCount;
};



// n-buffer in smem, pipelined with Blackwell UMMA and TMA, Warp specialized dynamic schedule
template<
  int Stages_,
  int SchedulerPipelineStageCount_,
  int AccumulatorPipelineStageCount_,
  class ClusterShape_ = Shape<_1,_1,_1>
>
struct MainloopSm100ArrayTmaUmmaWarpSpecialized {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm100;
  constexpr static bool IsOverlappingAccum = false;
  using Schedule = KernelPtrArrayTmaWarpSpecializedSm100<SchedulerPipelineStageCount_, AccumulatorPipelineStageCount_>;
};

// n-buffer in smem, pipelined with Blackwell UMMA and TMA, Warp specialized dynamic schedule
template<
  int Stages_,
  int SchedulerPipelineStageCount_,
  int AccumulatorPipelineStageCount_,
  class ClusterShape_ = Shape<_1,_1,_1>
>
struct MainloopSm100ArrayTmaUmmaWarpSpecializedBlockScaled {
  constexpr static int Stages = Stages_;
  using ClusterShape = ClusterShape_;
  using ArchTag = arch::Sm100;
  constexpr static bool IsOverlappingAccum = AccumulatorPipelineStageCount_ == 1;
  using Schedule = KernelPtrArrayTmaWarpSpecializedBlockScaledSm100<SchedulerPipelineStageCount_, AccumulatorPipelineStageCount_>;
};



// n-buffer in smem, pipelined with Blackwell Fast FP32 kernel with UMMA (HwScaled) and TMA,
// Warp specialized dynamic schedule
template<
  // Number of Pipeline stages for
  // MainloopLoad <-> Conversion <-> MainLoad
  int Load2TransformPipelineStageCount_,
  // Number of Pipeline stages for
  // MainloopLoad <-> Conversion <-> MainLoad
  int Transform2MmaPipelineStageCount_,
  // TileScheduler pipeline depth
  int SchedulerPipelineStageCount_,
  // Accmulator pipeline depth
  int AccumulatorPipelineStageCount_,
  // Number of MMA Bands to be computed in a single FastF32 MMA operation.
  // For BF16 emulation, we have 3 compute matrices, with 9 MMAs forming 5 bands.
  //    We can eliminate bands 4 and/or 5 (up to last 3 MMA operations).
  //    Valid values are 3, 4, 5
  int NumBandsToCompute_,
  // Scaling factor for decomposed matrices (2^ScalingFactor)
  // 8 for BF16, 11 for TF32
  int ScalingFactor_,
  // Number of UMMA instructions emulated a single stage
  // Ex: Staged16 has 1 FastF32 MMA per stage
  // Should be smaller than K-mode of a single ClusterTile
  int AccPromotionInterval_,
  // ClusterShape for the kernel
  class ClusterShape_ = Shape<_1,_1,_1>,
  // The TMEM_LOAD atom to be used for loading local accumulator
  // from TMEM to registers
  class AccumulatorCopyAtom_ = cute::SM100_TMEM_LOAD_32dp32b32x
>
struct MainloopSm100ArrayTmaUmmaWarpSpecializedFastF32 {
  constexpr static int Load2TransformPipelineStageCount = Load2TransformPipelineStageCount_;
  constexpr static int Transform2MmaPipelineStageCount = Transform2MmaPipelineStageCount_;
  constexpr static int NumBandsToCompute = NumBandsToCompute_;
  constexpr static int ScalingFactor = ScalingFactor_;
  constexpr static int AccPromotionInterval = AccPromotionInterval_;
  constexpr static detail::KernelInputTransformType InputTransformType = detail::KernelInputTransformType::FastF32;
  using ClusterShape = ClusterShape_;
  using AccumulatorCopyAtom = AccumulatorCopyAtom_;
  using ArchTag = arch::Sm100;
  using Schedule = KernelPtrArrayTmaWarpSpecializedInputTransformSm100<SchedulerPipelineStageCount_, AccumulatorPipelineStageCount_>;

  // For backwards compatibility with GemmUniversalAdapter.
  constexpr static int Stages = Load2TransformPipelineStageCount;
};



//////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm
