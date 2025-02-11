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

/*! \file
  \brief Visitor tree store operations for the sm100 TMA warp-specialized (ws) epilogue
*/



#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/detail/sm100_blockscaled_layout.hpp" 
#include "cute/tensor.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_tma_warpspecialized.hpp"
#include "cutlass/detail/helper_macros.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::fusion {

using namespace cute;
using namespace detail;

namespace detail {
  template <int SFVecSize, class ElementOutput, class ElementCompute, class ElementBlockScaleFactor, int FragmentSize, int NumVecs>
  CUTLASS_DEVICE auto
  compute_quantized_with_row_scalefactor(
      Array<ElementCompute, FragmentSize>& frg_compute,
      Array<ElementBlockScaleFactor, NumVecs>& frg_sf,
      ElementCompute norm_constant)
  {
    cutlass::multiplies<ElementCompute> mul;
    cutlass::multiplies<Array<ElementCompute, SFVecSize>> mul_array;

    Array<ElementOutput, FragmentSize> frg_output;
    auto output_frgs = reinterpret_cast<Array<ElementOutput, SFVecSize> *>(frg_output.data());
    auto compute_frgs = reinterpret_cast<Array< ElementCompute, SFVecSize> *>(frg_compute.data());

      Array<ElementCompute, NumVecs> qpvscale_rcps = [&]() CUTLASS_LAMBDA_FUNC_INLINE {
        if constexpr (cute::is_same_v<ElementBlockScaleFactor, float_ue8m0_t>) {
          // UE8M0: Use integer subtraction to do the fast rcp in ue8m0 and then convert to float.
          auto e8m0_qpvscale_rcp = cutlass::reciprocal_approximate<Array<ElementBlockScaleFactor, NumVecs>>{}(frg_sf);
          return cutlass::NumericArrayConverter<ElementCompute, ElementBlockScaleFactor, NumVecs>{}(e8m0_qpvscale_rcp);
        }
        else {
          // UE4M3: Do the rcp in fp32 data type.
          auto qpvscale_ups = cutlass::NumericArrayConverter<ElementCompute, ElementBlockScaleFactor, NumVecs>{}(frg_sf);
          return cutlass::reciprocal_approximate_ftz<decltype(qpvscale_ups)>{}(qpvscale_ups);
        }
      }();

      CUTLASS_PRAGMA_UNROLL
      for (int sf_v = 0; sf_v < NumVecs; ++sf_v) {
        // norm_constant and qpvscale_rcps[sf_v] are all positive numbers.
        ElementCompute acc_scale = mul(norm_constant, qpvscale_rcps[sf_v]);
        // Map INF to fp32::max
        acc_scale = minimum_with_nan_propagation<ElementCompute>{}(acc_scale, cutlass::platform::numeric_limits<ElementCompute>::max());
        // Convert to output type
        output_frgs[sf_v] = cutlass::NumericArrayConverter<ElementOutput, ElementCompute, SFVecSize>{}(mul_array(compute_frgs[sf_v], acc_scale));
      }
    return frg_output;
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// BlockScaleFactor Generation Operations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int SFVecSize,
  class EpilogueTile,
  class ElementOutput,
  class ElementCompute,
  class ElementBlockScaleFactor,
  FloatRoundStyle RoundStyle = FloatRoundStyle::round_to_nearest
>
struct Sm100BlockScaleFactorRowStore {
  static_assert(size<1>(EpilogueTile{}) % SFVecSize == 0, "EpilogueTileN should be divisible by SFVecSize");
  static_assert(size<1>(EpilogueTile{}) / SFVecSize == 1 or
                size<1>(EpilogueTile{}) / SFVecSize == 2 or
                size<1>(EpilogueTile{}) / SFVecSize == 4 or
                size<1>(EpilogueTile{}) / SFVecSize == 8,
                "Possible store in interleaved 4B aligned format");
  using NormalConstStrideMNL = Stride<_0,_0,int64_t>;
  struct SharedStorage { };

  struct Arguments {
    ElementBlockScaleFactor* ptr_scale_factor = nullptr;
    ElementCompute const* norm_constant_ptr = nullptr;
    NormalConstStrideMNL norm_constant_stride = {};
  };

  using Params = Arguments;

  using UnderlyingElementBlockScaleFactor = cute::remove_pointer_t<ElementBlockScaleFactor>;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    return args;
  }

  template <class ProblemShape>
  static bool
  can_implement(ProblemShape const& problem_shape, Arguments const& args) {
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M,N,K,L] = problem_shape_MNKL;
    bool implementable = (N % SFVecSize == 0);
    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: [EVT Sm100BlockScaleFactorRowStore] N-dim should be divisible by SFVecSize.\n");
    }
    return implementable;
  }

  template <class ProblemShape>
  static size_t
  get_workspace_size(ProblemShape const& problem_shape, Arguments const& args) {
    return 0;
  }

  template <class ProblemShape>
  static cutlass::Status
  initialize_workspace(ProblemShape const& problem_shape, Arguments const& args, void* workspace, cudaStream_t stream,
    CudaHostAdapter* cuda_adapter = nullptr) {
    return cutlass::Status::kSuccess;
  }

  CUTLASS_HOST_DEVICE
  Sm100BlockScaleFactorRowStore() { }

  CUTLASS_HOST_DEVICE
  Sm100BlockScaleFactorRowStore(Params const& params, SharedStorage const& shared_storage)
      : params_ptr(&params) { }

  Params const* params_ptr = nullptr;

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return false;
  }

  CUTLASS_DEVICE bool
  is_C_load_needed() const {
    return false;
  }

  template <class... Args>
  CUTLASS_DEVICE auto
  get_producer_load_callbacks(ProducerLoadArgs<Args...> const& args) {
    return EmptyProducerLoadCallbacks{};
  }

  template <
    class RTensor,
    class GTensor,
    class CoordGTensor,
    class ThrResidue,
    class EpiTileCoordMN,
    class ElementType
  >
  struct ConsumerStoreCallbacks : EmptyConsumerStoreCallbacks {
    CUTLASS_DEVICE
    ConsumerStoreCallbacks(
          RTensor&& tC_rSFD_,                   // (CPY,CPY_M,CPY_N)
          GTensor&& tC_gSFD_,                   // (CPY,CPY_M,CPY_N,EPI_M,EPI_N,#EPI_Ms, #EPI_Ns)
          CoordGTensor tC_cSFD_,                // (m,n)
          ThrResidue residue_tC_cSFD_,          // (m,n)
          Params const* params_ptr_,
          EpiTileCoordMN epi_tile_coord_mn_,    // (epi_tile_coord_m, epi_tile_coord_n)
          ElementType norm_constant_,
          ElementType norm_constant_scaled_down_)
      : tC_rSFD(cute::forward<RTensor>(tC_rSFD_))
      , tC_gSFD(cute::forward<GTensor>(tC_gSFD_))
      , tC_cSFD(tC_cSFD_)
      , residue_tC_cSFD(residue_tC_cSFD_)
      , params_ptr(params_ptr_)
      , norm_constant(norm_constant_)
      , norm_constant_scaled_down(norm_constant_scaled_down_)
      , epi_tile_coord_mn(epi_tile_coord_mn_){}

    static_assert(is_same_v<ElementType, ElementCompute>);
    RTensor tC_rSFD;
    GTensor tC_gSFD;
    CoordGTensor tC_cSFD;
    ThrResidue residue_tC_cSFD;
    Params const* params_ptr;
    ElementCompute norm_constant;
    ElementCompute norm_constant_scaled_down;
    EpiTileCoordMN epi_tile_coord_mn;

    template <class ElementAccumulator, class ElementInput, int FragmentSize>
    CUTLASS_DEVICE auto
    visit(Array<ElementAccumulator, FragmentSize> const& frg_acc,
          int epi_v,
          int epi_m,
          int epi_n,
          Array<ElementInput, FragmentSize> const& frg_input)
    {
      static_assert(FragmentSize % SFVecSize == 0, "Scale factor vector size should divide FragmentSize");
      constexpr int NumVecs = FragmentSize / SFVecSize;
      Array<ElementCompute, FragmentSize> frg_compute;

      auto input_frgs = reinterpret_cast<Array< ElementInput, SFVecSize> const*>(frg_input.data());
      auto compute_frgs = reinterpret_cast<Array< ElementCompute, SFVecSize> *>(frg_compute.data());

      Tensor tC_rSFD_frg = recast<cutlass::Array<UnderlyingElementBlockScaleFactor, NumVecs>>(coalesce(filter(tC_rSFD)));               // (EPI_V)

      cutlass::multiplies<ElementCompute> mul;
      cutlass::maximum_absolute_value_reduction<Array<ElementCompute, SFVecSize>, true> amax_reduction;

      cutlass::Array<ElementCompute, NumVecs> pvscales;
      // SF generation
      CUTLASS_PRAGMA_UNROLL
      for (int sf_v = 0; sf_v < NumVecs; ++sf_v) {
        compute_frgs[sf_v] = NumericArrayConverter<ElementCompute, ElementInput, SFVecSize>{}(input_frgs[sf_v]);
        /// Step1: get max across a vector
        ElementCompute vec_max = amax_reduction(ElementCompute(0), compute_frgs[sf_v]);
        /// Step2: Compute Scale
        pvscales[sf_v] = mul(vec_max, norm_constant_scaled_down);
      }

      tC_rSFD_frg(_0{}) = cutlass::NumericArrayConverter<UnderlyingElementBlockScaleFactor, ElementCompute, NumVecs>{}(pvscales);

      Tensor tCgSFD_flt = filter_zeros(tC_gSFD(_,_,_,_0{},_0{},get<0>(epi_tile_coord_mn) + epi_m, get<1>(epi_tile_coord_mn) + epi_n));
      Tensor tCrSFD_flt = filter_zeros(tC_rSFD);
      constexpr auto MCL = decltype(max_common_layout(tCgSFD_flt, tCrSFD_flt)){};
      constexpr int V = cute::min(4, size(MCL));
      using VecType = uint_bit_t<V * sizeof_bits_v<UnderlyingElementBlockScaleFactor>>;
      Tensor tCgSFD_vec = recast<VecType>(coalesce(tCgSFD_flt));
      Tensor tCrSFD_vec = recast<VecType>(coalesce(tCrSFD_flt));
      Tensor tCcSFD_pred = tC_cSFD(_,_,_, epi_m, epi_n);
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size(tCrSFD_vec); i++){
        if (elem_less(tCcSFD_pred(i * SFVecSize * V), residue_tC_cSFD)) {
          tCgSFD_vec(i) = tCrSFD_vec(i);
        }
      }
      /// Step3: Compute quantized output values
      return detail::compute_quantized_with_row_scalefactor<SFVecSize, ElementOutput>(frg_compute, tC_rSFD_frg(_0{}), norm_constant);
    }
  };

  template <
    bool ReferenceSrc, // do register tensors reference the src or dst layout of the tiled copy
    class... Args
  >
  CUTLASS_DEVICE auto
  get_consumer_store_callbacks(ConsumerStoreArgs<Args...> const& args) {

    auto [M, N, K, L] = args.problem_shape_mnkl;
    auto [tile_coord_m, tile_coord_n, tile_coord_k, tile_coord_l] = args.tile_coord_mnkl;
    using Sm100BlockScaledOutputConfig = cutlass::detail::Sm100BlockScaledOutputConfig<SFVecSize>;
    UnderlyingElementBlockScaleFactor* ptr_scale_factor = nullptr;
    // If Ptr-Array/Grouped GEMM with BlockScaleFactor per batch/group
    if constexpr (!cute::is_same_v<UnderlyingElementBlockScaleFactor, ElementBlockScaleFactor>) {
      ptr_scale_factor = params_ptr->ptr_scale_factor[tile_coord_l];
      tile_coord_l = 0;
    }
    else {
      ptr_scale_factor = params_ptr->ptr_scale_factor;
    }

    auto epi_tile_mn = shape<1>(zipped_divide(make_layout(take<0,2>(args.tile_shape_mnk)), args.epi_tile));
    Tensor mSFD = make_tensor(make_gmem_ptr(ptr_scale_factor), Sm100BlockScaledOutputConfig::tile_atom_to_shape_SFD(args.problem_shape_mnkl));
    static_assert(size<1>(EpilogueTile{}) && ((size<1>(EpilogueTile{}) & (size<1>(EpilogueTile{}) - 1)) == 0), "Epilogue Tile N should be pow of 2");
    Tensor gSFD = local_tile(mSFD, args.epi_tile, make_coord(_,_,tile_coord_l));                   // (EPI_M,EPI_N, #EPI_Ms, #EPI_Ns)
    Tensor tCgSFD = sm90_partition_for_epilogue<ReferenceSrc>(                                     // (CPY,CPY_M,CPY_N,EPI_M,EPI_N,#EPI_Ms, #EPI_Ns)
                        gSFD, args.epi_tile, args.tiled_copy, args.thread_idx);
    Tensor tCrSFD = make_tensor_like<UnderlyingElementBlockScaleFactor>(take<0,3>(cute::layout(tCgSFD)));    // (CPY,CPY_M,CPY_N)

    auto epi_tile_coord_mn = make_coord(tile_coord_m * size<0>(epi_tile_mn), tile_coord_n * size<1>(epi_tile_mn));

    // Fetch and compute these during initialization
    Tensor mNormConst= make_tensor(make_gmem_ptr(params_ptr->norm_constant_ptr), make_layout(make_shape(M, N, L), params_ptr->norm_constant_stride));
    ElementCompute norm_constant = mNormConst(_0{},_0{},tile_coord_l);
    ElementCompute fp_max = ElementCompute(cutlass::platform::numeric_limits<ElementOutput>::max());
    ElementCompute scale_down_factor = cutlass::reciprocal_approximate_ftz<ElementCompute>{}(fp_max);
    ElementCompute norm_constant_scaled_down = cutlass::multiplies<ElementCompute>{}(norm_constant, scale_down_factor);
#if 0
    if(threadIdx.x == 128 && blockIdx.x == 0 && blockIdx.y == 0){
      print("epi_tile     ");print(args.epi_tile);    print("\n");
      print("mSFD         ");print(mSFD);       print("\n");
      print("gSFD         ");print(gSFD);       print("\n");
      print("tCgSFD       ");print(tCgSFD);     print("\n");
      print("tCrSFD       ");print(tCrSFD);     print("\n");
      print("filter(tCrSFD) ");print(filter(tCrSFD));     print("\n");
      print("filter(tCgSFD) ");print(filter(tCgSFD));     print("\n");
    }
#endif

    return ConsumerStoreCallbacks(
      cute::move(tCrSFD),
      cute::move(tCgSFD),
      args.tCcD,
      args.residue_tCcD,
      params_ptr,
      epi_tile_coord_mn,
      norm_constant,
      norm_constant_scaled_down);

  }
};

} // namespace cutlass::epilogue::fusion

/////////////////////////////////////////////////////////////////////////////////////////////////
