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
//

//

#include "cutlass/gemm/collective/builders/sm100_common.inl"
#include "cutlass/gemm/collective/builders/sm100_pipeline_carveout.inl"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template <
  int CapacityBytes,
  class ElementA,
  class ElementB,
  class TileShapeMNK,
  class TileShapeSFA,
  class TileShapeSFB,
  int stages
>
constexpr int
sm100_compute_stage_count_or_override_blockscaled(StageCount<stages> stage_count) {
  return stages;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count.
template <
  int CapacityBytes,
  class ElementA,
  class ElementB,
  class TileShapeMNK,
  class TileShapeSFA,
  class TileShapeSFB,
  int carveout_bytes
>
constexpr int
sm100_compute_stage_count_or_override_blockscaled(StageCountAutoCarveout<carveout_bytes> stage_count) {
  // For MXF8F6F4 MMA, ElementA/B will be passed in as uint8_t
  // Each stage include (CollectiveMma::SharedStorage)
  // 1. smem for A and smem for B (CollectiveMma::SharedStorage::TensorStorage)
  // 2. one MainloopPipeline = PipelineTmaUmmaAsync (CollectiveMma::SharedStorage::SharedStorage)
  // 3. smem for SFB and smem for SFB (CollectiveMma::SharedStorage::TensorStorage, independent of input size b.c. sizeof(sf) is fixed)
  constexpr auto mainloop_pipeline_bytes = sizeof(typename cutlass::PipelineTmaUmmaAsync<1>::SharedStorage);
  constexpr auto a_bits = cute::sizeof_bits_v<ElementA>;
  constexpr auto b_bits = cute::sizeof_bits_v<ElementB>;
  constexpr auto stage_sfa_bytes = size(filter_zeros(TileShapeSFA{}));
  constexpr auto stage_sfb_bytes = size(filter_zeros(TileShapeSFB{}));

  constexpr int stage_bytes =
    cutlass::bits_to_bytes(a_bits * size<0>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    cutlass::bits_to_bytes(b_bits * size<1>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    static_cast<int>(mainloop_pipeline_bytes + stage_sfa_bytes + stage_sfb_bytes);

  return (CapacityBytes - carveout_bytes) / stage_bytes;
}

template <class ClusterShapeMNK, class AtomThrId>
constexpr auto
sm100_cluster_shape_to_tma_atom_SFB(ClusterShapeMNK cluster_shape_mnk, AtomThrId atom_thr_id) {
  static_assert(cute::rank(cluster_shape_mnk) == 3);
  if constexpr (cute::size(atom_thr_id) == 2) {
    // Always could use multicast feature for SFB with 2cta MMA.
    return cute::SM100_TMA_2SM_LOAD_MULTICAST{};
  }
  else if constexpr (size(atom_thr_id) == 1) {
      return detail::sm90_cluster_shape_to_tma_atom(cute::size<0>(cluster_shape_mnk));
  }
  else {
    static_assert(cutlass::detail::dependent_false<ClusterShapeMNK>,
        "Unsupported Configuration for SM100 TMA");
  }
}

namespace blockscaled {

enum class BlockScaledInstr {
  MXF4_NVF4,
  MXF4F6F8
};

template <class KernelScheduleType, class T>
struct blockscaled_type {};

template <class KernelScheduleType, class T, class SF>
struct blockscaled_type<KernelScheduleType, cute::tuple<T,SF>> {
  using sf_type = SF;
  using data_type = T;
  static constexpr uint32_t SfVectorSize = detail::find_vector_size<KernelScheduleType>();
};

template <class KernelScheduleType, class T, class SF, int SfVectorSize_>
struct blockscaled_type<KernelScheduleType, cute::tuple<T,SF, cute::Int<SfVectorSize_>>> {
  using sf_type = SF;
  using data_type = T;
  static constexpr uint32_t SfVectorSize = SfVectorSize_;
};

template <class KernelScheduleType, class T>
struct blockscaled_type<KernelScheduleType, cutlass::mx_float6_t<T>> {
  using sf_type = cutlass::float_ue8m0_t;
  using data_type = T;
  static constexpr uint32_t SfVectorSize = 32;
};

template <class KernelScheduleType, class T>
struct blockscaled_type<KernelScheduleType, cutlass::mx_float4_t<T>> {
  using sf_type = cutlass::float_ue8m0_t;
  using data_type = T;
  static constexpr uint32_t SfVectorSize = 32;
};

template <class KernelScheduleType, class T>
struct blockscaled_type<KernelScheduleType, nv_float4_t<T>> {
  using sf_type = cutlass::float_ue4m3_t;
  using data_type = T;
  static constexpr uint32_t SfVectorSize = 16;
};
template <class KernelScheduleType, class T>
struct blockscaled_type<KernelScheduleType, cutlass::mx_float8_t<T>> {
  using sf_type = cutlass::float_ue8m0_t;
  using data_type = T;
  static constexpr uint32_t SfVectorSize = 32;
};

template <
  class KernelScheduleType,
  class ElementPairA, class ElementPairB,
  UMMA::Major UmmaMajorA, UMMA::Major UmmaMajorB
>
CUTLASS_HOST_DEVICE
static constexpr bool
check_input_datatypes() {
  using ElementSFA = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::sf_type;
  using ElementSFB = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::sf_type;
  using ElementA = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::data_type;
  using ElementB = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::data_type;
  constexpr uint32_t SfVectorSizeA = detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::SfVectorSize;
  constexpr uint32_t SfVectorSizeB = detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::SfVectorSize;

  auto is_auto_instr_selection_policy = [&]() {
    return ((cute::is_same_v<KernelScheduleType, KernelScheduleAuto>)                                    ||
            (cute::is_same_v<KernelScheduleType, KernelScheduleBlockScaledGemmSm100>)                    ||
            (cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecialized1SmBlockScaledSm100>)           ||
            (cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecialized2SmBlockScaledSm100>)           ||
            (cute::is_same_v<KernelSchedulePtrArrayBlockScaledGemmSm100, KernelScheduleType>)            ||
            (cute::is_same_v<KernelPtrArrayTmaWarpSpecialized1SmBlockScaledSm100, KernelScheduleType>)   ||
            (cute::is_same_v<KernelPtrArrayTmaWarpSpecialized2SmBlockScaledSm100, KernelScheduleType>));
  };
  
  static_assert(cute::is_same_v<ElementSFA, ElementSFB>, "Scale factor types for A and B should be the same.");
  static_assert((SfVectorSizeA == SfVectorSizeB), "Scale factor vector size for A and B should be the same.");
  if constexpr ((SfVectorSizeA == 0) || (SfVectorSizeB == 0)) {
     static_assert(!is_auto_instr_selection_policy(), "Auto instr selection isn't valid if scale factor vector size can't be determined from the types");
  }

  static_assert(cute::is_same_v<ElementSFA, cutlass::float_ue8m0_t> 
                || cute::is_same_v<ElementSFA, cutlass::float_ue4m3_t>, "Incorrect scale factor type");

    if constexpr (((sizeof_bits_v<ElementA> == 4 || sizeof_bits_v<ElementA> == 6 || sizeof_bits_v<ElementA> == 8) &&
                   (sizeof_bits_v<ElementB> == 4 || sizeof_bits_v<ElementB> == 6 || sizeof_bits_v<ElementB> == 8)    ) &&  // A and B are 4, 6, or 8 bit types and
                  (!(sizeof_bits_v<ElementA> == 4 && sizeof_bits_v<ElementB> == 4)                                   )     // A and B are not both 4 bit types
                 ) {
      ///////////////////////////////////////////////////////////////////////
      // Mixed Precision FP4, FP6, FP8 case. -> MX_F4F6F8 instructions
      ///////////////////////////////////////////////////////////////////////
      // 1. Check Scale factor data type
      static_assert(cute::is_same_v<ElementSFA, cutlass::float_ue8m0_t>, "MX_F4F6F8 only supports ue8m0 SF type");
      // 2. Check whether A and B type combinations are valid or not
      static_assert(
        ( // If runtime datatypes are used, then both A and B should be runtime data type
          (
           cute::is_same_v<ElementA, cutlass::type_erased_dynamic_float8_t> ||
           cute::is_same_v<ElementA, cutlass::type_erased_dynamic_float6_t> ||
           cute::is_same_v<ElementA, cutlass::type_erased_dynamic_float4_t>
          ) &&
          (
           cute::is_same_v<ElementB, cutlass::type_erased_dynamic_float8_t> ||
           cute::is_same_v<ElementB, cutlass::type_erased_dynamic_float6_t> ||
           cute::is_same_v<ElementB, cutlass::type_erased_dynamic_float4_t>
          )
        ) ||
        ( // Valid (explicit) A and B type pairs
          (
           cute::is_same_v<ElementA, cutlass::float_e2m1_t> ||
           cute::is_same_v<ElementA, cutlass::float_e2m3_t> ||
           cute::is_same_v<ElementA, cutlass::float_e3m2_t> ||
           cute::is_same_v<ElementA, cutlass::float_e4m3_t> ||
           cute::is_same_v<ElementA, cutlass::float_e5m2_t> 
          ) &&
          (
           cute::is_same_v<ElementB, cutlass::float_e2m1_t> ||
           cute::is_same_v<ElementB, cutlass::float_e2m3_t> ||
           cute::is_same_v<ElementB, cutlass::float_e3m2_t> ||
           cute::is_same_v<ElementB, cutlass::float_e4m3_t> ||
           cute::is_same_v<ElementB, cutlass::float_e5m2_t> 
          )
        ), "Incorrect types for A and B for MX_F4F6F8"
      );
      // 3. Check Scale factor vector size is valid. 
      //   Only SfVectorSize = 32 is allowed.
      static_assert((SfVectorSizeA == 32) && (SfVectorSizeB == 32), "Incorrect SfVectorSize for MX_F4F6F8 is deduced. SfVectorSize should be 32.");
      // 4. Check the kernel policy. Kernel policy should be either auto or *MXf8f6f4*
      static_assert((cute::is_base_of_v<KernelScheduleMxf8f6f4Sm100, KernelScheduleType>          ||
                     cute::is_base_of_v<KernelSchedulePtrArrayMxf8f6f4Sm100, KernelScheduleType>  ||
                     is_auto_instr_selection_policy()), "Incorrect Kernel Schedule Policy for Mx_F4F6F8 type inputs.");

      return true;
    }
    else if constexpr ((sizeof_bits_v<ElementA> == 4 && sizeof_bits_v<ElementB> == 4)) {
      ///////////////////////////////////////////////////////////////////////
      // A and B are both 4 bit types
      // There are multiple block scaled tcgen05.mma instructions supporting F4 types.
      ///////////////////////////////////////////////////////////////////////

      // 1. Check Scale factor data type
      static_assert(cute::is_same_v<ElementSFA, cutlass::float_ue8m0_t> 
                      || cute::is_same_v<ElementSFA, cutlass::float_ue4m3_t>
                      , "MXNV_F4 supports ue8m0 and ue4m3 SF types");
      // 2. Check whether A and B type combinations are valid or not
      static_assert(
         ( // If runtime datatypes are used, then both A and B should be runtime data type
          cute::is_same_v<ElementA, cutlass::type_erased_dynamic_float4_t> && 
          cute::is_same_v<ElementB, cutlass::type_erased_dynamic_float4_t>
         ) ||
         ( // Valid (explicit) A and B type pairs
          (
            cute::is_same_v<ElementA, cutlass::float_e2m1_t>
          ) &&
          (
            cute::is_same_v<ElementB, cutlass::float_e2m1_t>
          )
         ), "Incorrect types for A and B for MXNV_F4");
        // 3. Skip checking the scale factor vector size. Will be checked later for specific Kernel Schedule policies.
        // 4. Check the kernel policy.
        static_assert((cute::is_base_of_v<KernelScheduleMxf8f6f4Sm100, KernelScheduleType>          ||
                       cute::is_base_of_v<KernelSchedulePtrArrayMxf8f6f4Sm100, KernelScheduleType>  ||
                       cute::is_base_of_v<KernelScheduleMxNvf4Sm100, KernelScheduleType>          ||
                       cute::is_base_of_v<KernelSchedulePtrArrayMxNvf4Sm100, KernelScheduleType>  ||
                       is_auto_instr_selection_policy()), "Incorrect Kernel Schedule Policy for F4 type inputs.");
        // If a policy is specified, do more checks
        if constexpr (cute::is_base_of_v<KernelScheduleMxf8f6f4Sm100, KernelScheduleType>
                      || cute::is_base_of_v<KernelSchedulePtrArrayMxf8f6f4Sm100, KernelScheduleType>
                     ) {
          // Perform additional checks. Only subset of FP4 and scale factor types are supported.
          static_assert(cute::is_same_v<ElementSFA, cutlass::float_ue8m0_t>, "MX_F4F6F8 only supports ue8m0 SF type");
          static_assert((cute::is_same_v<ElementA, cutlass::type_erased_dynamic_float4_t> && cute::is_same_v<ElementB, cutlass::type_erased_dynamic_float4_t>) ||
                        (cute::is_same_v<ElementA, cutlass::float_e2m1_t> && cute::is_same_v<ElementB, cutlass::float_e2m1_t>), "Incorrect types for A and B for MX_F4F6F8");
          static_assert((SfVectorSizeA == 32) && (SfVectorSizeB == 32), "Incorrect SfVectorSize for MX_F4F6F8 is deduced. SfVectorSize should be 32.");
          return true;
        }
        else if constexpr (cute::is_base_of_v<KernelScheduleMxNvf4Sm100, KernelScheduleType>
                           || cute::is_base_of_v<KernelSchedulePtrArrayMxNvf4Sm100, KernelScheduleType>
                          ) {
            static_assert((UmmaMajorA == UMMA::Major::K && UmmaMajorB == UMMA::Major::K), "MX/NV_F4 only supports RowMajor A, and ColMajorB");
            static_assert(detail::find_vector_size<KernelScheduleType>() == SfVectorSizeA, "Kernel Schedule policy doesn't match the scale factor vector size.");
          return true;
        }
        else { // auto policy
          // If the scale factor type is ue4m3 or the scale factor vector size is 16 -> only MXF4_NVF4 instruction can support it
          // For MXF4_NVF4, the layouts should be RowMajor A, and ColMajorB
          static_assert(is_auto_instr_selection_policy(), "Kernel Schedule policy should be auto");
          if constexpr (SfVectorSizeA == 16 || SfVectorSizeB == 16
                        || cute::is_same_v<ElementSFA, cutlass::float_ue4m3_t>
                       ) { // Only MXF4NVF4 can support these types
            static_assert((UmmaMajorA == UMMA::Major::K && UmmaMajorB == UMMA::Major::K), "NV_F4 only supports RowMajor A, and ColMajorB");
            return true;
          }
          return true;
        }
    }
    else {
      return false;
    }
  return false;
}

template <
  class TileShape_MNK, // (MmaAtomShape_M, MmaAtomShape_N, CtaTileShapeK)
  class ClusterShape_MNK,
  class KernelScheduleType
>
CUTLASS_HOST_DEVICE
static constexpr bool
is_2sm() {
  // 2SM kernel schedule is requested
  if constexpr (cute::is_base_of_v<KernelSchedule2Sm, KernelScheduleType>) { return true; }
  // 1SM kernel schedule is requested
  else if constexpr (cute::is_base_of_v<KernelSchedule1Sm, KernelScheduleType>) { return false; }
  // auto schedule is used.
  else {
    if constexpr (!cute::is_static_v<ClusterShape_MNK>) {
      // If the cluster shape is dynamic, we can't guarantee 2x1. Default to 1sm.
      // If tile shape M is 256, throw an error. M=256 is only supported by 2SM instructions.
      static_assert(get<0>(TileShape_MNK{}) != 256, "If M=256, auto policy can't create 2sm kernels. Specify a 2SM policy");
      return false;
    }
    else if constexpr (cute::is_static_v<ClusterShape_MNK> && cute::get<0>(ClusterShape_MNK{}) % 2 == 0) {
      // We need to check the TileShape
      if constexpr (get<0>(TileShape_MNK{}) == 256) {
        return true;
      }
      else if constexpr (get<0>(TileShape_MNK{}) == 128) {
        return false;
      }
      else {
        static_assert(get<0>(TileShape_MNK{}) == 0, "Unsupported M dimension for TileShape_MNK.");
      }
    }
    else { return false;}
  }
}

template <
  class ElementPairA,
  class ElementPairB,
  class ElementAccumulator,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  class KernelScheduleType
>
CUTLASS_HOST_DEVICE
static constexpr auto
select_instr() {
  using ElementSFA = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::sf_type;
  using ElementSFB = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::sf_type;
  using ElementA = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::data_type;
  using ElementB = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::data_type;
  constexpr uint32_t SfVectorSizeA = detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::SfVectorSize;
  constexpr uint32_t SfVectorSizeB = detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::SfVectorSize;
  constexpr int SFVectorSize = SfVectorSizeA > SfVectorSizeB ? SfVectorSizeA : SfVectorSizeB;
  using ElementSF = ElementSFA;

  if constexpr (cute::is_base_of_v<KernelScheduleMxf8f6f4Sm100, KernelScheduleType>
                || cute::is_base_of_v<KernelSchedulePtrArrayMxf8f6f4Sm100, KernelScheduleType>
                ) {
    return detail::blockscaled::BlockScaledInstr::MXF4F6F8;
  }
  else if constexpr (cute::is_base_of_v<KernelScheduleMxNvf4Sm100, KernelScheduleType>
                      || cute::is_base_of_v<KernelSchedulePtrArrayMxNvf4Sm100, KernelScheduleType>
                    ) {
    return detail::blockscaled::BlockScaledInstr::MXF4_NVF4;
  }
  else {
    // Auto scheduling
    if constexpr ((sizeof_bits_v<ElementA> >= 6 && sizeof_bits_v<ElementA> <= 8) &&
                  (sizeof_bits_v<ElementB> >= 6 && sizeof_bits_v<ElementB> <= 8)) {
      // These types can only be supported by MX_F8F6F4 instruction
      static_assert(SFVectorSize == 32, "Incorrect SF vector size");
      return detail::blockscaled::BlockScaledInstr::MXF4F6F8;
    }
    else if constexpr (( sizeof_bits_v<ElementA> == 4 && (sizeof_bits_v<ElementB> == 6 || sizeof_bits_v<ElementB> == 8)) ||
                      ((sizeof_bits_v<ElementA> == 6 || sizeof_bits_v<ElementA> == 8) && sizeof_bits_v<ElementB> == 4)) {
      // Fp4 can be mixed with FP6, Fp8 with MMA.MXF8F6F4 only
      return detail::blockscaled::BlockScaledInstr::MXF4F6F8;
    }
    else if constexpr (sizeof_bits_v<ElementA> == 4 && sizeof_bits_v<ElementB> == 4) {
      // Both A and B are 4bits
      if constexpr (UmmaMajorA == UMMA::Major::K && UmmaMajorB == UMMA::Major::K) {
        // MXF4_NVF4 possible
        return detail::blockscaled::BlockScaledInstr::MXF4_NVF4;
      }
      else {
        static_assert(SFVectorSize == 32, "Incorrect SF vector size");
        static_assert( cute::is_same_v<ElementSF, cutlass::float_ue8m0_t> &&
                      (cute::is_same_v<ElementA, cutlass::float_e2m1_t> && cute::is_same_v<ElementB, cutlass::float_e2m1_t> ||
                        cute::is_same_v<ElementA, cutlass::type_erased_dynamic_float4_t> && cute::is_same_v<ElementB, cutlass::type_erased_dynamic_float4_t>),
                      "Only MXF4 support with non-TN and MMA.MXF8F6F4.");
        return detail::blockscaled::BlockScaledInstr::MXF4F6F8;
      }
    }
  }
}

} // namespace blockscaled

template <
  class ElementPairA,
  class ElementPairB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  detail::blockscaled::BlockScaledInstr Instr,
  class KernelScheduleType
>
constexpr auto
sm100_make_blockscaled_1sm_trivial_tiled_mma() {
  // For MMA_1sm atoms, the MMA's AtomLayout is same as the ClusterShape
  using AtomLayout_MNK = Layout<ClusterShape_MNK>;
  constexpr int M = cute::size<0>(TileShape_MNK{});
  static_assert(M == 128, "Invalid TileShape_M.");

  // Do not allow a tiled MMA N mode > 1, as that is not reasonable.
  constexpr int N = cute::size<1>(TileShape_MNK{});
  static_assert(N == 128 || N == 192 || N == 256, "Invalid TileShape_N.");

  using ElementSFA = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::sf_type;
  using ElementSFB = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::sf_type;
  using ElementA = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::data_type;
  using ElementB = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::data_type;
  constexpr uint32_t SfVectorSizeA = detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::SfVectorSize;
  [[maybe_unused]] constexpr uint32_t SfVectorSizeB = detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::SfVectorSize;

  using ElementAMma = decltype(cutlass::gemm::collective::detail::sm100_kernel_input_element_to_mma_input_element<ElementA, Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8>());
  using ElementBMma = decltype(cutlass::gemm::collective::detail::sm100_kernel_input_element_to_mma_input_element<ElementB, Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8>());

  using ElementSF = ElementSFA;

  if constexpr (Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8) {

    return make_tiled_mma(cute::SM100_MMA_MXF8F6F4_SS<ElementAMma, ElementBMma, ElementAccumulator, ElementSF,
                                                 M, N, UmmaMajorA, UmmaMajorB>{});
  }
  else if constexpr (Instr == detail::blockscaled::BlockScaledInstr::MXF4_NVF4) {
    constexpr int SFVectorSize = SfVectorSizeA;
    return make_tiled_mma(cute::SM100_MMA_MXF4_SS<ElementAMma, ElementBMma, ElementAccumulator, ElementSF,
                                                 M, N, SFVectorSize, UmmaMajorA, UmmaMajorB>{});
  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementAMma>,
        "Unsupported configuration for SM100 collective builder.");
  }
}

template <
  class ElementPairA,
  class ElementPairB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  detail::blockscaled::BlockScaledInstr Instr,
  class KernelScheduleType
>
constexpr auto
sm100_make_blockscaled_2sm_trivial_tiled_mma() {

  constexpr int M = cute::size<0>(TileShape_MNK{});
  static_assert(M == 256, "Invalid TileShape_M.");

  // Do not allow a tiled MMA N mode > 1, as that is not reasonable.
  constexpr int N = cute::size<1>(TileShape_MNK{});
  static_assert(N == 128 || N == 192 || N == 256, "Invalid TileShape_N.");

  using ElementSFA = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::sf_type;
  using ElementSFB = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::sf_type;
  using ElementA = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::data_type;
  using ElementB = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::data_type;
  constexpr uint32_t SfVectorSizeA = detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::SfVectorSize;
  [[maybe_unused]] constexpr uint32_t SfVectorSizeB = detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::SfVectorSize;
  using ElementAMma = decltype(cutlass::gemm::collective::detail::sm100_kernel_input_element_to_mma_input_element<ElementA, Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8>());
  using ElementBMma = decltype(cutlass::gemm::collective::detail::sm100_kernel_input_element_to_mma_input_element<ElementB, Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8>());

  using ElementSF = ElementSFA;

  if constexpr (Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8) {
    return make_tiled_mma(cute::SM100_MMA_MXF8F6F4_2x1SM_SS<ElementAMma, ElementBMma, ElementAccumulator, ElementSF,
                                                       M, N, UmmaMajorA, UmmaMajorB>{});
  }
  else if constexpr (Instr == detail::blockscaled::BlockScaledInstr::MXF4_NVF4) {
    constexpr int SFVectorSize = SfVectorSizeA > SfVectorSizeB ? SfVectorSizeA : SfVectorSizeB;
    return make_tiled_mma(cute::SM100_MMA_MXF4_2x1SM_SS<ElementAMma, ElementBMma, ElementAccumulator, ElementSF,
                                                       M, N, SFVectorSize, UmmaMajorA, UmmaMajorB>{});
  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementAMma>,
        "Unsupported configuration for SM100 collective builder.");
  }
}


template <
  class ElementPairA,
  class ElementPairB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  detail::blockscaled::BlockScaledInstr Instr,
  class KernelScheduleType,
  bool Is2SM
>
struct TrivialBlockscaledMma {};

template <
  class ElementPairA,
  class ElementPairB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  detail::blockscaled::BlockScaledInstr Instr,
  class KernelScheduleType
>
struct TrivialBlockscaledMma <
  ElementPairA,
  ElementPairB,
  ElementAccumulator,
  TileShape_MNK,
  ClusterShape_MNK,
  UmmaMajorA,
  UmmaMajorB,
  Instr,
  KernelScheduleType,
  true /*Is2SM*/> {
    using type = decltype(sm100_make_blockscaled_2sm_trivial_tiled_mma<ElementPairA, ElementPairB, ElementAccumulator,
                                                        TileShape_MNK, ClusterShape_MNK, UmmaMajorA, UmmaMajorB, Instr, KernelScheduleType>());
  };

template <
  class ElementPairA,
  class ElementPairB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  detail::blockscaled::BlockScaledInstr Instr,
  class KernelScheduleType
>
struct TrivialBlockscaledMma<
  ElementPairA,
  ElementPairB,
  ElementAccumulator,
  TileShape_MNK,
  ClusterShape_MNK,
  UmmaMajorA,
  UmmaMajorB,
  Instr,
  KernelScheduleType,
  false /*Is2SM*/> {
    using type = decltype(sm100_make_blockscaled_1sm_trivial_tiled_mma<ElementPairA, ElementPairB, ElementAccumulator,
                                                        TileShape_MNK, ClusterShape_MNK, UmmaMajorA, UmmaMajorB, Instr, KernelScheduleType>());
};
} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class ElementPairA,
  class GmemLayoutATag,
  int AlignmentA,
  class ElementPairB,
  class GmemLayoutBTag,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,        // (MmaAtomShapeM, MmaAtomShapeN, TileK)
  class ClusterShape_MNK,     // Static cluster shape or dynamic (int, int, _1)
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm100,
    arch::OpClassBlockScaledTensorOp,
    ElementPairA,
    GmemLayoutATag,
    AlignmentA,
    ElementPairB,
    GmemLayoutBTag,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      // Blockscaled Gemm
      (cute::is_base_of_v<KernelScheduleBlockScaledGemmSm100, KernelScheduleType> ||
       cute::is_same_v<KernelScheduleAuto, KernelScheduleType>) 
       &&
      // Alignment check
      detail::sm1xx_blockscaled_gemm_is_aligned<typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::data_type,
                                                AlignmentA,
                                                typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::data_type,
                                                AlignmentB,
                                                KernelScheduleType>()>>
{
  using ElementSFA = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::sf_type;
  using ElementSFB = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::sf_type;
  using ElementA = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairA>::data_type;
  using ElementB = typename detail::blockscaled::blockscaled_type<KernelScheduleType, ElementPairB>::data_type;
  using ElementSF = ElementSFA;

  static constexpr cute::UMMA::Major UmmaMajorA = cutlass::gemm::collective::detail::tag_to_umma_major_A<GmemLayoutATag>();
  static constexpr cute::UMMA::Major UmmaMajorB = cutlass::gemm::collective::detail::tag_to_umma_major_B<GmemLayoutBTag>();

  static_assert(cute::is_static_v<TileShape_MNK>, "TileShape has to be static");
  static_assert(detail::blockscaled::check_input_datatypes<KernelScheduleType, ElementPairA, ElementPairB, UmmaMajorA, UmmaMajorB>(), "Incorrect input types");

  static constexpr bool is_2sm = detail::blockscaled::is_2sm<TileShape_MNK, ClusterShape_MNK, KernelScheduleType>();
  static constexpr auto Instr = detail::blockscaled::select_instr<ElementPairA, ElementPairB, ElementAccumulator, UmmaMajorA, UmmaMajorB, KernelScheduleType>();

  using TiledMma = typename cutlass::gemm::collective::detail::TrivialBlockscaledMma<ElementPairA, ElementPairB, ElementAccumulator,
                                                                  TileShape_MNK, ClusterShape_MNK,
                                                                  UmmaMajorA, UmmaMajorB, Instr, KernelScheduleType, is_2sm>::type;

  static constexpr bool UseMxf8f6f4 = Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8;

  static_assert(UseMxf8f6f4 || (cutlass::gemm::detail::is_k_major_A<GmemLayoutATag>() && cutlass::gemm::detail::is_k_major_B<GmemLayoutBTag>()), "Only MMA.MXF8F6F4 supports non-K major inputs");

  // Data type used by MMA instruction
  using ElementAMma = decltype(cutlass::gemm::collective::detail::sm100_kernel_input_element_to_mma_input_element<ElementA, UseMxf8f6f4>());
  using ElementBMma = decltype(cutlass::gemm::collective::detail::sm100_kernel_input_element_to_mma_input_element<ElementB, UseMxf8f6f4>());

  static_assert(detail::sm100_gemm_check_for_f8f6f4_mix8bit_requirement<ElementAMma, ElementBMma,
                                                                      TileShape_MNK, ClusterShape_MNK,
                                                                      UmmaMajorA, UmmaMajorB, KernelScheduleType, is_2sm>(),
                "TileSize and MNK Major does not met with MMA Mix 8-bit TMA load requirement" );

  static constexpr uint32_t SFVectorSize = TiledMma::SFVecSize;

  // Basic storage block for new Scaling Factor Layouts
  using AtomThrID = typename TiledMma::AtomThrID;
  using Sm100BlkScaledConfig = cutlass::detail::Sm100BlockScaledConfig<SFVectorSize>;

  using ElementAMma_SmemAllocType = cute::conditional_t<UseMxf8f6f4, uint8_t, ElementAMma>;
  using ElementBMma_SmemAllocType = cute::conditional_t<UseMxf8f6f4, uint8_t, ElementBMma>;

  // ((MMA_TILE_M,MMA_TILE_K), MMA_M, MMA_K)
  using MmaShapeA_MK = decltype(partition_shape_A(TiledMma{}, make_shape(cute::size<0>(TileShape_MNK{}),
                                                                         cute::size<2>(TileShape_MNK{}))));
  // ((MMA_TILE_N,MMA_TILE_K), MMA_N, MMA_K)
  using MmaShapeB_NK = decltype(partition_shape_B(TiledMma{}, make_shape(cute::size<1>(TileShape_MNK{}),
                                                                         cute::size<2>(TileShape_MNK{}))));

  using GmemTiledCopyA = decltype(cutlass::gemm::collective::detail::sm100_cluster_shape_to_tma_atom_A(
      ClusterShape_MNK{}, AtomThrID{}));

  using GmemTiledCopyB = decltype(cutlass::gemm::collective::detail::sm100_cluster_shape_to_tma_atom_B(
      ClusterShape_MNK{}, AtomThrID{}));

  using GmemTiledCopySFA = decltype(cutlass::gemm::collective::detail::sm100_cluster_shape_to_tma_atom_A(
      ClusterShape_MNK{}, AtomThrID{}));

  using GmemTiledCopySFB = decltype(cutlass::gemm::collective::detail::sm100_cluster_shape_to_tma_atom_SFB(
      ClusterShape_MNK{}, AtomThrID{})); 

  using GmemTiledCopyPairA = decltype(cute::make_tuple(GmemTiledCopyA{}, GmemTiledCopySFA{}));
  using GmemTiledCopyPairB = decltype(cute::make_tuple(GmemTiledCopyB{}, GmemTiledCopySFB{}));

  //
  // Construct SMEM layout (SmemLayoutAtom) for A and SFA
  //
  using BlockTileA_M = decltype(cute::size<0,0>(MmaShapeA_MK{}) * cute::size<1>(MmaShapeA_MK{}));
  using BlockTileA_K = decltype(cute::size<0,1>(MmaShapeA_MK{}) * cute::size<2>(MmaShapeA_MK{}));
  using SmemLayoutAtomA = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      UmmaMajorA, ElementAMma_SmemAllocType, BlockTileA_M, BlockTileA_K>());

  // A single indivisible block will hold 4 scale factors of 128 rows/columns (A/B matrix).
  // 4 is chosen to make consecutive 32bits of data to have scale factors for only a single row (col). 32bits corresponds to the TMEM word size 
  using Blk_MN    = typename Sm100BlkScaledConfig::Blk_MN;
  using Blk_SF    = typename Sm100BlkScaledConfig::Blk_SF; 
  using Blk_Elems = decltype(Blk_MN{} * Blk_SF{});
  using SmemLayoutAtomSFA = decltype(Sm100BlkScaledConfig::deduce_smem_layoutSFA(TiledMma{}, TileShape_MNK{}));
  using SmemLayoutAtomsA = decltype(cute::make_tuple(SmemLayoutAtomA{}, SmemLayoutAtomSFA{}));

  //
  // Construct SMEM layout (SmemLayoutAtom) for B and SFB
  //
  using BlockTileB_N = decltype(cute::size<0,0>(MmaShapeB_NK{}) * cute::size<1>(MmaShapeB_NK{}));
  using BlockTileB_K = decltype(cute::size<0,1>(MmaShapeB_NK{}) * cute::size<2>(MmaShapeB_NK{}));
  using SmemLayoutAtomB = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      UmmaMajorB, ElementBMma_SmemAllocType, BlockTileB_N, BlockTileB_K>());
  using SmemLayoutAtomSFB = decltype(Sm100BlkScaledConfig::deduce_smem_layoutSFB(TiledMma{}, TileShape_MNK{}));
  using SmemLayoutAtomsB = decltype(cute::make_tuple(SmemLayoutAtomB{}, SmemLayoutAtomSFB{}));

  //
  // Construct Strides for A, SFA, B, and SFB
  //
  using StrideA = cutlass::gemm::TagToStrideA_t<GmemLayoutATag>;
  using StrideB = cutlass::gemm::TagToStrideB_t<GmemLayoutBTag>;
  using InternalStrideA  = cute::remove_pointer_t<StrideA>;
  using InternalStrideB  = cute::remove_pointer_t<StrideB>;
  using InternalLayoutSFA = decltype(Sm100BlkScaledConfig::deduce_layoutSFA());
  using InternalLayoutSFB = decltype(Sm100BlkScaledConfig::deduce_layoutSFB());
  using LayoutSFA = cute::conditional_t<cute::is_same_v<InternalStrideA, StrideA>, InternalLayoutSFA, InternalLayoutSFA *>;
  using LayoutSFB = cute::conditional_t<cute::is_same_v<InternalStrideB, StrideB>, InternalLayoutSFB, InternalLayoutSFB *>;
  using StridePairA = decltype(cute::make_tuple(StrideA{}, LayoutSFA{}));
  using StridePairB = decltype(cute::make_tuple(StrideB{}, LayoutSFB{}));

  static constexpr int MMA_N = cute::size<1>(TileShape_MNK{});
  static constexpr uint32_t AccumulatorPipelineStageCount = (MMA_N == 256) ? 1 : 2;
  // Grouped GEMM (where Stride type is Stride*) does not use CLC based scheduler.
  static constexpr uint32_t SchedulerPipelineStageCount = cute::is_same_v<InternalStrideA, StrideA> ? 3 : 1;
  static constexpr bool IsArrayOfPointersGemm = cute::is_base_of_v<KernelSchedulePtrArrayBlockScaledGemmSm100, KernelScheduleType>;
  static constexpr uint32_t KernelSmemCarveout = detail::Sm100DenseGemmTmaUmmaCarveout<
      ClusterShape_MNK,
      AccumulatorPipelineStageCount,
      SchedulerPipelineStageCount,
      detail::CLCResponseSize,
      IsArrayOfPointersGemm,
      4 // 4 Tensor maps for A, SFA, B and SFB
    >::KernelSmemCarveout;
  // Reduce SMEM capacity available for buffers considering barrier allocations.
  static constexpr int Sm100ReducedSmemCapacityBytes = cutlass::gemm::collective::detail::sm100_smem_capacity_bytes - KernelSmemCarveout;

  using SmemTileShape = cute::Shape<BlockTileA_M, BlockTileB_N, BlockTileA_K>;

  static constexpr int PipelineStages = cutlass::gemm::collective::detail::sm100_compute_stage_count_or_override_blockscaled<
      Sm100ReducedSmemCapacityBytes, ElementAMma_SmemAllocType, ElementBMma_SmemAllocType, SmemTileShape, SmemLayoutAtomSFA, SmemLayoutAtomSFB>(StageCountType{});
  static_assert(PipelineStages > 0, "Smem usage is too high. Can't create any SMEM buffers for A, B, SFA, and SFB.");

  using DispatchPolicy = 
    cute::conditional_t<IsArrayOfPointersGemm,
      cutlass::gemm::MainloopSm100ArrayTmaUmmaWarpSpecializedBlockScaled<
          PipelineStages,
          SchedulerPipelineStageCount,
          AccumulatorPipelineStageCount,
          ClusterShape_MNK
      >,
      cutlass::gemm::MainloopSm100TmaUmmaWarpSpecializedBlockScaled<
          PipelineStages,
          SchedulerPipelineStageCount,
          AccumulatorPipelineStageCount,
          ClusterShape_MNK
      >
    >;

  using CollectiveOp = cutlass::gemm::collective::CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      cute::tuple<ElementA, ElementSF>,
      StridePairA,
      cute::tuple<ElementB, ElementSF>,
      StridePairB,
      TiledMma,
      GmemTiledCopyPairA,
      SmemLayoutAtomsA,
      void,
      cute::identity,
      GmemTiledCopyPairB,
      SmemLayoutAtomsB,
      void,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
