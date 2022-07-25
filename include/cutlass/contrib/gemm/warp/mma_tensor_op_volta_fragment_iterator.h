#pragma once

#include "cutlass/array.h"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/layout/tensor.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/numeric_conversion.h"
#include "mma_tensor_op_fragment_iterator.h"

namespace cutlass {
namespace contrib {
namespace gemm {
namespace warp {

// Partial specialization for row-major accumulator tile

template <
    /// Shape of warp tile to load (concept: MatrixShape)
    typename Shape_,
    /// Shape of the warp accumulation tile (concept: MatrixShape)
    typename AccumulatorShape_,
    /// KBlocks columns to compute residual
    int KBlocksColumn_,
    /// Accumulator Element type
    typename ElementAccumulator_,
    /// Element type
    typename Element_,
    /// Shape of one matrix product operation (concept: MatrixShape)
    /// Output operation on fragment
    typename OutputOp_>
class MmaTensorOpFragmentIterator<Shape_,
                                  AccumulatorShape_,
                                  KBlocksColumn_,
                                  ElementAccumulator_,
                                  Element_,
                                  cutlass::layout::RowMajor,
                                  cutlass::gemm::GemmShape<8, 8, 4>,
                                  OutputOp_,
                                  true> {
 public:
  /// Shape of warp tile to load (concept: MatrixShape)
  using Shape = Shape_;

  /// Shape of the warp accumulation tile (concept: MatrixShape)
  using AccumulatorShape = AccumulatorShape_;

  /// KBlocks columns to compute residual
  static int const kKBlockColumn = KBlocksColumn_;

  /// Accumulator Element type
  using ElementAccumulator = ElementAccumulator_;

  /// Element type
  using Element = Element_;

  /// Layout of source tile
  using Layout = cutlass::layout::RowMajor;

  /// Shape of one matrix product operation (concept: MatrixShape),
  /// For Volta, warp tile is splitted into 32x32x4 interleave tiles
  using InterleavedTileShape = cutlass::gemm::GemmShape<32, 32, 4>;

  /// Output operation on fragment
  using OutputOp = OutputOp_;

  /// Whether beta is zero
  static bool const IsBetaZero = true;

  /// Number of participating threads
  static int const kThreads = 32;

  /// Internal structure of iterator - made public to enable introspection
  struct Policy {
    static_assert(!(Shape::kRow % InterleavedTileShape::kM) &&
                      !(Shape::kColumn % InterleavedTileShape::kK),
                  "Shape of warp-level Mma must be divisible by interleaved tile shape.");
    static_assert(!(AccumulatorShape::kRow % Shape::kRow) &&
                      !(AccumulatorShape::kColumn % Shape::kColumn),
                  "Shape of Warp Accumulator must be divisible by warp shape.");
    static_assert(!(kKBlockColumn % Shape::kColumn),
                  "KBlock size must be divisible by warp shape.");

    /// Number of times this iterator can be incremented
    static int const kIterations = AccumulatorShape::kCount / Shape::kCount;
  };

 private:
  static int const kElementsPerAccess = 4;

  /// Number of mma operations (by interleaved tile) performed by a warp
  using TileIterations = MatrixShape<Shape::kRow / InterleavedTileShape::kM,
                                     Shape::kColumn / InterleavedTileShape::kK>;
  /// Number of mma operations (by interleaved tile) performed by the entire accumulator
  using AccumulatorIterations = MatrixShape<AccumulatorShape::kRow / InterleavedTileShape::kM,
                                            AccumulatorShape::kColumn / InterleavedTileShape::kN>;
  static_assert(Shape::kRow == AccumulatorShape::kRow,
                "Shape::kRow must be equal to Accumulator::kRow");
  static_assert(TileIterations::kColumn == 1, "TileIteration::kColumn must be 1");

 public:
  //
  // Derived quantities
  //

  /// Fragment object holding a thread's part of a tile
  /// This is the fragment size produced by one access of the iterator.
  using Fragment = Array<Element, Shape::kCount / kThreads * 2>;

  /// Accumulator Fragment object
  using AccumulatorFragment = Array<ElementAccumulator, AccumulatorShape::kCount / kThreads>;

 private:
  /// Internal access type
  using AccessType = Array<ElementAccumulator, kElementsPerAccess>;
  using FragmentAccessType = Array<Element, kElementsPerAccess>;

 private:
  //
  // Data members
  //

  /// Accumulator tile
  AccessType const* accumulators_;

  /// Internal index
  int index_;

 public:
  /// Constructs an iterator
  CUTLASS_HOST_DEVICE
  MmaTensorOpFragmentIterator(AccumulatorFragment const& accum)
      : accumulators_(reinterpret_cast<AccessType const*>(&accum)), index_(0) {
  }

  /// Add offset
  CUTLASS_HOST_DEVICE
  void add_offset(int index_offset) {
    index_ += index_offset;
  }

  /// Increments
  CUTLASS_HOST_DEVICE
  MmaTensorOpFragmentIterator& operator++() {
    add_offset(1);
    return *this;
  }

  /// Decrements
  CUTLASS_HOST_DEVICE
  MmaTensorOpFragmentIterator& operator--() {
    add_offset(-1);
    return *this;
  }

  /// Loads a fragment from the referenced part of the accumulator tile
  // CUTLASS_HODEVICE
  CUTLASS_DEVICE
  void load(Fragment& frag) const {
    FragmentAccessType* frag_ptr = reinterpret_cast<FragmentAccessType*>(&frag);
    //  NumericArrayConverter<Element, ElementAccumulator, kElementsPerAccess,
    //  FloatRoundStyle::round_indeterminate> fragmentConverter;

    int k_group = index_ % 8;
    bool flag1 = static_cast<bool>(k_group & 0x1);
    bool flag2 = static_cast<bool>(k_group & 0x2);
    bool flag4 = static_cast<bool>(k_group & 0x4);
    int lane_id = threadIdx.x % 32;

    int offset0 = (flag1 ? 4 : 0) + (flag4 ? 1 : 0);
    int offset1 = offset0 + 2;
    CUTLASS_PRAGMA_UNROLL
    for (int m = 0; m < TileIterations::kRow; m++) {
      // here one mma stands for a 32x32x4 tile
      int mma_index = index_ / 8 * AccumulatorIterations::kRow + m;
      // each thread holds 32 half values, i.e. 8 AccessType
      int accumulator_access_offset = mma_index * 8;

      AccessType value0 = accumulators_[accumulator_access_offset + offset0];
      AccessType value1 = accumulators_[accumulator_access_offset + offset1];

      uint64_t value0_synced =
          __shfl_xor_sync(0xFFFFFFFF, *reinterpret_cast<uint64_t*>(&value0), 0x8, 32);
      uint64_t value1_synced =
          __shfl_xor_sync(0xFFFFFFFF, *reinterpret_cast<uint64_t*>(&value1), 0x8, 32);

      if (flag2 != static_cast<bool>(lane_id & 0x8)) {
        value0 = *reinterpret_cast<AccessType*>(&value0_synced);
        value1 = *reinterpret_cast<AccessType*>(&value1_synced);
      }

      int frag_access_offset = m * 2;
      frag_ptr[frag_access_offset].clear();
      frag_ptr[frag_access_offset + 1].clear();
      frag_ptr[frag_access_offset] = value0;
      frag_ptr[frag_access_offset + 1] = value1;
    }
    // cutlass::debug::dump_fragment(frag);
  }
};

////////////////////////////////////////////////////////////////////////////////

}  // namespace warp
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
