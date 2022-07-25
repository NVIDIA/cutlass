#pragma once

#include "../kernel/gemm_grouped.h"
#include "cutlass/cutlass.h"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/contrib/epilogue/threadblock/default_epilogue_tensor_op.h"
#include "cutlass/epilogue/threadblock/default_epilogue_volta_tensor_op.h"
#include "cutlass/epilogue/threadblock/epilogue.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm70.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm75.h"
#include "cutlass/gemm/threadblock/default_mma_core_sm80.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/numeric_types.h"
#include "cutlass/transform/threadblock/predicated_tile_iterator.h"
#include "cutlass/contrib/args_pack_def.h"
#include "cutlass/contrib/gemm/threadblock/default_mma.h"

////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace contrib {
namespace gemm {
namespace kernel {

////////////////////////////////////////////////////////////////////////////////

template <
    /// Tensor defs
    typename TensorDefA,
    typename TensorDefB,
    typename TensorDefC,
    typename TensorDefD,
    /// Prolog defs
    typename PrologueDefA,
    typename PrologueDefB,
    // Epilogue defs
    typename EpilogueDef,
    /// Operator class tag
    typename OperatorClass,
    /// Tag indicating architecture to tune for
    typename ArchTag,
    /// Tile shape def
    typename TileShapeDef,
    /// Number of stages used in the pipelined mainloop
    int Stages,
    /// Operation performed by GEMM
    typename Operator,
    /// Operator to generate problem size
    typename ProblemSizeOperator,
    /// Operator to generate batch count
    typename BatchCountOperator>
struct DefaultGemmGrouped {
  using Mma = typename cutlass::contrib::gemm::threadblock::DefaultMma<TensorDefA,
                                                                       TensorDefB,
                                                                       TensorDefC,
                                                                       TensorDefD,
                                                                       PrologueDefA,
                                                                       PrologueDefB,
                                                                       EpilogueDef,
                                                                       arch::OpClassTensorOp,
                                                                       ArchTag,
                                                                       TileShapeDef,
                                                                       Stages,
                                                                       Operator>::ThreadblockMma;

  static const int kPartitionsK = TileShapeDef::kPartitionsK;
  using EpilogueOp = typename EpilogueDef::Operator;

  using Epilogue = typename std::conditional<
      std::is_same<ArchTag, cutlass::arch::Sm70>::value,
      typename cutlass::epilogue::threadblock::DefaultEpilogueVoltaTensorOp<
          typename TileShapeDef::ThreadblockShape,
          typename Mma::Operator,
          kPartitionsK,
          EpilogueOp,
          EpilogueOp::kCount>::Epilogue,
      typename cutlass::contrib::epilogue::threadblock::DefaultEpilogueTensorOp<
          typename TileShapeDef::ThreadblockShape,
          typename Mma::Operator,
          kPartitionsK,
          EpilogueOp,
          EpilogueOp::kCount>::Epilogue>::type;

  using ParamsDef = GemmParamsDef<ProblemSizeOperator,
                                  BatchCountOperator,
                                  typename TensorDefA::ParamOp,
                                  typename TensorDefB::ParamOp,
                                  typename TensorDefC::ParamOp,
                                  typename TensorDefD::ParamOp>;
  /// Define the kernel-level GEMM operator.
  using GemmGroupedKernel = kernel::GemmGrouped<Mma, Epilogue, ParamsDef>;
};

}  // namespace kernel
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
