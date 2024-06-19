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

#include "cutlass/cutlass.h"
#include "cutlass/gemm/dispatch_policy.hpp"

#include "cute/algorithm/functional.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/gemm.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/tensor_predicate.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////
 
namespace cutlass::gemm::collective {
using namespace cute;
/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class TileShape_,
  class ElementA_,
  class StrideA_,
  class ElementB_,
  class StrideB_,
  class TiledMma_,
  class GmemTiledCopyA_,
  class SmemLayoutAtomA_,
  class SmemCopyAtomA_,
  class TransformA_,
  class GmemTiledCopyB_,
  class SmemLayoutAtomB_,
  class SmemCopyAtomB_,
  class TransformB_>
struct CollectiveMma<
    MainloopIntelPVCUnpredicated,
    TileShape_,
    ElementA_,
    StrideA_,
    ElementB_,
    StrideB_,
    TiledMma_,
    GmemTiledCopyA_,
    SmemLayoutAtomA_,
    SmemCopyAtomA_,
    TransformA_,
    GmemTiledCopyB_,
    SmemLayoutAtomB_,
    SmemCopyAtomB_,
    TransformB_>
{
  //
  // Type Aliases
  //
  using DispatchPolicy = MainloopIntelPVCUnpredicated;
  using WorkgroupTileShape = TileShape_;
  using ElementA = ElementA_;
  using StrideA = StrideA_;
  using ElementB = ElementB_;
  using StrideB = StrideB_;
  using TiledMma = TiledMma_;
  using ElementAccumulator = typename TiledMma::ValTypeC;
  using GmemTiledCopyA = GmemTiledCopyA_;
  using GmemTiledCopyB = GmemTiledCopyB_;
  using SmemLayoutAtomA = SmemLayoutAtomA_;
  using SmemLayoutAtomB = SmemLayoutAtomB_;
  using SmemCopyAtomA = SmemCopyAtomA_;
  using SmemCopyAtomB = SmemCopyAtomB_;
  using TransformA = TransformA_;
  using TransformB = TransformB_;
  using ArchTag = typename DispatchPolicy::ArchTag;

  static constexpr int SubgroupSize = DispatchPolicy::SubgroupSize;

  using MmaAtomShape = typename TiledMma::AtomShape_MNK;
  using SubgroupTileShape = decltype(tile_shape(TiledMma()));

  static constexpr uint32_t MaxThreadsPerBlock =
          cute::size(WorkgroupTileShape{}) / cute::size(SubgroupTileShape{})* SubgroupSize;

  static constexpr int FragsM = get<0>(SubgroupTileShape{}) / get<0>(MmaAtomShape()); // A frags per sub_group
  static constexpr int FragsN = get<1>(SubgroupTileShape{}) / get<1>(MmaAtomShape()); // B frags per sub_group
  static constexpr int FragsK = get<2>(SubgroupTileShape{}) / get<2>(MmaAtomShape());

  // Calculate the vector width based on the amount of registers 
  // required per work item by dividing the total fragment size by 
  // the sub_group size.
  static constexpr int VecC = (get<1>(MmaAtomShape()) * get<0>(MmaAtomShape())) / SubgroupSize;
  static constexpr int VecA = (get<0>(MmaAtomShape()) * get<2>(MmaAtomShape())) / SubgroupSize;
  static constexpr int VecB = (get<1>(MmaAtomShape()) * get<2>(MmaAtomShape())) / SubgroupSize;

  // Host side kernel arguments
  struct Arguments {
    ElementA const* ptr_A;
    StrideA dA;
    ElementB const* ptr_B;
    StrideB dB;
  };

  struct Params {
    using XE_Copy_A = decltype(make_xe_2d_copy<GmemTiledCopyA>(make_tensor(static_cast<ElementA const*>(nullptr), 
                                repeat_like(StrideA{}, int32_t(0)), StrideA{})));
    using XE_Copy_B = decltype(make_xe_2d_copy<GmemTiledCopyB>(make_tensor(static_cast<ElementB const*>(nullptr), 
                                repeat_like(StrideB{}, int32_t(0)), StrideB{})));
    XE_Copy_A gmem_tiled_copy_a;
    XE_Copy_B gmem_tiled_copy_b;
  };

  //
  // Methods
  //

  CollectiveMma() = default;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    (void) workspace;

    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    Tensor tensorA = make_tensor(args.ptr_A, make_layout(make_shape(M,K,L), args.dA));
    Tensor tensorB = make_tensor(args.ptr_B, make_layout(make_shape(N,K,L), args.dB));

    typename Params::XE_Copy_A copyA = make_xe_2d_copy<GmemTiledCopyA>(tensorA);
    typename Params::XE_Copy_B copyB = make_xe_2d_copy<GmemTiledCopyB>(tensorB);
    return Params{copyA, copyB};
  }

  /// Perform a subgroup-scoped matrix multiply-accumulate
  template <
    class FrgTensorD,
    class TensorA,
    class TensorB,
    class FrgTensorC,
    class KTileIterator,
    class ResidueMNK
  >
  CUTLASS_DEVICE void
  operator() (
      FrgTensorD &accum,
      TensorA gA,
      TensorB gB,
      FrgTensorC const &src_accum,
      KTileIterator k_tile_iter, int k_tile_count,
      ResidueMNK residue_mnk,
      int thread_idx,
      char *smem_buf,
      Params const& mainloop) 
  {
    (void)residue_mnk;
    (void)thread_idx;
    (void)smem_buf;

    static_assert(is_rmem<FrgTensorD>::value, "D tensor must be rmem resident.");
    static_assert(is_tuple<typename TensorA::engine_type::iterator::value_type>::value, "A tensor must be a tuple iterator.");
    static_assert(is_tuple<typename TensorB::engine_type::iterator::value_type>::value, "B tensor must be a tuple iterator.");
    static_assert(is_rmem<FrgTensorC>::value, "C tensor must be rmem resident.");

    // Tensor to hold input data
    Tensor tAr = make_tensor<typename TiledMma::ValTypeA>(Shape<Int<get<0>(SubgroupTileShape{}) * FragsK>, _1>{});
    Tensor tBr = make_tensor<typename TiledMma::ValTypeB>(Shape<Int<get<1>(SubgroupTileShape{}) / 2>, Int<FragsN>>{});

    Tensor tAr_view = make_tensor(static_cast<decltype(tAr) &&>(tAr).data(),
                            Shape<Int<VecA>, Int<FragsM>, Int<FragsK>>{});
    Tensor tBr_view = make_tensor(static_cast<decltype(tBr) &&>(tBr).data(),
                            Shape<Int<VecB>, Int<FragsN>, Int<FragsK>>{},
                            Stride<_1, Int<get<1>(SubgroupTileShape{}) / 2>, Int<VecB>>{});

    // Instantiate the M MA object
    TiledMma tiled_mma;

    //
    // Mainloop
    //
   for (int k_tile = 0, k = 0; k_tile < k_tile_count; ++k_tile, k += get<2>(MmaAtomShape()) * FragsK)
   {
     // Copy gmem to rmem for the first k_tile
     copy(mainloop.gmem_tiled_copy_a, gA(_,_,k), tAr);
     copy(mainloop.gmem_tiled_copy_b, gB(_,_,k/2), tBr);

     cute::gemm(tiled_mma, accum, tAr_view, tBr_view, src_accum);
   }
  }
};

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
