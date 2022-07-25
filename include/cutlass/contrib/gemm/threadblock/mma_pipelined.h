#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/array.h"
#include "cutlass/aligned_buffer.h"
#include "cutlass/numeric_conversion.h"

#include "cutlass/numeric_types.h"
#include "cutlass/matrix_shape.h"

#include "cutlass/gemm/gemm.h"
#include "cutlass/contrib/gemm/threadblock/mma_base.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace contrib {
namespace gemm {
namespace threadblock {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Structure to compute the matrix product targeting CUDA cores and SIMT math instructions.
template <
    /// Size of the Gemm problem - concept: gemm::GemmShape<>
    typename Shape_,
    /// Iterates over tiles of A operand in global memory
    //  (concept: ReadableTileIterator | ForwardTileIterator | MaskedTileIterator)
    typename IteratorA_,
    /// Iterates over tiles of A operand in shared memory
    /// (concept: WriteableTileIterator | RandomAccessTileIterator)
    typename SmemIteratorA_,
    /// Iterates over tiles of B operand in global memory
    //  (concept: ReadableTileIterator | ForwardTileIterator | MaskedTileIterator)
    typename IteratorB_,
    /// Iterates over tiles of B operand in shared memory
    /// (concept: WriteableTileIterator | RandomAccessTileIterator)
    typename SmemIteratorB_,
    /// Data type of accumulator matrix
    typename ElementC_,
    /// Data type of accumulator matrix
    typename LayoutC_,
    /// Policy describing tuning details (concept: MmaPolicy)
    typename Policy_,
    /// Prologue of A
    typename PrologueDefA_,
    /// Prologue of B
    typename PrologueDefB_,
    /// Used for partial specialization
    typename Enable = bool>
class MmaPipelined : public cutlass::contrib::gemm::threadblock::MmaBase<Shape_, Policy_, 2> {
 public:
  ///< Base class
  using Base = cutlass::contrib::gemm::threadblock::MmaBase<Shape_, Policy_, 2>;

  using Shape = Shape_;          ///< Size of the Gemm problem - concept: gemm::GemmShape<>
  using IteratorA = IteratorA_;  ///< Iterates over tiles of A operand in global memory
  using IteratorB = IteratorB_;  ///< Iterates over tiles of B operand in global memory
  using ElementC = ElementC_;    ///< Data type of accumulator matrix
  using LayoutC = LayoutC_;      ///< Layout of accumulator matrix
  using Policy = Policy_;        ///< Policy describing tuning details

  using SmemIteratorA = SmemIteratorA_;
  using SmemIteratorB = SmemIteratorB_;

  using PrologueDefA = PrologueDefA_;
  using PrologueOpA = typename PrologueDefA::Operator;

  using PrologueDefB = PrologueDefB_;
  using PrologueOpB = typename PrologueDefB::Operator;

  //
  // Dependent types
  //

  /// Fragment of operand A loaded from global memory
  using FragmentA = typename IteratorA::Fragment;

  /// Fragment of operand B loaded from global memory
  using FragmentB = typename IteratorB::Fragment;

  /// Fragment of accumulator tile
  using FragmentC = typename Policy::Operator::FragmentC;

  /// Warp-level Mma
  using Operator = typename Policy::Operator;

  /// Obtain the arch tag from the warp-level operator
  using ArchTag = typename Policy::Operator::ArchTag;

  /// Complex transform on A operand
  static ComplexTransform const kTransformA = Operator::kTransformA;

  /// Complex transform on B operand
  static ComplexTransform const kTransformB = Operator::kTransformB;

  // staticaly assert kStages for MmaPipelined is two (Double-buffered pipeline)
  static_assert((Base::kStages == 2), "MmaPipelined requires kStages set to value 2");

 private:
  using WarpFragmentA = typename Operator::FragmentA;
  using WarpFragmentB = typename Operator::FragmentB;

 protected:
  /// Iterator to write threadblock-scoped tile of A operand to shared memory
  SmemIteratorA smem_iterator_A_;

  /// Iterator to write threadblock-scoped tile of B operand to shared memory
  SmemIteratorB smem_iterator_B_;

 public:
  /// Construct from tensor references
  CUTLASS_DEVICE
  MmaPipelined(
      typename Base::SharedStorage&
          shared_storage,  ///< Shared storage needed for internal use by threadblock-scoped GEMM
      int thread_idx,      ///< ID within the threadblock
      int warp_idx,        ///< ID of warp
      int lane_idx         ///< ID of each thread within a warp
      )
      : Base(shared_storage, thread_idx, warp_idx, lane_idx),
        smem_iterator_A_(shared_storage.operand_A_ref(), thread_idx),
        smem_iterator_B_(shared_storage.operand_B_ref(), thread_idx) {
    // Compute warp location within threadblock tile by mapping the warp_id to
    // three coordinates:
    //   _m: the warp's position within the threadblock along the M dimension
    //   _n: the warp's position within the threadblock along the N dimension
    //   _k: the warp's position within the threadblock along the K dimension

    int warp_idx_mn = warp_idx % (Base::WarpCount::kM * Base::WarpCount::kN);
    int warp_idx_k = warp_idx / (Base::WarpCount::kM * Base::WarpCount::kN);

    int warp_idx_m = warp_idx_mn % Base::WarpCount::kM;
    int warp_idx_n = warp_idx_mn / Base::WarpCount::kM;

    // Add per-warp offsets in units of warp-level tiles
    this->warp_tile_iterator_A_.add_tile_offset(
        {warp_idx_m, Base::kWarpGemmIterations * warp_idx_k});
    this->warp_tile_iterator_B_.add_tile_offset(
        {Base::kWarpGemmIterations * warp_idx_k, warp_idx_n});
  }

  /// Perform a threadblock-scoped matrix multiply-accumulate
  CUTLASS_DEVICE
  void operator()(int gemm_k_iterations,         ///< number of iterations of the mainloop
                  FragmentC& accum,              ///< destination accumulator tile
                  IteratorA iterator_A,          ///< iterator over A operand in global memory
                  IteratorB iterator_B,          ///< iterator over B operand in global memory
                  PrologueOpA prologue_op_A,     ///< transformation applied to A fragment
                  PrologueOpB prologue_op_B,     ///< transformation applied to B fragment
                  FragmentC const& src_accum) {  ///< source accumulator tile

    //
    // Prologue
    //
    using WarpLoadIteratorA = typename Base::Operator::IteratorA;
    using WarpLoadIteratorB = typename Base::Operator::IteratorB;

    // Perform accumulation in the 'd' output operand
    accum = src_accum;

    FragmentA tb_frag_A;
    FragmentB tb_frag_B;

    tb_frag_A.clear();
    tb_frag_B.clear();

    // The last kblock is loaded in the prolog
    iterator_A.load(tb_frag_A);
    iterator_B.load(tb_frag_B);

    ++iterator_A;
    ++iterator_B;

    this->smem_iterator_A_.store(tb_frag_A);
    this->smem_iterator_B_.store(tb_frag_B);

    ++this->smem_iterator_A_;
    ++this->smem_iterator_B_;

    typename PrologueOpA::Detail<WarpLoadIteratorA>::Fragment prologue_frag_A;
    typename PrologueOpB::Detail<WarpLoadIteratorB>::Fragment prologue_frag_B;
    prologue_op_A.template load<WarpLoadIteratorA>(prologue_frag_A);
    prologue_op_B.template load<WarpLoadIteratorB>(prologue_frag_B);

    __syncthreads();

    // Pair of fragments used to overlap shared memory loads and math instructions
    WarpFragmentA warp_frag_A[2];
    WarpFragmentB warp_frag_B[2];

    this->warp_tile_iterator_A_.set_kgroup_index(0);
    this->warp_tile_iterator_B_.set_kgroup_index(0);

    prologue_op_A.template set_kgroup_index<WarpLoadIteratorA>(0);
    prologue_op_B.template set_kgroup_index<WarpLoadIteratorB>(0);

    this->warp_tile_iterator_A_.load(warp_frag_A[0]);
    this->warp_tile_iterator_B_.load(warp_frag_B[0]);

    ++this->warp_tile_iterator_A_;
    ++this->warp_tile_iterator_B_;

    Operator warp_mma;

    int smem_write_stage_idx = 1;

    // Avoid reading out of bounds
    iterator_A.clear_mask(gemm_k_iterations <= 1);
    iterator_B.clear_mask(gemm_k_iterations <= 1);

    // Issue loads during the first warp-level matrix multiply-add *AFTER* issuing
    // shared memory loads (which have the tighest latency requirement).

    //
    // Mainloop
    //

    // Note: The main loop does not support Base::kWarpGemmIterations == 2.
    CUTLASS_GEMM_LOOP
    for (; gemm_k_iterations > 0; --gemm_k_iterations) {
      //
      // Loop over GEMM K dimension
      //

      CUTLASS_PRAGMA_UNROLL
      for (int warp_mma_k = 0; warp_mma_k < Base::kWarpGemmIterations; ++warp_mma_k) {
        // Load warp-level tiles from shared memory, wrapping to k offset if this is the last group
        // as the case may be.

        prologue_op_A.template set_kgroup_index<WarpLoadIteratorA>(warp_mma_k);
        prologue_op_B.template set_kgroup_index<WarpLoadIteratorB>(warp_mma_k);

        if (warp_mma_k == Base::kWarpGemmIterations - 1) {
          // Write fragments to shared memory
          this->smem_iterator_A_.store(tb_frag_A);

          this->smem_iterator_B_.store(tb_frag_B);

          __syncthreads();

          ++this->smem_iterator_A_;
          ++this->smem_iterator_B_;

          // Add negative offsets to return iterators to the 'start' of the circular buffer in
          // shared memory
          if (smem_write_stage_idx == 1) {
            this->smem_iterator_A_.add_tile_offset({0, -Base::kStages});
            this->smem_iterator_B_.add_tile_offset({-Base::kStages, 0});
          } else {
            this->warp_tile_iterator_A_.add_tile_offset(
                {0, -Base::kStages * Policy::kPartitionsK * Base::kWarpGemmIterations});
            this->warp_tile_iterator_B_.add_tile_offset(
                {-Base::kStages * Policy::kPartitionsK * Base::kWarpGemmIterations, 0});
          }

          smem_write_stage_idx ^= 1;
        }

        this->warp_tile_iterator_A_.set_kgroup_index((warp_mma_k + 1) % Base::kWarpGemmIterations);
        this->warp_tile_iterator_B_.set_kgroup_index((warp_mma_k + 1) % Base::kWarpGemmIterations);

        this->warp_tile_iterator_A_.load(warp_frag_A[(warp_mma_k + 1) % 2]);
        this->warp_tile_iterator_B_.load(warp_frag_B[(warp_mma_k + 1) % 2]);

        ++this->warp_tile_iterator_A_;
        ++this->warp_tile_iterator_B_;

        if (warp_mma_k == 0) {
          tb_frag_A.clear();
          tb_frag_B.clear();
          iterator_A.load(tb_frag_A);
          iterator_B.load(tb_frag_B);

          ++iterator_A;
          ++iterator_B;

          // Avoid reading out of bounds if this was the last loop iteration
          iterator_A.clear_mask(gemm_k_iterations <= 2);
          iterator_B.clear_mask(gemm_k_iterations <= 2);
        }

        warp_frag_A[warp_mma_k % 2] = prologue_op_A.template operator()<WarpLoadIteratorA>(
            warp_frag_A[warp_mma_k % 2], prologue_frag_A);
        warp_frag_B[warp_mma_k % 2] = prologue_op_B.template operator()<WarpLoadIteratorB>(
            warp_frag_B[warp_mma_k % 2], prologue_frag_B);

        warp_mma(accum, warp_frag_A[warp_mma_k % 2], warp_frag_B[warp_mma_k % 2], accum);
      }

      prologue_op_A.template operator++<WarpLoadIteratorA>();
      prologue_op_B.template operator++<WarpLoadIteratorB>();
      prologue_op_A.template load<WarpLoadIteratorA>(prologue_frag_A);
      prologue_op_B.template load<WarpLoadIteratorB>(prologue_frag_B);
    }
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace threadblock
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
