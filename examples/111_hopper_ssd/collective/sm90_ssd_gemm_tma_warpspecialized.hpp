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

#include "cutlass/cutlass.h"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "../collective/common.hpp"

namespace cutlass::ssd::collective {

using namespace cute;

template<
  class Element_,
  class ElementDA_,
  class ElementAcc_,
  class ElementD_,
  class TileShape_,
  int Stages_
>
struct SsdMainloopTmaWarpSpecialized {

  using Element = Element_;
  using ElementDA = ElementDA_;
  using ElementAcc = ElementAcc_;
  using TileShape = TileShape_;                                                                     // (L,D,N)

  // avoid "warning #3357-D: capturing structured bindings is a C++20 feature"
  static constexpr auto L = get<0>(TileShape{});
  static constexpr auto D = get<1>(TileShape{});
  static constexpr auto N = get<2>(TileShape{});

  using TileShapeIntraBMM1 = decltype(make_shape(L, L, N));                                         // (L,L,N)
  using TileShapeIntraBMM2 = decltype(make_shape(L, D, N));                                         // (L,D,L)
  using TileShapeInterBMM1 = decltype(make_shape(N, D, L));                                         // (N,D,L)
  using TileShapeInterBMM2 = decltype(make_shape(L, D, N));                                         // (L,D,N)

  using ClusterShape = Shape<_1, _1, _1>;

  // 16B alignment lets us use TMA
  static constexpr int Alignment = 16 / sizeof(Element);

  using Stages = cutlass::gemm::collective::StageCount<Stages_>;
  // IntraMma1 NT
  using CollectiveIntraMma1 = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      Element, cutlass::layout::ColumnMajor, Alignment,
      Element, cutlass::layout::RowMajor, Alignment,
      ElementAcc,
      TileShapeIntraBMM1, ClusterShape, Stages,
      cutlass::gemm::KernelTmaWarpSpecialized>::CollectiveOp;
  // IntraMma2 TN
  using CollectiveIntraMma2 = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      Element, cutlass::layout::RowMajor, Alignment,
      Element, cutlass::layout::ColumnMajor, Alignment,
      ElementAcc,
      TileShapeIntraBMM2, ClusterShape, Stages,
      cutlass::gemm::KernelTmaWarpSpecialized>::CollectiveOp;
  // InterMma1 TN
  using CollectiveInterMma1 = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      Element, cutlass::layout::RowMajor, Alignment,
      Element, cutlass::layout::ColumnMajor, Alignment,
      ElementAcc,
      TileShapeInterBMM1, ClusterShape, Stages,
      cutlass::gemm::KernelTmaWarpSpecialized>::CollectiveOp;
  // InterMma2 NN
  using CollectiveInterMma2 = typename cutlass::gemm::collective::CollectiveBuilder<
      cutlass::arch::Sm90, cutlass::arch::OpClassTensorOp,
      Element, cutlass::layout::ColumnMajor, Alignment,
      Element, cutlass::layout::ColumnMajor, Alignment,
      ElementAcc,
      TileShapeInterBMM2, ClusterShape, Stages,
      cutlass::gemm::KernelTmaWarpSpecialized>::CollectiveOp;
  
  using TiledMmaIntra1 = typename CollectiveIntraMma1::TiledMma;
  using TiledMmaIntra2 = decltype(convert_to_gmma_rs(typename CollectiveIntraMma2::TiledMma{}));
  using TiledMmaInter1 = decltype(convert_to_gmma_rs(typename CollectiveInterMma1::TiledMma{}));
  using TiledMmaInter2 = typename CollectiveInterMma2::TiledMma;

  using SmemLayoutX = typename CollectiveIntraMma2::SmemLayoutB;
  using SmemLayoutC = typename CollectiveIntraMma1::SmemLayoutA;
  using SmemLayoutB = typename CollectiveIntraMma1::SmemLayoutB;

  // Use 1 stage buffer since it is immediate result by the previous gemm
  using SmemLayoutP_Ref = typename CollectiveInterMma2::SmemLayoutB;
  using SmemLayoutP = decltype(take<0,2>(SmemLayoutP_Ref{}));

  using MainloopPipelineX = cutlass::PipelineTmaAsync<Stages::value>;
  using MainloopPipelineB = cutlass::PipelineTmaAsync<Stages::value>;
  using MainloopPipelineC = cutlass::PipelineTmaAsync<Stages::value>;
  using MainloopPipelineDelta = cutlass::PipelineTmaAsync<Stages::value>;

  static constexpr int kXLoadBytes = size(SmemLayoutX{}(_,_,_0{})) * sizeof(Element);
  static constexpr int kBLoadBytes = size(SmemLayoutB{}(_,_,_0{})) * sizeof(Element);
  static constexpr int kCLoadBytes = size(SmemLayoutC{}(_,_,_0{})) * sizeof(Element);
  static constexpr int kDeltaLoadBytes = get<0>(TileShape{}) * sizeof(Element);
  static constexpr int kDeltaALoadBytes = get<0>(TileShape{}) * sizeof(ElementDA);

  struct SharedStorage : cute::aligned_struct<128, _0> {
    cute::array_aligned<Element, cute::cosize_v<SmemLayoutX>> smem_x;
    cute::array_aligned<Element, cute::cosize_v<SmemLayoutB>> smem_b;
    cute::array_aligned<Element, cute::cosize_v<SmemLayoutC>> smem_c;
    cute::array_aligned<Element, cute::cosize_v<SmemLayoutP>> smem_p;
    cute::array_aligned<Element, get<0>(TileShape{}) * Stages::value> smem_delta;
    cute::array_aligned<ElementDA, get<0>(TileShape{}) * Stages::value> smem_delta_a;
    cute::array_aligned<Element, get<1>(TileShape{}) * Stages::value> smem_d;
  };

  using LayoutX     = decltype(make_layout(make_shape(D, L, int32_t(0), int32_t(0)), make_stride(int32_t(0), _1{}, L, int32_t(0))));  // (D,L,C,B)
  using LayoutB     = decltype(make_layout(make_shape(L, N, int32_t(0), int32_t(0)), make_stride(_1{}, int32_t(0), L, int32_t(0))));  // (L,N,C,B)
  using LayoutC     = decltype(make_layout(make_shape(L, N, int32_t(0), int32_t(0)), make_stride(_1{}, int32_t(0), L, int32_t(0))));  // (L,N,C,B)
  using LayoutDelta = decltype(make_layout(make_shape(L,    int32_t(0), int32_t(0)), make_stride(_1{},             L, int32_t(0))));  // (L,C,B)

  // Not support Mcast
  using GmemTiledCopyX = cute::SM90_TMA_LOAD;
  using GmemTiledCopyB = cute::SM90_TMA_LOAD;
  using GmemTiledCopyC = cute::SM90_TMA_LOAD;

  struct Arguments {
    const Element* ptr_X{nullptr};
    const ElementDA* ptr_DeltaA{nullptr};
    const Element* ptr_Delta{nullptr};
    const Element* ptr_B{nullptr};
    const Element* ptr_C{nullptr};
    LayoutX        layout_X{};
    LayoutB        layout_B{};
    LayoutC        layout_C{};
    LayoutDelta    layout_Delta{};
  };

  struct Params {
    using TMA_X = decltype(make_tma_copy(
        GmemTiledCopyX{},
        make_tensor(static_cast<Element const*>(nullptr), LayoutX{}),
        SmemLayoutX{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShapeIntraBMM2{}), shape<2>(TileShapeIntraBMM2{})),
        _1{}));
    using TMA_B = decltype(make_tma_copy(
        GmemTiledCopyB{},
        make_tensor(static_cast<Element const*>(nullptr), LayoutB{}),
        SmemLayoutB{}(_,_,cute::Int<0>{}),
        make_shape(shape<0>(TileShapeIntraBMM1{}), shape<2>(TileShapeIntraBMM1{})),
        _1{}));
    using TMA_C = decltype(make_tma_copy(
        GmemTiledCopyC{},
        make_tensor(static_cast<Element const*>(nullptr), LayoutC{}),
        SmemLayoutC{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShapeIntraBMM1{}), shape<2>(TileShapeIntraBMM1{})),
        _1{}));
    using TensorDelta = decltype(make_tensor(
      make_gmem_ptr(static_cast<Element const*>(nullptr)),
      LayoutDelta{}));
    using TensorDeltaA = decltype(make_tensor(
      make_gmem_ptr(static_cast<ElementDA const*>(nullptr)),
      LayoutDelta{}));

    TMA_X         tma_load_x;
    TMA_B         tma_load_b;
    TMA_C         tma_load_c;
    TensorDelta   tensor_delta;
    TensorDeltaA  tensor_delta_a;
  };

  template<class ProblemShape>
  static bool can_implement(ProblemShape const& problem_size, Arguments const& args) {
    return true;
  }

  template<class ProblemShape>
  static Params to_underlying_arguments(ProblemShape const& problem_size, Arguments const& args, void* workspace) {

    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;

    Tensor tensor_x = make_tensor(make_gmem_ptr(args.ptr_X), args.layout_X);
    Tensor tensor_b = make_tensor(make_gmem_ptr(args.ptr_B), args.layout_B);
    Tensor tensor_c = make_tensor(make_gmem_ptr(args.ptr_C), args.layout_C);
    Tensor tensor_delta = make_tensor(make_gmem_ptr(args.ptr_Delta), args.layout_Delta);
    Tensor tensor_delta_a = make_tensor(make_gmem_ptr(args.ptr_DeltaA), args.layout_Delta);

#if 0
    print("tensor_x      : ");print(tensor_x);print("\n");
    print("smem_X        : ");print(SmemLayoutX{});print("\n");
    print("tensor_b      : ");print(tensor_b);print("\n");
    print("smem_b        : ");print(SmemLayoutB{});print("\n");
    print("tensor_c      : ");print(tensor_c);print("\n");
    print("smem_c        : ");print(SmemLayoutC{});print("\n");
    print("tensor_delta  : ");print(tensor_delta);print("\n");
    print("tensor_delta_a: ");print(tensor_delta_a);print("\n");
    print("tile          : ");print(TileShape{});print("\n");
    print("tileIntra1    : ");print(TileShapeIntraBMM1{});print("\n");
    print("tileIntra2    : ");print(TileShapeIntraBMM2{});print("\n");
    print("tileInter1    : ");print(TileShapeInterBMM1{});print("\n");
    print("tileInter2    : ");print(TileShapeInterBMM2{});print("\n");
#endif

    typename Params::TMA_X tma_load_x = make_tma_copy(
        GmemTiledCopyX{},
        tensor_x,
        SmemLayoutX{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShapeIntraBMM2{}), shape<2>(TileShapeIntraBMM2{})),
        _1{});
    typename Params::TMA_B tma_load_b = make_tma_copy(
        GmemTiledCopyB{},
        tensor_b,
        SmemLayoutB{}(_,_,cute::Int<0>{}),
        make_shape(shape<0>(TileShapeIntraBMM1{}), shape<2>(TileShapeIntraBMM1{})),
        _1{});
    typename Params::TMA_C tma_load_c = make_tma_copy(
        GmemTiledCopyC{},
        tensor_c,
        SmemLayoutC{}(_,_,cute::Int<0>{}),
        make_shape(shape<1>(TileShapeIntraBMM1{}), shape<2>(TileShapeIntraBMM1{})),
        _1{});

    return Params{
      tma_load_x,
      tma_load_b,
      tma_load_c,
      tensor_delta,
      tensor_delta_a
    };
  }

  CUTLASS_DEVICE
  static void prefetch_tma_descriptors(Params const& params) {
    cute::prefetch_tma_descriptor(params.tma_load_x.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_b.get_tma_descriptor());
    cute::prefetch_tma_descriptor(params.tma_load_c.get_tma_descriptor());
  }

  template <
    class Params, class ProblemShape
  >
  CUTLASS_DEVICE 
  auto load_x_init(Params const& params, ProblemShape const& problem_size) {

    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;

    Tensor mX_mkl = params.tma_load_x.get_tma_tensor(make_shape(D,L,C,EH*B));
    Tensor gX_mkl = local_tile(mX_mkl, TileShapeIntraBMM2{}, make_coord(_,_,_), Step<X,_1,_1>{});        // (BLK_M,BLK_K,m,k,l)

#if 0
    if (threadIdx.x % 32 == 0 && (blockIdx.x + blockIdx.y + blockIdx.z == 0)) {
      print("mX_mkl  : ");print(mX_mkl);print("\n");
      print("gX_mkl  : ");print(gX_mkl);print("\n");
    }
#endif
    return make_tuple(gX_mkl);
  }
  
  template<
    class Params, class ProblemShape,
    class MainloopPipeline, class PipelineState,
    class GTensor,
    class TensorStorage
  >
  CUTLASS_DEVICE
  void load_x(
    int const& blk_coord, Params const& params, ProblemShape const& problem_size,
    MainloopPipeline& pipeline, PipelineState& pipeline_state,
    cute::tuple<GTensor> const& load_inputs,
    TensorStorage& shared_tensors) {
    
    int lane_predicate = cute::elect_one_sync();

    if (lane_predicate) {
      Tensor sX_ = make_tensor(make_smem_ptr(shared_tensors.smem_x.data()), SmemLayoutX{});       // (BLK_M,BLK_K,PIPE)
      Tensor sX  = as_position_independent_swizzle_tensor(sX_);                                  // (BLK_M,BLK_K,PIPE)

      //
      // Prepare the TMA loads for X
      //

      Tensor gX_mkl = get<0>(load_inputs);

      // Partition the inputs based on the current block coordinates.
      Tensor gX = gX_mkl(_,_,_0{},_0{},_,blk_coord);                                             // (BLK_M,BLK_K,k)

      // no multicast
      auto tma_load_x = params.tma_load_x.get_slice(_0{});
      // Applies the mapping from block_tma_a
      Tensor tXgX = tma_load_x.partition_S(gX);                                           // (TMA,TMA_M,TMA_K,k)
      Tensor tXsX = tma_load_x.partition_D(sX);                                           // (TMA,TMA_M,TMA_K,PIPE)

#if 0
    if (threadIdx.x % 32 == 0 && (blockIdx.x + blockIdx.y + blockIdx.z == 0)) {
      print("tXgX  : ");print(tXgX);print("\n");
      print("tXsX  : ");print(tXsX);print("\n");
    }
#endif
      // Disable multicast
      uint16_t mcast_mask_x = 0;

      auto chunk = get<3>(problem_size);
      // Mainloop
      CUTLASS_PRAGMA_NO_UNROLL
      for (int chunk_idx = 0; chunk_idx < chunk; ++chunk_idx) {
        int write_stage = pipeline_state.index();

        // LOCK pipeline_state for _writing_
        pipeline.producer_acquire(pipeline_state);

        //
        // Copy gmem to smem for chunk
        //

        using BarrierType = typename MainloopPipeline::ProducerBarrierType;
        BarrierType* tma_barrier = pipeline.producer_get_barrier(pipeline_state);

        copy(params.tma_load_x.with(*tma_barrier, mcast_mask_x), tXgX(_,_,_,chunk_idx), tXsX(_,_,_,write_stage));

        // Advance pipeline_state
        ++pipeline_state;
      }
    }
  }

  /// Perform a Producer Epilogue to prevent early exit of blocks in a Cluster
  template<
    class MainloopPipeline, class PipelineState
  >
  CUTLASS_DEVICE void
  load_x_tail(MainloopPipeline pipeline, PipelineState pipeline_state) {
    int lane_predicate = cute::elect_one_sync();

    // Issue the epilogue waits
    if (lane_predicate) {
      /* This helps avoid early exit of blocks in Cluster
       * Waits for all stages to either be released (all 
       * Consumer UNLOCKs), or if the stage was never used
       * then would just be acquired since the phase was 
       * still inverted from make_producer_start_state
       */
      pipeline.producer_tail(pipeline_state);
    }
  }

  template <
    class Params, class ProblemShape
  >
  CUTLASS_DEVICE 
  auto load_b_init(Params const& params, ProblemShape const& problem_size) {

    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;

    Tensor mB_mkl = params.tma_load_b.get_tma_tensor(make_shape(L,N,C,G*B));
    Tensor gB_mkl = local_tile(mB_mkl, TileShapeIntraBMM1{}, make_coord(_,_,_), Step<_1, X,_1>{});        // (BLK_M,BLK_K,m,k,l)

#if 0
    if (threadIdx.x % 32 == 0 && (blockIdx.x + blockIdx.y + blockIdx.z == 0)) {
      print("mB_mkl  : ");print(mB_mkl);print("\n");
      print("gB_mkl  : ");print(gB_mkl);print("\n");
    }
#endif
    return make_tuple(gB_mkl);
  }
  
  template<
    class Params, class ProblemShape,
    class MainloopPipelineB, class PipelineStateB,
    class MainloopPipelineC, class PipelineStateC,
    class GTensorB, class GTensorC,
    class TensorStorage
  >
  CUTLASS_DEVICE
  void load_b_c(
    int const& blk_coord, Params const& params, ProblemShape const& problem_size,
    MainloopPipelineB& pipeline_b, PipelineStateB& pipeline_state_b,
    MainloopPipelineC& pipeline_c, PipelineStateC& pipeline_state_c,
    cute::tuple<GTensorB> const& load_inputs_b,
    cute::tuple<GTensorC> const& load_inputs_c,
    TensorStorage& shared_tensors) {
    
    int lane_predicate = cute::elect_one_sync();

    if (lane_predicate) {
      Tensor sB_ = make_tensor(make_smem_ptr(shared_tensors.smem_b.data()), SmemLayoutB{});       // (BLK_M,BLK_K,PIPE)
      Tensor sB  = as_position_independent_swizzle_tensor(sB_);                                  // (BLK_M,BLK_K,PIPE)
      Tensor sC_ = make_tensor(make_smem_ptr(shared_tensors.smem_c.data()), SmemLayoutC{});       // (BLK_M,BLK_K,PIPE)
      Tensor sC  = as_position_independent_swizzle_tensor(sC_);                                  // (BLK_M,BLK_K,PIPE)

      //
      // Prepare the TMA loads for B
      //

      Tensor gB_mkl = get<0>(load_inputs_b);
      Tensor gB = gB_mkl(_,_,_0{},_0{},_,blk_coord);                                             // (BLK_M,BLK_K,k)
      // no multicast
      auto tma_load_b = params.tma_load_b.get_slice(_0{});
      // Applies the mapping from block_tma_a
      Tensor tBgB = tma_load_b.partition_S(gB);                                           // (TMA,TMA_M,TMA_K,k)
      Tensor tBsB = tma_load_b.partition_D(sB);                                           // (TMA,TMA_M,TMA_K,PIPE)
      
      //
      // Prepare the TMA loads for X
      //

      Tensor gC_mkl = get<0>(load_inputs_c);
      Tensor gC = gC_mkl(_,_,_0{},_0{},_,blk_coord);                                             // (BLK_M,BLK_K,k)
      // no multicast
      auto tma_load_c = params.tma_load_c.get_slice(_0{});
      // Applies the mapping from block_tma_a
      Tensor tCgC = tma_load_c.partition_S(gC);                                           // (TMA,TMA_M,TMA_K,k)
      Tensor tCsC = tma_load_c.partition_D(sC);                                           // (TMA,TMA_M,TMA_K,PIPE)

#if 0
    if (threadIdx.x % 32 == 0 && (blockIdx.x + blockIdx.y + blockIdx.z == 0)) {
      print("tCgC  : ");print(tCgC);print("\n");
      print("tCsC  : ");print(tCsC);print("\n");
      print("tBgB  : ");print(tBgB);print("\n");
      print("tBsB  : ");print(tBsB);print("\n");
    }
#endif
      // Disable multicast
      uint16_t mcast_mask_b = 0;
      uint16_t mcast_mask_c = 0;

      auto chunk = get<3>(problem_size);
      // Mainloop
      CUTLASS_PRAGMA_NO_UNROLL
      for (int chunk_idx = 0; chunk_idx < chunk; ++chunk_idx) {
        int write_stage_b = pipeline_state_b.index();
        int write_stage_c = pipeline_state_c.index();

        // Load B
        pipeline_b.producer_acquire(pipeline_state_b);

        using BarrierTypeB = typename MainloopPipelineB::ProducerBarrierType;
        BarrierTypeB* tma_barrier_b = pipeline_b.producer_get_barrier(pipeline_state_b);

        copy(params.tma_load_b.with(*tma_barrier_b, mcast_mask_b), tBgB(_,_,_,chunk_idx), tBsB(_,_,_,write_stage_b));

        // Advance pipeline_state
        ++pipeline_state_b;

        // Load C
        pipeline_c.producer_acquire(pipeline_state_c);

        using BarrierTypeC = typename MainloopPipelineC::ProducerBarrierType;
        BarrierTypeC* tma_barrier_c = pipeline_c.producer_get_barrier(pipeline_state_c);

        copy(params.tma_load_c.with(*tma_barrier_c, mcast_mask_c), tCgC(_,_,_,chunk_idx), tCsC(_,_,_,write_stage_c));

        // Advance pipeline_state
        ++pipeline_state_c;
      }
    }
  }

  template <
    class Params, class ProblemShape
  >
  CUTLASS_DEVICE 
  auto load_c_init(Params const& params, ProblemShape const& problem_size) {

    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;

    Tensor mC_mkl = params.tma_load_c.get_tma_tensor(make_shape(L,N,C,G*B));
    Tensor gC_mkl = local_tile(mC_mkl, TileShapeIntraBMM1{}, make_coord(_,_,_), Step<X,_1,_1>{});        // (BLK_M,BLK_K,n,k,l)

#if 0
    if (threadIdx.x % 32 == 0 && (blockIdx.x + blockIdx.y + blockIdx.z == 0)) {
      print("mC_mkl  : ");print(mC_mkl);print("\n");
      print("gC_mkl  : ");print(gC_mkl);print("\n");
    }
#endif
    return make_tuple(gC_mkl);
  }

  /// Perform a Producer Epilogue to prevent early exit of blocks in a Cluster
  template<
    class MainloopPipelineB, class PipelineStateB,
    class MainloopPipelineC, class PipelineStateC
  >
  CUTLASS_DEVICE void
  load_b_c_tail(MainloopPipelineB pipeline_b, PipelineStateB pipeline_state_b,
                MainloopPipelineC pipeline_c, PipelineStateC pipeline_state_c) {
    int lane_predicate = cute::elect_one_sync();

    // Issue the epilogue waits
    if (lane_predicate) {
      /* This helps avoid early exit of blocks in Cluster
       * Waits for all stages to either be released (all 
       * Consumer UNLOCKs), or if the stage was never used
       * then would just be acquired since the phase was 
       * still inverted from make_producer_start_state
       */
      pipeline_b.producer_tail(pipeline_state_b);
      pipeline_c.producer_tail(pipeline_state_c);
    }
  }

  template<
    class Params, class ProblemShape,
    class MainloopPipeline, class PipelineState,
    class TensorStorage
  >
  CUTLASS_DEVICE
  void load_delta(
    int const& blk_coord, Params const& params, ProblemShape const& problem_size,
    MainloopPipeline& pipeline, PipelineState& pipeline_state,
    TensorStorage& shared_tensors) {
    
    int lane_predicate = cute::elect_one_sync();

    if (lane_predicate) {

      auto& gDelta = params.tensor_delta;
      auto& gDeltaA = params.tensor_delta_a;
      
      Element* ptr_delta = shared_tensors.smem_delta.data();
      ElementDA* ptr_delta_a = shared_tensors.smem_delta_a.data();
      auto smem_layout = make_layout(make_shape(get<0>(TileShape{}), Int<Stages::value>{}));
      auto sDelta = cute::as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(ptr_delta), smem_layout));
      auto sDeltaA = cute::as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(ptr_delta_a), smem_layout));

      auto bulk_atom_dt = Copy_Atom<SM90_BULK_COPY_AUTO, Element>{};
      auto bulk_atom_dA = Copy_Atom<SM90_BULK_COPY_AUTO, ElementDA>{};

      auto chunk = get<3>(problem_size);
      // Mainloop
      CUTLASS_PRAGMA_NO_UNROLL
      for (int chunk_idx = 0; chunk_idx < chunk; ++chunk_idx) {
        int write_stage = pipeline_state.index();

        // LOCK pipeline_state for _writing_
        pipeline.producer_acquire(pipeline_state);

        using BarrierType = typename MainloopPipeline::ProducerBarrierType;
        BarrierType* tma_barrier = pipeline.producer_get_barrier(pipeline_state);
        copy(bulk_atom_dt.with(*tma_barrier), gDelta(_,chunk_idx,blk_coord), sDelta(_,write_stage));
        copy(bulk_atom_dA.with(*tma_barrier), gDeltaA(_,chunk_idx,blk_coord), sDeltaA(_,write_stage));

        // Advance pipeline_state
        ++pipeline_state;
      }
    }
  }
  
  /// Perform a Producer Epilogue to prevent early exit of blocks in a Cluster
  template<
    class MainloopPipeline, class PipelineState
  >
  CUTLASS_DEVICE void
  load_delta_tail(MainloopPipeline pipeline, PipelineState pipeline_state) {
    int lane_predicate = cute::elect_one_sync();

    // Issue the epilogue waits
    if (lane_predicate) {
      /* This helps avoid early exit of blocks in Cluster
       * Waits for all stages to either be released (all 
       * Consumer UNLOCKs), or if the stage was never used
       * then would just be acquired since the phase was 
       * still inverted from make_producer_start_state
       */
      pipeline.producer_tail(pipeline_state);
    }
  }

  template<
    class MainloopPipelineB, class PipelineStateB,
    class MainloopPipelineC, class PipelineStateC,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto mma_intra_1(
    int& chunk,
    MainloopPipelineB& pipeline_b, PipelineStateB& pipeline_state_b,
    MainloopPipelineC& pipeline_c, PipelineStateC& pipeline_state_c,
    TensorStorage& shared_tensors) {

    int thread_idx = int(threadIdx.x % 128);

    int read_b_stage = pipeline_state_b.index();
    int read_c_stage = pipeline_state_c.index();

    TiledMmaIntra1 tiled_mma;
    auto thr_mma = tiled_mma.get_thread_slice(thread_idx);

    // Mainloop setup QK
    Tensor sB = make_tensor(make_smem_ptr(shared_tensors.smem_b.data()), SmemLayoutB{});
    Tensor sC = make_tensor(make_smem_ptr(shared_tensors.smem_c.data()), SmemLayoutC{});

    Tensor tCsC = thr_mma.partition_A(sC);                                   // (MMA,MMA_M,MMA_K,PIPE)
    Tensor tBsB = thr_mma.partition_B(sB);                                   // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tCrC = thr_mma.make_fragment_A(tCsC);                            // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tBrB = thr_mma.make_fragment_B(tBsB);                            // (MMA,MMA_M,MMA_N,PIPE)

    Tensor accumulator = partition_fragment_C(tiled_mma, take<0, 2>(TileShapeIntraBMM1{}));

    auto barrier_token_b = pipeline_b.consumer_try_wait(pipeline_state_b);
    auto barrier_token_c = pipeline_c.consumer_try_wait(pipeline_state_c);

    pipeline_b.consumer_wait(pipeline_state_b, barrier_token_b);
    pipeline_c.consumer_wait(pipeline_state_c, barrier_token_c);

#if 0
    if (threadIdx.x % 128 == 0  && (blockIdx.x + blockIdx.y + blockIdx.z == 0) && chunk == 0) {
      print("tBsB         : ");print(tBsB);print("\n");
      print("tCsC         : ");print(tCsC);print("\n");
      print("tBrB         : ");print(tBrB);print("\n");
      print("tCrC         : ");print(tCrC);print("\n");
      print("accumulator  : ");print(accumulator);print("\n");
    }
#endif

    warpgroup_fence_operand(accumulator);
    warpgroup_arrive();
    gemm_zero_acc(tiled_mma, tCrC(_,_,_,read_c_stage), tBrB(_,_,_,read_b_stage), accumulator);
    warpgroup_commit_batch();

    warpgroup_wait<0>();

    // Maybe delay
    pipeline_b.consumer_release(pipeline_state_b);
    ++pipeline_state_b;
    pipeline_c.consumer_release(pipeline_state_c);
    ++pipeline_state_c;

    return make_tuple(accumulator);
  }

  template<
    class MainloopPipelineDelta, class PipelineStateDelta,
    class TensorIntra1,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto pre_intra_2(
    int& chunk,
    MainloopPipelineDelta& pipeline_delta, PipelineStateDelta& pipeline_state_delta,
    TensorIntra1& tIntra1,
    TensorStorage& shared_tensors) {
    
    int thread_idx = int(threadIdx.x % 128);
    int read_delta_stage = pipeline_state_delta.index();
    
    auto synchronize = [&] () { cutlass::arch::NamedBarrier::sync(128, cutlass::arch::ReservedNamedBarriers::TransformBarrier); };

    TiledMmaIntra1 mma;
    
    auto ts0 = size<0>(TileShape{});

    Layout row_layout = make_layout(make_shape ( ts0,  ts0, Int<Stages::value>{}),
                                    make_stride(_0{}, _1{}, ts0));
    Layout col_layout = make_layout(make_shape ( ts0,  ts0, Int<Stages::value>{}),
                                    make_stride(_1{}, _0{}, ts0));

    Tensor sDelta_row   = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta.data()), row_layout));
    Tensor sDeltaA_row  = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta_a.data()), row_layout));
    Tensor sDeltaA_col  = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta_a.data()), col_layout));
    Tensor coord_tensor = make_coord_tensor(make_identity_layout(make_shape(ts0, ts0)));

    ThrMMA thr_mma = mma.get_slice(thread_idx);

    Tensor tDelta_row   = thr_mma.partition_C(sDelta_row)(_,_,_,read_delta_stage);
    Tensor tDeltaA_row  = thr_mma.partition_C(sDeltaA_row)(_,_,_,read_delta_stage);
    Tensor tDeltaA_col  = thr_mma.partition_C(sDeltaA_col)(_,_,_,read_delta_stage);
    Tensor tC           = thr_mma.partition_C(coord_tensor);

    auto tSR_Delta_bf16      = make_tensor<Element>(shape(tDelta_row));
    auto tSR_DeltaA_row_bf16 = make_tensor<ElementDA>(shape(tDeltaA_row));
    auto tSR_DeltaA_col_bf16 = make_tensor<ElementDA>(shape(tDeltaA_col));

    auto tSR_Delta      = make_tensor<ElementAcc>(shape(tDelta_row));
    auto tSR_DeltaA_row = make_tensor<ElementAcc>(shape(tDeltaA_row));
    auto tSR_DeltaA_col = make_tensor<ElementAcc>(shape(tDeltaA_col));

    auto barrier_token = pipeline_delta.consumer_try_wait(pipeline_state_delta);
    pipeline_delta.consumer_wait(pipeline_state_delta, barrier_token);

    // Load delta/delta_a
    copy(tDelta_row, tSR_Delta_bf16);
    copy(tDeltaA_row, tSR_DeltaA_row_bf16);
    copy(tDeltaA_col, tSR_DeltaA_col_bf16);

    pipeline_delta.consumer_release(pipeline_state_delta);
    ++pipeline_state_delta;

    // Data convert
    type_convert<Element, ElementAcc>(tSR_Delta_bf16, tSR_Delta);
    type_convert<ElementDA, ElementAcc>(tSR_DeltaA_row_bf16, tSR_DeltaA_row);
    type_convert<ElementDA, ElementAcc>(tSR_DeltaA_col_bf16, tSR_DeltaA_col);

    // SegSum
    #pragma unroll
    for (int ii = 0; ii < size(tIntra1); ++ii) {
      ElementAcc tmp(0.f);
      auto [m,n] = tC(ii);
      if (m >= n) {
        tmp = expf(tSR_DeltaA_col(ii) - tSR_DeltaA_row(ii));
      }
      tIntra1(ii) = tmp * tSR_Delta(ii) * tIntra1(ii);
    }

    synchronize();

    return make_tuple(tIntra1);
  }


  template<
    class MainloopPipelineX, class PipelineStateX,
    class TensorIntra1,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto mma_intra_2(
    int& chunk,
    MainloopPipelineX& pipeline_x, PipelineStateX& pipeline_state_x,
    TensorIntra1& tIntra1,
    TensorStorage& shared_tensors) {

    int thread_idx = int(threadIdx.x % 128);

    Tensor sX = make_tensor(make_smem_ptr(shared_tensors.smem_x.data()), SmemLayoutX{});

    TiledMmaIntra2 tiled_mma;
    auto thr_mma = tiled_mma.get_thread_slice(thread_idx);
    Tensor tCsX = thr_mma.partition_B(sX);                                        // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tCrX = thr_mma.make_fragment_B(tCsX);                                  // (MMA,MMA_N,MMA_K,PIPE)

    auto tCrIntra = make_acc_into_op<Element>(tIntra1, typename TiledMmaIntra2::LayoutA_TV{});
    auto accumulator = partition_fragment_C(tiled_mma, take<0, 2>(TileShapeIntraBMM2{}));

#if 0
    if (threadIdx.x % 128 == 0  && (blockIdx.x + blockIdx.y + blockIdx.z == 0) && chunk == 0) {
      print("tCsX         : ");print(tCsX);print("\n");
      print("tCrX         : ");print(tCrX);print("\n");
      print("tIntra1      : ");print(tIntra1);print("\n");
      print("tCrIntra     : ");print(tCrIntra);print("\n");
      print("accumulator  : ");print(accumulator);print("\n");
    }
#endif

    int read_stage = pipeline_state_x.index();

    auto barrier_token = pipeline_x.consumer_try_wait(pipeline_state_x);
    pipeline_x.consumer_wait(pipeline_state_x, barrier_token);
    
    // Delay the X pipeline release
    warpgroup_wait<0>();
    warpgroup_fence_operand(tCrIntra);
    warpgroup_fence_operand(accumulator);
    
    gemm_zero_acc(tiled_mma, tCrIntra, tCrX(_,_,_,read_stage), accumulator);

    warpgroup_commit_batch();

    // May delay
    warpgroup_wait<0>();

    pipeline_x.consumer_release(pipeline_state_x);
    ++pipeline_state_x;

    return make_tuple(accumulator);
  }

  template<
    class MainloopPipelineB, class PipelineStateB,
    class MainloopPipelineDelta, class PipelineStateDelta,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto pre_inter_1(
    int& chunk,
    MainloopPipelineB& pipeline_b, PipelineStateB& pipeline_state_b,
    MainloopPipelineDelta& pipeline_delta, PipelineStateDelta& pipeline_state_delta,
    TensorStorage& shared_tensors) {
    
    int thread_idx = int(threadIdx.x % 128);

    // Different from the original SmemB
    using SmemLayoutB = typename CollectiveInterMma1::SmemLayoutA;

    Tensor sB_ = make_tensor(make_smem_ptr(shared_tensors.smem_b.data()), SmemLayoutB{});
    Tensor sB = as_position_independent_swizzle_tensor(sB_); 

    int read_delta_stage = pipeline_state_delta.index();
    int read_b_stage = pipeline_state_b.index();

    auto barrier_token_b = pipeline_b.consumer_try_wait(pipeline_state_b);
    auto barrier_token_delta = pipeline_delta.consumer_try_wait(pipeline_state_delta);

    // construct
    TiledMmaInter1 tiled_mma;
    auto thr_mma = tiled_mma.get_thread_slice(thread_idx);
    Tensor tCrB_mma = thr_mma.partition_fragment_A(sB(_,_,Int<0>{}));
    Tensor tCrB_load_bf16 = make_fragment_like<Element>(tCrB_mma);
    Tensor tCrB_load = make_fragment_like<ElementAcc>(tCrB_mma);

    // using CopyAtom = Copy_Atom<cute::DefaultCopy, Element>;
    using CopyAtom = Copy_Atom<SM75_U32x4_LDSM_N, Element>;
    auto smem_tiled_copy_B = make_tiled_copy_A(CopyAtom{}, tiled_mma);
    auto smem_thr_copy_B   = smem_tiled_copy_B.get_thread_slice(thread_idx);
    Tensor tCrB_copy_view  = smem_thr_copy_B.retile_D(tCrB_load_bf16);
    Tensor tCsB            = smem_thr_copy_B.partition_S(sB);

    // load delta/delta_a
    auto ts0 = size<0>(TileShape{});

    Layout row_layout = make_layout(make_shape ( ts0,  ts0, Int<Stages::value>{}),
                                    make_stride(_0{}, _1{}, ts0));

    Tensor sDelta   = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta.data()), row_layout));
    Tensor sDeltaA  = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(shared_tensors.smem_delta_a.data()), row_layout));

    Tensor tDelta   = thr_mma.partition_A(sDelta)(_,_,_,read_delta_stage);
    Tensor tDeltaA  = thr_mma.partition_A(sDeltaA)(_,_,_,read_delta_stage);

    auto tSR_Delta_bf16  = make_tensor<Element>(shape(tDelta));
    auto tSR_DeltaA_bf16 = make_tensor<ElementDA>(shape(tDeltaA));

    auto tSR_Delta  = make_tensor<ElementAcc>(shape(tDelta));
    auto tSR_DeltaA = make_tensor<ElementAcc>(shape(tDeltaA));

    pipeline_b.consumer_wait(pipeline_state_b, barrier_token_b);

    // load B
    copy(smem_tiled_copy_B, tCsB(_,_,_,read_b_stage), tCrB_copy_view(_,_,_));

    pipeline_delta.consumer_wait(pipeline_state_delta, barrier_token_delta);

    // Load delta/delta_a
    copy(tDelta, tSR_Delta_bf16);
    copy(tDeltaA, tSR_DeltaA_bf16);

    // data conver
    type_convert<Element, ElementAcc>(tSR_Delta_bf16, tSR_Delta);
    type_convert<ElementDA, ElementAcc>(tSR_DeltaA_bf16, tSR_DeltaA);
    type_convert<Element, ElementAcc>(tCrB_load_bf16, tCrB_load);

    // xxx : This is specific to GMMA and it depends on the known TV partitioner.
    //       Only work for 128x64x128 tile as the layout is ((REG_N,REG_M,REG_N_REP),ATOM_M_REP,ATOM_N_REP).
    //       So we can use ((-1,_,-1),_,-1) to iterate the last column process (here -1 means the last coordinate)
    static_assert(cute::rank(tSR_DeltaA) == Int<3>{}, "The rank of Tensor is mismatched");
    static_assert(cute::rank<0>(tSR_DeltaA) == Int<3>{}, "The rank of MMA_ATOM is mismatched");
    static_assert(std::is_same<typename TiledMmaInter1::AtomLayoutA_TV, GMMA::ALayout_64x16>::value, "Only ALayout_64x16 is supported");
    // get last column
    bool last_thread_per_row = thread_idx % 4 == 3;
    ElementAcc last_column = ElementAcc(0.f);
    if (last_thread_per_row) {
      auto coord0 = get<0>(shape<0>(tSR_DeltaA)) - _1{};
      auto coord1 = get<2>(shape<0>(tSR_DeltaA)) - _1{};
      auto coord2 = get<2>(shape(tSR_DeltaA)) - _1{};
      auto tSR_DeltaA_slice = tSR_DeltaA(make_coord(coord0,_,coord1),_,coord2);
      last_column = tSR_DeltaA_slice(_0{});
    }

    // broadcast the last column
    last_column = __shfl_sync(0xFFFFFFFF, last_column, 3, 32);
    CUTLASS_PRAGMA_UNROLL
    for (int ii = 0; ii < size(tSR_DeltaA); ++ii) {
      tSR_DeltaA(ii) = expf(last_column - tSR_DeltaA(ii));
    } 

    // Delta*DeltaA
    auto tCompute   = make_tensor<ElementAcc>(tCrB_mma.layout());
    CUTLASS_PRAGMA_UNROLL
    for (int ii = 0; ii < size(tCompute); ++ii) {
      tCompute(ii) = tSR_DeltaA(ii) * tSR_Delta(ii);
    }

    CUTLASS_PRAGMA_UNROLL
    for (int ii = 0; ii < size(tCompute); ++ii) {
      tCompute(ii) = tCrB_load(ii) * tCompute(ii);
    }

    copy(tCompute, tCrB_mma);

    // release B buffer
    pipeline_b.consumer_release(pipeline_state_b);
    ++pipeline_state_b;
    return make_tuple(tCrB_mma, last_column);
  }

  template<
    class MainloopPipelineX, class PipelineStateX,
    class TensorB,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto mma_inter_1(
    int& chunk,
    MainloopPipelineX& pipeline_x, PipelineStateX& pipeline_state_x,
    TensorB tCrB,
    TensorStorage& shared_tensors) {

    Tensor sX = make_tensor(make_smem_ptr(shared_tensors.smem_x.data()), SmemLayoutX{});

    int thread_idx = int(threadIdx.x % 128);
    TiledMmaInter1 tiled_mma;
    auto thr_mma = tiled_mma.get_thread_slice(thread_idx);

    Tensor tCsX = thr_mma.partition_B(sX);
    Tensor tCrX = thr_mma.make_fragment_B(tCsX);

    Tensor accumulator = partition_fragment_C(tiled_mma, take<0, 2>(TileShapeInterBMM1{}));

    int read_stage = pipeline_state_x.index();

    auto barrier_token_x = pipeline_x.consumer_try_wait(pipeline_state_x);
    pipeline_x.consumer_wait(pipeline_state_x, barrier_token_x);

    warpgroup_fence_operand(accumulator);
    warpgroup_arrive();
    gemm_zero_acc(tiled_mma, tCrB, tCrX(_,_,_,read_stage), accumulator);
    warpgroup_commit_batch();

    warpgroup_wait<0>();

    return make_tuple(accumulator);
  }

  template<
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto state_init(TensorStorage& shared_tensors) {
    TiledMmaInter1 tiled_mma;
    Tensor tensor_state = partition_fragment_C(tiled_mma, take<0, 2>(TileShapeInterBMM1{}));

    auto synchronize = [&] () { cutlass::arch::NamedBarrier::sync(128, cutlass::arch::ReservedNamedBarriers::TransposeBarrier); };
    int thread_idx = int(threadIdx.x % 128);

    Tensor sP_ = make_tensor(make_smem_ptr(shared_tensors.smem_p.data()), SmemLayoutP{});           // (D, N)
    // Transpose
    auto sP_tmp = make_tensor(sP_.data(), make_layout(reverse(shape(sP_)), reverse(stride(sP_))));  // (N, D)
    Tensor sP = as_position_independent_swizzle_tensor(sP_tmp); 

    using CopyAtomC = Copy_Atom<SM90_U32x4_STSM_N, Element>;
    TiledCopy tiled_r2s_atom = make_tiled_copy_C(CopyAtomC{}, tiled_mma);

    using CopyOpR2S = SM90_U16x8_STSM_T;
    TiledCopy tiled_r2s = make_tiled_copy_S(Copy_Atom<CopyOpR2S, Element>{}, tiled_r2s_atom);
    ThrCopy thread_r2s = tiled_r2s.get_slice(thread_idx);
    Tensor tRS_rP = make_tensor<Element>(shape(thread_r2s.partition_S(sP)));
    Tensor tRS_sP = thread_r2s.partition_D(sP);

    clear(tRS_rP);
    clear(tensor_state);
    // Store P
    copy(tiled_r2s, tRS_rP, tRS_sP);

    cutlass::arch::fence_view_async_shared(); // ensure smem writes are visible to TMA
    synchronize(); // ensure all threads have issued their async fence
    
    return make_tuple(tensor_state);
  }
  template<
    class TensorInter1,
    class TensorState
  >
  CUTLASS_DEVICE
  void pre_inter_2(
    ElementAcc& last_column,
    TensorInter1& tInter1,
    TensorState& tState) {

    // Apply the state
    for (int ii = 0; ii < size(tInter1); ++ii) {
      tInter1(ii) = tInter1(ii) + expf(last_column) * static_cast<ElementAcc>(tState(ii));
    }
    // Update the state
    copy(tInter1, tState);

  }
  
  template<
    class TensorState,
    class TensorStorage
  >
  CUTLASS_DEVICE
  void post_inter_2(
    TensorState& tState,
    TensorStorage& shared_tensors) {

    int thread_idx = int(threadIdx.x % 128);

    auto synchronize = [&] () { cutlass::arch::NamedBarrier::sync(128, cutlass::arch::ReservedNamedBarriers::TransposeBarrier); };

    Tensor sP_ = make_tensor(make_smem_ptr(shared_tensors.smem_p.data()), SmemLayoutP{});           // (D, N)
    // Transpose
    auto sP_tmp = make_tensor(sP_.data(), make_layout(reverse(shape(sP_)), reverse(stride(sP_))));  // (N, D)
    Tensor sP = as_position_independent_swizzle_tensor(sP_tmp); 
    auto tP = make_tensor<Element>(shape(tState));

    type_convert<ElementAcc, Element>(tState, tP);

    synchronize(); // ensure all threads have issued their async fence

    using CopyAtomC = Copy_Atom<SM90_U32x4_STSM_N, Element>;
    TiledMmaInter1 tiled_mma;
    TiledCopy tiled_r2s_atom = make_tiled_copy_C(CopyAtomC{}, tiled_mma);

    using CopyOpR2S = SM90_U16x8_STSM_T;
    TiledCopy tiled_r2s = make_tiled_copy_S(Copy_Atom<CopyOpR2S, Element>{}, tiled_r2s_atom);
    ThrCopy thread_r2s = tiled_r2s.get_slice(thread_idx);
    Tensor tRS_rP = thread_r2s.retile_S(tP);
    Tensor tRS_sP = thread_r2s.partition_D(sP);

    // Store P
    copy(tiled_r2s, tRS_rP, tRS_sP);

    cutlass::arch::fence_view_async_shared(); // ensure smem writes are visible to TMA
    synchronize(); // ensure all threads have issued their async fence
  }

  template<
    class MainloopPipelineC, class PipelineStateC,
    class MainloopPipelineDelta, class PipelineStateDelta,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto mma_inter_2(
    int& chunk,
    MainloopPipelineC& pipeline_c, PipelineStateC& pipeline_state_c,
    MainloopPipelineDelta& pipeline_delta, PipelineStateDelta& pipeline_state_delta,
    TensorStorage& shared_tensors) {

    int thread_idx = int(threadIdx.x % 128);

    int read_c_stage = pipeline_state_c.index();

    TiledMmaInter2 tiled_mma;
    auto thr_mma = tiled_mma.get_thread_slice(thread_idx);

    // Mainloop setup QK
    Tensor sP = make_tensor(make_smem_ptr(shared_tensors.smem_p.data()), SmemLayoutP{});
    Tensor sC = make_tensor(make_smem_ptr(shared_tensors.smem_c.data()), SmemLayoutC{});

    Tensor tCsC = thr_mma.partition_A(sC);                                   // (MMA,MMA_M,MMA_K,PIPE)
    Tensor tPsP = thr_mma.partition_B(sP);                                   // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tCrC = thr_mma.make_fragment_A(tCsC);                            // (MMA,MMA_N,MMA_K,PIPE)
    Tensor tPrP = thr_mma.make_fragment_B(tPsP);                            // (MMA,MMA_M,MMA_N,PIPE)

    Tensor accumulator = partition_fragment_C(tiled_mma, take<0, 2>(TileShapeInterBMM2{}));

#if 0
    if (threadIdx.x % 128 == 0  && (blockIdx.x + blockIdx.y + blockIdx.z == 0) && chunk == 0) {
      print("sP           : ");print(sP);print("\n");
      print("sC           : ");print(sC);print("\n");
      print("tCsC         : ");print(tCsC);print("\n");
      print("tPsP         : ");print(tPsP);print("\n");
      print("tCrC         : ");print(tCrC);print("\n");
      print("tPrP         : ");print(tPrP);print("\n");
      print("accumulator  : ");print(accumulator);print("\n");
    }
#endif

    auto barrier_token_c = pipeline_c.consumer_try_wait(pipeline_state_c);
    pipeline_c.consumer_wait(pipeline_state_c, barrier_token_c);

    warpgroup_fence_operand(accumulator);
    warpgroup_arrive();
    gemm_zero_acc(tiled_mma, tCrC(_,_,_,read_c_stage), tPrP, accumulator);
    warpgroup_commit_batch();

    // release C
    warpgroup_wait<0>();

    pipeline_c.consumer_release(pipeline_state_c);
    ++pipeline_state_c;

    int read_delta_stage = pipeline_state_delta.index();
    // Load delta for epilogue
    auto col_layout = make_layout(make_shape(get<0>(TileShape{}), get<0>(TileShape{}), Int<Stages::value>{}), make_stride(_1{}, _0{}, get<0>(TileShape{})));
    auto c_tv_layout = typename TiledMmaInter2::LayoutC_TV{};
    auto tile_mn     = make_shape(tile_size<0>(tiled_mma), tile_size<1>(tiled_mma));
    auto delta_col_layout = zipped_divide(col_layout, tile_mn);
    auto delta_a_col_tv_layout = composition(delta_col_layout, make_tuple(c_tv_layout,_));

    auto tDeltaA_col_  = make_tensor(make_smem_ptr(shared_tensors.smem_delta_a.data()), delta_a_col_tv_layout)(make_coord(thread_idx,_), make_coord(_,_,read_delta_stage));
    auto tDeltaA_col = as_position_independent_swizzle_tensor(tDeltaA_col_); 
    auto tSR_DeltaA_col = make_tensor<ElementAcc>(shape(tDeltaA_col));

    copy(tDeltaA_col, tSR_DeltaA_col);

    pipeline_delta.consumer_release(pipeline_state_delta);
    ++pipeline_state_delta;

    for (int ii = 0; ii < size(tSR_DeltaA_col); ++ii) {
      tSR_DeltaA_col(ii) = expf(tSR_DeltaA_col(ii));
    }

    return make_tuple(accumulator, tSR_DeltaA_col);
  }

  template<
    class ElementSrc, class ElementDst,
    class TensorSrc, class TensorDst
  >
  CUTLASS_DEVICE
  auto type_convert(
    TensorSrc& tS,
    TensorDst& tD) {

    static constexpr int FragmentSize = 2;
    NumericArrayConverter<ElementDst, ElementSrc, FragmentSize> converter;

    auto tS_frg = recast<Array<ElementSrc, FragmentSize>>(tS);
    auto tD_frg = recast<Array<ElementDst, FragmentSize>>(tD);

    CUTLASS_PRAGMA_UNROLL
    for (int ii = 0; ii < size(tS_frg); ++ii) {
      tD_frg(ii) = converter(tS_frg(ii));
    }
  }
};

}  // namespace cutlass::fmha::collective
