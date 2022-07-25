#pragma once

#include "cutlass/cutlass.h"

#include "cutlass/array.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/layout/tensor.h"
#include "cutlass/numeric_conversion.h"
#include "cutlass/layout/pitch_linear.h"

namespace cutlass {
namespace contrib {
namespace gemm {
namespace threadblock {

////////////////////////////////////////////////////////////////////////////////

template <
    /// Gemm0 threadblock tile
    typename Shape0_,
    /// Gemm1 threadblock tile
    typename Shape1_,
    /// Gemm0 warp tile
    typename WarpShape0_,
    /// Shape of one mma
    typename InstructionShape_,
    /// Accumulator Element type
    typename ElementAccumulator_,
    /// Element type
    typename Element_,
    /// Layout of operand in memory
    typename Layout_,
    /// Layout of shared memmory
    typename SmemLayout_>
class MmaTensorOpFragmentShmIterator;

// Partial specialization for col-major operand tile
template <
    /// Gemm0 threadblock tile
    typename Shape0_,
    /// Gemm1 threadblock tile
    typename Shape1_,
    /// Gemm0 warp tile
    typename WarpShape0_,
    /// Shape of one mma
    typename InstructionShape_,
    /// Accumulator Element type
    typename ElementAccumulator_,
    /// Element type
    typename Element_,
    /// Layout of operand in memory
    typename SmemLayout_>
class MmaTensorOpFragmentShmIterator<Shape0_,
                                     Shape1_,
                                     WarpShape0_,
                                     InstructionShape_,
                                     ElementAccumulator_,
                                     Element_,
                                     cutlass::layout::RowMajor,
                                     SmemLayout_> {
 public:
  /// Arguments rename
  using Shape0 = Shape0_;
  using Shape1 = Shape1_;
  using WarpShape0 = WarpShape0_;
  using InstructionShape = InstructionShape_;
  using ElementAccumulator = ElementAccumulator_;
  using Element = Element_;
  using Layout = cutlass::layout::RowMajor;
  using SmemLayout = SmemLayout_;

  /// Type calculation
  using AccumulatorShape = cutlass::MatrixShape<WarpShape0::kM, WarpShape0::kN>;

  /// Tensor Reference Type
  using TensorRef = TensorRef<Element, SmemLayout>;

  /// Number of participating threads
  static int const kThreads = 32;

 private:
  static int const kElementsPerMma = InstructionShape::kM * InstructionShape::kN / kThreads;
  static int const kElementsPerAccess = 2;

  static_assert(!(Shape1::kK % InstructionShape::kN),
                "Shape1::kK must be divisible by Instruction::kN");
  static const int kMmaCountColumnPerCtaTile = Shape1::kK / InstructionShape::kN;

  /// Number of mma operations performed by the entire accumulator
  using AccumulatorIterations =
      MatrixShape<WarpShape0::kM / InstructionShape::kM, WarpShape0::kN / InstructionShape::kN>;

 public:
  //
  // Derived quantities
  //
  /// Accumulator Fragment object
  using AccumulatorFragment = Array<ElementAccumulator, AccumulatorShape::kCount / kThreads>;

 private:
  /// Internal access type
  using AccessType = Array<Element, kElementsPerAccess>;

 private:
  //
  // Data members
  //

  TensorRef shm_ref_;

  /// warp offsets in threadblock tile
  MatrixCoord warp_offset_;

  /// thread offset in mma
  MatrixCoord thread_mma_offset_;

  /// Internal index
  int index_;

 public:
  /// Constructs an iterator
  CUTLASS_HOST_DEVICE
  MmaTensorOpFragmentShmIterator() {
  }
  /// Constructs an iterator
  CUTLASS_HOST_DEVICE
  MmaTensorOpFragmentShmIterator(TensorRef ref, MatrixCoord warp_offset, int thread_idx)
      : shm_ref_(ref), warp_offset_(warp_offset), index_(0) {
    int lane_idx = thread_idx % 32;
    thread_mma_offset_ = {lane_idx / 4, lane_idx % 4 * kElementsPerAccess};
  }

  /// Add offset
  CUTLASS_HOST_DEVICE void add_offset(int index_offset) {
    index_ += index_offset;
  }

  /// Increments
  CUTLASS_HOST_DEVICE
  MmaTensorOpFragmentShmIterator& operator++() {
    add_offset(1);
    return *this;
  }

  /// Decrements
  CUTLASS_HOST_DEVICE
  MmaTensorOpFragmentShmIterator& operator--() {
    add_offset(-1);
    return *this;
  }

  /// Stores sub fragment of accumulator to shared memory
  CUTLASS_HOST_DEVICE
  void store(const AccumulatorFragment& accum) {
    AccessType const* accumulators = reinterpret_cast<AccessType const*>(&accum);
    // initial column of the current warp
    int const warp_mma_row_offset = warp_offset_.row() * AccumulatorIterations::kRow;
    int const warp_mma_column_offset = warp_offset_.column() * AccumulatorIterations::kColumn;

    CUTLASS_PRAGMA_UNROLL
    for (int n = 0; n < AccumulatorIterations::kColumn; ++n) {
      // current iterating column in cta
      int mma_column_idx = warp_mma_column_offset + n;
      // if not in loading operand cta, skip storing to shared memory
      if (mma_column_idx / kMmaCountColumnPerCtaTile != index_) {
        continue;
      }
      CUTLASS_PRAGMA_UNROLL
      for (int m = 0; m < AccumulatorIterations::kRow; ++m) {
        int accumulator_access_offset = (n * AccumulatorIterations::kRow + m) * (kElementsPerMma / kElementsPerAccess);

        // calculate coordinates in cta tile
        int cta_mma_column_idx = mma_column_idx % kMmaCountColumnPerCtaTile;
        int cta_mma_row_idx = warp_mma_row_offset + m;

        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < kElementsPerMma / kElementsPerAccess; ++i) {
          int element_row_idx =
              cta_mma_row_idx * InstructionShape::kM + (i * 8) + thread_mma_offset_.row();
          int element_column_idx =
              cta_mma_column_idx * InstructionShape::kN + thread_mma_offset_.column();

          // map element coordinate to offset in shared memory
          auto offset = shm_ref_.offset({element_row_idx, element_column_idx});
          auto set_ptr = reinterpret_cast<AccessType*>(shm_ref_.data() + offset);
          set_ptr[0] = accumulators[accumulator_access_offset + i];
        }
      }
    }
  }
};

////////////////////////////////////////////////////////////////////////////////

}  // namespace threadblock
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
