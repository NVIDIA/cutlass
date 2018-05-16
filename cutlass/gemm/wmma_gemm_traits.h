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
    \brief Defies structural properties of GEMM targeting WMMA API in CUDA.
*/
#pragma once

#include <cutlass/wmma_matrix.h>
#ifdef CUTLASS_USE_WMMA_API

#include <cutlass/convert.h>
#include <cutlass/gemm/gemm.h>
#include <cutlass/gemm/gemm_epilogue.h>
#include <cutlass/gemm/gemm_epilogue_traits.h>
#include <cutlass/gemm/gemm_global_tile.h>
#include <cutlass/gemm/gemm_shared_tile.h>
#include <cutlass/gemm/gemm_traits.h>
#include <cutlass/gemm/wmma_gemm_epilogue_traits.h>
#include <cutlass/gemm/wmma_gemm_global_tile.h>
#include <cutlass/gemm/wmma_gemm_multiply_add.h>

namespace cutlass {
namespace gemm {

////////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// The layout for A.
    MatrixLayout::Kind kLayoutA_,
    /// The layout for B.
    MatrixLayout::Kind kLayoutB_,
    /// The tile size for the GEMM KxNxM.
    typename OutputTile_,
    /// The output type.
    typename ScalarC_,
    /// The accumulator type.
    typename Accumulator_,
    /// The number of accumulators per warp.
    typename AccumulatorsPerWarp_,
    /// The shape of the WMMA instruction.
    typename InstructionShape_,
    /// The number of scalars per LDG for A.
    int kScalarsPerLdgA_,
    /// The number of scalars per LDG for B.
    int kScalarsPerLdgB_>
struct WmmaGemmConfig : public GemmConfig<
                            /// The scalar type for A.
                            half,
                            /// The scalar type for B.
                            half,
                            /// The scalar type for C.
                            ScalarC_,
                            /// The scalar type for D.
                            ScalarC_,
                            /// The tile size for the GEMM KxNxM.
                            OutputTile_,
                            /// The functor to do the math in the main loop.
                            WmmaGemmMultiplyAdd<kLayoutA_,
                                                half,
                                                kLayoutB_,
                                                half,
                                                MatrixLayout::kColumnMajor,
                                                Accumulator_,
                                                AccumulatorsPerWarp_,
                                                InstructionShape_>,
                            /// The number of scalars per LDG for A.
                            kScalarsPerLdgA_,
                            /// The number of scalars per STS for A.
                            kScalarsPerLdgA_,
                            /// The number of scalars per LDS for A.
                            8,
                            /// The number of scalars per LDG for B.
                            kScalarsPerLdgB_,
                            /// The number of scalars per STS for B.
                            kScalarsPerLdgB_,
                            /// The number of scalars per LDS for B.
                            8,
                            /// The number of scalars per LDG for C and STG for D.
                            16 / sizeof(ScalarC_),
                            /// The number of scalars per STS for D.
                            16 / sizeof(ScalarC_),
                            /// The number of scalars per LDS for D.
                            16 / sizeof(ScalarC_),
                            /// The number of stages in shared memory.
                            1> {};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <enum MatrixLayout::Kind kLayout_, typename GemmConfig_>
struct WmmaGemmTileTraitsHelperA {};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmConfig_>
struct WmmaGemmTileTraitsHelperA<MatrixLayout::kColumnMajor, GemmConfig_>
    : public GemmTileTraitsHelperA<MatrixLayout::kColumnMajor, GemmConfig_> {
  /// The base config.
  typedef GemmTileTraitsHelperA<MatrixLayout::kColumnMajor, GemmConfig_> Base;

  /// The skew.
  static int const kSkew = 16 / sizeof(typename Base::MultiplyAddScalar);
  /// The shared tile size.
  typedef Shape<GemmConfig_::kStages,
                GemmConfig_::OutputTile::kD,
                GemmConfig_::OutputTile::kW + kSkew>
      Tile;

  /// WMMA matrix
  typedef WmmaMatrix<GemmOperand::kA,
                     MatrixLayout::kColumnMajor,
                     typename Base::MultiplyAddScalar,
                     typename GemmConfig_::InstructionShape>
      WmmaMatrix;

  /// The traits class to build the iterator to store data to shared memory for A^N.
  typedef GemmSharedStoreTileAbTraits<
      // The pointer.
      typename Base::MultiplyAddScalar,
      // The tile has size KxM in GEMM's terminology.
      Tile,
      // The threads are distributed as warps x 32 (the traits may reorganize).
      typename Base::GlobalTileTraits::Threads,
      // The number of scalars per STS (STS.32 or STS.128, etc).
      GemmConfig_::kScalarsPerStsA>
      SharedStoreTileTraits;

  /// The number of elements loaded in one LDG.
  static int const kScalarsPerW = GemmConfig_::InstructionShape::kW * GemmConfig_::Warps::kW;
  /// The number of scalars loaded per iteration.
  static int const kScalarsPerIteration = Tile::kW * GemmConfig_::InstructionShape::kD;
  /// The traits class to build the iterator to load from shared memory for A.
  typedef WmmaGemmSharedLoadTileATraits<
      // The layout of the matrix.
      MatrixLayout::kColumnMajor,
      // The pointer.
      typename Base::MultiplyAddScalar,
      // The output tile size.
      Tile,
      // The number of warps.
      typename GemmConfig_::Warps,
      // The strides between warps.
      GemmConfig_::InstructionShape::kW,
      // The number of iterations to load the data.
      Shape<1, 1, GemmConfig_::OutputTile::kW / kScalarsPerW>,
      // The stride between iterations.
      Shape<kScalarsPerIteration, 0, kScalarsPerW, 0>,
      // The shape of the instruction.
      typename GemmConfig_::InstructionShape>
      SharedLoadTileTraits;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmConfig_>
struct WmmaGemmTileTraitsHelperA<MatrixLayout::kRowMajor, GemmConfig_> {
  /// The layout.
  static MatrixLayout::Kind const kLayout = MatrixLayout::kRowMajor;

  /// The input scalar.
  typedef typename GemmConfig_::ScalarA Scalar;
  /// The scalar stored in shared memory.
  typedef typename GemmConfig_::MultiplyAdd::ScalarA MultiplyAddScalar;

  /// WMMA matrix
  typedef WmmaMatrix<GemmOperand::kA,
                     MatrixLayout::kRowMajor,
                     MultiplyAddScalar,
                     typename GemmConfig_::InstructionShape>
      WmmaMatrix;

  /// The traits class to build the iterator to load data from global memory for A^T.
  typedef GemmGlobalTileTraits<
      // That's A.
      GemmOperand::kA,
      // A is row-major.
      MatrixLayout::kRowMajor,
      // The pointer is float const.
      Scalar const,
      // The tile has size KxM in GEMM's terminology.
      Shape<1, GemmConfig_::OutputTile::kW, GemmConfig_::OutputTile::kD>,
      // The threads are distributed as warps x 32 (the traits may reorganize).
      Shape<1, GemmConfig_::kThreads / GemmConfig_::OutputTile::kD, GemmConfig_::OutputTile::kD>,
      // The number of scalars per LDG (LDG.32 or LDG.128, etc).
      GemmConfig_::kScalarsPerLdgA>
      GlobalTileTraits;

  /// The skew.
  static int const kSkew = 16 / sizeof(MultiplyAddScalar);
  /// The tile.
  typedef Shape<GemmConfig_::kStages,
                GemmConfig_::OutputTile::kW,
                GemmConfig_::OutputTile::kD + kSkew>
      Tile;

  /// The traits class to build the iterator to store data to shared memory for A^N.
  typedef GemmSharedStoreTileAbTraits<
      // The pointer.
      MultiplyAddScalar,
      // The tile has size KxM in GEMM's terminology.
      Tile,
      // The threads are distributed as warps x 32 (the traits may reorganize).
      typename GlobalTileTraits::Threads,
      // The number of scalars per STS (STS.32 or STS.128, etc).
      GemmConfig_::kScalarsPerStsA>
      SharedStoreTileTraits;

  /// The number of elements loaded in one LDG.
  static int const kScalarsPerW = GemmConfig_::InstructionShape::kW * GemmConfig_::Warps::kW;
  /// The traits class to build the iterator to load from shared memory for A.
  typedef WmmaGemmSharedLoadTileATraits<
      // The layout of the matrix.
      MatrixLayout::kRowMajor,
      // The pointer.
      MultiplyAddScalar,
      // The tile in shared memory.
      Tile,
      // The number of warps.
      typename GemmConfig_::Warps,
      // The strides between warps.
      GemmConfig_::InstructionShape::kW * Tile::kW,
      // The number of iterations to load the data.
      Shape<1, 1, GemmConfig_::OutputTile::kW / kScalarsPerW>,
      // The stride between iterations.
      Shape<GemmConfig_::InstructionShape::kD, 0, kScalarsPerW * Tile::kW>,
      // The shape of the instruction.
      typename GemmConfig_::InstructionShape>
      SharedLoadTileTraits;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <enum MatrixLayout::Kind kLayout_, typename GemmConfig_>
struct WmmaGemmTileTraitsHelperB {};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmConfig_>
struct WmmaGemmTileTraitsHelperB<MatrixLayout::kRowMajor, GemmConfig_>
    : public GemmTileTraitsHelperB<MatrixLayout::kRowMajor, GemmConfig_> {
  /// The base config.
  typedef GemmTileTraitsHelperB<MatrixLayout::kRowMajor, GemmConfig_> Base;

  /// The skew.
  static int const kSkew = 16 / sizeof(typename Base::MultiplyAddScalar);
  /// The shared tile size.
  typedef Shape<GemmConfig_::kStages,
                GemmConfig_::OutputTile::kD,
                GemmConfig_::OutputTile::kH + kSkew>
      Tile;

  /// WMMA matrix
  typedef WmmaMatrix<GemmOperand::kB,
                     MatrixLayout::kRowMajor,
                     typename Base::MultiplyAddScalar,
                     typename GemmConfig_::InstructionShape>
      WmmaMatrix;

  /// The traits class to build the iterator to store data to shared memory for B^T.
  typedef GemmSharedStoreTileAbTraits<
      // The pointer.
      typename Base::MultiplyAddScalar,
      // The tile has size KxM in GEMM's terminology.
      Tile,
      // The threads are distributed as warps x 32 (the traits may reorganize).
      typename Base::GlobalTileTraits::Threads,
      // The number of scalars per STS (STS.32 or STS.128, etc).
      GemmConfig_::kScalarsPerStsB>
      SharedStoreTileTraits;

  /// The number of elements loaded in one LDG.
  static int const kScalarsPerW = GemmConfig_::InstructionShape::kH * GemmConfig_::Warps::kH;
  /// The number of scalars loaded per iteration.
  static int const kScalarsPerIteration = Tile::kW * GemmConfig_::InstructionShape::kD;
  /// The traits class to build the iterator to load from shared memory for B.
  typedef WmmaGemmSharedLoadTileBTraits<
      // The layout of the matrix.
      MatrixLayout::kRowMajor,
      // The pointer.
      typename Base::MultiplyAddScalar,
      // The output tile size.
      Tile,
      // The number of warps.
      typename GemmConfig_::Warps,
      // The strides between warps.
      GemmConfig_::InstructionShape::kH,
      // The number of iterations to load the data.
      Shape<1, 1, GemmConfig_::OutputTile::kH / kScalarsPerW>,
      // The stride between iterations.
      Shape<kScalarsPerIteration, 0, kScalarsPerW, 0>,
      // The shape of the instruction.
      typename GemmConfig_::InstructionShape>
      SharedLoadTileTraits;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename GemmConfig_>
struct WmmaGemmTileTraitsHelperB<MatrixLayout::kColumnMajor, GemmConfig_> {
  /// The layout.
  static MatrixLayout::Kind const kLayout = MatrixLayout::kColumnMajor;

  /// The input scalar.
  typedef typename GemmConfig_::ScalarB Scalar;
  /// The scalar stored in shared memory.
  typedef typename GemmConfig_::MultiplyAdd::ScalarB MultiplyAddScalar;

  /// WMMA matrix
  typedef WmmaMatrix<GemmOperand::kB,
                     MatrixLayout::kColumnMajor,
                     MultiplyAddScalar,
                     typename GemmConfig_::InstructionShape>
      WmmaMatrix;

  /// The traits class to build the iterator to load data from global memory for B^N.
  typedef GemmGlobalTileTraits<
      // That's B.
      GemmOperand::kB,
      // A is row-major.
      MatrixLayout::kColumnMajor,
      // The pointer is float const.
      Scalar const,
      // The tile has size KxM in GEMM's terminology.
      Shape<1, GemmConfig_::OutputTile::kH, GemmConfig_::OutputTile::kD>,
      // The threads are distributed as warps x 32 (the traits may reorganize).
      Shape<1, GemmConfig_::kThreads / GemmConfig_::OutputTile::kD, GemmConfig_::OutputTile::kD>,
      // The number of scalars per LDG (LDG.32 or LDG.128, etc).
      GemmConfig_::kScalarsPerLdgB>
      GlobalTileTraits;

  /// The skew.
  static int const kSkew = 16 / sizeof(MultiplyAddScalar);
  /// The tile.
  typedef Shape<GemmConfig_::kStages,
                GemmConfig_::OutputTile::kH,
                GemmConfig_::OutputTile::kD + kSkew>
      Tile;

  /// The traits class to build the iterator to store data to shared memory for B^N.
  typedef GemmSharedStoreTileAbTraits<
      // The pointer.
      MultiplyAddScalar,
      // The tile has size KxM in GEMM's terminology.
      Tile,
      // The threads are distributed as warps x 32 (the traits may reorganize).
      typename GlobalTileTraits::Threads,
      // The number of scalars per STS (STS.32 or STS.128, etc).
      GemmConfig_::kScalarsPerStsB>
      SharedStoreTileTraits;

  /// The number of elements loaded in one LDG.
  static int const kScalarsPerW = GemmConfig_::InstructionShape::kH * GemmConfig_::Warps::kH;
  /// The traits class to build the iterator to load from shared memory for B.
  typedef WmmaGemmSharedLoadTileBTraits<
      // The layout of the matrix.
      MatrixLayout::kColumnMajor,
      // The pointer.
      MultiplyAddScalar,
      // The tile in shared memory.
      Tile,
      // The number of warps.
      typename GemmConfig_::Warps,
      // The strides between warps.
      GemmConfig_::InstructionShape::kH * Tile::kW,
      // The number of iterations to load the data.
      Shape<1, 1, GemmConfig_::OutputTile::kH / kScalarsPerW>,
      // The stride between iterations.
      Shape<GemmConfig_::InstructionShape::kD, 0, kScalarsPerW * Tile::kW>,
      // The shape of the instruction.
      typename GemmConfig_::InstructionShape>
      SharedLoadTileTraits;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// The layout for A.
    MatrixLayout::Kind kLayoutA_,
    /// The layout for B.
    MatrixLayout::Kind kLayoutB_,
    /// The output tile.
    typename OutputTile_,
    /// The output type.
    typename ScalarC_,
    /// The accumulator type.
    typename Accumulator_,
    /// The functor to do the math in the epilogue.
    typename EpilogueFunctor_,
    /// The number of accumulators per warp.
    typename AccumulatorsPerWarp_,
    /// The shape of the WMMA instruction.
    typename InstructionShape_,
    /// The number of halfs loaded in one LDG for A.
    int kScalarsPerLdgA_,
    /// The number of halfs loaded in one LDG for B.
    int kScalarsPerLdgB_,
    /// The index.
    typename Index_>
struct WmmaGemmTraitsHelper {
  /// The WMMA GEMM config.
  typedef WmmaGemmConfig<kLayoutA_,
                         kLayoutB_,
                         OutputTile_,
                         ScalarC_,
                         Accumulator_,
                         AccumulatorsPerWarp_,
                         InstructionShape_,
                         kScalarsPerLdgA_,
                         kScalarsPerLdgB_>
      GemmConfig;

  /// The GEMM config for A.
  typedef WmmaGemmTileTraitsHelperA<kLayoutA_, GemmConfig> GemmTileTraitsHelperA;
  /// The GEMM config for B.
  typedef WmmaGemmTileTraitsHelperB<kLayoutB_, GemmConfig> GemmTileTraitsHelperB;

  /// The iterator to load A from global memory.
  typedef GemmGlobalIteratorAb<typename GemmTileTraitsHelperA::GlobalTileTraits, Index_>
      GlobalLoadIteratorA;
  /// The default transformer for A.
  typedef Copy<typename GlobalLoadIteratorA::Fragment> GlobalTransformerA;
  /// The iterator to store A to shared memory.
  typedef TileStoreIterator<typename GemmTileTraitsHelperA::SharedStoreTileTraits,
                            typename GemmTileTraitsHelperA::SharedStoreTileTraits::Scalar,
                            IteratorAdvance::kH,
                            MemorySpace::kShared>
      SharedStoreIteratorA;
  /// The stream to load A from global memory to shared memory.
  typedef GlobalLoadStream<GlobalLoadIteratorA, SharedStoreIteratorA, GlobalTransformerA>
      GlobalLoadStreamA;

  /// The iterator to load B from global memory.
  typedef GemmGlobalIteratorAb<typename GemmTileTraitsHelperB::GlobalTileTraits, Index_>
      GlobalLoadIteratorB;
  // The default transformer for B.
  typedef Copy<typename GlobalLoadIteratorB::Fragment> GlobalTransformerB;
  /// The iterator to store B to shared memory.
  typedef TileStoreIterator<typename GemmTileTraitsHelperB::SharedStoreTileTraits,
                            typename GemmTileTraitsHelperB::SharedStoreTileTraits::Scalar,
                            IteratorAdvance::kH,
                            MemorySpace::kShared>
      SharedStoreIteratorB;
  /// The stream to load B from global memory to shared memory.
  typedef GlobalLoadStream<GlobalLoadIteratorB, SharedStoreIteratorB, GlobalTransformerB>
      GlobalLoadStreamB;

  /// The iterator to load A from shared memory.
  typedef TileLoadIterator<typename GemmTileTraitsHelperA::SharedLoadTileTraits,
                           typename GemmTileTraitsHelperA::SharedLoadTileTraits::Scalar,
                           IteratorAdvance::kH,
                           MemorySpace::kShared,
                           Index_,
                           typename GemmTileTraitsHelperA::WmmaMatrix,
                           IteratorFragment::kWmmaMatrix>
      SharedLoadIteratorA;
  /// The stream to load A from shared memory.
  typedef SharedLoadStream<SharedLoadIteratorA> SharedLoadStreamA;
  /// The iterator to load B from shared memory.
  typedef TileLoadIterator<typename GemmTileTraitsHelperB::SharedLoadTileTraits,
                           typename GemmTileTraitsHelperB::SharedLoadTileTraits::Scalar,
                           IteratorAdvance::kH,
                           MemorySpace::kShared,
                           Index_,
                           typename GemmTileTraitsHelperB::WmmaMatrix,
                           IteratorFragment::kWmmaMatrix>
      SharedLoadIteratorB;
  /// The stream to load B from shared memory.
  typedef SharedLoadStream<SharedLoadIteratorB> SharedLoadStreamB;

  /// The functor to do the multiply-add in the main loop.
  typedef typename GemmConfig::MultiplyAdd MultiplyAdd;
  /// The object to clear accumulators.
  typedef ClearAccumulators<typename MultiplyAdd::ScalarC> ClearAccumulators;

  /// The helper to create the epilogue traits.
  typedef WmmaGemmEpilogueTraitsHelper<GemmConfig, EpilogueFunctor_, Index_> EpilogueTraitsHelper;
  /// The traits class for the epilogue.
  typedef SimplifiedGemmEpilogueTraits<GemmConfig, EpilogueFunctor_, Index_, EpilogueTraitsHelper>
      GemmEpilogueTraits;
  /// The epilogue.
  typedef GemmEpilogue<GemmEpilogueTraits> Epilogue;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename OutputTile_, typename DefaultShape_ = Shape<64, 32, 64> >
struct WmmaGemmAccumulatorsPerWarp {
  typedef typename ShapeMin<OutputTile_, DefaultShape_>::Shape Shape;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// The layout for A.
    MatrixLayout::Kind kLayoutA_,
    /// The layout for B.
    MatrixLayout::Kind kLayoutB_,
    /// The tile size for the GEMM KxNxM.
    typename OutputTile_ = Shape<64, 128, 128>,
    /// The output type.
    typename ScalarC_ = float,
    /// The functor to do the math in the epilogue.
    typename EpilogueFunctor_ = LinearScaling<ScalarC_>,
    /// The accumulator type.
    typename Accumulator_ = ScalarC_,
    /// The number of accumulators per warp.
    typename AccumulatorsPerWarp_ = typename WmmaGemmAccumulatorsPerWarp<OutputTile_>::Shape,
    /// The shape of the WMMA instruction.
    typename InstructionShape_ = Shape<16, 16, 16>,
    /// The number of scalars per LDG for A.
    int kScalarsPerLdgA_ = 8,
    /// The number of scalars per LDG for B.
    int kScalarsPerLdgB_ = 8,
    /// The index.
    typename Index_ = int,
    /// The helper class.
    typename Helper_ = WmmaGemmTraitsHelper<kLayoutA_,
                                            kLayoutB_,
                                            OutputTile_,
                                            ScalarC_,
                                            Accumulator_,
                                            EpilogueFunctor_,
                                            AccumulatorsPerWarp_,
                                            InstructionShape_,
                                            kScalarsPerLdgA_,
                                            kScalarsPerLdgB_,
                                            Index_> >
struct WmmaGemmTraits : public GemmTraits<
                            // The config.
                            typename Helper_::GemmConfig,
                            // The stream to load A from global memory to shared memory.
                            typename Helper_::GlobalLoadStreamA,
                            // The stream to load B from global memory to shared memory.
                            typename Helper_::GlobalLoadStreamB,
                            // The stream to load A from shared memory.
                            typename Helper_::SharedLoadStreamA,
                            // The stream to load B from shared memory.
                            typename Helper_::SharedLoadStreamB,
                            // The epilogue.
                            typename Helper_::Epilogue,
                            // The block swizzle to reorganize the grid.
                            IdentityBlockSwizzle,
                            // The index.
                            Index_,
                            // The tool used to clear accumulators.
                            typename Helper_::ClearAccumulators> {};

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace gemm
}  // namespace cutlass

#endif  // defined CUTLASS_USE_WMMA_API
