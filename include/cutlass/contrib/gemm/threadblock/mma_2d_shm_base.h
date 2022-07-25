#pragma once

#include "cutlass/aligned_buffer.h"
#include "cutlass/arch/memory.h"
#include "cutlass/array.h"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/numeric_types.h"
////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace contrib {
namespace gemm {
namespace threadblock {

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

/// Structure to compute the matrix product targeting CUDA cores and SIMT math
/// instructions.
template <
    /// Size of the Gemm problem - concept: gemm::GemmShape<>
    typename Shape0_,
    /// Size of the Gemm problem - concept: gemm::GemmShape<>
    typename Shape1_,
    /// Policy describing tuning details (concept: MmaPolicy)
    typename Policy0_,
    /// Policy describing tuning details (concept: MmaPolicy)
    typename Policy1_,
    /// Epilgue after Gemm 0
    typename Epilogue_,
    /// Number of stages,
    int Stages,
    /// Used for partial specialization
    typename Enable = bool>
class Mma2DShmBase {
 public:
  ///< Size of the Gemm problem - concept: gemm::GemmShape<>
  using Shape0 = Shape0_;
  using Shape1 = Shape1_;

  ///< Policy describing tuning details
  using Policy0 = Policy0_;
  using Policy1 = Policy1_;

  using Epilogue = Epilogue_;

  //
  // Dependent types
  //

  /// Warp-level Mma
  using Operator0 = typename Policy0::Operator;
  using Operator1 = typename Policy1::Operator;

  /// Shape describing the overall GEMM computed from shared memory
  /// by each warp.
  using WarpGemm0 = typename Policy0::Operator::Shape;
  using WarpGemm1 = typename Policy1::Operator::Shape;

  /// Shape describing the number of warps filling the CTA
  using WarpCount0 = cutlass::gemm::GemmShape<Shape0::kM / WarpGemm0::kM,
                                              Shape0::kN / WarpGemm0::kN,
                                              Shape0::kK / WarpGemm0::kK>;
  using WarpCount1 = cutlass::gemm::GemmShape<Shape1::kM / WarpGemm1::kM,
                                              Shape1::kN / WarpGemm1::kN,
                                              Shape1::kK / WarpGemm1::kK>;

  /// Number of warp-level GEMM oeprations
  static int const kWarpGemmIterations0 = (WarpGemm0::kK / Operator0::Policy::MmaShape::kK);
  static int const kWarpGemmIterations1 = (WarpGemm1::kK / Operator1::Policy::MmaShape::kK);

  /// Number of stages
  static int const kStages = Stages;

  //
  // Nested structs
  //

  /// Shared storage object needed by threadblock-scoped GEMM
  template <typename Shape_, typename Policy_>
  class SharedStorage {
   public:
    //
    // Type definitions
    //
    using Shape = Shape_;
    using Policy = Policy_;
    using Operator = typename Policy::Operator;

    /// Tensor reference to the A operand
    using TensorRefA = TensorRef<typename Operator::ElementA, typename Operator::LayoutA>;

    /// Tensor reference to the B operand
    using TensorRefB = TensorRef<typename Operator::ElementB, typename Operator::LayoutB>;

    /// Shape of the A matrix operand in shared memory
    using ShapeA = MatrixShape<Shape::kM + Policy::SmemPaddingA::kRow,
                               Shape::kK * kStages + Policy::SmemPaddingA::kColumn>;

    /// Shape of the B matrix operand in shared memory
    using ShapeB = MatrixShape<Shape::kK * kStages + Policy::SmemPaddingB::kRow,
                               Shape::kN + Policy::SmemPaddingB::kColumn>;

   public:
    //
    // Data members
    //

    /// Buffer for A operand
    AlignedBuffer<typename Operator::ElementA, ShapeA::kCount> operand_A;

    /// Buffer for B operand
    AlignedBuffer<typename Operator::ElementB, ShapeB::kCount> operand_B;

   public:
    //
    // Methods
    //

    /// Returns a layout object for the A matrix
    CUTLASS_DEVICE
    static typename Operator::LayoutA LayoutA() {
      return Operator::LayoutA::packed({ShapeA::kRow, ShapeA::kColumn});
    }

    /// Returns a layout object for the B matrix
    CUTLASS_HOST_DEVICE
    static typename Operator::LayoutB LayoutB() {
      return Operator::LayoutB::packed({ShapeB::kRow, ShapeB::kColumn});
    }

    /// Returns a TensorRef to the A operand
    CUTLASS_HOST_DEVICE
    TensorRefA operand_A_ref() {
      return TensorRefA{operand_A.data(), LayoutA()};
    }

    /// Returns a TensorRef to the B operand
    CUTLASS_HOST_DEVICE
    TensorRefB operand_B_ref() {
      return TensorRefB{operand_B.data(), LayoutB()};
    }
  };

  using SharedStorage0 = SharedStorage<Shape0, Policy0>;
  using SharedStorage1 = SharedStorage<Shape1, Policy1>;
  union Mma2DSharedStorage {
    SharedStorage0 shared_storage0;
    SharedStorage1 shared_storage1;
    typename Epilogue::SharedStorage epilogue;
  };

 protected:
  //
  // Data members
  //

  /// Iterator to load a warp-scoped tile of A0 operand from shared memory
  typename Operator0::IteratorA warp_tile_iterator_A0_;

  /// Iterator to load a warp-scoped tile of B0 operand from shared memory
  typename Operator0::IteratorB warp_tile_iterator_B0_;

  /// Iterator to load a warp-scoped tile of A1 operand from shared memory
  typename Operator1::IteratorA warp_tile_iterator_A1_;

  /// Iterator to load a warp-scoped tile of B1 operand from shared memory
  typename Operator1::IteratorB warp_tile_iterator_B1_;

 public:
  /// Construct from tensor references
  CUTLASS_DEVICE
  Mma2DShmBase(
      ///< Shared storage needed for internal use by threadblock-scoped GEMM
      Mma2DSharedStorage& shared_storage,
      ///< ID within the threadblock
      int thread_idx,
      ///< ID of warp
      int warp_idx,
      ///< ID of each thread within a warp
      int lane_idx)
      : warp_tile_iterator_A0_(shared_storage.shared_storage0.operand_A_ref(), lane_idx),
        warp_tile_iterator_B0_(shared_storage.shared_storage0.operand_B_ref(), lane_idx),
        warp_tile_iterator_A1_(shared_storage.shared_storage1.operand_A_ref(), lane_idx),
        warp_tile_iterator_B1_(shared_storage.shared_storage1.operand_B_ref(), lane_idx) {
    // printf("0_A: %d, 0_B: %d, 1_A: %d, 1_B: %d, padA_row: %d, padB_row: %d, stages: %d\n",
    // shared_storage.shared_storage0.operand_A.kBytes,shared_storage.shared_storage0.operand_B.kBytes,
    // shared_storage.shared_storage1.operand_A.kBytes,shared_storage.shared_storage1.operand_B.kBytes,
    // SharedStorage0::Policy::SmemPaddingA::kRow,SharedStorage0::Policy::SmemPaddingB::kColumn,
    // Stages );
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace threadblock
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
