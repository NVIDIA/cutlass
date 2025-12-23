#pragma once

#include "cutlass/gemm/threadblock/gemv.h"
#include "cutlass/gemm/threadblock/default_gemv_core.h"
#include "cutlass/gemm/threadblock/threadblock_swizzle.h"

namespace cutlass {
namespace gemm {
namespace kernel {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// Size of the ThreadBlock tile - concept: gemm::GemmShape<>
    typename ThreadBlockShape_,
    /// Size of the per-thread shape - concept: gemm::GemmShape<>
    typename ThreadShape_,
    /// Data type of A elements
    typename ElementA_,
    /// Layout of A matrix (concept: MatrixLayout)
    typename LayoutA_,
    /// Data type of B elements
    typename ElementB_,
    /// Layout of B matrix (concept: MatrixLayout)
    typename LayoutB_,
    /// Element type of C/D matrix
    typename ElementCD_,
    /// Layout of C/D matrix (concept: MatrixLayout)
    typename LayoutCD_,
    ///  Data type of the accumulator
    typename ElementAccumulator_ = ElementCD_>
struct DefaultGemv {

  /// Shape of Threadblock-level matrix operation (concept: GemmShape)
  using ThreadBlockShape = ThreadBlockShape_;

  /// Shape of warp-level matrix operation (concept: GemmShape)
  using ThreadShape = ThreadShape_;

  /// Data type of multiplicand A
  using ElementA = ElementA_;

  /// Layout of multiplicand A
  using LayoutA = LayoutA_;

  /// Data type of multiplicand B
  using ElementB = ElementB_;

  /// Layout of multiplicand B
  using LayoutB = LayoutB_;

  /// Data type of accumulators
  using ElementAccumulator = ElementAccumulator_;

  /// Data type of accumulators (same as C/D)
  using LayoutAccumulator = LayoutCD_;

  /// Data type of input/output matrix C/D
  using ElementCD = ElementCD_;

  /// Layout of input/output matrix C/D
  using LayoutCD = LayoutCD_;

  // Define the core components
  using Core = typename cutlass::gemm::threadblock::DefaultGemvCore<
      ThreadBlockShape, ThreadShape, ElementA, LayoutA, ElementB, LayoutB,
      ElementAccumulator, LayoutAccumulator>;

  // Define the threadblock-scoped gemv
  using ThreadBlockGemv = cutlass::gemm::threadblock::Gemv<Core>;

  // Iterator for multiplicand A
  using IteratorA = typename ThreadBlockGemv::IteratorA;

  // Iterator for multiplicand B
  using IteratorB = typename ThreadBlockGemv::IteratorB;

  /// Policy for the iterator that reads/writes C/D
  using IteratorPolicyCD = typename platform::conditional<
        platform::is_same<LayoutCD, layout::RowMajor>::value,
        cutlass::transform::PitchLinearTilePolicyStripminedThreadContiguous<
          layout::PitchLinearShape<ThreadBlockShape::kN, ThreadBlockShape::kM>, Core::kThreadsPerN, ThreadShape::kN>,
        cutlass::transform::PitchLinearTilePolicyStripminedThreadStrided<
          layout::PitchLinearShape<ThreadBlockShape::kM, ThreadBlockShape::kN>, Core::kThreadsPerN, ThreadShape::kM>>::type;

  /// Iterator that reads/writes C/D
  using IteratorCD = cutlass::transform::threadblock::PredicatedTileIterator<
   cutlass::MatrixShape<ThreadBlockShape::kM, ThreadBlockShape::kN>, ElementCD, LayoutCD, 0, IteratorPolicyCD>;

  /// Fragment storage for C/D
  using FragmentCD = typename IteratorCD::Fragment;

  // Define the threadblock swizzle
  using ThreadBlockSwizzle = cutlass::gemm::threadblock::GemvBatchedStridedThreadblockDefaultSwizzle;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace kernel
}  // namespace gemm
}  // namespace cutlass
