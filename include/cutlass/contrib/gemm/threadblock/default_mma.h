#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"
#include "cutlass/arch/arch.h"

#include "cutlass/layout/matrix.h"
#include "cutlass/transform/threadblock/predicated_tile_iterator.h"
#include "cutlass/contrib/transform/threadblock/predicated_tile_iterator.h"

#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm70.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm75.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm80.h"
#include "cutlass/contrib/gemm/threadblock/mma_singlestage.h"
#include "cutlass/contrib/gemm/threadblock/mma_pipelined.h"
#include "cutlass/contrib/gemm/threadblock/mma_multistage.h"
#include "cutlass/contrib/args_pack_def.h"

namespace cutlass {
namespace contrib {
namespace gemm {
namespace threadblock {
template <
    /// TensorDefs
    typename TensorDefA,
    typename TensorDefB,
    typename TensorDefC,
    typename TensorDefD,
    /// Prologue defs
    typename PrologueDefA,
    typename PrologueDefB,
    /// Epilogue defs
    typename EpilogueDef,
    typename OperatorClass_,
    typename ArchTag_,
    typename TileShapeDef,
    int Stages,
    typename Operator,
    /// Store the accumulators in row major or column major.  Row major is used
    /// when output layout is interleaved.
    bool AccumulatorsInRowMajor = false,
    /// Use zfill or predicate for out-of-bound cp.async
    cutlass::gemm::SharedMemoryClearOption SharedMemoryClear =
        cutlass::gemm::SharedMemoryClearOption::kZfill>
struct DefaultMma;

////////////////////////////////////////////////////////////////////////////////
/// Specialization for 1 stage (OperatorClass TensorOp)
template <
    /// TensorDefs
    typename TensorDefA,
    typename TensorDefB,
    typename TensorDefC,
    typename TensorDefD,
    /// Prologue defs
    typename PrologueDefA,
    typename PrologueDefB,
    /// Epilogue defs
    typename EpilogueDef,
    typename ArchTag,
    typename TileShapeDef,
    typename Operator,
    cutlass::gemm::SharedMemoryClearOption SharedMemoryClear>
struct DefaultMma<TensorDefA,
                  TensorDefB,
                  TensorDefC,
                  TensorDefD,
                  PrologueDefA,
                  PrologueDefB,
                  EpilogueDef,
                  cutlass::arch::OpClassTensorOp,
                  ArchTag,
                  TileShapeDef,
                  1,
                  Operator,
                  false,
                  SharedMemoryClear> {
  // Define the MmaCore components
  using MmaCore =
      typename cutlass::gemm::threadblock::DefaultMmaCore<typename TileShapeDef::ThreadblockShape,
                                                          typename TileShapeDef::WarpShape,
                                                          typename TileShapeDef::InstructionShape,
                                                          typename TensorDefA::Element,
                                                          typename TensorDefA::Layout,
                                                          typename TensorDefB::Element,
                                                          typename TensorDefB::Layout,
                                                          typename TensorDefC::Element,
                                                          typename TensorDefC::Layout,
                                                          arch::OpClassTensorOp,
                                                          2,
                                                          Operator>;

  // Define iterators over tiles from the A operand
  using IteratorA = cutlass::contrib::transform::threadblock::PredicatedTileIterator<
      cutlass::MatrixShape<MmaCore::Shape::kM, MmaCore::Shape::kK>,
      typename TensorDefA::Element,
      typename TensorDefA::Layout,
      1,
      typename MmaCore::IteratorThreadMapA,
      TensorDefA::kAlignment>;

  // Define iterators over tiles from the B operand
  using IteratorB = cutlass::contrib::transform::threadblock::PredicatedTileIterator<
      cutlass::MatrixShape<MmaCore::Shape::kK, MmaCore::Shape::kN>,
      typename TensorDefB::Element,
      typename TensorDefB::Layout,
      0,
      typename MmaCore::IteratorThreadMapB,
      TensorDefB::kAlignment>;

  // Define the threadblock-scoped pipelined matrix multiply
  using ThreadblockMma =
      cutlass::contrib::gemm::threadblock::MmaSingleStage<typename MmaCore::Shape,
                                                        IteratorA,
                                                        typename MmaCore::SmemIteratorA,
                                                        IteratorB,
                                                        typename MmaCore::SmemIteratorB,
                                                        typename TensorDefC::Element,
                                                        typename TensorDefC::Layout,
                                                        typename MmaCore::MmaPolicy,
                                                        PrologueDefA,
                                                        PrologueDefB>;
};

////////////////////////////////////////////////////////////////////////////////
/// Specialization for 2 stage (OperatorClass TensorOp)
template <
    /// TensorDefs
    typename TensorDefA,
    typename TensorDefB,
    typename TensorDefC,
    typename TensorDefD,
    /// Prologue defs
    typename PrologueDefA,
    typename PrologueDefB,
    /// Epilogue defs
    typename EpilogueDef,
    typename ArchTag,
    typename TileShapeDef,
    typename Operator,
    cutlass::gemm::SharedMemoryClearOption SharedMemoryClear>
struct DefaultMma<TensorDefA,
                  TensorDefB,
                  TensorDefC,
                  TensorDefD,
                  PrologueDefA,
                  PrologueDefB,
                  EpilogueDef,
                  cutlass::arch::OpClassTensorOp,
                  ArchTag,
                  TileShapeDef,
                  2,
                  Operator,
                  false,
                  SharedMemoryClear> {
  // Define the MmaCore components
  using MmaCore =
      typename cutlass::gemm::threadblock::DefaultMmaCore<typename TileShapeDef::ThreadblockShape,
                                                          typename TileShapeDef::WarpShape,
                                                          typename TileShapeDef::InstructionShape,
                                                          typename TensorDefA::Element,
                                                          typename TensorDefA::Layout,
                                                          typename TensorDefB::Element,
                                                          typename TensorDefB::Layout,
                                                          typename TensorDefC::Element,
                                                          typename TensorDefC::Layout,
                                                          arch::OpClassTensorOp,
                                                          2,
                                                          Operator>;

  // Define iterators over tiles from the A operand
  using IteratorA = cutlass::contrib::transform::threadblock::PredicatedTileIterator<
      cutlass::MatrixShape<MmaCore::Shape::kM, MmaCore::Shape::kK>,
      typename TensorDefA::Element,
      typename TensorDefA::Layout,
      1,
      typename MmaCore::IteratorThreadMapA,
      TensorDefA::kAlignment>;

  // Define iterators over tiles from the B operand
  using IteratorB = cutlass::contrib::transform::threadblock::PredicatedTileIterator<
      cutlass::MatrixShape<MmaCore::Shape::kK, MmaCore::Shape::kN>,
      typename TensorDefB::Element,
      typename TensorDefB::Layout,
      0,
      typename MmaCore::IteratorThreadMapB,
      TensorDefB::kAlignment>;

  // Define the threadblock-scoped pipelined matrix multiply
  using ThreadblockMma =
      cutlass::contrib::gemm::threadblock::MmaPipelined<typename MmaCore::Shape,
                                                        IteratorA,
                                                        typename MmaCore::SmemIteratorA,
                                                        IteratorB,
                                                        typename MmaCore::SmemIteratorB,
                                                        typename TensorDefC::Element,
                                                        typename TensorDefC::Layout,
                                                        typename MmaCore::MmaPolicy,
                                                        PrologueDefA,
                                                        PrologueDefB>;
};

/// Specialization for multistage (OperatorClass TensorOp)
template <
    /// TensorDefs
    typename TensorDefA,
    typename TensorDefB,
    typename TensorDefC,
    typename TensorDefD,
    /// Prologue defs
    typename PrologueDefA,
    typename PrologueDefB,
    /// Epilogue defs
    typename EpilogueDef,
    typename ArchTag,
    typename TileShapeDef,
    int Stages,
    typename Operator,
    cutlass::gemm::SharedMemoryClearOption SharedMemoryClear>
struct DefaultMma<TensorDefA,
                  TensorDefB,
                  TensorDefC,
                  TensorDefD,
                  PrologueDefA,
                  PrologueDefB,
                  EpilogueDef,
                  cutlass::arch::OpClassTensorOp,
                  ArchTag,
                  TileShapeDef,
                  Stages,
                  Operator,
                  false,
                  SharedMemoryClear> {
  static_assert(std::is_same<typename TensorDefD::Layout, cutlass::layout::RowMajor>::value,
                "Only support row-major output");

  static cutlass::arch::CacheOperation::Kind const CacheOpA =
      ((sizeof_bits<typename TensorDefA::Element>::value * TensorDefA::kAlignment) == 128)
          ? cutlass::arch::CacheOperation::Global
          : cutlass::arch::CacheOperation::Always;

  static cutlass::arch::CacheOperation::Kind const CacheOpB =
      ((sizeof_bits<typename TensorDefB::Element>::value * TensorDefB::kAlignment) == 128)
          ? cutlass::arch::CacheOperation::Global
          : cutlass::arch::CacheOperation::Always;

  // Define the MmaCore components
  using MmaCore =
      typename cutlass::gemm::threadblock::DefaultMmaCore<typename TileShapeDef::ThreadblockShape,
                                                          typename TileShapeDef::WarpShape,
                                                          typename TileShapeDef::InstructionShape,
                                                          typename TensorDefA::Element,
                                                          typename TensorDefA::Layout,
                                                          typename TensorDefB::Element,
                                                          typename TensorDefB::Layout,
                                                          typename TensorDefC::Element,
                                                          typename TensorDefC::Layout,
                                                          arch::OpClassTensorOp,
                                                          Stages,
                                                          Operator,
                                                          false,
                                                          CacheOpA,
                                                          CacheOpB>;

  // Define iterators over tiles from the A operand
  using ThreadMapA = typename MmaCore::IteratorThreadMapA;
  using AccessTypeA = cutlass::Array<typename TensorDefA::Element, TensorDefA::kAlignment>;
  using IteratorA = cutlass::transform::threadblock::PredicatedTileAccessIterator<
      cutlass::MatrixShape<TileShapeDef::ThreadblockShape::kM, TileShapeDef::ThreadblockShape::kK>,
      typename TensorDefA::Element,
      typename TensorDefA::Layout,
      1,
      ThreadMapA,
      AccessTypeA>;

  // Define iterators over tiles from the B operand
  using ThreadMapB = typename MmaCore::IteratorThreadMapB;
  using AccessTypeB = cutlass::Array<typename TensorDefB::Element, TensorDefB::kAlignment>;
  using IteratorB = cutlass::transform::threadblock::PredicatedTileAccessIterator<
      cutlass::MatrixShape<TileShapeDef::ThreadblockShape::kK, TileShapeDef::ThreadblockShape::kN>,
      typename TensorDefB::Element,
      typename TensorDefB::Layout,
      0,
      ThreadMapB,
      AccessTypeB>;

  // Define the threadblock-scoped multistage matrix multiply
  using ThreadblockMma =
      cutlass::contrib::gemm::threadblock::MmaMultistage<typename MmaCore::Shape,
                                                         IteratorA,
                                                         typename MmaCore::SmemIteratorA,
                                                         MmaCore::kCacheOpA,
                                                         IteratorB,
                                                         typename MmaCore::SmemIteratorB,
                                                         MmaCore::kCacheOpB,
                                                         typename TensorDefC::Element,
                                                         typename TensorDefC::Layout,
                                                         typename MmaCore::MmaPolicy,
                                                         PrologueDefA,
                                                         PrologueDefB,
                                                         Stages,
                                                         SharedMemoryClear>;
};
}  // namespace threadblock
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass