/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Defines structural properties of complete GEMM computation.
*/
#pragma once

#include <cutlass/convert.h>
#include <cutlass/gemm/clear_accumulators.h>
#include <cutlass/gemm/gemm_global_stream.h>
#include <cutlass/gemm/gemm_operand.h>
#include <cutlass/gemm/gemm_shared_stream.h>
#include <cutlass/gemm/identity_block_swizzle.h>
#include <cutlass/matrix_traits.h>
#include <cutlass/reshape_tile.h>
#include <cutlass/tile_iterator.h>

namespace cutlass {
namespace gemm {

////////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// The scalar type for A.
    typename ScalarA_,
    /// The scalar type for B.
    typename ScalarB_,
    /// The scalar type for C.
    typename ScalarC_,
    /// The scalar type for D.
    typename ScalarD_,
    /// The output tile size for the GEMM KxNxM.
    typename OutputTile_,
    /// The functor to do the math.
    typename MultiplyAdd_,
    /// The number of scalars per LDG for A.
    int kScalarsPerLdgA_,
    /// The number of scalars per STS for A.
    int kScalarsPerStsA_,
    /// The number of scalars per LDG for A.
    int kScalarsPerLdsA_,
    /// The number of scalars per LDG for B.
    int kScalarsPerLdgB_,
    /// The number of scalars per STS for B.
    int kScalarsPerStsB_,
    /// The number of scalars per LDS for B.
    int kScalarsPerLdsB_,
    /// The number of scalars per LDG for C and STG for D.
    int kScalarsPerLdgCAndStgD_,
    /// The number of scalars per STS for D.
    int kScalarsPerStsD_,
    /// The number of scalars per LDS for D.
    int kScalarsPerLdsD_,
    /// The number of stages in shared memory to do single/double/triple-buffering.
    int kStages_>

struct GemmConfig {
  //
  /// The scalar for A.
  typedef ScalarA_ ScalarA;
  /// The scalar for B.
  typedef ScalarB_ ScalarB;
  /// The scalar for C.
  typedef ScalarC_ ScalarC;
  /// The scalar for D.
  typedef ScalarD_ ScalarD;

  /// The tile.
  typedef OutputTile_ OutputTile;
  /// The functor to do D = A*B + C.
  typedef MultiplyAdd_ MultiplyAdd;
  /// The shape of the instruction.
  typedef typename MultiplyAdd::InstructionShape InstructionShape;
  /// The number of accumulators per warp.
  typedef typename MultiplyAdd::AccumulatorsPerWarp AccumulatorsPerWarp;
  /// The accumulators.
  typedef typename MultiplyAdd::Accumulators Accumulators;

  /// The number of warps.
  typedef typename ShapeDiv<OutputTile, AccumulatorsPerWarp>::Shape Warps;
  /// The default warp size (32 threads per warp).
  static int const kWarpSize = cutlass::kWarpSize;
  /// The numnber of threads.
  static int const kThreads = ShapeCount<Warps>::kCount * kWarpSize;

  /// The number of scalars per LDG/STS/LDS for A.
  static int const kScalarsPerLdgA = kScalarsPerLdgA_;
  static int const kScalarsPerStsA = kScalarsPerStsA_;
  static int const kScalarsPerLdsA = kScalarsPerLdsA_;

  /// The number of scalars per LDG/STS/LDS for B.
  static int const kScalarsPerLdgB = kScalarsPerLdgB_;
  static int const kScalarsPerStsB = kScalarsPerStsB_;
  static int const kScalarsPerLdsB = kScalarsPerLdsB_;

  /// The number of scalars per LDG for C.
  static int const kScalarsPerLdgC = kScalarsPerLdgCAndStgD_;

  /// The number of scalars per STS/LDS/STG for D.
  static int const kScalarsPerStgD = kScalarsPerLdgCAndStgD_;
  static int const kScalarsPerStsD = kScalarsPerStsD_;
  static int const kScalarsPerLdsD = kScalarsPerLdsD_;

  /// The number of accumulators that are going to be fed from one LDS A/B.
  static int const kAccumulatorsPerLdsA = kScalarsPerLdsA / InstructionShape::kD;
  static int const kAccumulatorsPerLdsB = kScalarsPerLdsB / InstructionShape::kD;

  /// The number of stages in shared memory to implement double, triple, more-buffering.
  static int const kStages = kStages_;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <enum MatrixLayout::Kind, typename GemmConfig_>
struct GemmTileTraitsHelperA {};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmConfig_>
struct GemmTileTraitsHelperA<MatrixLayout::kColumnMajor, GemmConfig_> {
  /// The layout.
  static MatrixLayout::Kind const kLayout = MatrixLayout::kColumnMajor;

  /// The input scalar.
  typedef typename GemmConfig_::ScalarA Scalar;
  /// The scalar stored in shared memory.
  typedef typename GemmConfig_::MultiplyAdd::ScalarA MultiplyAddScalar;

  /// The traits class to build the iterator to load data from global memory for A^N.
  typedef GemmGlobalTileTraits<
      // That's A.
      GemmOperand::kA,
      // A is column-major.
      MatrixLayout::kColumnMajor,
      // The pointer is float const.
      Scalar const,
      // The tile has size KxM in GEMM's terminology.
      Shape<1, GemmConfig_::OutputTile::kD, GemmConfig_::OutputTile::kW>,
      // The threads are distributed as warps x 32 (the traits may reorganize).
      Shape<1, ShapeCount<typename GemmConfig_::Warps>::kCount, GemmConfig_::kWarpSize>,
      // The number of scalars per LDG (LDG.32 or LDG.128, etc).
      GemmConfig_::kScalarsPerLdgA>
      GlobalTileTraits;

  /// The traits class to build the iterator to store data to shared memory for A^N.
  typedef GemmSharedStoreTileAbTraits<
      // The pointer is float.
      MultiplyAddScalar,
      // The tile has size KxM in GEMM's terminology.
      Shape<GemmConfig_::kStages,
            GemmConfig_::OutputTile::kD / GemmConfig_::InstructionShape::kD,
            GemmConfig_::OutputTile::kW * GemmConfig_::InstructionShape::kD>,
      // The threads are distributed as warps x 32 (the traits may reorganize).
      typename GlobalTileTraits::Threads,
      // The number of scalars per STS (STS.32 or STS.128, etc).
      GemmConfig_::kScalarsPerStsA>
      SharedStoreTileTraits;

  /// The traits class to build the iterator to load from shared memory for A^N.
  typedef GemmSharedLoadTileATraits<
      // The pointer is float const.
      MultiplyAddScalar const,
      // The output tile size.
      typename GemmConfig_::OutputTile,
      // The number of warps.
      typename GemmConfig_::Warps,
      // The number of threads per warp.
      typename GemmConfig_::MultiplyAdd::ThreadsPerWarp,
      // The shape of the FMA instruction.
      typename GemmConfig_::InstructionShape,
      // The number of stages.
      GemmConfig_::kStages,
      // The number of scalars per LDS.
      GemmConfig_::kScalarsPerLdsA,
      // The skew.
      0>
      SharedLoadTileTraits;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmConfig_>
struct GemmTileTraitsHelperA<MatrixLayout::kRowMajor, GemmConfig_> {
  /// The layout.
  static MatrixLayout::Kind const kLayout = MatrixLayout::kRowMajor;

  /// The input scalar.
  typedef typename GemmConfig_::ScalarA Scalar;
  /// The scalar stored in shared memory.
  typedef typename GemmConfig_::MultiplyAdd::ScalarA MultiplyAddScalar;

  /// The traits class to build the iterator to load data from global memory for A^T.
  typedef GemmGlobalTileTraits<
      // That's A.
      GemmOperand::kA,
      // A is row-major.
      MatrixLayout::kRowMajor,
      // The pointer is float const.
      Scalar const,
      // The tile has size MxK in GEMM's terminology.
      Shape<1, GemmConfig_::OutputTile::kW, GemmConfig_::OutputTile::kD>,
      // The threads are distributed as (threads / K) x K (the traits may reorganize).
      Shape<1, GemmConfig_::kThreads / GemmConfig_::OutputTile::kD, GemmConfig_::OutputTile::kD>,
      // The number of scalars per LDG (LDG.32 or LDG.128, etc).
      GemmConfig_::kScalarsPerLdgA>
      GlobalTileTraits;

  /// The number of scalars in 4B.
  static int const kScalarsIn4B = sizeof(MultiplyAddScalar) > 4 ? 1 : 4 / sizeof(MultiplyAddScalar);
  /// The traits class to build the iterator to store data to shared memory for A^T.
  typedef GemmSharedStoreWithSkewTileAbTraits<
      // The pointer is float.
      MultiplyAddScalar,
      // The tile has size KxM in GEMM's terminology.
      Shape<GemmConfig_::kStages,
            GemmConfig_::OutputTile::kD / GemmConfig_::InstructionShape::kD,
            GemmConfig_::OutputTile::kW * GemmConfig_::InstructionShape::kD>,
      // The threads are distributed as (threads / K) x K (the traits may reorganize).
      typename GlobalTileTraits::Threads,
      // The number of scalars per STS.
      GemmConfig_::kScalarsPerStsA,
      // The skew to avoid bank conflicts added in the tile W dimension.
      128 / sizeof(MultiplyAddScalar) / GemmConfig_::kScalarsPerStsA /
          GlobalTileTraits::Threads::kW * kScalarsIn4B>
      SharedStoreTileTraits;

  /// The traits class to build the iterator to load from shared memory for A^T.
  typedef GemmSharedLoadTileATraits<
      // The pointer is float const.
      MultiplyAddScalar const,
      // The output tile size.
      typename GemmConfig_::OutputTile,
      // The number of warps.
      typename GemmConfig_::Warps,
      // The number of threads per warp.
      typename GemmConfig_::MultiplyAdd::ThreadsPerWarp,
      // The shape of the FMA instruction.
      typename GemmConfig_::InstructionShape,
      // The number of stages.
      GemmConfig_::kStages,
      // The number of scalars per LDS.
      GemmConfig_::kScalarsPerLdsA,
      // The skew.
      SharedStoreTileTraits::kSkew>
      SharedLoadTileTraits;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <enum MatrixLayout::Kind, typename GemmConfig_>
struct GemmTileTraitsHelperB {};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmConfig_>
struct GemmTileTraitsHelperB<MatrixLayout::kColumnMajor, GemmConfig_> {
  /// The layout.
  static MatrixLayout::Kind const kLayout = MatrixLayout::kColumnMajor;

  /// The input scalar.
  typedef typename GemmConfig_::ScalarB Scalar;
  /// The scalar stored in shared memory.
  typedef typename GemmConfig_::MultiplyAdd::ScalarB MultiplyAddScalar;

  /// The traits class to build the iterator to load data from global memory for B^N.
  typedef GemmGlobalTileTraits<
      // That's B.
      GemmOperand::kB,
      // B is column-major.
      MatrixLayout::kColumnMajor,
      // The pointer is float const.
      Scalar const,
      // The tile has size MxK in GEMM's terminology.
      Shape<1, GemmConfig_::OutputTile::kH, GemmConfig_::OutputTile::kD>,
      // The threads are distributed as (threads / K) x K (the traits may reorganize).
      Shape<1, GemmConfig_::kThreads / GemmConfig_::OutputTile::kD, GemmConfig_::OutputTile::kD>,
      // The number of scalars per LDG (LDG.32 or LDG.128, etc).
      GemmConfig_::kScalarsPerLdgB>
      GlobalTileTraits;

  /// The number of scalars in 4B.
  static int const kScalarsIn4B = sizeof(MultiplyAddScalar) > 4 ? 1 : 4 / sizeof(MultiplyAddScalar);
  /// The traits class to build the iterator to store data to shared memory for B^N.
  typedef GemmSharedStoreWithSkewTileAbTraits<
      // The pointer is float.
      MultiplyAddScalar,
      // The tile has size KxN in GEMM's terminology.
      Shape<GemmConfig_::kStages,
            GemmConfig_::OutputTile::kD / GemmConfig_::InstructionShape::kD,
            GemmConfig_::OutputTile::kH * GemmConfig_::InstructionShape::kD>,
      // The threads are distributed as (threads / K) x K (the traits may reorganize).
      typename GlobalTileTraits::Threads,
      // The number of scalars per STS.
      GemmConfig_::kScalarsPerStsB,
      // The skew to avoid bank conflicts added in the tile W dimension.
      128 / sizeof(MultiplyAddScalar) / GemmConfig_::kScalarsPerStsB /
          GlobalTileTraits::Threads::kW * kScalarsIn4B>
      SharedStoreTileTraits;

  /// The traits class to build the iterator to load from shared memory for B^N.
  typedef GemmSharedLoadTileBTraits<
      // The pointer is float const.
      MultiplyAddScalar const,
      // The output tile size.
      typename GemmConfig_::OutputTile,
      // The number of warps.
      typename GemmConfig_::Warps,
      // The number of threads per warp.
      typename GemmConfig_::MultiplyAdd::ThreadsPerWarp,
      // The shape of the FMA instruction.
      typename GemmConfig_::InstructionShape,
      // The number of stages.
      GemmConfig_::kStages,
      // The number of scalars per LDS.
      GemmConfig_::kScalarsPerLdsB,
      // The skew.
      SharedStoreTileTraits::kSkew>
      SharedLoadTileTraits;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmConfig_>
struct GemmTileTraitsHelperB<MatrixLayout::kRowMajor, GemmConfig_> {
  /// The layout.
  static MatrixLayout::Kind const kLayout = MatrixLayout::kRowMajor;

  /// The input scalar.
  typedef typename GemmConfig_::ScalarB Scalar;
  /// The scalar stored in shared memory.
  typedef typename GemmConfig_::MultiplyAdd::ScalarB MultiplyAddScalar;

  /// The traits class to build the iterator to load data from global memory for B^T.
  typedef GemmGlobalTileTraits<
      // That's B.
      GemmOperand::kB,
      // B is row-major.
      MatrixLayout::kRowMajor,
      // The pointer is float const.
      Scalar const,
      // The tile has size KxN in GEMM's terminology.
      Shape<1, GemmConfig_::OutputTile::kD, GemmConfig_::OutputTile::kH>,
      // The threads are distributed as warps x 32 (the traits may reorganize).
      Shape<1, ShapeCount<typename GemmConfig_::Warps>::kCount, GemmConfig_::kWarpSize>,
      // The number of scalars per LDG (LDG.32 or LDG.128, etc).
      GemmConfig_::kScalarsPerLdgB>
      GlobalTileTraits;

  /// The traits class to build the iterator to store data to shared memory for B^T.
  typedef GemmSharedStoreTileAbTraits<
      // The pointer is float.
      MultiplyAddScalar,
      // The tile has size KxN in GEMM's terminology.
      Shape<GemmConfig_::kStages,
            GemmConfig_::OutputTile::kD / GemmConfig_::InstructionShape::kD,
            GemmConfig_::OutputTile::kH * GemmConfig_::InstructionShape::kD>,
      // The threads are distributed as warps x 32 (the traits may reorganize).
      typename GlobalTileTraits::Threads,
      // The number of scalars per STS (STS.32 or STS.128, etc).
      GemmConfig_::kScalarsPerStsB>
      SharedStoreTileTraits;

  /// The traits class to build the iterator to load from shared memory for B^T.
  typedef GemmSharedLoadTileBTraits<
      // The pointer is float const.
      MultiplyAddScalar const,
      // The output tile size.
      typename GemmConfig_::OutputTile,
      // The number of warps.
      typename GemmConfig_::Warps,
      // The number of threads per warp.
      typename GemmConfig_::MultiplyAdd::ThreadsPerWarp,
      // The shape of the FMA instruction.
      typename GemmConfig_::InstructionShape,
      // The number of stages.
      GemmConfig_::kStages,
      // The number of scalars per LDS.
      GemmConfig_::kScalarsPerLdsB,
      // The skew.
      0>
      SharedLoadTileTraits;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// The GEMM configuration.
    typename GemmConfig_,
    /// The stream to load A from global memory to shared memory.
    typename GlobalLoadStreamA_,
    /// The stream to load B from global memory to shared memory.
    typename GlobalLoadStreamB_,
    /// The stream to load A from shared memory.
    typename SharedLoadStreamA_,
    /// The stream to load B from shared memory.
    typename SharedLoadStreamB_,
    /// The epilogue.
    typename Epilogue_,
    /// The block swizzle to reorganize the grid.
    typename BlockSwizzle_ = IdentityBlockSwizzle,
    /// The index.
    typename Index_ = int,
    /// The tool used to clear accumulators.
    typename ClearAccumulators_ = ClearAccumulators<typename GemmConfig_::Accumulators::Scalar> >

struct GemmTraits {
  /// The configuration.
  typedef GemmConfig_ GemmConfig;
  /// The output tile.
  typedef typename GemmConfig::OutputTile OutputTile;

  /// The stream to load A from global memory to shared memory.
  typedef GlobalLoadStreamA_ GlobalLoadStreamA;
  /// The layout of A.
  static MatrixLayout::Kind const kLayoutA = GlobalLoadStreamA::kLayout;
  /// The scalar for A.
  typedef typename GlobalLoadStreamA_::Scalar ScalarA;

  /// The stream to load B from global memory to shared memory.
  typedef GlobalLoadStreamB_ GlobalLoadStreamB;
  /// The layout of B.
  static MatrixLayout::Kind const kLayoutB = GlobalLoadStreamB::kLayout;
  /// The scalar for B.
  typedef typename GlobalLoadStreamB_::Scalar ScalarB;

  /// The iterator for A to load from shared memory.
  typedef SharedLoadStreamA_ SharedLoadStreamA;
  /// The iterator for B to load from shared memory.
  typedef SharedLoadStreamB_ SharedLoadStreamB;

  /// The shared storage for A.
  typedef typename GlobalLoadStreamA::SharedStoreStorage SharedStoreStorageA;
  // Btw, make sure we did not messed up with the size of the storage.
  static_assert(sizeof(SharedStoreStorageA) == sizeof(typename SharedLoadStreamA::SharedStorage),
                "");

  /// The shared storage for B.
  typedef typename GlobalLoadStreamB::SharedStoreStorage SharedStoreStorageB;
  // Btw, make sure we did not messed up with the size of the storage.
  static_assert(sizeof(SharedStoreStorageB) == sizeof(typename SharedLoadStreamB::SharedStorage),
                "");

  /// The multiply-add functor.
  typedef typename GemmConfig::MultiplyAdd MultiplyAdd;
  /// The epilogue.
  typedef Epilogue_ Epilogue;
  /// The scalars in the epilogue.
  typedef typename Epilogue::ScalarC ScalarC;
  typedef typename Epilogue::ScalarD ScalarD;

  /// The block swizzle to reorganize the grid.
  typedef BlockSwizzle_ BlockSwizzle;
  /// The index.
  typedef Index_ Index;
  /// Clear the accumulators.
  typedef ClearAccumulators_ ClearAccumulators;

  /// The params.
  struct Params {
    /// The dimensions of the GEMM.
    Index m, n, k;
    /// The params for the A stream.
    typename GlobalLoadStreamA::Params global_stream_a;
    /// The params for the B stream.
    typename GlobalLoadStreamB::Params global_stream_b;
    /// The params for the A stream from shared memory.
    typename SharedLoadStreamA::Params shared_stream_a;
    /// The params for the B stream from shared memory.
    typename SharedLoadStreamB::Params shared_stream_b;
    /// The params for the epilogue.
    typename Epilogue::Params epilogue;

    /// Initialize the parameters.
    template <typename GemmDesc_>
    CUTLASS_HOST_DEVICE int initialize(GemmDesc_ const& desc) {
      // Set the problem size.
      this->m = desc.m;
      this->n = desc.n;
      this->k = desc.k;

      // Initialize the iterator for A.
      int error_code =
          global_stream_a.initialize(reinterpret_cast<ScalarA const*>(desc.d_a), desc.lda);

      if (error_code) {
        return error_code;
      }

      // Initialize the iterator for B.
      error_code = global_stream_b.initialize(reinterpret_cast<ScalarB const*>(desc.d_b), desc.ldb);

      if (error_code) {
        return error_code;
      }

      // The epilogue.
      return epilogue.initialize(desc);
    }
  };

  // The storage for A.
  template <typename GlobalLoadStream_, typename SharedLoadStream_>
  union StreamSharedStorage {
    // The storage needed by the global stream.
    typename GlobalLoadStream_::SharedStorage global;
    // The storage needed by the shared stream.
    typename SharedLoadStream_::SharedStorage shared;
  };

  // The storage for the main loop + prologue.
  struct MainLoopSharedStorage {
    // The storage to shuffle the A matrix in shared memory.
    StreamSharedStorage<GlobalLoadStreamA, SharedLoadStreamA> stream_a;
    // The storage to shuffle the B matrix in shared memory.
    StreamSharedStorage<GlobalLoadStreamB, SharedLoadStreamB> stream_b;
    // The storage to clear the accumulators if needed.
    typename ClearAccumulators::SharedStorage clear;
  };

  /// The storage in shared memory.
  union SharedStorage {
    // The storage for the main loop.
    MainLoopSharedStorage main_loop;
    // The storage for the epilogue.
    typename Epilogue::SharedStorage epilogue;
  };

  /// Assemble the global load streams for A/B.
  struct GlobalLoadStream {
    /// Ctor.
    CUTLASS_DEVICE GlobalLoadStream(Params const& params,
                                    SharedStorage& shared_storage,
                                    dim3 const& block)
        : stream_a(params.global_stream_a,
                   shared_storage.main_loop.stream_a.global,
                   cutlass::make_Coord(0, params.k, params.m),
                   cutlass::make_Coord(0, 0, block.x)),
          stream_b(params.global_stream_b,
                   shared_storage.main_loop.stream_b.global,
                   cutlass::make_Coord(0, params.k, params.n),
                   make_Coord(0, 0, block.y)) {}

    /// Trigger the copies from shared memory to registers.
    CUTLASS_DEVICE void copy() {
      stream_a.copy();
      stream_b.copy();
    }

    /// Commit the data.
    CUTLASS_DEVICE void commit() {
      stream_a.commit();
      stream_b.commit();
    }

    /// Execute the residue code.
    CUTLASS_DEVICE void residue(Index k, bool skip_clear = false) {
      stream_a.residue(k, skip_clear);
      stream_b.residue(k, skip_clear);
    }

    /// The stream for A.
    GlobalLoadStreamA stream_a;
    /// The stream for B.
    GlobalLoadStreamB stream_b;
  };

  /// Assemble the shared load stream for A/B.
  struct SharedLoadStream {
    /// Ctor.
    CUTLASS_DEVICE SharedLoadStream(Params const& params, SharedStorage& shared_storage) {
      stream_a.initialize(params.shared_stream_a, shared_storage.main_loop.stream_a.shared);
      stream_b.initialize(params.shared_stream_b, shared_storage.main_loop.stream_b.shared);
    }

    /// Trigger the copies from shared memory to registers.
    CUTLASS_DEVICE void copy(int step) {
      stream_a.copy(step, fetched_a[step % 2]);
      stream_b.copy(step, fetched_b[step % 2]);
    }

    /// Commit the data.
    CUTLASS_DEVICE void commit(int step) {
      stream_a.commit(fetched_a[step % 2], transformed_a[step % 2]);
      stream_b.commit(fetched_b[step % 2], transformed_b[step % 2]);
    }

    /// The fragment A.
    CUTLASS_DEVICE typename SharedLoadStreamA::Fragment const& fragment_a(int step) const {
      return transformed_a[step % 2];
    }

    /// The fragment B.
    CUTLASS_DEVICE typename SharedLoadStreamB::Fragment const& fragment_b(int step) const {
      return transformed_b[step % 2];
    }

    /// Increment the stage.
    CUTLASS_DEVICE void inc_stage() {
      stream_a.inc_stage();
      stream_b.inc_stage();
    }

    /// The stream for A.
    SharedLoadStreamA stream_a;
    /// The fragments to fetch A.
    typename SharedLoadStreamA::FetchedFragment fetched_a[2];
    /// The fragments to transform A.
    typename SharedLoadStreamA::TransformedFragment transformed_a[2];
    /// The stream for B.
    SharedLoadStreamB stream_b;
    /// The fragments to fetch B.
    typename SharedLoadStreamB::FetchedFragment fetched_b[2];
    /// The fragments to transform B.
    typename SharedLoadStreamB::TransformedFragment transformed_b[2];
  };

  /// The memory fence for shared loads.
  static CUTLASS_DEVICE void shared_load_fence(bool in_loop) {
    if (SharedLoadStreamA::Iterator::kRequiresLoadFence ||
        SharedLoadStreamB::Iterator::kRequiresLoadFence) {
      __syncthreads();
    }
  }

  /// The memory fence for shared stores.
  static CUTLASS_DEVICE void shared_store_fence(bool in_loop) { __syncthreads(); }
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmTileTraitsHelperA_, typename GemmTileTraitsHelperB_, typename Index_>
struct SimplifiedGemmTraitsHelper {
  /// The global iterator to load A from global memory.
  typedef GemmGlobalIteratorAb<typename GemmTileTraitsHelperA_::GlobalTileTraits, Index_>
      GlobalLoadIteratorA;
  /// The data converter for A before storing to shared memory.
  typedef Copy<typename GlobalLoadIteratorA::Fragment> GlobalTransformerA;
  /// The iterator to store A to shared memory.
  typedef TileStoreIterator<typename GemmTileTraitsHelperA_::SharedStoreTileTraits,
                            typename GemmTileTraitsHelperA_::SharedStoreTileTraits::Scalar,
                            IteratorAdvance::kH,
                            MemorySpace::kShared>
      SharedStoreIteratorA;
  /// The stream to load A from global memory to shared memory.
  typedef GlobalLoadStream<GlobalLoadIteratorA, SharedStoreIteratorA, GlobalTransformerA>
      GlobalLoadStreamA;

  /// The global iterator to load B from global memory.
  typedef GemmGlobalIteratorAb<typename GemmTileTraitsHelperB_::GlobalTileTraits, Index_>
      GlobalLoadIteratorB;
  /// The data converter for B before storing to shared memory.
  typedef Copy<typename GlobalLoadIteratorB::Fragment> GlobalTransformerB;
  /// The iterator to store B to shared memory.
  typedef TileStoreIterator<typename GemmTileTraitsHelperB_::SharedStoreTileTraits,
                            typename GemmTileTraitsHelperB_::SharedStoreTileTraits::Scalar,
                            IteratorAdvance::kH,
                            MemorySpace::kShared>
      SharedStoreIteratorB;
  /// The stream to load B from global memory to shared memory.
  typedef GlobalLoadStream<GlobalLoadIteratorB, SharedStoreIteratorB, GlobalTransformerB>
      GlobalLoadStreamB;

  /// The iterator to load A from shared memory.
  typedef TileLoadIterator<typename GemmTileTraitsHelperA_::SharedLoadTileTraits,
                           typename GemmTileTraitsHelperA_::Scalar,
                           IteratorAdvance::kH,
                           MemorySpace::kShared>
      SharedLoadIteratorA;
  /// The stream to load A from shared memory.
  typedef SharedLoadStream<SharedLoadIteratorA> SharedLoadStreamA;
  /// The iterator to load B from shared memory.
  typedef TileLoadIterator<typename GemmTileTraitsHelperB_::SharedLoadTileTraits,
                           typename GemmTileTraitsHelperB_::Scalar,
                           IteratorAdvance::kH,
                           MemorySpace::kShared>
      SharedLoadIteratorB;
  /// The stream to load B from shared memory.
  typedef SharedLoadStream<SharedLoadIteratorB> SharedLoadStreamB;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// The layout for A.
    MatrixLayout::Kind kLayoutA_,
    /// The layout for B.
    MatrixLayout::Kind kLayoutB_,
    /// The config for the GEMM.
    typename GemmConfig_,
    /// The epilogue.
    typename Epilogue_,
    /// The index.
    typename Index_ = int,
    // The configuration for the A matrix.
    typename GemmTileTraitsHelperA_ = GemmTileTraitsHelperA<kLayoutA_, GemmConfig_>,
    // The configuration for the B matrix.
    typename GemmTileTraitsHelperB_ = GemmTileTraitsHelperB<kLayoutB_, GemmConfig_>,
    // The helper class to create the streams and iterators.
    typename Helper_ =
        SimplifiedGemmTraitsHelper<GemmTileTraitsHelperA_, GemmTileTraitsHelperB_, Index_> >
struct SimplifiedGemmTraits : public GemmTraits<
                                  // The config.
                                  GemmConfig_,
                                  // The stream to load A from global memory to shared memory.
                                  typename Helper_::GlobalLoadStreamA,
                                  // The stream to load B from global memory to shared memory.
                                  typename Helper_::GlobalLoadStreamB,
                                  // The stream to load A from shared memory.
                                  typename Helper_::SharedLoadStreamA,
                                  // The stream to load B from shared memory.
                                  typename Helper_::SharedLoadStreamB,
                                  // The epilogue.
                                  Epilogue_,
                                  // The block swizzle to reorganize the grid.
                                  IdentityBlockSwizzle,
                                  // The index.
                                  Index_,
                                  // The tool used to clear accumulators.
                                  ClearAccumulators<typename GemmConfig_::Accumulators::Element> > {
};

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace gemm
}  // namespace cutlass
