#pragma once

#include "../kernel/gemm_grouped_2d.h"
#include "../threadblock/default_mma_2d.h"
#include "cutlass/cutlass.h"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/epilogue/threadblock/default_epilogue_tensor_op.h"
#include "cutlass/epilogue/threadblock/default_epilogue_volta_tensor_op.h"
#include "cutlass/epilogue/threadblock/epilogue.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/numeric_types.h"
#include "cutlass/transform/threadblock/predicated_tile_iterator.h"
#include "cutlass/contrib/args_pack_def.h"

////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace contrib {
namespace gemm {
namespace kernel {

////////////////////////////////////////////////////////////////////////////////

template <
    /// Tensor defs
    typename TensorDefA,
    typename TensorDefB0,
    typename TensorDefB1,
    typename TensorDefC0,
    typename TensorDefC1,
    typename TensorDefD,
    /// Prolog defs
    typename PrologDefA,
    typename PrologDefB0,
    typename PrologDefB1,
    /// Epilogue defs
    typename EpilogueDef0,
    typename EpilogueDef1,
    /// Operator class tag
    typename OperatorClass,
    /// Tag indicating architecture to tune for
    typename ArchTag,
    /// Tile shape defs
    typename TileShapeDef0,
    typename TileShapeDef1,
    /// Stages
    int Stages,
    /// Operation performed by GEMM
    typename Operator,
    /// Operator to generate problem size 0
    typename ProblemSizeOperator0,
    /// Operator to generate problem size 1
    typename ProblemSizeOperator1,
    /// Operator to generate batch count
    typename BatchCountOperator>
struct DefaultGemmGrouped2D {
  static_assert(std::is_same<arch::OpClassTensorOp, OperatorClass>::value,
                "only support tensor op");
  using Mma2D =
      typename cutlass::contrib::gemm::threadblock::DefaultMma2d<TensorDefA,
                                                                 TensorDefB0,
                                                                 TensorDefB1,
                                                                 TensorDefD,
                                                                 PrologDefA,
                                                                 PrologDefB0,
                                                                 PrologDefB1,
                                                                 EpilogueDef0,
                                                                 EpilogueDef1,
                                                                 arch::OpClassTensorOp,
                                                                 ArchTag,
                                                                 TileShapeDef0,
                                                                 TileShapeDef1,
                                                                 Stages,
                                                                 Operator>::ThreadblockMma2D;

  using EpilogueOp = typename EpilogueDef1::Operator;
  using Epilogue = typename std::conditional<
      std::is_same<ArchTag, cutlass::arch::Sm70>::value,
      typename cutlass::epilogue::threadblock::DefaultEpilogueVoltaTensorOp<
          typename TileShapeDef1::ThreadblockShape,
          typename Mma2D::Operator1,
          TileShapeDef1::kPartitionsK,
          EpilogueOp,
          EpilogueOp::kCount>::Epilogue,
      typename cutlass::epilogue::threadblock::DefaultEpilogueTensorOp<
          typename TileShapeDef1::ThreadblockShape,
          typename Mma2D::Operator1,
          TileShapeDef1::kPartitionsK,
          EpilogueOp,
          EpilogueOp::kCount>::Epilogue>::type;

  using ParamsDef = Gemm2DParamsDef<ProblemSizeOperator0,
                                    ProblemSizeOperator1,
                                    BatchCountOperator,
                                    typename TensorDefA::ParamOp,
                                    typename TensorDefB0::ParamOp,
                                    typename TensorDefB1::ParamOp,
                                    typename TensorDefC0::ParamOp,
                                    typename TensorDefC1::ParamOp,
                                    typename TensorDefD::ParamOp>;
  /// Define the kernel-level GEMM operator.
  using GemmGrouped2DKernel = kernel::GemmGrouped2D<Mma2D, Epilogue, ParamsDef>;
};

}  // namespace kernel
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
