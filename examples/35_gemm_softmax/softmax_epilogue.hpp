/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
  \brief Functor performing elementwise operations used by epilogues.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/detail.hpp"

#include "cute/tensor.hpp"
#include "cute/numeric/numeric_types.hpp"
#include "cutlass/cuda_host_adapter.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Applies an element wise operation to all elements within the fragment
/// and writes them out to destination storage.
template <
  class StrideC_,
  class StrideD_,
  class StrideTmp_,
  class BlockShapeMNK,
  class ThreadEpilogueOp_,
  class EpilogueSchedule_
>
class SoftmaxEpilogue {
public:
  //
  // Type Aliases
  //
  using EpilogueSchedule = EpilogueSchedule_;
  using DispatchPolicy = EpilogueSchedule_;

  // derived types of output thread level operator
  using ThreadEpilogueOp = ThreadEpilogueOp_;
  using ElementOutput = typename ThreadEpilogueOp::ElementOutput;
  using ElementAccumulator = typename ThreadEpilogueOp::ElementAccumulator;
  using ElementCompute = typename ThreadEpilogueOp::ElementCompute;
  using ElementScalar = ElementCompute;
  using ElementC = typename ThreadEpilogueOp::ElementC;
  using StrideC = StrideC_;
  using ElementD = typename ThreadEpilogueOp::ElementD;
  using StrideD = StrideD_;
  using StrideTmp = StrideTmp_;

  using GmemTiledCopyC = void;
  using GmemTiledCopyD = void;

  static const int kOutputAlignment = ThreadEpilogueOp::kCount;
  using AlignmentType = typename cute::uint_bit<sizeof_bits<ElementOutput>::value * kOutputAlignment>::type;

  static_assert(cute::rank(StrideC{}) == 3, "StrideCD must be rank-3: [M, N, L]");
  static_assert(cute::rank(StrideD{}) == 3, "StrideCD must be rank-3: [M, N, L]");

  struct SharedStorage { 
    //cute::array_aligned<ElementAccumulator, cute::cosize_v<Layout<Shape<C<get<0>(BlockShapeMNK{})>,C<get<1>(BlockShapeMNK{})>>>>> smem_c;
    cute::array_aligned<ElementAccumulator, get<0>(BlockShapeMNK{}) * get<1>(BlockShapeMNK{})> smem_c;
  };

  using TensorStorage = SharedStorage;

  // Host side epilogue arguments
  struct Arguments {
    typename ThreadEpilogueOp::Params thread{};
    ElementC const* ptr_C = nullptr;
    StrideC dC{};
    ElementD* ptr_D = nullptr;
    StrideD dD{};
    ElementAccumulator* ptr_max;
    ElementAccumulator* ptr_sum;
    StrideTmp dTmp{};
  };

  // Device side epilogue params
  using Params = Arguments;

  //
  // Methods
  //

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(
      [[maybe_unused]] ProblemShape const& _,
      Arguments const& args,
      [[maybe_unused]] void* workspace) {
    return args;
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

  template<class ProblemShape>
  static bool
  can_implement(
      [[maybe_unused]] ProblemShape const& problem_shape,
      [[maybe_unused]] Arguments const& args) {
    return true;
  }

  CUTLASS_HOST_DEVICE
  SoftmaxEpilogue(Params const& params_, SharedStorage const& shared_storage = SharedStorage())
      : params(params_), epilogue_op(params_.thread) { }

  CUTLASS_DEVICE
  bool
  is_source_needed() {
    return epilogue_op.is_source_needed();
  }

  template <
  bool zero_init,
  class FragSrc,
  class FragDst,
  class Op
  >
  CUTLASS_DEVICE static void reduceSg(FragSrc const &src, FragDst &dst, Op op) {
    // reduce across all the -N- M tiles in shape <VecC, FragsM, FragsN>
    CUTLASS_PRAGMA_UNROLL
    for(int z = 1; z < size<2>(src); z++) {
      dst(z) = zero_init ? src(0, 0, z) : op(dst(z), src(0, 0, z));
      CUTLASS_PRAGMA_UNROLL
      for(int x = 0; x < size<0>(src); x++) {
        CUTLASS_PRAGMA_UNROLL
        for(int y = 0; y < size<1>(src); y++) {
          dst(z) = op(dst(z), src(x, y, z));
        }
      }
    }

    // reduce across the sub_group to get the final output
    auto sg = syclcompat::get_nd_item<1>().get_sub_group();
    CUTLASS_PRAGMA_UNROLL
    for(int z = 1; z < size<2>(src); z++) {
      CUTLASS_PRAGMA_UNROLL
      for(uint laneMask = 8; laneMask >= 1; laneMask /= 2) {
        dst(z) = op(dst(z), syclcompat::permute_sub_group_by_xor(sg, dst(z), laneMask, 16));
      }
    }
  }
  
  template <
  class FragSrc,
  class FragDst,
  class SharedThreadTens,
  class SharedTens,
  class ResidueMap,
  class Residue,
  class Op
  >
  CUTLASS_DEVICE static ElementAccumulator reduceWg(FragSrc const &src, FragDst &dst,
                                      SharedThreadTens& tCsC, SharedTens& sC, 
                                      ResidueMap tCcD, Residue residue_mnk, int thread_idx,
                                      ElementAccumulator init, Op op) {
      //TODO(Tadej): single loop over all dims  
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size<0>(src); ++i) {
        CUTLASS_PRAGMA_UNROLL
        for (int j = 0; j < size<1>(src); ++j) {
          CUTLASS_PRAGMA_UNROLL
          for (int k = 0; k < size<2>(src); ++k) {
            if (elem_less(tCcD(i,j,k), make_coord(get<0>(residue_mnk), get<1>(residue_mnk)))) {
              tCsC(i,j,k) = src(i,j,k);
            } else{
              tCsC(i,j,k) = init;
            }
          }
        }
      }

      syncthreads();

      ElementAccumulator acc = sC(0, thread_idx);
      for (int i = 1; i < size(src); ++i) {
        acc = op(acc, sC(i, thread_idx));
      }

      syncthreads();

      //broadcast it back to threads
      //TODO(Tadej): optimize
      for (int i = 0; i < size(src); ++i) {
        sC(i, thread_idx) = acc;
      }
      
      syncthreads();
      
      CUTLASS_PRAGMA_UNROLL
      for(int k = 1; k < size<2>(src); k++) {
        dst(k) = tCsC(0,0,k);
      }

      return acc;

    /*reduceSg<zero_init>(src, dst, op);
    for(int i=ThreadIdxX() % NumThreadsPerWarp; i<size(dst); i+=NumThreadsPerWarp){
      // TODO 
    }*/
  }

  template <
  bool zero_init,
  class FragSrc,
  class FragMax
  >
  CUTLASS_DEVICE static void reduce_max(FragSrc const &src, FragMax& max) {
      reduceSg<zero_init>(src, max, [](ElementAccumulator const & x, ElementAccumulator const & y) { return x > y ? x : y; });
  }

  template <
  class FragSrc,
  class FragDst,
  class SharedThreadTens,
  class SharedTens,
  class ResidueMap,
  class Residue
  >
  CUTLASS_DEVICE static ElementAccumulator reduce_max_wg(FragSrc const &src, FragDst &dst,
                                          SharedThreadTens& tCsC, SharedTens& sC, 
                                          ResidueMap tCcD, Residue residue_mnk, int thread_idx) {
      
      return reduceWg(src, dst, tCsC, sC, tCcD, residue_mnk, thread_idx, 
                      std::numeric_limits<ElementAccumulator>::min(), 
                      [](ElementAccumulator const & x, ElementAccumulator const & y) { return x > y ? x : y; });
  }

  template <
  bool zero_init,
  class FragSrc,
  class FragSum
  >
  CUTLASS_DEVICE static void reduce_sum(FragSrc const &src, FragSum& sum) {
      reduceSg<zero_init>(src, sum, [](ElementAccumulator const & x, ElementAccumulator const & y) { return x + y; });
  }
    
  template <
  class FragSrc,
  class FragDst,
  class SharedThreadTens,
  class SharedTens,
  class Residue,
  class ResidueMap
  >
  CUTLASS_DEVICE static ElementAccumulator reduce_sum_wg(FragSrc const &src, FragDst &dst,
                                          SharedThreadTens& tCsC, SharedTens& sC, 
                                          ResidueMap tCcD, Residue residue_mnk, int thread_idx) {
      
      return reduceWg(src, dst, tCsC, sC, tCcD, residue_mnk, thread_idx, 
                      0, [](ElementAccumulator const & x, ElementAccumulator const & y) { return x+y; });
  }

  template<
    class ProblemShapeMNKL,
    //class BlockShapeMNK,
    class BlockCoordMNKL,
    class FrgEngine, class FrgLayout,
    class TiledMma,
    class ResidueMNK
  >
  CUTLASS_HOST_DEVICE void
  operator()(
      ProblemShapeMNKL problem_shape_mnkl,
      BlockShapeMNK blk_shape_MNK,
      BlockCoordMNKL blk_coord_mnkl,
      cute::Tensor<FrgEngine, FrgLayout> & accumulators,
      TiledMma tiled_mma,
      ResidueMNK residue_mnk,
      int thread_idx,
      [[maybe_unused]] char* smem_buf)
  {
    using namespace cute;
    using X = Underscore;

    static_assert(cute::rank(ProblemShapeMNKL{}) == 4, "ProblemShapeMNKL must be rank 4");
    static_assert(is_static<BlockShapeMNK>::value, "ThreadBlock tile shape must be static");
    static_assert(cute::rank(BlockShapeMNK{}) == 3, "BlockShapeMNK must be rank 3");
    static_assert(cute::rank(BlockCoordMNKL{}) == 4, "BlockCoordMNKL must be rank 3");

    //auto wlid = thread_idx % NumWarpsPerWarpGroup; // warp local id
    //auto wid = thread_idx / NumWarpsPerWarpGroup; // warp id in tile

    // Separate out problem and tile shape for convenience
    auto M = get<0>(problem_shape_mnkl);
    auto N = get<1>(problem_shape_mnkl);
    auto L = get<3>(problem_shape_mnkl);

    auto M_tile = get<0>(blk_shape_MNK);
    auto N_tile = get<1>(blk_shape_MNK);
    auto K_tile = get<2>(blk_shape_MNK);

    auto N_tmp = cute::ceil_div(N, N_tile);

    cute::packed_tuple partial_block(M_tile, C<1>(), K_tile);

    auto stride_c = detail::get_epilogue_stride<EpilogueSchedule>(params.dC);
    auto stride_d = detail::get_epilogue_stride<EpilogueSchedule>(params.dD);

    // Represent the full output tensors
    Tensor mC_mnl = make_tensor(make_gmem_ptr(params.ptr_C), make_shape(M,N,L), stride_c);                 // (m,n,l)
    Tensor mD_mnl = make_tensor(make_gmem_ptr(params.ptr_D), make_shape(M,N,L), stride_d);                 // (m,n,l)
    Tensor mMax_mnl = make_tensor(make_gmem_ptr(params.ptr_max), make_shape(M,N_tmp,L), params.dTmp);                 // (m,n,l)
    Tensor mSum_mnl = make_tensor(make_gmem_ptr(params.ptr_sum), make_shape(M,N_tmp,L), params.dTmp);                 // (m,n,l)
    Tensor gC_mnl = local_tile(mC_mnl, blk_shape_MNK, make_coord(_,_,_), Step<_1,_1, X>{});    // (BLK_M,BLK_N,m,n,l)
    Tensor gD_mnl = local_tile(mD_mnl, blk_shape_MNK, make_coord(_,_,_), Step<_1,_1, X>{});    // (BLK_M,BLK_N,m,n,l)
    Tensor gMax_mnl = local_tile(mMax_mnl, partial_block, make_coord(_,_,_), Step<_1,_1, X>{});    // (BLK_M,BLK_N,m,n,l)
    Tensor gSum_mnl = local_tile(mSum_mnl, partial_block, make_coord(_,_,_), Step<_1,_1, X>{});    // (BLK_M,BLK_N,m,n,l)

    // Slice to get the tile this CTA is responsible for
    auto [m_coord, n_coord, k_coord, l_coord] = blk_coord_mnkl;
    Tensor gC = gC_mnl(_,_,m_coord,n_coord,l_coord);                                                 // (BLK_M,BLK_N)
    Tensor gD = gD_mnl(_,_,m_coord,n_coord,l_coord);                                                 // (BLK_M,BLK_N)
    Tensor gMax = gMax_mnl(_,_,m_coord,n_coord,l_coord);                                                 // (BLK_M,BLK_N)
    Tensor gSum = gSum_mnl(_,_,m_coord,n_coord,l_coord);                                                 // (BLK_M,BLK_N)

    //Represent the shared tensor
    Tensor sC = make_tensor(make_smem_ptr(reinterpret_cast<ElementAccumulator*>(smem_buf)), make_layout(make_shape(M_tile, N_tile)));

    // Partition the tiles to match the accumulator partitioning
    auto thr_mma = tiled_mma.get_thread_slice(thread_idx);
    Tensor tCgD = thr_mma.partition_C(gD);                                       // (VEC,THR_M,THR_N)
    Tensor tCgC = thr_mma.partition_C(gC);                                       // (VEC,THR_M,THR_N)
    //Tensor tCgMax = thr_mma.partition_C(gMax);                                   // (VEC,THR_M,THR_N)
    //Tensor tCgSum = thr_mma.partition_C(gSum);                                   // (VEC,THR_M,THR_N)
    Tensor tCsC = thr_mma.partition_C(sC);                                       // (VEC,THR_M,THR_N)


    static_assert(is_static<FrgLayout>::value, "Accumulator layout must be static");
    CUTE_STATIC_ASSERT_V(size(tCgC) == size(tCgD),
        "Source and destination must have the same number of elements.");
    CUTE_STATIC_ASSERT_V(size(tCgD) == size(accumulators),
        "Accumulator count must have the same destination element count.");

    // Make an identity coordinate tensor for predicating our output MN tile
    auto cD = make_identity_tensor(make_shape(unwrap(shape<0>(gD)), unwrap(shape<1>(gD))));
    Tensor tCcD = thr_mma.partition_C(cD);

    //Tensor acc_max = make_tensor<ElementAccumulator>(Shape<Int<size<0>(accumulators)>, Int<size<1>(accumulators)>>{});
    //Tensor acc_max = make_tensor<ElementAccumulator>(size<0>(accumulators));
    //Tensor acc_max = make_tensor_like(take<2,3>(accumulators));
    //Tensor acc_sum = make_tensor_like(acc_max); //TODO can reuse prev?
    
    //Tensor acc_max = make_tensor<ElementAccumulator>(shape<2>(accumulators), LayoutLeft{});
    //Tensor acc_sum = make_tensor<ElementAccumulator>(shape<2>(accumulators), LayoutLeft{}); //TODO can reuse prev?

    bool is_first = ThreadIdxX()==0 && BlockIdxX()==0 && BlockIdxY()==0 && BlockIdxZ()==0;
    if(is_first){
      print("blk_coord_mnkl: "); print(blk_coord_mnkl); print("\n");
      //print("blk_shape_MNK: "); print(blk_shape_MNK); print("\n");
      //print("partial_block: "); print(partial_block); print("\n");
      //print("thr_mma: "); print(thr_mma); print("\n");
      //print("tiled_mma: "); print(tiled_mma); print("\n");
      //print("acc: "); print(accumulators); print("\n");
      //print("mD_mnl: "); print(mD_mnl); print("\n");
      print("mMax_mnl: "); print(mMax_mnl); print("\n");
      //print("gD_mnl: "); print(gD_mnl); print("\n");
      print("gMax_mnl: "); print(gMax_mnl); print("\n");
      //print("gD: "); print(gD); print("\n");
      print("gMax: "); print(gMax); print("\n");
      //print("tCgD: "); print(tCgD); print("\n");
      //print("sC: "); print(sC); print("\n");
      //print("tCsC: "); print(tCsC); print("\n");
      //print("sC.data: "); print(&sC(0)); print("\n");
      //print("tCsC.data: "); print(&tCsC(0)); print("\n");
      //decltype(tCsC(0)) a = "asd";
      //print("tCgMax: "); print(tCgMax); print("\n");
      //print("acc_max: "); print(acc_max); print("\n");
      //print("accumulators: "); print(accumulators); print("\n");
    }

    if(is_source_needed()){
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size<0>(accumulators); ++i) {
        CUTLASS_PRAGMA_UNROLL
        for (int j = 0; j < size<1>(accumulators); ++j) {
          CUTLASS_PRAGMA_UNROLL
          for (int k = 0; k < size<2>(accumulators); ++k) {
            if (elem_less(tCcD(i,j,k), make_coord(get<0>(residue_mnk), get<1>(residue_mnk)))) {
              accumulators(i,j,k) = epilogue_op(accumulators(i,j,k), tCgC(i,j,k));
              tCgD(i,j,k) = accumulators(i,j,k);
              tCsC(i,j,k) = accumulators(i,j,k);
              /*if(is_first){
                print("acc1.1:"); print(tCsC(i,j,k)); print("\n");
              }*/
            }
          }
        }
      }
    } else{
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size<0>(accumulators); ++i) {
        CUTLASS_PRAGMA_UNROLL
        for (int j = 0; j < size<1>(accumulators); ++j) {
          CUTLASS_PRAGMA_UNROLL
          for (int k = 0; k < size<2>(accumulators); ++k) {
            if (elem_less(tCcD(i,j,k), make_coord(get<0>(residue_mnk), get<1>(residue_mnk)))) {
              accumulators(i,j,k) = epilogue_op(accumulators(i,j,k));
              tCgD(i,j,k) = accumulators(i,j,k);
              tCsC(i,j,k) = accumulators(i,j,k);
              /*if(is_first){
                print("acc1.2:"); print(accumulators(i,j,k)); print(".\n");
                print("idx:"); print(tCsC.layout()(i,j,k)); print(".\n");
              }*/
            } 
          }
        }
      }
    }

    syncthreads();

    // assumption size<0>(sC) == wg size
    ElementAccumulator max = std::numeric_limits<ElementAccumulator>::min();
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size<0>(sC); ++i) {
      if (elem_less(cD(thread_idx, i), make_coord(get<0>(residue_mnk), get<1>(residue_mnk)))) {
        accumulators(i) = sC(thread_idx, i);
        max = cutlass::fast_max(max, accumulators(i));
        /*if(is_first && i < 3){
          print("acc2 :"); print(accumulators(i)); print("\n");
          //print("idx:"); print(sC.layout()(thread_idx, i)); print(".\n");
          for (int j = 0; j < 3; ++j) {
            print("shared :"); print(j); print(" "); print(i); print(": "); print(sC(j, i)); print("\n");
          }
        }*/
      }
    }
    /*if(m_coord == 0 && n_coord == 1 && ThreadIdxX()==0){
      print("max epilogue val:"); print(max); print("\n");
      print("idx:"); print(n_coord); print("\n");
    }*/

    gMax(thread_idx,0) = max;
    
    ElementAccumulator sum = 0;
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size<0>(sC); ++i) {
      if (elem_less(cD(thread_idx, i), make_coord(get<0>(residue_mnk), get<1>(residue_mnk)))) {
        sum += cutlass::fast_exp(accumulators(i) - max);
        if(is_first){
          //print("acc3 :"); print(accumulators(i)); print("\n");
          //print("diff :"); print(accumulators(i) - max); print("\n");
          //print("add :"); print(cutlass::fast_exp(accumulators(i) - max)); print("\n");
          //print("sum :"); print(sum); print("\n");
          //print("idx:"); print(sC.layout()(thread_idx, i)); print(".\n");
        } 
      }
    }
    if(is_first){
      print("sum epilogue val:"); print(sum); print("\n");
    }

    gSum(thread_idx,0) = sum;


    /*//reduce_max<true>(accumulators, acc_max);
    reduce_max_wg(accumulators, acc_max, tCsC, sC, tCcD, residue_mnk, thread_idx);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size<0>(accumulators); ++i) {
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < size<1>(accumulators); ++j) {
        CUTLASS_PRAGMA_UNROLL
        for (int k = 0; k < size<2>(accumulators); ++k) {
          if (elem_less(tCcD(i,j,k), make_coord(get<0>(residue_mnk), get<1>(residue_mnk)))) {
            accumulators(i,j,k) = expf(accumulators(i,j,k) - acc_max(k));
          }
        }
      }
    }

    reduce_sum<true>(accumulators, acc_sum);
    if(wlid == 0){
      for (int k = 0; k < size<2>(accumulators); ++k) {
        gSum(wid,k) = acc_sum(k);
      }
    }*/

    //TODO write out reductions

    //second kernel: 
    // - finalize max reduction: mN = sum(mj)
    // - finalize sum reduction: sN = sum(sj * exp(mj-mN))
    // - finalize softmax: yi = exp(xi-mN)/sN

    /*CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size<0>(accumulators); ++i) {
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < size<1>(accumulators); ++j) {
        CUTLASS_PRAGMA_UNROLL
        for (int k = 0; k < size<2>(accumulators); ++k) {
          if (elem_less(tCcD(i,j,k), make_coord(get<0>(residue_mnk), get<1>(residue_mnk)))) {
            tCgD(i,j,k) = accumulators(i,j,k);
          }
        }
      }
    }*/

  }

private:
  Params params;
  ThreadEpilogueOp epilogue_op;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace collective
} // namespace epilogue
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
