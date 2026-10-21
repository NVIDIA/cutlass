// Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

#include "../../common/cutlass_unit_test.h"
#include "cutlass/numeric_conversion.h"
#include "cutlass/epilogue/fusion/sm90_visitor_tma_warpspecialized.hpp"

namespace {

template <size_t Size>
struct MockWorkspaceOp {
  struct SharedStorage {};
  struct Arguments {};
  struct Params { uint8_t* workspace; };

  template <bool IsLoad>
  using TensorMaps = cute::tuple<>;

  template <class ProblemShape>
  static constexpr Params to_underlying_arguments(
      ProblemShape const&, Arguments const&, void* workspace) {
    return {reinterpret_cast<uint8_t*>(workspace)};
  }

  template <class ProblemShape>
  static bool can_implement(ProblemShape const&, Arguments const&) { return true; }

  template <class ProblemShape>
  static size_t get_workspace_size(ProblemShape const&, Arguments const&) { return Size; }

  template <class ProblemShape>
  static cutlass::Status initialize_workspace(
      ProblemShape const&, Arguments const&, void*, cudaStream_t,
      cutlass::CudaHostAdapter* = nullptr) {
    return cutlass::Status::kSuccess;
  }

  CUTLASS_HOST_DEVICE MockWorkspaceOp() {}
  CUTLASS_HOST_DEVICE MockWorkspaceOp(Params const&, SharedStorage const&) {}
};

ptrdiff_t offset_from(uint8_t* pointer, uint8_t* workspace) {
  return pointer - workspace;
}

} // namespace

TEST(Epilogue_Threadblock, Sm90VisitorWorkspaceAlignment) {
  alignas(16) uint8_t workspace[64] = {};
  auto problem_shape = cute::Shape<cute::_1>{};

  using Visitor2 = cutlass::epilogue::fusion::Sm90VisitorImplBase<
      MockWorkspaceOp<3>, MockWorkspaceOp<5>>;
  auto params2 = Visitor2::to_underlying_arguments(
      problem_shape, typename Visitor2::Arguments{}, workspace);
  EXPECT_EQ(offset_from(params2.op_1.workspace, workspace), 16);

  using Visitor3 = cutlass::epilogue::fusion::Sm90VisitorImplBase<
      MockWorkspaceOp<3>, MockWorkspaceOp<5>, MockWorkspaceOp<7>>;
  auto params3 = Visitor3::to_underlying_arguments(
      problem_shape, typename Visitor3::Arguments{}, workspace);
  EXPECT_EQ(offset_from(params3.op_1.workspace, workspace), 16);
  EXPECT_EQ(offset_from(params3.op_2.workspace, workspace), 32);

  using Visitor4 = cutlass::epilogue::fusion::Sm90VisitorImplBase<
      MockWorkspaceOp<3>, MockWorkspaceOp<5>, MockWorkspaceOp<7>, MockWorkspaceOp<9>>;
  auto params4 = Visitor4::to_underlying_arguments(
      problem_shape, typename Visitor4::Arguments{}, workspace);
  EXPECT_EQ(offset_from(params4.op_1.workspace, workspace), 16);
  EXPECT_EQ(offset_from(params4.op_2.workspace, workspace), 32);
  EXPECT_EQ(offset_from(params4.op_3.workspace, workspace), 48);
}
