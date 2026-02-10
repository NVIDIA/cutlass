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

#include "../collective/sm90_ssd_epilogue.hpp"
#include "../collective/sm90_ssd_gemm_tma_warpspecialized.hpp"
#include "../kernel/sm90_ssd_kernel_tma_warpspecialized.hpp"
#include "../kernel/sm90_ssd_tile_scheduler.hpp"

#include "cutlass/cutlass.h"
#include "cutlass/epilogue/collective/collective_builder.hpp"

namespace cutlass::ssd::kernel {

template<
  class Element_,
  class ElementDA_,
  class ElementAcc_,
  class ElementY_,
  class TileShape_,
  bool HAS_D_,
  bool D_HAS_HDIM_,
  bool HAS_Z_
>
struct Sm90SsdBuilder {

  using Element = Element_;
  using ElementDA = ElementDA_;
  using ElementAcc = ElementAcc_;
  using ElementY = ElementY_;
  using TileShape = TileShape_;

  static constexpr bool HAS_D = HAS_D_;
  static constexpr bool D_HAS_HDIM = D_HAS_HDIM_;
  static constexpr bool HAS_Z = HAS_Z_;

  static constexpr int StagesY = 2;
  static constexpr int StagesX = 2;
  static constexpr int StagesZ = 1; // smem size limitation
  using EpilogueTileType = cutlass::epilogue::collective::EpilogueTileAuto;
  using Schedule = cutlass::epilogue::TmaWarpSpecialized;
  using EpilogueTile = decltype(cutlass::epilogue::collective::detail::sm90_compute_tile_shape_or_override<
    ElementY, EpilogueTileType, Schedule, TileShape>());
  
  using SmemLayoutAtomY = decltype(cutlass::gemm::collective::detail::ss_smem_selector<
      cute::GMMA::Major::MN, ElementY, decltype(get<0>(EpilogueTile{})), decltype(get<1>(EpilogueTile{}))>());
  using SmemLayoutY = decltype(tile_to_shape(
      SmemLayoutAtomY{},
      make_shape(size<0>(EpilogueTile{}), size<1>(EpilogueTile{}), Int<StagesY>{}),
      Step<_2,_1,_3>{}));

  using SmemLayoutAtomX = decltype(cutlass::gemm::collective::detail::ss_smem_selector<
      cute::GMMA::Major::MN, Element, decltype(get<0>(TileShape{})), decltype(get<1>(TileShape{}))>());
  using SmemLayoutX = decltype(tile_to_shape(
      SmemLayoutAtomY{},
      make_shape(size<0>(TileShape{}), size<1>(TileShape{}), Int<StagesX>{}),
      Step<_2,_1,_3>{}));

  using SmemLayoutAtomZ = decltype(cutlass::gemm::collective::detail::ss_smem_selector<
      cute::GMMA::Major::MN, Element, decltype(get<0>(TileShape{})), decltype(get<1>(TileShape{}))>());
  using SmemLayoutZ = decltype(tile_to_shape(
      SmemLayoutAtomZ{},
      make_shape(size<0>(TileShape{}), size<1>(TileShape{}), Int<StagesZ>{}),
      Step<_2,_1,_3>{}));

  static constexpr auto epi_tile_m = size<0>(EpilogueTile{});
  static constexpr auto epi_tile_n = size<1>(EpilogueTile{});
  static constexpr auto partial_m = Int<128>{};
  static constexpr auto partial_n = Int<epi_tile_m * epi_tile_n / 128>{};

  using SmemLayoutAtomPartialY = typename GMMA::Layout_K_SW64_Atom<ElementAcc>;
  using SmemLayoutPartialY = decltype(tile_to_shape(
      SmemLayoutAtomPartialY{}, 
      make_shape(partial_m, partial_n, Int<StagesY>{})));
                                    
  using CollectiveMainloop = cutlass::ssd::collective::SsdMainloopTmaWarpSpecialized<Element, ElementDA, ElementAcc, ElementY, TileShape, StagesX>;
  using CollectiveEpilogue = cutlass::ssd::collective::SsdEpilogue<
    ElementAcc, ElementY, TileShape,
    EpilogueTile, SmemLayoutX, SmemLayoutY, SmemLayoutPartialY, typename CollectiveMainloop::SmemLayoutP, SmemLayoutZ,
    StagesX, StagesY, StagesZ,
    HAS_D, D_HAS_HDIM, HAS_Z>;
  using TileScheduler = cutlass::ssd::kernel::PersistentTileScheduler;
  using Kernel = cutlass::ssd::kernel::SsdKernelTmaWarpSpecialized<CollectiveMainloop, CollectiveEpilogue, TileScheduler>;

};

}
