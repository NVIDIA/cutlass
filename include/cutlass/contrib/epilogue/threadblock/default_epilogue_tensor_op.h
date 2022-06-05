#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"
#include "cutlass/array.h"

#include "cutlass/platform/platform.h"

#include "cutlass/gemm/gemm.h"

// #include "cutlass/epilogue/thread/linear_combination.h"
// #include "cutlass/epilogue/thread/linear_combination_clamp.h"
// #include "cutlass/epilogue/thread/linear_combination_relu.h"
// #include "cutlass/epilogue/thread/linear_combination_relu0.h"
// #include "cutlass/epilogue/thread/linear_combination_gelu.h"
// #include "cutlass/epilogue/thread/linear_combination_sigmoid.h"
// #include "cutlass/epilogue/thread/linear_combination_hardswish.h"
// #include "cutlass/epilogue/thread/linear_combination_planar_complex.h"

// #include "cutlass/epilogue/thread/conversion_op.h"
// #include "cutlass/epilogue/thread/reduction_op.h"

#include "cutlass/transform/threadblock/regular_tile_iterator_pitch_linear.h"

#include "cutlass/epilogue/warp/fragment_iterator_tensor_op.h"
#include "cutlass/epilogue/warp/fragment_iterator_complex_tensor_op.h"
#include "cutlass/epilogue/warp/tile_iterator_tensor_op.h"
#include "cutlass/epilogue/warp/tile_iterator_tensor_op_mixed.h"
#include "cutlass/epilogue/threadblock/default_thread_map_tensor_op.h"
#include "cutlass/epilogue/threadblock/predicated_tile_iterator.h"
#include "cutlass/epilogue/threadblock/shared_load_iterator.h"
#include "cutlass/epilogue/threadblock/shared_load_iterator_mixed.h"

#include "cutlass/contrib/epilogue/threadblock/epilogue.h"
#include "cutlass/contrib/epilogue/threadblock/predicated_tile_iterator.h"

////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace contrib {
namespace epilogue {
namespace threadblock {

////////////////////////////////////////////////////////////////////////////////

namespace detail {

template <typename ElementOutput,
          typename ElementAccumulator,
          int ElementsPerAccess,
          typename ThreadblockShape,
          typename WarpShape,
          typename InstructionShape,
          typename ThreadMap>
struct DefaultIteratorsTensorOp {
  using WarpTileIterator = cutlass::epilogue::warp::
      TileIteratorTensorOp<WarpShape, InstructionShape, ElementAccumulator, layout::RowMajor>;

  using SharedLoadIterator =
      cutlass::epilogue::threadblock::SharedLoadIterator<ThreadMap, ElementAccumulator>;

  static int const kFragmentsPerIteration = 1;
};

/// Partial specialization for float <= float x 4
template <typename ThreadblockShape,
          typename WarpShape,
          typename InstructionShape,
          typename ThreadMap>
struct DefaultIteratorsTensorOp<float,
                                float,
                                4,
                                ThreadblockShape,
                                WarpShape,
                                InstructionShape,
                                ThreadMap> {
  using WarpTileIterator = cutlass::epilogue::warp::
      TileIteratorTensorOp<WarpShape, InstructionShape, float, layout::RowMajor>;

  using SharedLoadIterator = cutlass::epilogue::threadblock::SharedLoadIterator<ThreadMap, float>;

  static int const kFragmentsPerIteration = 2;
};

/// Partial specialization for half <= float x 8 epilogues avoids shared memory bank conflicts.
template <typename ThreadblockShape,
          typename WarpShape,
          typename InstructionShape,
          typename ThreadMap>
struct DefaultIteratorsTensorOp<half_t,
                                float,
                                8,
                                ThreadblockShape,
                                WarpShape,
                                InstructionShape,
                                ThreadMap> {
  using WarpTileIterator = cutlass::epilogue::warp::
      TileIteratorTensorOpMixed<WarpShape, InstructionShape, float, 32, 16, 8, 8>;

  using SharedLoadIterator =
      cutlass::epilogue::threadblock::SharedLoadIteratorMixed<ThreadMap, float, 32, 16, 8, 8>;

  static int const kFragmentsPerIteration = 2;
};
}  // namespace detail

////////////////////////////////////////////////////////////////////////////////

/// Defines sensible defaults for epilogues for TensorOps.
template <typename Shape_,
          typename WarpMmaTensorOp_,
          int PartitionsK,
          typename OutputOp_,
          int ElementsPerAccess>
struct DefaultEpilogueTensorOp {
  using Shape = Shape_;
  using WarpMmaTensorOp = WarpMmaTensorOp_;
  static int const kPartitionsK = PartitionsK;
  using OutputOp = OutputOp_;
  static int const kElementsPerAccess = ElementsPerAccess;

  using ElementOutput = typename OutputOp::ElementOutput;
  using LayoutC = typename WarpMmaTensorOp::LayoutC;
  using ElementAccumulator = typename WarpMmaTensorOp::ElementC;

  //
  // Thread map
  //

  using OutputTileThreadMap = typename cutlass::epilogue::threadblock::DefaultThreadMapTensorOp<
      Shape,
      typename WarpMmaTensorOp::Shape,
      kPartitionsK,
      ElementOutput,
      kElementsPerAccess>::Type;

  static bool const UseCUDAStore = platform::is_same<ElementOutput, double>::value;

  using OutputTileIterator = cutlass::contrib::epilogue::threadblock::
      PredicatedTileIterator<OutputTileThreadMap, ElementOutput, UseCUDAStore>;

  using AccumulatorFragmentIterator =
      typename std::conditional<is_complex<ElementOutput>::value,
                                cutlass::epilogue::warp::FragmentIteratorComplexTensorOp<
                                    typename WarpMmaTensorOp::Shape,
                                    typename WarpMmaTensorOp::Policy::Operator::Shape,
                                    typename WarpMmaTensorOp::Policy::Operator::ElementC,
                                    typename WarpMmaTensorOp::Policy::Operator::FragmentC,
                                    LayoutC>,
                                cutlass::epilogue::warp::FragmentIteratorTensorOp<
                                    typename WarpMmaTensorOp::Shape,
                                    typename WarpMmaTensorOp::Policy::Operator::Shape,
                                    typename WarpMmaTensorOp::Policy::Operator::ElementC,
                                    typename WarpMmaTensorOp::Policy::Operator::FragmentC,
                                    LayoutC>>::type;

  /// Support several implementations depending on structure of epilogue
  using DefaultIterators =
      detail::DefaultIteratorsTensorOp<ElementOutput,
                                       ElementAccumulator,
                                       kElementsPerAccess,
                                       Shape,
                                       typename WarpMmaTensorOp::Shape,
                                       typename WarpMmaTensorOp::Policy::Operator::Shape,
                                       typename OutputTileThreadMap::CompactedThreadMap>;

  using WarpTileIterator = typename DefaultIterators::WarpTileIterator;
  using SharedLoadIterator = typename DefaultIterators::SharedLoadIterator;

  /// Hard-coded padding elements added
  using Padding = cutlass::MatrixShape<0, 64 / sizeof_bits<ElementAccumulator>::value * 4>;

  static int const kFragmentsPerIteration =
      (kPartitionsK == 1 ? DefaultIterators::kFragmentsPerIteration : 1);

  //
  // Define the epilogue
  //
  using Epilogue = cutlass::contrib::epilogue::threadblock::Epilogue<Shape,
                                                                     WarpMmaTensorOp,
                                                                     kPartitionsK,
                                                                     OutputTileIterator,
                                                                     AccumulatorFragmentIterator,
                                                                     WarpTileIterator,
                                                                     SharedLoadIterator,
                                                                     OutputOp,
                                                                     Padding,
                                                                     kFragmentsPerIteration>;
};

}  // namespace threadblock
}  // namespace epilogue
}  // namespace contrib
}  // namespace cutlass

////////////////////////////////////////////////////////////////////////////////
