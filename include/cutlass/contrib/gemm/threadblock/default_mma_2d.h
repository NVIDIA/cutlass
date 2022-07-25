#pragma once

#include "../../epilogue/threadblock/default_softmax_epilogue_tensor_op.h"
#include "../../epilogue/threadblock/softmax_epilogue.h"
#include "../warp/mma_tensor_op_volta_fragment_iterator.h"
#include "cutlass/arch/arch.h"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm70.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm75.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm80.h"
#include "cutlass/gemm/warp/mma_tensor_op_fragment_iterator.h"
#include "cutlass/numeric_types.h"
#include "cutlass/contrib/transform/threadblock/predicated_tile_iterator.h"
#include "mma_2d_pipelined.h"
#include "mma_2d_singlestage.h"
#include "mma_2d_shm_singlestage.h"
#include "mma_tensor_op_fragment_shm_iterator.h"
#include "cutlass/contrib/args_pack_def.h"

////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace contrib {
namespace gemm {
namespace threadblock {

////////////////////////////////////////////////////////////////////////////////

template <
    /// Tensor defs
    typename TensorDefA,
    typename TensorDefB0,
    typename TensorDefB1,
    typename TensorDefD,
    /// Prologue defs
    typename PrologueDefA,
    typename PrologueDefB0,
    typename PrologueDefB1,
    /// Epilogue defs
    typename EpilogueDef0,
    typename EpilogueDef1,
    typename OperatorClass_,
    /// Tag indicating architecture to tune for
    typename ArchTag_,
    typename TileShapeDef0,
    typename TileShapeDef1,
    /// Number of stages used in the pipelined mainloop
    int Stages,
    /// Operation perfomed by GEMM
    typename Operator>
struct DefaultMma2d {
  using ElementA1 = typename EpilogueDef0::TensorDef::Element;
  using LayoutA1 = typename EpilogueDef0::TensorDef::Layout;
  static_assert(std::is_same<LayoutA1, layout::RowMajor>::value, "A1 must be row major");
  static_assert(std::is_same<arch::OpClassTensorOp, OperatorClass_>::value,
                "only support tensor op");

  // Define the MmaCore components
  using MmaCore0 =
      typename cutlass::gemm::threadblock::DefaultMmaCore<typename TileShapeDef0::ThreadblockShape,
                                                          typename TileShapeDef0::WarpShape,
                                                          typename TileShapeDef0::InstructionShape,
                                                          typename TensorDefA::Element,
                                                          typename TensorDefA::Layout,
                                                          typename TensorDefB0::Element,
                                                          typename TensorDefB0::Layout,
                                                          ElementA1,
                                                          LayoutA1,
                                                          arch::OpClassTensorOp,
                                                          2,
                                                          Operator>;
  using MmaCore1 =
      typename cutlass::gemm::threadblock::DefaultMmaCore<typename TileShapeDef1::ThreadblockShape,
                                                          typename TileShapeDef1::WarpShape,
                                                          typename TileShapeDef1::InstructionShape,
                                                          ElementA1,
                                                          LayoutA1,
                                                          typename TensorDefB1::Element,
                                                          typename TensorDefB1::Layout,
                                                          typename TensorDefD::Element,
                                                          typename TensorDefD::Layout,
                                                          arch::OpClassTensorOp,
                                                          2,
                                                          Operator>;

  // Define iterators over tiles from the A operand
  using IteratorA0 = cutlass::contrib::transform::threadblock::PredicatedTileIterator<
      cutlass::MatrixShape<MmaCore0::Shape::kM, MmaCore0::Shape::kK>,
      typename TensorDefA::Element,
      typename TensorDefA::Layout,
      1,
      typename MmaCore0::IteratorThreadMapA,
      TensorDefA::kAlignment>;

  // Define iterators over tiles from the B operand
  using IteratorB0 = cutlass::contrib::transform::threadblock::PredicatedTileIterator<
      cutlass::MatrixShape<MmaCore0::Shape::kK, MmaCore0::Shape::kN>,
      typename TensorDefB0::Element,
      typename TensorDefB0::Layout,
      0,
      typename MmaCore0::IteratorThreadMapB,
      TensorDefB0::kAlignment>;

  static_assert(TileShapeDef0::kPartitionsK == 1, "SplitK not allowed");

  using Epilogue0 =
      typename cutlass::contrib::epilogue::threadblock::DefaultSoftmaxEpilogueTensorOp<
          typename TileShapeDef0::ThreadblockShape,
          typename MmaCore0::MmaPolicy::Operator,
          TileShapeDef0::kPartitionsK,
          typename EpilogueDef0::Operator,
          EpilogueDef0::TensorDef::kAlignment>::Epilogue;

  // Use fragment iterator for A operand
  using AccumulatorLayout = LayoutA1;
  using FragmentIteratorA1 = cutlass::contrib::gemm::warp::MmaTensorOpFragmentIterator<
      cutlass::MatrixShape<MmaCore1::WarpShape::kM,
                           MmaCore1::InstructionShape::kK>,                    // warp shape
      cutlass::MatrixShape<MmaCore0::WarpShape::kM, MmaCore0::WarpShape::kN>,  // accumulator
                                                                               // shape
      MmaCore1::Shape::kK,
      ElementA1,
      ElementA1,
      AccumulatorLayout,
      typename TileShapeDef0::InstructionShape,
      typename EpilogueDef0::Operator,
      true>;

  // Define iterators over tiles from the B operand
  using IteratorB1 = cutlass::contrib::transform::threadblock::PredicatedTileIterator<
      cutlass::MatrixShape<MmaCore1::Shape::kK, MmaCore1::Shape::kN>,
      typename TensorDefB1::Element,
      typename TensorDefB1::Layout,
      0,
      typename MmaCore1::IteratorThreadMapB,
      TensorDefB1::kAlignment>;

  // Define the threadblock-scoped pipelined matrix multiply

  using ThreadblockMma2D = typename std::conditional<
      Stages == 1,
      cutlass::contrib::gemm::threadblock::Mma2DSingleStage<typename MmaCore0::Shape,
                                                            IteratorA0,
                                                            typename MmaCore0::SmemIteratorA,
                                                            IteratorB0,
                                                            typename MmaCore0::SmemIteratorB,
                                                            typename MmaCore1::Shape,
                                                            FragmentIteratorA1,
                                                            IteratorB1,
                                                            typename MmaCore1::SmemIteratorB,
                                                            ElementA1,
                                                            LayoutA1,
                                                            typename EpilogueDef0::Operator,
                                                            Epilogue0,
                                                            typename MmaCore0::MmaPolicy,
                                                            typename MmaCore1::MmaPolicy,
                                                            PrologueDefA,
                                                            PrologueDefB0,
                                                            PrologueDefB1>,
      cutlass::contrib::gemm::threadblock::Mma2DPipelined<typename MmaCore0::Shape,
                                                          IteratorA0,
                                                          typename MmaCore0::SmemIteratorA,
                                                          IteratorB0,
                                                          typename MmaCore0::SmemIteratorB,
                                                          typename MmaCore1::Shape,
                                                          FragmentIteratorA1,
                                                          IteratorB1,
                                                          typename MmaCore1::SmemIteratorB,
                                                          ElementA1,
                                                          LayoutA1,
                                                          typename EpilogueDef0::Operator,
                                                          Epilogue0,
                                                          typename MmaCore0::MmaPolicy,
                                                          typename MmaCore1::MmaPolicy,
                                                          PrologueDefA,
                                                          PrologueDefB0,
                                                          PrologueDefB1>>::type;
};

////////////////////////////////////////////////////////////////////////////////

}  // namespace threadblock
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
