/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "../collective/sm100_ssd_epilogue.hpp"
#include "../collective/sm100_ssd_gemm_tma_warpspecialized.hpp"
#include "../kernel/sm100_ssd_kernel_tma_warpspecialized.hpp"
#include "../kernel/sm100_ssd_tile_scheduler.hpp"

#include "cutlass/cutlass.h"
#include "cutlass/epilogue/collective/collective_builder.hpp"

namespace cutlass::ssd::kernel::detail {

template<
  class ElementA,
  class ElementB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB
>
constexpr auto
sm100_make_ts_tiled_mma() {
  return cutlass::gemm::collective::detail::sm100_make_1sm_ts_trivial_tiled_mma<
                ElementA, ElementB, ElementAccumulator,
                TileShape_MNK, ClusterShape_MNK, UmmaMajorA, UmmaMajorB>();
}

template<
  class ElementA,
  class ElementB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB
>
constexpr auto
sm100_make_ss_tiled_mma() {
  return cutlass::gemm::collective::detail::sm100_make_1sm_trivial_tiled_mma<
                ElementA, ElementB, ElementAccumulator,
                TileShape_MNK, ClusterShape_MNK, UmmaMajorA, UmmaMajorB>();
}

}

namespace cutlass::ssd::kernel {

template<
  class Element_,
  class ElementDA_,
  class ElementAcc_,
  class ElementY_,
  class TileShape_,
  bool HAS_D_,
  bool D_HAS_HDIM_
>
struct Sm100SsdBuilder {

  using Element = Element_;
  using ElementDA = ElementDA_;
  using ElementAcc = ElementAcc_;
  using ElementY = ElementY_;
  using TileShape = TileShape_;
  using ArchTag = cutlass::arch::Sm100;

  // hard-code
  using ClusterShape = Shape<_1,_1,_1>;

  static constexpr int StagesInput = 2;
  static constexpr int StagesOutput = 2;

  using TileShapeIntraBMM1 = decltype(make_shape(get<0>(TileShape{}), get<0>(TileShape{}), get<2>(TileShape{})));   // (L,L,N)
  using TileShapeIntraBMM2 = decltype(make_shape(get<0>(TileShape{}), get<1>(TileShape{}), get<0>(TileShape{})));   // (L,D,L)
  using TileShapeInterBMM1 = decltype(make_shape(get<2>(TileShape{}), get<1>(TileShape{}), get<0>(TileShape{})));   // (N,D,L)
  using TileShapeInterBMM2 = decltype(make_shape(get<0>(TileShape{}), get<1>(TileShape{}), get<2>(TileShape{})));   // (L,D,N)
  
  // LxLxN, NT
  using TiledMmaIntra1 = decltype(detail::sm100_make_ss_tiled_mma<Element, Element, ElementAcc,
                                                                  TileShapeIntraBMM1, ClusterShape,
                                                                  cute::UMMA::Major::MN, cute::UMMA::Major::MN>());
  // LxNxL, TN
  using TiledMmaIntra2 = decltype(detail::sm100_make_ts_tiled_mma<Element, Element, ElementAcc,
                                                                  TileShapeIntraBMM2, ClusterShape,
                                                                  cute::UMMA::Major::K, cute::UMMA::Major::K>());
  // NxDxL, TN
  using TiledMmaInter1 = decltype(detail::sm100_make_ts_tiled_mma<Element, Element, ElementAcc,
                                                                  TileShapeInterBMM1, ClusterShape,
                                                                  cute::UMMA::Major::K, cute::UMMA::Major::K>());
  // LxDxN, NN
  using TiledMmaInter2 = decltype(detail::sm100_make_ss_tiled_mma<Element, Element, ElementAcc,
                                                                  TileShapeInterBMM2, ClusterShape,
                                                                  cute::UMMA::Major::MN, cute::UMMA::Major::K>());

  // ((MMA_TILE_M,MMA_TILE_K), MMA_M, MMA_K)
  using MmaShapeC_MK = decltype(partition_shape_A(TiledMmaIntra1{}, make_shape(cute::size<0>(TileShapeIntraBMM1{}),
                                                                               cute::size<2>(TileShapeIntraBMM1{}))));
  using MmaShapeB_NK = decltype(partition_shape_B(TiledMmaIntra1{}, make_shape(cute::size<1>(TileShapeIntraBMM1{}),
                                                                               cute::size<2>(TileShapeIntraBMM1{}))));
  using MmaShapeQ_MK = decltype(partition_shape_A(TiledMmaIntra2{}, make_shape(cute::size<0>(TileShapeIntraBMM2{}),
                                                                               cute::size<2>(TileShapeIntraBMM2{}))));
  using MmaShapeX_NK = decltype(partition_shape_B(TiledMmaIntra2{}, make_shape(cute::size<1>(TileShapeIntraBMM2{}),
                                                                               cute::size<2>(TileShapeIntraBMM2{}))));

  using MmaShapeB_MK = decltype(partition_shape_A(TiledMmaInter1{}, make_shape(cute::size<0>(TileShapeInterBMM1{}),
                                                                               cute::size<2>(TileShapeInterBMM1{}))));
  using MmaShapeP_NK = decltype(partition_shape_B(TiledMmaInter2{}, make_shape(cute::size<1>(TileShapeInterBMM2{}),
                                                                               cute::size<2>(TileShapeInterBMM2{}))));

  using GmemTiledCopyX = cute::SM90_TMA_LOAD;
  using GmemTiledCopyB = cute::SM90_TMA_LOAD;
  using GmemTiledCopyC = cute::SM90_TMA_LOAD;

  using BlockTileX_N = decltype(cute::size<0,0>(MmaShapeX_NK{}) * cute::size<1>(MmaShapeX_NK{}));
  using BlockTileX_K = decltype(cute::size<0,1>(MmaShapeX_NK{}) * cute::size<2>(MmaShapeX_NK{}));
  using SmemLayoutAtomX = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      cute::UMMA::Major::K, Element, BlockTileX_N, BlockTileX_K>());

  using BlockTileB_N = decltype(cute::size<0,0>(MmaShapeB_NK{}) * cute::size<1>(MmaShapeB_NK{}));
  using BlockTileB_K = decltype(cute::size<0,1>(MmaShapeB_NK{}) * cute::size<2>(MmaShapeB_NK{}));
  using SmemLayoutAtomB = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      cute::UMMA::Major::MN, Element, BlockTileB_N, BlockTileB_K>());

  using BlockTileBT_M = decltype(cute::size<0,0>(MmaShapeB_MK{}) * cute::size<1>(MmaShapeB_MK{}));
  using BlockTileBT_K = decltype(cute::size<0,1>(MmaShapeB_MK{}) * cute::size<2>(MmaShapeB_MK{}));
  using SmemLayoutAtomBT = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      cute::UMMA::Major::K, Element, BlockTileBT_M, BlockTileBT_K>());
  using TmemLayoutAtomB = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      cute::UMMA::Major::K, Element, BlockTileBT_M, BlockTileBT_K>());

  using BlockTileC_M = decltype(cute::size<0,0>(MmaShapeC_MK{}) * cute::size<1>(MmaShapeC_MK{}));
  using BlockTileC_K = decltype(cute::size<0,1>(MmaShapeC_MK{}) * cute::size<2>(MmaShapeC_MK{}));
  using SmemLayoutAtomC = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      cute::UMMA::Major::MN, Element, BlockTileC_M, BlockTileC_K>());

  using BlockTileP_N = decltype(cute::size<0,0>(MmaShapeP_NK{}) * cute::size<1>(MmaShapeP_NK{}));
  using BlockTileP_K = decltype(cute::size<0,1>(MmaShapeP_NK{}) * cute::size<2>(MmaShapeP_NK{}));
  using SmemLayoutAtomP = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      cute::UMMA::Major::K, Element, BlockTileP_N, BlockTileP_K>());

  using SmemLayoutAtomPT = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      cute::UMMA::Major::MN, Element, BlockTileP_K, BlockTileP_N>());

  using BlockTileQ_M = decltype(cute::size<0,0>(MmaShapeQ_MK{}) * cute::size<1>(MmaShapeQ_MK{}));
  using BlockTileQ_K = decltype(cute::size<0,1>(MmaShapeQ_MK{}) * cute::size<2>(MmaShapeQ_MK{}));
  using SmemLayoutAtomQ = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      cute::UMMA::Major::K, Element, BlockTileP_N, BlockTileP_K>());
  using TmemLayoutAtomQ = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      cute::UMMA::Major::K, Element, BlockTileQ_M, BlockTileQ_K>());

  using SmemLayoutX = decltype(UMMA::tile_to_mma_shape(
      SmemLayoutAtomX{},
      append(MmaShapeX_NK{}, Int<StagesInput>{}),
      Step<_2,_1,_3>{}));
  using SmemLayoutB = decltype(UMMA::tile_to_mma_shape(
      SmemLayoutAtomB{},
      append(MmaShapeB_NK{}, Int<StagesInput>{}),
      Step<_2,_1,_3>{}));
  // Be consistent with SmemLayoutB
  using SmemLayoutBT = decltype(UMMA::tile_to_mma_shape(
      SmemLayoutAtomBT{},
      append(MmaShapeB_MK{}, Int<StagesInput>{}),
      Step<_1,_2,_3>{}));
  using TmemLayoutB = decltype(UMMA::tile_to_mma_shape(
      TmemLayoutAtomB{},
      append(MmaShapeB_MK{}, Int<1>{}),
      Step<_2,_1,_3>{}));
  using SmemLayoutC = decltype(UMMA::tile_to_mma_shape(
      SmemLayoutAtomC{},
      append(MmaShapeC_MK{}, Int<StagesInput>{}),
      Step<_2,_1,_3>{}));
  // P only need 1 stage in this case
  using SmemLayoutPT = decltype(tile_to_shape(
      SmemLayoutAtomPT{},
      append(make_shape(get<2>(TileShape{}), get<1>(TileShape{})), Int<1>{})));
  using SmemLayoutP = decltype(UMMA::tile_to_mma_shape(
      SmemLayoutAtomP{},
      append(MmaShapeP_NK{}, Int<1>{}), 
      Step<_2,_1,_3>{}));
  using TmemLayoutQ = decltype(UMMA::tile_to_mma_shape(
      TmemLayoutAtomQ{},
      append(MmaShapeQ_MK{}, Int<1>{}), 
      Step<_2,_1,_3>{}));
  using SmemLayoutQ = decltype(UMMA::tile_to_mma_shape(
      SmemLayoutAtomQ{},
      append(MmaShapeQ_MK{}, Int<2>{}), 
      Step<_2,_1,_3>{}));

  using SmemLayoutAtomXT = decltype(cutlass::gemm::collective::detail::ss_smem_selector<
      cute::GMMA::Major::MN, Element, decltype(get<0>(TileShape{})), decltype(get<1>(TileShape{}))>());
  using SmemLayoutXT = decltype(tile_to_shape(
      SmemLayoutAtomXT{},
      make_shape(size<0>(TileShape{}), size<1>(TileShape{}), Int<StagesInput>{}),
      Step<_1,_2,_3>{}));

  using EpilogueTileType = cutlass::epilogue::collective::EpilogueTileAuto;
  using Schedule = cutlass::epilogue::TmaWarpSpecialized;
  using EpilogueTile = Shape<Int<128>, Int<32>>;
  
  using SmemLayoutAtomY = decltype(cutlass::gemm::collective::detail::ss_smem_selector<
      cute::GMMA::Major::MN, ElementY, decltype(get<0>(EpilogueTile{})), decltype(get<1>(EpilogueTile{}))>());
  using SmemLayoutY = decltype(tile_to_shape(
      SmemLayoutAtomY{},
      make_shape(size<0>(EpilogueTile{}), size<1>(EpilogueTile{}), Int<StagesOutput>{}),
      Step<_2,_1,_3>{}));
  using SmemLayoutStoreP = decltype(tile_to_shape(
      SmemLayoutAtomP{},
      append(make_shape(get<1>(TileShape{}), get<2>(TileShape{})), Int<1>{}),
      Step<_2,_1,_3>{}));

  using CollectiveMainloop = cutlass::ssd::collective::SsdMainloopTmaWarpSpecialized<
    Element, ElementDA, ElementAcc, ElementY, TileShape,
    StagesInput, StagesOutput,
    TiledMmaIntra1, TiledMmaIntra2,
    TiledMmaInter1, TiledMmaInter2,
    SmemLayoutX, SmemLayoutB, SmemLayoutC, SmemLayoutP,
    SmemLayoutBT, SmemLayoutPT, SmemLayoutQ,
    TmemLayoutB, TmemLayoutQ>;
  using CollectiveEpilogue = cutlass::ssd::collective::SsdEpilogue<
    ElementAcc, Element, ElementDA, TileShape,
    EpilogueTile, SmemLayoutY, SmemLayoutStoreP, SmemLayoutXT, StagesInput, StagesOutput,
    HAS_D_, D_HAS_HDIM_>;
  using TileScheduler = cutlass::ssd::kernel::PersistentTileScheduler;
  using Kernel = cutlass::ssd::kernel::SsdKernelTmaWarpSpecialized<CollectiveMainloop, CollectiveEpilogue, TileScheduler>;

};

}
