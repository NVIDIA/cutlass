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

  using GmemTiledCopyC = void;
  using GmemTiledCopyD = void;

  static const int kOutputAlignment = ThreadEpilogueOp::kCount;
  using AlignmentType = typename cute::uint_bit<sizeof_bits<ElementOutput>::value * kOutputAlignment>::type;

  static_assert(cute::rank(StrideC{}) == 3, "StrideCD must be rank-3: [M, N, L]");
  static_assert(cute::rank(StrideD{}) == 3, "StrideCD must be rank-3: [M, N, L]");

  struct SharedStorage { };

  using TensorStorage = SharedStorage;

  // Host side epilogue arguments
  struct Arguments {
    typename ThreadEpilogueOp::Params thread{};
    ElementC const* ptr_C = nullptr;
    StrideC dC{};
    ElementD* ptr_D = nullptr;
    StrideD dD{};
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
  int SizeA,
  int SizeB,
  int SizeC,
  class FragSrc,
  class FragDst,
  class Op
  >
  CUTLASS_DEVICE static void reduceSg(FragSrc const &src, FragDst &dst, Op op) {
    // reduce across all the N tiles in shape <VecC, FragsM, FragsN>
    CUTLASS_PRAGMA_UNROLL
    for(int x = 0; x < SizeA; x++) {
      CUTLASS_PRAGMA_UNROLL
      for(int y = 0; y < SizeB; y++) {
        dst(x, y) = zero_init ? src(x, y, 0) : op(dst(x, y), src(x, y, 0));
        CUTLASS_PRAGMA_UNROLL
        for(int z = 1; z < SizeC; z++) {
          dst(x, y) = op(dst(x, y), src(x, y, z));
        }
      }
    }

    // reduce across the sub_group to get the final output
    auto sg = syclcompat::get_nd_item<1>().get_sub_group();
    CUTLASS_PRAGMA_UNROLL
    for(int x = 0; x < SizeA; x++) {
      CUTLASS_PRAGMA_UNROLL
      for(int y = 0; y < SizeB; y++) {
        CUTLASS_PRAGMA_UNROLL
        for(uint laneMask = 8; laneMask >= 1; laneMask /= 2) {
          dst(x,y) = op(dst(x, y), syclcompat::permute_sub_group_by_xor(sg, dst(x, y), laneMask, 16));
        }
      }
    }
  }
  
  template <
  bool zero_init,
  int SizeA,
  int SizeB,
  int SizeC,
  class FragSrc,
  class FragDst,
  class Op
  >
  CUTLASS_DEVICE static void reduceWg(FragSrc const &src, FragDst &dst, char* smem_buf, Op op, SharedStorage const& shared_storage) {
    reduceSg<zero_init, SizeA, SizeB, SizeC>(src, dst, op);
    for(int i=ThreadIdxX() % NumThreadsPerWarp; i<size(dst); i+=NumThreadsPerWarp){
      // TODO 
    }
  }

  template <
  bool zero_init,
  int SizeA,
  int SizeB,
  int SizeC,
  class FragSrc,
  class FragMax
  >
  CUTLASS_DEVICE static void reduce_max(FragSrc const &src, FragMax& max) {
      reduceSg<zero_init, SizeA, SizeB, SizeC>(src, max, [](ElementAccumulator const & x, ElementAccumulator const & y) { return x > y ? x : y; });
  }

  template <
  bool zero_init,
  int SizeA,
  int SizeB,
  int SizeC,
  class FragSrc,
  class FragSum
  >
  CUTLASS_DEVICE static void reduce_sum(FragSrc const &src, FragSum& sum) {
      reduceSg<zero_init, SizeA, SizeB, SizeC>(src, sum, [](ElementAccumulator const & x, ElementAccumulator const & y) { return x + y; });
  }

  template<
    class ProblemShapeMNKL,
    class BlockShapeMNK,
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
      cute::Tensor<FrgEngine, FrgLayout> const& accumulators,
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

    // Separate out problem shape for convenience
    auto M = get<0>(problem_shape_mnkl);
    auto N = get<1>(problem_shape_mnkl);
    auto L = get<3>(problem_shape_mnkl);

    //auto stride_c = detail::get_epilogue_stride<EpilogueSchedule>(params.dC);
    auto stride_d = detail::get_epilogue_stride<EpilogueSchedule>(params.dD);

    // Represent the full output tensor
    //Tensor mC_mnl = make_tensor(make_gmem_ptr(params.ptr_C), make_shape(M,N,L), stride_c);                 // (m,n,l)
    Tensor mD_mnl = make_tensor(make_gmem_ptr(params.ptr_D), make_shape(M,N,L), stride_d);                 // (m,n,l)
    //Tensor gC_mnl = local_tile(mC_mnl, blk_shape_MNK, make_coord(_,_,_), Step<_1,_1, X>{});    // (BLK_M,BLK_N,m,n,l)
    Tensor gD_mnl = local_tile(mD_mnl, blk_shape_MNK, make_coord(_,_,_), Step<_1,_1, X>{});    // (BLK_M,BLK_N,m,n,l)

    // Slice to get the tile this CTA is responsible for
    auto [m_coord, n_coord, k_coord, l_coord] = blk_coord_mnkl;
    //Tensor gC = gC_mnl(_,_,m_coord,n_coord,l_coord);                                                 // (BLK_M,BLK_N)
    Tensor gD = gD_mnl(_,_,m_coord,n_coord,l_coord);                                                 // (BLK_M,BLK_N)

    // Partition source and destination tiles to match the accumulator partitioning
    auto thr_mma = tiled_mma.get_thread_slice(thread_idx);
    Tensor tCgD = thr_mma.partition_C(gD);                                       // (VEC,THR_M,THR_N)
    //Tensor tCgC = thr_mma.partition_C(gC);                                       // (VEC,THR_M,THR_N)

    static_assert(is_static<FrgLayout>::value, "Accumulator layout must be static");
    //CUTE_STATIC_ASSERT_V(size(tCgC) == size(tCgD),
    //    "Source and destination must have the same number of elements.");
    CUTE_STATIC_ASSERT_V(size(tCgD) == size(accumulators),
        "Accumulator count must have the same destination element count.");

    // Make an identity coordinate tensor for predicating our output MN tile
    auto cD = make_identity_tensor(make_shape(unwrap(shape<0>(gD)), unwrap(shape<1>(gD))));
    Tensor tCcD = thr_mma.partition_C(cD);

    if(ThreadIdxX()==0 && BlockIdxX()==0 && BlockIdxY()==0 && BlockIdxZ()==0){
      print("thr_mma: "); print(thr_mma); print("\n");
      print("tiled_mma: "); print(tiled_mma); print("\n");
      //print("tiled_mma L: "); print_latex(tiled_mma); print("\n");
      print("acc: "); print(accumulators); print("\n");
      print("tCgD: "); print(tCgD); print("\n");
      print("gD: "); print(gD); print("\n");
    }

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size<0>(accumulators); ++i) {
      for (int j = 0; j < size<1>(accumulators); ++j) {
        for (int k = 0; k < size<2>(accumulators); ++k) {
          if (elem_less(tCcD(i,j,k), make_coord(get<0>(residue_mnk), get<1>(residue_mnk)))) {
            tCgD(i,j,k) = epilogue_op(accumulators(i,j,k));
          }
        }
      }
    }
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
