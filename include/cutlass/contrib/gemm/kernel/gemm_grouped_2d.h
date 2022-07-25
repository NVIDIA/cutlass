#pragma once

#include "cutlass/arch/memory.h"
#include "cutlass/complex.h"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/kernel/gemm_transpose_operands.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/matrix_coord.h"
#include "cutlass/semaphore.h"
#include "cutlass/trace.h"
#include "cutlass/util/debug.h"
#include "cutlass/util/device_dump.h"
#include "cutlass/contrib/args_pack_def.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace contrib {
namespace gemm {
namespace kernel {

template <typename ProblemSizeOperator0_,
          typename ProblemSizeOperator1_,
          typename BatchCountOperator_>
struct GemmGrouped2DProblemVisitor {
  using ProblemSizeOperator0 = ProblemSizeOperator0_;
  using ProblemSizeOperator1 = ProblemSizeOperator1_;
  using BatchCountOperator = BatchCountOperator_;

  struct Params {
    typename ProblemSizeOperator0::Params problem_size_op_0;
    typename ProblemSizeOperator1::Params problem_size_op_1;
    typename BatchCountOperator::Params batch_count_op;
    int32_t problem_count;

    //
    // Methods
    //

    /// Ctor
    CUTLASS_HOST_DEVICE
    Params() : problem_count(0) {
    }

    /// Ctor
    CUTLASS_HOST_DEVICE
    Params(typename ProblemSizeOperator0::Params problem_size_op_0,
           typename ProblemSizeOperator1::Params problem_size_op_1,
           typename BatchCountOperator::Params batch_count_op,
           int32_t problem_count)
        : problem_size_op_0(problem_size_op_0),
          problem_size_op_1(problem_size_op_1),
          batch_count_op(batch_count_op),
          problem_count(problem_count) {
    }
  };

  struct SharedStorage {
    /// currently nothing
  };

  //
  // Data members
  //

  SharedStorage& shared_storage;
  Params const& params;

  ProblemSizeOperator0 problem_size_op_0;
  ProblemSizeOperator1 problem_size_op_1;
  BatchCountOperator batch_count_op;

  cutlass::MatrixCoord threadblock_shape_0;
  cutlass::MatrixCoord threadblock_shape_1;

  int32_t tile_idx;
  int32_t group_problem_start;
  // tile range of current group of problems: [group_tile_start, group_tile_end)
  int32_t group_tile_start;
  int32_t group_tile_end;
  int32_t presum_in_group;
  int32_t count_in_group;
  int32_t problem_idx;
  // tile range of current problem: [problem_tile_start, problem_tile_end)
  int32_t problem_tile_start;
  int32_t problem_tile_end;

  //
  // Methods
  //
  CUTLASS_DEVICE
  GemmGrouped2DProblemVisitor(Params const& params_,
                              SharedStorage& shared_storage_,
                              cutlass::MatrixCoord threadblock_shape_0_,
                              cutlass::MatrixCoord threadblock_shape_1_,
                              int32_t block_idx)
      : shared_storage(shared_storage_),
        params(params_),
        problem_size_op_0(params.problem_size_op_0),
        problem_size_op_1(params.problem_size_op_1),
        batch_count_op(params.batch_count_op),
        threadblock_shape_0(threadblock_shape_0_),
        threadblock_shape_1(threadblock_shape_1_),
        tile_idx(block_idx),
        group_problem_start(-32),
        group_tile_start(0),
        group_tile_end(0),
        problem_idx(-1),
        problem_tile_start(0),
        problem_tile_end(0) {
  }

  /// Get the grid shape
  CUTLASS_HOST_DEVICE
  static cutlass::gemm::GemmCoord grid_shape(cutlass::gemm::GemmCoord problem,
                                             cutlass::MatrixCoord const& block_shape,
                                             int32_t batch_count) {
    return cutlass::gemm::GemmCoord(
        ((problem.m() - 1 + block_shape.row()) / block_shape.row()),
        ((problem.n() - 1 + block_shape.column()) / block_shape.column()),
        batch_count);
  }

  CUTLASS_HOST_DEVICE
  cutlass::gemm::GemmCoord grid_shape_0(cutlass::gemm::GemmCoord problem) {
    return grid_shape(problem, threadblock_shape_0, batch_count_op(problem_idx));
  }

  CUTLASS_HOST_DEVICE
  cutlass::gemm::GemmCoord grid_shape_1(cutlass::gemm::GemmCoord problem) {
    return grid_shape(problem, threadblock_shape_1, batch_count_op(problem_idx));
  }

  CUTLASS_DEVICE
  bool next_tile() {
    if (tile_idx < problem_tile_end) {
      // tile idx still in current problem range
      return true;
    }

    int lane_idx = threadIdx.x % 32;

    while (group_tile_end <= tile_idx) {
      group_problem_start += 32;
      if (group_problem_start > params.problem_count) {
        return false;
      }
      group_tile_start = group_tile_end;
      // int32_t prev_sum = 0;
      int32_t problem_idx = group_problem_start + lane_idx;
      count_in_group = 0;
      if (problem_idx < params.problem_count) {
        cutlass::gemm::GemmCoord problem = problem_size_op_0(problem_idx);
        cutlass::gemm::GemmCoord grid =
            grid_shape(problem, threadblock_shape_0, batch_count_op(problem_idx));
        count_in_group = grid.m() * grid.n() * grid.k();
      }
      presum_in_group = count_in_group;
      CUTLASS_PRAGMA_UNROLL
      for (int i = 1; i < 32; i <<= 1) {
        int32_t val = __shfl_up_sync(0xffffffff, presum_in_group, i);
        if (lane_idx >= i) {
          presum_in_group += val;
        }
      }
      int32_t total = __shfl_sync(0xffffffff, presum_in_group, 31);
      group_tile_end += total;
    }

    int32_t problem_idx_in_group =
        __popc(__ballot_sync(0xffffffff, presum_in_group <= tile_idx - group_tile_start));
    problem_idx = group_problem_start + problem_idx_in_group;
    int32_t count = __shfl_sync(0xffffffff, count_in_group, problem_idx_in_group);
    int32_t presum = __shfl_sync(0xffffffff, presum_in_group, problem_idx_in_group);
    problem_tile_start = group_tile_start + presum - count;
    problem_tile_end = group_tile_start + presum;
    return true;
  }

  /// Gets the global tile index
  CUTLASS_HOST_DEVICE
  int32_t tile_index() const {
    return tile_idx;
  }

  /// Gets the index of the problem
  CUTLASS_HOST_DEVICE
  int32_t problem_index() const {
    return problem_idx;
  }

  /// Returns the problem size for the current problem
  CUTLASS_HOST_DEVICE
  cutlass::gemm::GemmCoord problem_size_0() const {
    cutlass::gemm::GemmCoord problem = problem_size_op_0(problem_idx);
    return problem;
  }

  /// Returns the problem size for the current problem
  CUTLASS_HOST_DEVICE
  cutlass::gemm::GemmCoord problem_size_1() const {
    cutlass::gemm::GemmCoord problem = problem_size_op_1(problem_idx);
    return problem;
  }

  CUTLASS_HOST_DEVICE
  int32_t threadblock_index() const {
    return tile_idx - problem_tile_start;
  }

  CUTLASS_DEVICE
  void advance(int32_t grid_size) {
    tile_idx += grid_size;
  }
};

template <typename ProblemSizeOperator0_,
          typename ProblemSizeOperator1_,
          typename BatchCountOperator_,
          typename ParamOperatorA_,
          typename ParamOperatorB0_,
          typename ParamOperatorB1_,
          typename ParamOperatorC0_,
          typename ParamOperatorC1_,
          typename ParamOperatorD_>
struct Gemm2DParamsDef {
  using ProblemSizeOperator0 = ProblemSizeOperator0_;
  using ProblemSizeOperator1 = ProblemSizeOperator1_;
  using BatchCountOperator = BatchCountOperator_;
  using ParamOperatorA = ParamOperatorA_;
  using ParamOperatorB0 = ParamOperatorB0_;
  using ParamOperatorB1 = ParamOperatorB1_;
  using ParamOperatorC0 = ParamOperatorC0_;
  using ParamOperatorC1 = ParamOperatorC1_;
  using ParamOperatorD = ParamOperatorD_;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Mma2D_,     ///! Threadblock-scoped matrix multiply-accumulate
          typename Epilogue_,  ///! Epilogue
          typename ParamsDef_>
struct GemmGrouped2D {
  using Mma2D = Mma2D_;
  // using Epilogue0 = typename Mma2D::Epilogue;
  using Epilogue1 = Epilogue_;
  using ParamsDef = ParamsDef_;
  using OutputOp0 = typename Mma2D::OutputOp;
  using OutputOp1 = typename Epilogue1::OutputOp;

  using ElementA = typename Mma2D::IteratorA0::Element;
  using LayoutA = typename Mma2D::IteratorA0::Layout;
  using PrologueDefA = typename Mma2D::PrologueDefA0;

  using ElementB0 = typename Mma2D::IteratorB0::Element;
  using LayoutB0 = typename Mma2D::IteratorB0::Layout;
  using PrologueDefB0 = typename Mma2D::PrologueDefB0;

  using ElementB1 = typename Mma2D::IteratorB1::Element;
  using LayoutB1 = typename Mma2D::IteratorB1::Layout;
  using PrologueDefB1 = typename Mma2D::PrologueDefB1;

  using ElementC0 = typename Mma2D::ElementC;
  using LayoutC0 = typename Mma2D::LayoutC;

  using ElementC1 = typename Epilogue1::OutputTileIterator::Element;
  using LayoutC1 = typename Epilogue1::OutputTileIterator::Layout;

  using ProblemVisitor = GemmGrouped2DProblemVisitor<typename ParamsDef::ProblemSizeOperator0,
                                                     typename ParamsDef::ProblemSizeOperator1,
                                                     typename ParamsDef::BatchCountOperator>;

  /// Warp count (concept: GemmShape)
  using WarpCount0 = typename Mma2D::WarpCount0;
  using WarpShape0 = typename Mma2D::WarpGemm0;
  using ThreadblockShape0 = typename Mma2D::Shape0;
  using WarpShape1 = typename Mma2D::WarpGemm1;
  using ThreadblockShape1 = typename Mma2D::Shape1;
  static int const kThreadCount = 32 * WarpCount0::kCount;

  /// Argument structure
  struct Arguments {
    //
    // Data members
    //

    cutlass::gemm::GemmUniversalMode mode;
    int problem_count;
    int threadblock_count;

    typename ParamsDef::ProblemSizeOperator0::Params problem_size_op_0;
    typename ParamsDef::ProblemSizeOperator1::Params problem_size_op_1;
    typename ParamsDef::BatchCountOperator::Params batch_count_op;

    typename PrologueDefA::Operator::Params prologue_op_A;
    typename PrologueDefB0::Operator::Params prologue_op_B0;
    typename PrologueDefB1::Operator::Params prologue_op_B1;

    typename OutputOp0::Params output_op_0;
    typename OutputOp1::Params output_op_1;

    typename ParamsDef::ParamOperatorA::Params param_A_op;
    typename ParamsDef::ParamOperatorB0::Params param_B0_op;
    typename ParamsDef::ParamOperatorB1::Params param_B1_op;
    typename ParamsDef::ParamOperatorC0::Params param_C0_op;
    typename ParamsDef::ParamOperatorC1::Params param_C1_op;
    typename ParamsDef::ParamOperatorD::Params param_D_op;

    //
    // Methods
    //

    /// Default ctor
    CUTLASS_HOST_DEVICE
    Arguments()
        : mode(cutlass::gemm::GemmUniversalMode::kGemm), problem_count(0), threadblock_count(0) {
    }

    /// Ctor
    CUTLASS_HOST_DEVICE
    Arguments(cutlass::gemm::GemmUniversalMode mode,
              int problem_count,
              int threadblock_count,
              typename ParamsDef::ProblemSizeOperator0::Params problem_size_op_0,
              typename ParamsDef::ProblemSizeOperator1::Params problem_size_op_1,
              typename ParamsDef::BatchCountOperator::Params batch_count_op,
              typename PrologueDefA::Operator::Params prologue_op_A,
              typename PrologueDefB0::Operator::Params prologue_op_B0,
              typename PrologueDefB1::Operator::Params prologue_op_B1,
              typename OutputOp0::Params output_op_0,
              typename OutputOp1::Params output_op_1,
              typename ParamsDef::ParamOperatorA::Params param_A_op,
              typename ParamsDef::ParamOperatorB0::Params param_B0_op,
              typename ParamsDef::ParamOperatorB1::Params param_B1_op,
              typename ParamsDef::ParamOperatorC0::Params param_C0_op,
              typename ParamsDef::ParamOperatorC1::Params param_C1_op,
              typename ParamsDef::ParamOperatorD::Params param_D_op)
        : mode(mode),
          problem_count(problem_count),
          threadblock_count(threadblock_count),
          problem_size_op_0(problem_size_op_0),
          problem_size_op_1(problem_size_op_1),
          batch_count_op(batch_count_op),
          prologue_op_A(prologue_op_A),
          prologue_op_B0(prologue_op_B0),
          prologue_op_B1(prologue_op_B1),
          output_op_0(output_op_0),
          output_op_1(output_op_1),
          param_A_op(param_A_op),
          param_B0_op(param_B0_op),
          param_B1_op(param_B1_op),
          param_C0_op(param_C0_op),
          param_C1_op(param_C1_op),
          param_D_op(param_D_op) {
    }
  };

  /// Parameters structure
  struct Params {
    typename ProblemVisitor::Params problem_visitor;
    cutlass::gemm::GemmUniversalMode mode;
    int threadblock_count;

    typename PrologueDefA::Operator::Params prologue_op_A;
    typename PrologueDefB0::Operator::Params prologue_op_B0;
    typename PrologueDefB1::Operator::Params prologue_op_B1;
    typename OutputOp0::Params output_op_0;
    typename OutputOp1::Params output_op_1;

    typename ParamsDef::ParamOperatorA::Params param_A_op;
    typename ParamsDef::ParamOperatorB0::Params param_B0_op;
    typename ParamsDef::ParamOperatorB1::Params param_B1_op;
    typename ParamsDef::ParamOperatorC0::Params param_C0_op;
    typename ParamsDef::ParamOperatorC1::Params param_C1_op;
    typename ParamsDef::ParamOperatorD::Params param_D_op;

    //
    // Methods
    //

    CUTLASS_HOST_DEVICE
    Params() : mode(cutlass::gemm::GemmUniversalMode::kGemm) {
    }

    CUTLASS_HOST_DEVICE
    Params(Arguments const& args, void* workspace = nullptr)
        : problem_visitor(args.problem_size_op_0,
                          args.problem_size_op_1,
                          args.batch_count_op,
                          args.problem_count),
          mode(args.mode),
          threadblock_count(args.threadblock_count),
          prologue_op_A(args.prologue_op_A),
          prologue_op_B0(args.prologue_op_B0),
          prologue_op_B1(args.prologue_op_B1),
          output_op_0(args.output_op_0),
          output_op_1(args.output_op_1),
          param_A_op(args.param_A_op),
          param_B0_op(args.param_B0_op),
          param_B1_op(args.param_B1_op),
          param_C0_op(args.param_C0_op),
          param_C1_op(args.param_C1_op),
          param_D_op(args.param_D_op) {
    }

    CUTLASS_HOST_DEVICE void update(Arguments const& args, void* workspace = nullptr) {
      problem_visitor = typename ProblemVisitor::Params(
          args.problem_size_op_0, args.problem_size_op_1, args.batch_count_op, args.problem_count);
      mode = args.mode;
      threadblock_count = args.threadblock_count;
      prologue_op_A = args.prologue_op_A;
      prologue_op_B0 = args.prologue_op_B0;
      prologue_op_B1 = args.prologue_op_B1;
      output_op_0 = args.output_op_0;
      output_op_1 = args.output_op_1;
      param_A_op = args.param_A_op;
      param_B0_op = args.param_B0_op;
      param_B1_op = args.param_B1_op;
      param_C0_op = args.param_C0_op;
      param_C1_op = args.param_C1_op;
      param_D_op = args.param_D_op;
    }
  };

  /// Shared memory storage structure
  union SharedStorage {
    typename ProblemVisitor::SharedStorage problem_visitor;
    typename Mma2D::Mma2DSharedStorage main_loop;
    typename Epilogue1::SharedStorage epilogue;
  };

  //
  // Methods
  //

  CUTLASS_HOST_DEVICE
  GemmGrouped2D() {
  }

  /// Determines whether kernel satisfies alignment
  static Status can_implement(cutlass::gemm::GemmCoord const& problem_size) {
    return Status::kSuccess;
  }

  static Status can_implement(Arguments const& args) {
    return Status::kSuccess;
  }

  static size_t get_extra_workspace_size(Arguments const& args,
                                         cutlass::gemm::GemmCoord const& grid_tiled_shape) {
    return 0;
  }

  /// Executes one GEMM
  CUTLASS_DEVICE
  void operator()(Params const& params, SharedStorage& shared_storage) {
    //
    // These types shadow the type-level definitions and support the ability to implement
    // a 'transposed' GEMM that computes the transposed problems.
    //
    // Problem visitor.
    //

    // auto start = clock64();
    ProblemVisitor problem_visitor(params.problem_visitor,
                                   shared_storage.problem_visitor,
                                   {Mma2D::Shape0::kM, Mma2D::Shape0::kN},
                                   {Mma2D::Shape1::kM, Mma2D::Shape1::kN},
                                   blockIdx.x);

    typename ParamsDef::ParamOperatorA param_A_op(params.param_A_op);
    typename ParamsDef::ParamOperatorB0 param_B0_op(params.param_B0_op);
    typename ParamsDef::ParamOperatorB1 param_B1_op(params.param_B1_op);
    typename ParamsDef::ParamOperatorC0 param_C0_op(params.param_C0_op);
    typename ParamsDef::ParamOperatorC1 param_C1_op(params.param_C1_op);
    typename ParamsDef::ParamOperatorD param_D_op(params.param_D_op);

    // Outer 'persistent' loop to iterate over tiles
    while (problem_visitor.next_tile()) {
      int problem_idx = problem_visitor.problem_index();
      int cta_idx = int32_t(problem_visitor.threadblock_index());

      cutlass::gemm::GemmCoord problem_size_0 = problem_visitor.problem_size_0();
      cutlass::gemm::GemmCoord problem_size_1 = problem_visitor.problem_size_1();

      cutlass::gemm::GemmCoord grid_shape_0 = problem_visitor.grid_shape_0(problem_size_0);

      int batch_idx = cta_idx / (grid_shape_0.m() * grid_shape_0.n());
      cta_idx %= grid_shape_0.m() * grid_shape_0.n();

      cutlass::gemm::GemmCoord threadblock_offset_0(
          int(cta_idx / grid_shape_0.n()) * Mma2D::Shape0::kM,
          int(cta_idx % grid_shape_0.n()) * Mma2D::Shape0::kN,
          0);

      cutlass::gemm::GemmCoord threadblock_offset_1(
          int(cta_idx / grid_shape_0.n()) * Mma2D::Shape1::kM,
          int(cta_idx % grid_shape_0.n()) * Mma2D::Shape1::kN,
          0);

      // Compute initial location in logical coordinates
      cutlass::MatrixCoord tb_offset_A{
          threadblock_offset_0.m(),
          0,
      };

      cutlass::MatrixCoord tb_offset_B_0{0, threadblock_offset_0.n()};

      cutlass::MatrixCoord tb_offset_B_1{0, threadblock_offset_1.n()};

      // Compute position within threadblock
      int thread_idx = threadIdx.x;

      cutlass::contrib::TensorParams<ElementA> params_A = param_A_op(problem_idx, batch_idx);
      // Construct iterators to A and B operands
      typename Mma2D::IteratorA0 iterator_A(LayoutA(params_A.ldm),
                                            params_A.ptr,
                                            {problem_size_0.m(), problem_size_0.k()},
                                            thread_idx,
                                            tb_offset_A);

      cutlass::contrib::TensorParams<ElementB0> params_B0 = param_B0_op(problem_idx, batch_idx);
      typename Mma2D::IteratorB0 iterator_B_0(LayoutB0(params_B0.ldm),
                                              params_B0.ptr,
                                              {problem_size_0.k(), problem_size_0.n()},
                                              thread_idx,
                                              tb_offset_B_0);
      cutlass::contrib::TensorParams<ElementB1> params_B1 = param_B1_op(problem_idx, batch_idx);
      typename Mma2D::IteratorB1 iterator_B_1(LayoutB1(params_B1.ldm),
                                              params_B1.ptr,
                                              {problem_size_1.k(), problem_size_1.n()},
                                              thread_idx,
                                              tb_offset_B_1);
      using Epilogue0 = typename Mma2D::Epilogue;

      cutlass::contrib::TensorParams<ElementC0> params_C0 = param_C0_op(problem_idx, batch_idx);
      // Tile iterator loading from source tensor.
      typename Epilogue0::OutputTileIterator iterator_C_0(
          typename Epilogue0::OutputTileIterator::Params(LayoutC0(params_C0.ldm)),
          params_C0.ptr,
          problem_size_0.mn(),
          thread_idx,
          threadblock_offset_0.mn());

      // Broadcast the warp_id computed by lane 0 to ensure dependent code
      // is compiled as warp-uniform.
      int warp_idx = __shfl_sync(0xffffffff, threadIdx.x / 32, 0);

      int lane_idx = threadIdx.x % 32;

      int warp_idx_mn = warp_idx % (WarpCount0::kM * WarpCount0::kN);

      int warp_idx_m = warp_idx_mn % WarpCount0::kM;
      int warp_idx_n = warp_idx_mn / WarpCount0::kM;

      cutlass::gemm::GemmCoord warp_offset_0 =
          threadblock_offset_0 +
          cutlass::gemm::GemmCoord(warp_idx_m * WarpShape0::kM, warp_idx_n * WarpShape0::kN, 0);
      cutlass::gemm::GemmCoord warp_offset_1 =
          threadblock_offset_1 +
          cutlass::gemm::GemmCoord(warp_idx_m * WarpShape1::kM, warp_idx_n * WarpShape1::kN, 0);
      //
      // Matrix multiply phase
      //

      // Construct thread-scoped matrix multiply
      Mma2D mma(shared_storage.main_loop, thread_idx, warp_idx, lane_idx);

      OutputOp0 output_op_0(params.output_op_0);

      typename Mma2D::FragmentC0 accum0;
      typename Mma2D::FragmentC1 accumulators;

      accum0.clear();
      accumulators.clear();

      // Compute threadblock-scoped matrix multiply-add
      int gemm_k_iterations_0 = (problem_size_0.k() + Mma2D::Shape0::kK - 1) / Mma2D::Shape0::kK;
      int gemm_k_iterations_1 = (problem_size_1.k() + Mma2D::Shape1::kK - 1) / Mma2D::Shape1::kK;

      // Wait for all threads to finish their epilogue phases from the previous tile.
      __syncthreads();

      // Compute threadblock-scoped matrix multiply-add
      if (gemm_k_iterations_0 > 0) {
        typename PrologueDefA::Operator prologue_op_A(params.prologue_op_A,
                                                      problem_idx,
                                                      batch_idx,
                                                      {problem_size_0.m(), problem_size_0.k()},
                                                      {warp_offset_0.m(), 0});
        typename PrologueDefB0::Operator prologue_op_B0(params.prologue_op_B0,
                                                        problem_idx,
                                                        batch_idx,
                                                        {problem_size_0.k(), problem_size_0.n()},
                                                        {0, warp_offset_0.n()});
        typename PrologueDefB1::Operator prologue_op_B1(params.prologue_op_B1,
                                                        problem_idx,
                                                        batch_idx,
                                                        {problem_size_1.k(), problem_size_1.n()},
                                                        {0, warp_offset_1.n()});
        typename Mma2D::FragmentIteratorA1 warp_tile_iterator_A1(accum0, problem_size_1.k());
        mma.gemm0(gemm_k_iterations_0,
                  iterator_A,
                  iterator_B_0,
                  iterator_C_0,
                  prologue_op_A,
                  prologue_op_B0,
                  output_op_0,
                  accum0);
        mma.gemm1(gemm_k_iterations_1,
                  accum0,
                  warp_tile_iterator_A1,
                  iterator_B_1,
                  prologue_op_B1,
                  accumulators);
      }

      //
      // Epilogue
      //

      OutputOp1 output_op_1(params.output_op_1);

      cutlass::contrib::TensorParams<ElementC1> params_C1 = param_C1_op(problem_idx, batch_idx);
      // Tile iterator loading from source tensor.
      typename Epilogue1::OutputTileIterator iterator_C(
          typename Epilogue1::OutputTileIterator::Params(LayoutC1(params_C1.ldm)),
          params_C1.ptr,
          problem_size_1.mn(),
          thread_idx,
          threadblock_offset_1.mn());

      cutlass::contrib::TensorParams<ElementC1> params_D = param_D_op(problem_idx, batch_idx);
      // Tile iterator writing to destination tensor.
      typename Epilogue1::OutputTileIterator iterator_D(
          typename Epilogue1::OutputTileIterator::Params(LayoutC1(params_D.ldm)),
          params_D.ptr,
          problem_size_1.mn(),
          thread_idx,
          threadblock_offset_1.mn());

      Epilogue1 epilogue(shared_storage.epilogue, thread_idx, warp_idx, lane_idx);

      // Execute the epilogue operator to update the destination tensor.
      epilogue(output_op_1, iterator_D, accumulators, iterator_C);

      // Next tile
      problem_visitor.advance(gridDim.x);
    }
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace kernel
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
